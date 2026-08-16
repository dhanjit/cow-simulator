extends Node3D
class_name CowModel

## Builds the cow's visual rig at runtime.
##
## Everything is lofted - a path, a radius per station, a ring of vertices swept
## along it - rather than assembled from box and cylinder primitives, which is
## what made the first version read as a crate on sticks.
##
## The legs are deliberately NOT part of the body mesh. Each is two separate
## segments with its origin at the joint, so cow_gait.gd can drive them with
## inverse kinematics. Same for the tail joints, the ears and the eyes: anything
## that needs to move independently is its own node.
##
## Proportions are keyed to a real Holstein, scaled so the withers land at 1.50
## and the belly at 0.76 (metres, hooves at y = 0):
##
##   width / withers height   0.41   - a cow is NARROW
##   body depth vs width      deeper than wide, not flatter
##   ground to belly          ~52% of withers height
##
## The head is left about 15% over life size, which reads as stylised.
##
## Winding convention: every shell is generated so that
## cross(p1 - p0, p2 - p0) points OUTWARD. Normals are accumulated from that,
## then the index order is reversed once at the end, because Godot treats the
## opposite winding as front-facing.

const HIDE := Color(0.95, 0.93, 0.89)
const SPOT := Color(0.13, 0.11, 0.11)
const PINK := Color(0.93, 0.62, 0.61)
const HOOF := Color(0.15, 0.13, 0.13)
const HORN := Color(0.85, 0.79, 0.66)
const EYE := Color(0.05, 0.04, 0.04)
const GLINT := Color(1.0, 1.0, 1.0)

## Leg order used everywhere: front-left, front-right, back-left, back-right.
enum { FL, FR, BL, BR }

const HIP_HEIGHT := 0.95
const UPPER_LEN := 0.55
const LOWER_LEN := 0.50

## Hip sockets in Model space.
const HIPS: Array[Vector3] = [
	Vector3(-0.22, HIP_HEIGHT, -0.56),
	Vector3(0.22, HIP_HEIGHT, -0.56),
	Vector3(-0.23, HIP_HEIGHT, 0.60),
	Vector3(0.23, HIP_HEIGHT, 0.60),
]

## Blob centres in Model space, as (x, y, z, radius).
const SPOTS: Array[Vector4] = [
	Vector4(-0.24, 1.30, -0.30, 0.29),
	Vector4(0.28, 1.16, 0.14, 0.27),
	Vector4(-0.20, 0.98, 0.46, 0.23),
	Vector4(0.17, 1.40, -0.56, 0.21),
	Vector4(-0.07, 1.44, 0.54, 0.22),
	Vector4(0.25, 0.94, -0.06, 0.17),
]

const TAIL_SEGMENTS := 4
const TAIL_SEG_LEN := 0.15

var leg_upper: Array[MeshInstance3D] = []
var leg_lower: Array[MeshInstance3D] = []
## A blob parked at each knee. Two lofted tubes meeting at an angle leave a
## visible notch; a joint mass is the cheapest way to hide it.
var leg_knee: Array[MeshInstance3D] = []
var tail_joints: Array[Node3D] = []
var ear_pivots: Array[Node3D] = []
var eyes: Array[MeshInstance3D] = []

var _noise: FastNoiseLite
var _material: StandardMaterial3D


## Accumulates several shells into one mesh.
class Shell:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	func add(part: Dictionary, color: Color) -> void:
		add_tinted(part, func(_v: Vector3) -> Color: return color)

	func add_tinted(part: Dictionary, tint: Callable) -> void:
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

	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.roughness = 0.72
	_material.metallic = 0.0

	_build_torso()
	_build_legs()
	_build_tail()
	_build_head()


func _attach(parent: Node3D, shell: Shell, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = _finish(shell)
	parent.add_child(mi)
	return mi


# ---------------------------------------------------------------------- torso

func _build_torso() -> void:
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
	# to a point reads as a deer.
	var barrel := PackedFloat32Array([
		0.05, 0.15, 0.26, 0.315, 0.34, 0.35, 0.345, 0.325, 0.27, 0.16, 0.05
	])
	# 80 x 76 is ~6k verts, chosen for the marking edges rather than the
	# silhouette - below about this density the spot borders step visibly.
	var body := _resample(spine, barrel, 80)
	shell.add_tinted(_loft(body["path"], body["radii"], 1.12, 76), _hide_or_spot)

	# Shoulder and haunch masses, so the legs emerge from muscle rather than
	# poking straight out of a tube.
	for i in HIPS.size():
		var h: Vector3 = HIPS[i]
		shell.add_tinted(_ellipsoid(Vector3(h.x * 0.72, h.y + 0.05, h.z), Vector3(0.16, 0.21, 0.24), 10, 16),
			_hide_or_spot)

	shell.add(_ellipsoid(Vector3(0.0, 0.80, 0.40), Vector3(0.13, 0.11, 0.16), 8, 14), PINK)

	_attach(self, shell, "Torso")


# ----------------------------------------------------------------------- legs

func _build_legs() -> void:
	leg_upper.clear()
	leg_lower.clear()
	leg_knee.clear()

	for i in HIPS.size():
		var upper := Shell.new()
		upper.add(_segment(UPPER_LEN, 0.165, 0.105), HIDE)
		leg_upper.append(_attach(self, upper, "LegUpper%d" % i))

		var knee := Shell.new()
		knee.add(_ellipsoid(Vector3.ZERO, Vector3(0.098, 0.098, 0.098), 8, 14), HIDE)
		leg_knee.append(_attach(self, knee, "LegKnee%d" % i))

		var lower := Shell.new()
		# Hoof is part of the same lofted tube, just coloured dark, which avoids
		# the seam a separate cylinder leaves.
		lower.add_tinted(_lower_leg(LOWER_LEN), func(v: Vector3) -> Color:
			return HOOF if v.y < -(LOWER_LEN - 0.11) else HIDE)
		leg_lower.append(_attach(self, lower, "LegLower%d" % i))


## A tapered tube running from the origin down its own -Y axis. Building each
## segment in its own local space is what lets the gait aim it by transform.
func _segment(length: float, r_top: float, r_bottom: float) -> Dictionary:
	var path := PackedVector3Array([
		Vector3.ZERO,
		Vector3(0.0, -length * 0.35, 0.0),
		Vector3(0.0, -length * 0.7, 0.0),
		Vector3(0.0, -length, 0.0),
	])
	var radii := PackedFloat32Array([r_top, lerpf(r_top, r_bottom, 0.4), lerpf(r_top, r_bottom, 0.78), r_bottom])
	var seg := _resample(path, radii, 16)
	return _loft(seg["path"], seg["radii"], 1.0, 16)


func _lower_leg(length: float) -> Dictionary:
	var path := PackedVector3Array([
		Vector3.ZERO,
		Vector3(0.0, -length * 0.42, 0.0),
		Vector3(0.0, -length * 0.74, 0.0),
		Vector3(0.0, -(length - 0.075), 0.0),
		Vector3(0.0, -(length - 0.03), 0.0),
		Vector3(0.0, -length, 0.0),
	])
	var radii := PackedFloat32Array([0.098, 0.080, 0.072, 0.082, 0.088, 0.050])
	var seg := _resample(path, radii, 26)
	return _loft(seg["path"], seg["radii"], 1.0, 16)


# ----------------------------------------------------------------------- tail

func _build_tail() -> void:
	tail_joints.clear()
	var parent: Node3D = self
	for i in TAIL_SEGMENTS:
		var joint := Node3D.new()
		joint.name = "TailJoint%d" % i
		if i == 0:
			# Base at the rump, angled back and down.
			joint.transform = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-28.0)), Vector3(0.0, 1.20, 0.92))
		else:
			joint.position = Vector3(0.0, -TAIL_SEG_LEN, 0.0)
		parent.add_child(joint)

		var shell := Shell.new()
		var r_top := lerpf(0.048, 0.020, float(i) / float(TAIL_SEGMENTS))
		var r_bot := lerpf(0.048, 0.020, float(i + 1) / float(TAIL_SEGMENTS))
		shell.add(_segment(TAIL_SEG_LEN, r_top, r_bot), HIDE)
		if i == TAIL_SEGMENTS - 1:
			shell.add(_ellipsoid(Vector3(0.0, -TAIL_SEG_LEN - 0.04, 0.0), Vector3(0.045, 0.075, 0.042), 8, 12), SPOT)
		_attach(joint, shell, "TailMesh%d" % i)

		tail_joints.append(joint)
		parent = joint


# ----------------------------------------------------------------------- head
# Built under the Neck pivot, which sits inside the shoulders so the neck does
# not tear away from the body when the head pitches down to graze.

func _build_head() -> void:
	var neck_node: Node3D = $Neck
	var shell := Shell.new()

	# Starts deep inside the ribcage. A neck base sitting proud of the shoulder
	# puts a step in the topline, which is the clearest sign a model was
	# assembled from separate parts.
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

	shell.add(_ellipsoid(Vector3(-0.05, -0.085, -0.725), Vector3(0.022, 0.018, 0.024), 6, 10), SPOT)
	shell.add(_ellipsoid(Vector3(0.05, -0.085, -0.725), Vector3(0.022, 0.018, 0.024), 6, 10), SPOT)

	for s in [-1.0, 1.0]:
		shell.add(_horn(s), HORN)

	# A patch over one eye. Reads as markings rather than as a painted-on decal.
	shell.add(_ellipsoid(Vector3(-0.11, 0.10, -0.33), Vector3(0.15, 0.13, 0.13), 10, 16), SPOT)

	_attach(neck_node, shell, "Head")

	# Eyes and ears are separate nodes so they can blink and flick.
	eyes.clear()
	ear_pivots.clear()
	for s in [-1.0, 1.0]:
		var eye_shell := Shell.new()
		eye_shell.add(_ellipsoid(Vector3.ZERO, Vector3(0.048, 0.05, 0.044), 8, 14), EYE)
		eye_shell.add(_ellipsoid(Vector3(s * 0.017, 0.02, -0.035), Vector3(0.018, 0.018, 0.018), 6, 10), GLINT)
		var eye := _attach(neck_node, eye_shell, "Eye%d" % eyes.size())
		eye.position = Vector3(s * 0.135, 0.075, -0.40)
		eyes.append(eye)

		var pivot := Node3D.new()
		pivot.name = "EarPivot%d" % ear_pivots.size()
		pivot.transform = Transform3D(
			Basis(Vector3.FORWARD, s * -0.45) * Basis(Vector3.UP, s * -0.35),
			Vector3(s * 0.165, 0.065, -0.27)
		)
		neck_node.add_child(pivot)
		var ear_shell := Shell.new()
		ear_shell.add(_ellipsoid(Vector3(s * 0.075, 0.0, 0.0), Vector3(0.135, 0.030, 0.078), 10, 18), HIDE)
		_attach(pivot, ear_shell, "EarMesh")
		ear_pivots.append(pivot)


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
		if Vector3(s.x, s.y, s.z).distance_to(v) + wobble < s.w:
			return SPOT
	return HIDE


# ------------------------------------------------------------ mesh machinery

## Catmull-Rom resample of a control path and its radii. Density matters for
## more than smoothness: the markings are vertex colours, so the width of the
## blur between a spot vertex and a hide vertex is the vertex spacing.
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


func _finish(shell: Shell) -> ArrayMesh:
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
	mesh.surface_set_material(0, _material)
	return mesh
