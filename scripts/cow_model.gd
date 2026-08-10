extends Node3D
class_name CowModel

## Builds the cow's visual mesh at runtime.
##
## The first pass used BoxMesh + CylinderMesh primitives and read as a crate on
## sticks, with the spots as flat plates hovering off the flanks. Everything
## here is lofted instead: a path, a radius per station, and a ring of vertices
## swept along it. That gives smooth normals and a continuous silhouette, which
## is the whole difference between "stylised" and "bad".
##
## Two meshes are produced: the body group (parented here) and the head group
## (parented to Neck, so cow.gd can pitch the head down to graze). Spots are
## vertex colours evaluated against noise-warped blobs on the body surface, so
## they wrap the form instead of sitting on top of it.
##
## Winding convention: every shell below is generated so that
## cross(p1 - p0, p2 - p0) points OUTWARD. Normals are accumulated from that,
## then the index order is reversed once at the end, because Godot treats the
## opposite winding as front-facing. Getting this backwards is what made the
## terrain collider's floor normals point down on day one.

const HIDE := Color(0.95, 0.93, 0.89)
const SPOT := Color(0.13, 0.11, 0.11)
const PINK := Color(0.93, 0.62, 0.61)
const HOOF := Color(0.15, 0.13, 0.13)
const HORN := Color(0.85, 0.79, 0.66)
const EYE := Color(0.05, 0.04, 0.04)
const GLINT := Color(1.0, 1.0, 1.0)

## Proportions are keyed to a real Holstein, scaled so the withers land at
## 1.50 and the belly at 0.76 (metres, hooves at y = 0):
##
##   width / withers height   0.41   - a cow is NARROW; this was the balloon
##   body depth vs width      deeper than wide, not flatter
##   ground to belly          ~52% of withers height
##   nose to rump             ~1.6x withers height
##
## The head is left about 15% over life size, which reads as stylised rather
## than as a mistake.
const WITHERS := 1.50
const BELLY := 0.76

## Blob centres in Model space, as (x, y, z, radius).
const SPOTS: Array[Vector4] = [
	Vector4(-0.24, 1.30, -0.30, 0.29),
	Vector4(0.28, 1.16, 0.14, 0.27),
	Vector4(-0.20, 0.98, 0.46, 0.23),
	Vector4(0.17, 1.40, -0.56, 0.21),
	Vector4(-0.07, 1.44, 0.54, 0.22),
	Vector4(0.25, 0.94, -0.06, 0.17),
]

var _noise: FastNoiseLite


## Accumulates several shells into one mesh.
class Shell:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	func add(part: Dictionary, color: Color) -> void:
		_add_tinted(part, func(_v: Vector3) -> Color: return color)

	func add_tinted(part: Dictionary, tint: Callable) -> void:
		_add_tinted(part, tint)

	func _add_tinted(part: Dictionary, tint: Callable) -> void:
		var base := verts.size()
		var pv: PackedVector3Array = part["verts"]
		var pi: PackedInt32Array = part["indices"]
		for v in pv:
			verts.append(v)
			colors.append(tint.call(v))
		for i in pi:
			indices.append(base + i)


func _ready() -> void:
	_noise = FastNoiseLite.new()
	_noise.seed = 7
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = 1.6

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.72
	mat.metallic = 0.0

	var neck: Node3D = $Neck
	_attach(self, _build_body(), mat, "BodyMesh")
	_attach(neck, _build_head(), mat, "HeadMesh")


func _attach(parent: Node3D, shell: Shell, mat: Material, node_name: String) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = _finish(shell, mat)
	parent.add_child(mi)


# ---------------------------------------------------------------- body group

func _build_body() -> Shell:
	var shell := Shell.new()

	# Ribcage. Nearly straight topline with a slight rise over the hips, and a
	# squash ABOVE 1 so the barrel is deeper than it is wide.
	var spine := PackedVector3Array([
		Vector3(0.0, 1.16, -0.96),
		Vector3(0.0, 1.16, -0.90),
		Vector3(0.0, 1.15, -0.76),
		Vector3(0.0, 1.14, -0.52),
		Vector3(0.0, 1.13, -0.22),
		Vector3(0.0, 1.13, 0.10),
		Vector3(0.0, 1.14, 0.38),
		Vector3(0.0, 1.15, 0.62),
		Vector3(0.0, 1.17, 0.80),
		Vector3(0.0, 1.18, 0.90),
		Vector3(0.0, 1.19, 0.96),
	])
	# Fuller through the brisket than a straight taper - a chest that narrows
	# to a point reads as a deer. Peak width sits at 0.35, between life size
	# (0.41 of withers height) and enough mass to still look like a cartoon.
	var barrel := PackedFloat32Array([
		0.05, 0.15, 0.26, 0.315, 0.34, 0.35, 0.345, 0.325, 0.27, 0.16, 0.05
	])
	# 80 x 76 is ~6k verts, which costs nothing and is chosen for the marking
	# edges rather than the silhouette - below about this density the spot
	# borders visibly step along the quad grid.
	var body := _resample(spine, barrel, 80)
	shell.add_tinted(_loft(body["path"], body["radii"], 1.12, 76), _hide_or_spot)

	# Legs. The hoof is part of the same lofted tube, just coloured dark, which
	# avoids the seam a separate cylinder leaves. Hind legs carry a hock, the
	# backward kink that stops a cow reading as a table.
	for leg in [Vector3(-0.22, -0.56, 0.0), Vector3(0.22, -0.56, 0.0),
			Vector3(-0.23, 0.60, 0.08), Vector3(0.23, 0.60, 0.08)]:
		shell.add_tinted(_leg(leg.x, leg.y, leg.z), _hide_or_hoof)

	shell.add(_ellipsoid(Vector3(0.0, 0.80, 0.40), Vector3(0.13, 0.11, 0.16), 8, 14), PINK)

	# Tail: a tapering tube on a curve, with a dark switch on the end.
	var tail := PackedVector3Array([
		Vector3(0.0, 1.22, 0.90),
		Vector3(0.0, 1.06, 1.02),
		Vector3(0.0, 0.88, 1.07),
		Vector3(0.0, 0.72, 1.07),
		Vector3(0.0, 0.60, 1.05),
	])
	shell.add(_loft(tail, PackedFloat32Array([0.048, 0.036, 0.028, 0.022, 0.016]), 1.0, 10), HIDE)
	shell.add(_ellipsoid(Vector3(0.0, 0.55, 1.04), Vector3(0.045, 0.075, 0.042), 8, 12), SPOT)

	return shell


## `hock` bows the middle of the leg backwards, which is what gives a hind leg
## its angled stance. Pass 0 for the front pair.
func _leg(x: float, z: float, hock: float) -> Dictionary:
	var path := PackedVector3Array([
		Vector3(x, 0.95, z),
		Vector3(x, 0.78, z + hock * 0.35),
		Vector3(x, 0.58, z + hock),
		Vector3(x, 0.38, z + hock * 0.75),
		Vector3(x, 0.20, z + hock * 0.15),
		Vector3(x, 0.10, z),
		Vector3(x, 0.035, z),
		Vector3(x, 0.005, z),
	])
	var radii := PackedFloat32Array([0.13, 0.105, 0.082, 0.068, 0.066, 0.076, 0.072, 0.04])
	var leg := _resample(path, radii, 30)
	return _loft(leg["path"], leg["radii"], 1.0, 18)


# ---------------------------------------------------------------- head group
# Local to the Neck pivot, which sits inside the shoulders so the neck does not
# tear away from the body when cow.gd pitches it down to graze.

func _build_head() -> Shell:
	var shell := Shell.new()

	# Starts deep inside the ribcage. If the neck base sits proud of the
	# shoulder the silhouette gets a step at the withers, which is the single
	# most obvious tell that a model was assembled from separate parts.
	var neck := PackedVector3Array([
		Vector3(0.0, 0.02, 0.32),
		Vector3(0.0, 0.05, 0.14),
		Vector3(0.0, 0.06, -0.04),
		Vector3(0.0, 0.05, -0.20),
	])
	var throat := _resample(neck, PackedFloat32Array([0.235, 0.212, 0.185, 0.165]), 16)
	shell.add(_loft(throat["path"], throat["radii"], 0.98, 36), HIDE)

	var skull := PackedVector3Array([
		Vector3(0.0, 0.03, -0.18),
		Vector3(0.0, 0.04, -0.28),
		Vector3(0.0, 0.02, -0.40),
		Vector3(0.0, -0.02, -0.52),
		Vector3(0.0, -0.06, -0.62),
		Vector3(0.0, -0.08, -0.70),
		Vector3(0.0, -0.09, -0.75),
	])
	var skull_r := PackedFloat32Array([0.155, 0.172, 0.163, 0.140, 0.118, 0.098, 0.035])
	var head := _resample(skull, skull_r, 34)
	shell.add_tinted(_loft(head["path"], head["radii"], 0.98, 40), func(v: Vector3) -> Color:
		return PINK if v.z < -0.56 else HIDE)

	# Nostrils, as two small dark dimples on the muzzle.
	shell.add(_ellipsoid(Vector3(-0.05, -0.085, -0.725), Vector3(0.022, 0.018, 0.024), 6, 10), SPOT)
	shell.add(_ellipsoid(Vector3(0.05, -0.085, -0.725), Vector3(0.022, 0.018, 0.024), 6, 10), SPOT)

	for s in [-1.0, 1.0]:
		shell.add(_ellipsoid(Vector3(s * 0.135, 0.075, -0.40), Vector3(0.048, 0.05, 0.044), 8, 14), EYE)
		shell.add(_ellipsoid(Vector3(s * 0.152, 0.095, -0.435), Vector3(0.018, 0.018, 0.018), 6, 10), GLINT)
		shell.add(_ear(s), HIDE)
		shell.add(_horn(s), HORN)

	# A patch over one eye. Reads as markings rather than as a painted-on decal.
	shell.add_tinted(_ellipsoid(Vector3(-0.11, 0.10, -0.33), Vector3(0.15, 0.13, 0.13), 10, 16),
		func(_v: Vector3) -> Color: return SPOT)

	return shell


func _ear(side: float) -> Dictionary:
	var part := _ellipsoid(Vector3.ZERO, Vector3(0.135, 0.030, 0.078), 10, 18)
	var basis := Basis(Vector3.FORWARD, side * -0.45) * Basis(Vector3.UP, side * -0.35)
	return _apply(part, Transform3D(basis, Vector3(side * 0.165, 0.065, -0.27)))


func _horn(side: float) -> Dictionary:
	var path := PackedVector3Array([
		Vector3(side * 0.075, 0.135, -0.31),
		Vector3(side * 0.115, 0.200, -0.32),
		Vector3(side * 0.150, 0.245, -0.335),
		Vector3(side * 0.175, 0.265, -0.345),
	])
	return _loft(path, PackedFloat32Array([0.040, 0.030, 0.019, 0.008]), 1.0, 10)


# ------------------------------------------------------------------ painting

func _hide_or_spot(v: Vector3) -> Color:
	# Noise warps the blob boundary so the markings are irregular, which is what
	# separates "cow" from "polka dots".
	var wobble := _noise.get_noise_3d(v.x * 3.2, v.y * 3.2, v.z * 3.2) * 0.11
	for s in SPOTS:
		var d := Vector3(s.x, s.y, s.z).distance_to(v)
		if d + wobble < s.w:
			return SPOT
	return HIDE


func _hide_or_hoof(v: Vector3) -> Color:
	return HOOF if v.y < 0.14 else HIDE


# ------------------------------------------------------------ mesh machinery

## Catmull-Rom resample of a control path and its radii. Density matters for
## more than smoothness here: the markings are vertex colours, so the width of
## the blur between a spot vertex and a hide vertex is the vertex spacing. Too
## few stations and the spots read as grey smudges instead of patches.
func _resample(path: PackedVector3Array, radii: PackedFloat32Array, count: int) -> Dictionary:
	var n := path.size()
	var out_path := PackedVector3Array()
	var out_radii := PackedFloat32Array()

	for i in count:
		var u := float(i) / float(count - 1) * float(n - 1)
		var i1 := clampi(int(floor(u)), 0, n - 2)
		var f := u - float(i1)
		var i0 := maxi(i1 - 1, 0)
		var i2 := i1 + 1
		var i3 := mini(i2 + 1, n - 1)

		out_path.append(Vector3(
			_catmull(path[i0].x, path[i1].x, path[i2].x, path[i3].x, f),
			_catmull(path[i0].y, path[i1].y, path[i2].y, path[i3].y, f),
			_catmull(path[i0].z, path[i1].z, path[i2].z, path[i3].z, f)
		))
		# Catmull-Rom can undershoot; a negative radius would invert the ring.
		out_radii.append(maxf(_catmull(radii[i0], radii[i1], radii[i2], radii[i3], f), 0.004))

	return {"path": out_path, "radii": out_radii}


func _catmull(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		2.0 * p1
		+ (-p0 + p2) * t
		+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
		+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)


## Sweeps a ring of `segments` vertices along `path`, one radius per station,
## and closes both ends with a fan. `squash` scales the vertical axis.
func _loft(path: PackedVector3Array, radii: PackedFloat32Array, squash: float, segments: int) -> Dictionary:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var n := path.size()

	for i in n:
		var tangent: Vector3
		if i == 0:
			tangent = path[1] - path[0]
		elif i == n - 1:
			tangent = path[n - 1] - path[n - 2]
		else:
			tangent = path[i + 1] - path[i - 1]
		tangent = tangent.normalized()

		var up := Vector3.UP
		if absf(tangent.dot(up)) > 0.95:
			up = Vector3.FORWARD
		var n1 := up.cross(tangent).normalized()
		var n2 := tangent.cross(n1).normalized()

		for j in segments:
			var a := TAU * float(j) / float(segments)
			verts.append(path[i] + n1 * (cos(a) * radii[i]) + n2 * (sin(a) * radii[i] * squash))

	for i in n - 1:
		for j in segments:
			var j2 := (j + 1) % segments
			var a0 := i * segments + j
			var a1 := i * segments + j2
			var b0 := (i + 1) * segments + j
			var b1 := (i + 1) * segments + j2
			indices.append_array(PackedInt32Array([a0, a1, b0, a1, b1, b0]))

	var tip_a := verts.size()
	verts.append(path[0])
	for j in segments:
		indices.append_array(PackedInt32Array([tip_a, (j + 1) % segments, j]))

	var tip_b := verts.size()
	verts.append(path[n - 1])
	var base := (n - 1) * segments
	for j in segments:
		indices.append_array(PackedInt32Array([tip_b, base + j, base + (j + 1) % segments]))

	return {"verts": verts, "indices": indices}


func _ellipsoid(center: Vector3, radius: Vector3, rings: int, segments: int) -> Dictionary:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()

	for i in rings + 1:
		var phi := PI * float(i) / float(rings)
		for j in segments:
			var theta := TAU * float(j) / float(segments)
			verts.append(center + Vector3(
				sin(phi) * cos(theta) * radius.x,
				cos(phi) * radius.y,
				sin(phi) * sin(theta) * radius.z
			))

	for i in rings:
		for j in segments:
			var j2 := (j + 1) % segments
			var a0 := i * segments + j
			var a1 := i * segments + j2
			var b0 := (i + 1) * segments + j
			var b1 := (i + 1) * segments + j2
			indices.append_array(PackedInt32Array([a0, a1, b0, a1, b1, b0]))

	return {"verts": verts, "indices": indices}


func _apply(part: Dictionary, xform: Transform3D) -> Dictionary:
	var out := PackedVector3Array()
	for v in part["verts"] as PackedVector3Array:
		out.append(xform * v)
	return {"verts": out, "indices": part["indices"]}


func _finish(shell: Shell, mat: Material) -> ArrayMesh:
	var verts := shell.verts
	var indices := shell.indices

	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in normals.size():
		normals[i] = Vector3.ZERO

	var i := 0
	while i < indices.size():
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		# Outward by construction - see the winding note at the top.
		var face := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		normals[a] += face
		normals[b] += face
		normals[c] += face
		i += 3

	for j in normals.size():
		normals[j] = normals[j].normalized() if normals[j].length_squared() > 0.0 else Vector3.UP

	# Flip to Godot's front-facing order now that normals are computed.
	var flipped := PackedInt32Array()
	flipped.resize(indices.size())
	var k := 0
	while k < indices.size():
		flipped[k] = indices[k]
		flipped[k + 1] = indices[k + 2]
		flipped[k + 2] = indices[k + 1]
		k += 3

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = shell.colors
	arrays[Mesh.ARRAY_INDEX] = flipped

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, mat)
	return mesh
