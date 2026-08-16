extends Node3D
class_name Scenery

## Trees, rocks and flowers. Everything is procedural and drawn through three
## MultiMeshes, so the whole lot costs three draw calls.
##
## Trees cluster instead of scattering evenly: a second noise field decides
## where groves are allowed, which is the difference between a landscape and a
## uniformly speckled field. Rocks do the opposite - they thin out on the flat
## and gather toward the foothills, where scree would actually collect.

@export var tree_spacing: float = 7.0
@export var max_trees: int = 260
## Groves form where the clumping noise clears this. Higher = fewer, denser.
@export_range(0.0, 1.0) var grove_threshold: float = 0.56
@export var rock_spacing: float = 6.0
@export var max_rocks: int = 420
@export var flower_spacing: float = 2.4
@export var max_flowers: int = 5200
@export var scatter_seed: int = 8675309

const TRUNK_LOW := Color(0.29, 0.21, 0.14)
const TRUNK_HIGH := Color(0.38, 0.28, 0.19)
const LEAF_DARK := Color(0.15, 0.30, 0.13)
const LEAF_LIGHT := Color(0.32, 0.48, 0.20)
const ROCK_LOW := Color(0.30, 0.29, 0.28)
const ROCK_HIGH := Color(0.48, 0.47, 0.45)

var _trees: MultiMeshInstance3D
var _rocks: MultiMeshInstance3D
var _flowers: MultiMeshInstance3D
var _bodies: StaticBody3D


func populate(terrain: MountainTerrain) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed

	var grove := FastNoiseLite.new()
	grove.seed = scatter_seed + 17
	grove.noise_type = FastNoiseLite.TYPE_SIMPLEX
	grove.frequency = 1.0 / 46.0
	grove.fractal_type = FastNoiseLite.FRACTAL_FBM
	grove.fractal_octaves = 3

	_bodies = StaticBody3D.new()
	_bodies.name = "TreeCollision"
	# Layer 3, deliberately not layer 1. The camera's pull-in raycast only looks
	# at the terrain; if trunks were on that layer the camera would collapse
	# onto the cow every time a tree passed behind her.
	_bodies.collision_layer = 4
	_bodies.collision_mask = 0
	add_child(_bodies)

	_scatter_trees(terrain, rng, grove)
	_scatter_rocks(terrain, rng)
	_scatter_flowers(terrain, rng)


# ---------------------------------------------------------------------- trees

func _scatter_trees(terrain: MountainTerrain, rng: RandomNumberGenerator, grove: FastNoiseLite) -> void:
	var reach := terrain.grazing_radius() * 1.12
	var placed := PackedVector3Array()
	var scales := PackedFloat32Array()
	var yaws := PackedFloat32Array()

	var steps := int((reach * 2.0) / tree_spacing)
	for gz in steps:
		for gx in steps:
			if placed.size() >= max_trees:
				break
			var x := -reach + (float(gx) + rng.randf()) * tree_spacing
			var z := -reach + (float(gz) + rng.randf()) * tree_spacing
			if x * x + z * z > reach * reach:
				continue
			# Keep the immediate spawn area clear so the opening view is open.
			if x * x + z * z < 900.0:
				continue
			if clampf(grove.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0) < grove_threshold:
				continue
			var h := terrain.height_at(x, z)
			if h > terrain.snow_line - 8.0:
				continue
			if terrain.normal_at(x, z).y < 0.86:
				continue
			placed.append(Vector3(x, h - 0.15, z))
			scales.append(rng.randf_range(0.78, 1.45))
			yaws.append(rng.randf_range(0.0, TAU))

	_trees = _make_instance("Trees", _tree_mesh(rng), placed.size(), terrain)
	var tint := RandomNumberGenerator.new()
	tint.seed = scatter_seed + 5
	for i in placed.size():
		var s := scales[i]
		var basis := Basis(Vector3.UP, yaws[i]).scaled(Vector3(s, s * rng.randf_range(0.92, 1.15), s))
		_trees.multimesh.set_instance_transform(i, Transform3D(basis, placed[i]))
		var shade := tint.randf_range(0.84, 1.14)
		_trees.multimesh.set_instance_color(i, Color(shade * 0.97, shade, shade * 0.9, 1.0))

		var shape := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.34 * s
		cyl.height = 3.2 * s
		shape.shape = cyl
		shape.position = placed[i] + Vector3(0.0, 1.6 * s, 0.0)
		_bodies.add_child(shape)


## A stylised conifer: one tapered trunk plus three stacked skirts. Reads at a
## distance, costs nothing, and matches the flat-shaded terrain.
func _tree_mesh(rng: RandomNumberGenerator) -> ArrayMesh:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	_add_taper(verts, indices, colors, Vector3.ZERO, 4.4, 0.26, 0.11, 9, TRUNK_LOW, TRUNK_HIGH)

	var tiers := 3
	for t in tiers:
		var f := float(t) / float(tiers)
		var y := lerpf(1.35, 3.5, f)
		var radius := lerpf(1.5, 0.62, f)
		var height := lerpf(1.9, 1.25, f)
		_add_cone(verts, indices, colors, Vector3(0.0, y, 0.0), height, radius, 11, LEAF_DARK, LEAF_LIGHT)

	return _finish(verts, indices, colors)


# ---------------------------------------------------------------------- rocks

func _scatter_rocks(terrain: MountainTerrain, rng: RandomNumberGenerator) -> void:
	var reach := terrain.grazing_radius() * 1.35
	var placed := PackedVector3Array()
	var basis_list: Array[Basis] = []

	var steps := int((reach * 2.0) / rock_spacing)
	for gz in steps:
		for gx in steps:
			if placed.size() >= max_rocks:
				break
			var x := -reach + (float(gx) + rng.randf()) * rock_spacing
			var z := -reach + (float(gz) + rng.randf()) * rock_spacing
			var d2 := x * x + z * z
			if d2 > reach * reach or d2 < 400.0:
				continue
			# Scree collects toward the foothills, so bias outward.
			if rng.randf() > 0.10 + 0.9 * (d2 / (reach * reach)):
				continue
			var h := terrain.height_at(x, z)
			if terrain.normal_at(x, z).y < 0.62:
				continue
			var s := rng.randf_range(0.22, 0.95)
			placed.append(Vector3(x, h - s * 0.32, z))
			basis_list.append(
				Basis(Vector3.UP, rng.randf_range(0.0, TAU))
				* Basis(Vector3.RIGHT, rng.randf_range(-0.4, 0.4))
				* Basis(Vector3.FORWARD, rng.randf_range(-0.4, 0.4))
			)

	_rocks = _make_instance("Rocks", _rock_mesh(), placed.size(), terrain)
	var tint := RandomNumberGenerator.new()
	tint.seed = scatter_seed + 9
	for i in placed.size():
		var s := tint.randf_range(0.22, 0.95)
		_rocks.multimesh.set_instance_transform(
			i, Transform3D(basis_list[i].scaled(Vector3(s, s * 0.72, s * 0.9)), placed[i])
		)
		var shade := tint.randf_range(0.82, 1.18)
		_rocks.multimesh.set_instance_color(i, Color(shade, shade, shade, 1.0))


## A sphere pushed around by noise. Faceted normals would be nicer still, but
## the flat lighting already reads the silhouette more than the shading.
func _rock_mesh() -> ArrayMesh:
	var noise := FastNoiseLite.new()
	noise.seed = 4242
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.1

	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	var rings := 9
	var segments := 12
	for i in rings + 1:
		var phi := PI * float(i) / float(rings)
		for j in segments:
			var theta := TAU * float(j) / float(segments)
			var n := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta))
			var lump := 1.0 + noise.get_noise_3d(n.x * 2.0, n.y * 2.0, n.z * 2.0) * 0.42
			verts.append(n * lump)
			colors.append(ROCK_LOW.lerp(ROCK_HIGH, clampf(n.y * 0.5 + 0.5, 0.0, 1.0)))

	for i in rings:
		for j in segments:
			var j2 := (j + 1) % segments
			var a0 := i * segments + j
			var a1 := i * segments + j2
			var b0 := (i + 1) * segments + j
			var b1 := (i + 1) * segments + j2
			indices.append_array(PackedInt32Array([a0, a1, b0, a1, b1, b0]))

	return _finish(verts, indices, colors)


# -------------------------------------------------------------------- flowers

func _scatter_flowers(terrain: MountainTerrain, rng: RandomNumberGenerator) -> void:
	var reach := terrain.grazing_radius()
	var placed := PackedVector3Array()
	var yaws := PackedFloat32Array()

	var steps := int((reach * 2.0) / flower_spacing)
	for gz in steps:
		for gx in steps:
			if placed.size() >= max_flowers:
				break
			var x := -reach + (float(gx) + rng.randf()) * flower_spacing
			var z := -reach + (float(gz) + rng.randf()) * flower_spacing
			if x * x + z * z > reach * reach:
				continue
			var h := terrain.height_at(x, z)
			if h > terrain.snow_line - 10.0:
				continue
			if terrain.normal_at(x, z).y < 0.86:
				continue
			placed.append(Vector3(x, h, z))
			yaws.append(rng.randf_range(0.0, TAU))

	_flowers = _make_instance("Flowers", _flower_mesh(), placed.size(), terrain)
	_flowers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var palette := [
		Color(1.0, 1.0, 0.98), Color(1.0, 0.93, 0.55),
		Color(0.95, 0.80, 0.92), Color(0.86, 0.88, 1.0),
	]
	var tint := RandomNumberGenerator.new()
	tint.seed = scatter_seed + 21
	for i in placed.size():
		var s := tint.randf_range(0.8, 1.25)
		_flowers.multimesh.set_instance_transform(
			i, Transform3D(Basis(Vector3.UP, yaws[i]).scaled(Vector3.ONE * s), placed[i])
		)
		_flowers.multimesh.set_instance_color(i, palette[tint.randi_range(0, palette.size() - 1)])


## A stem and a five-petal head, both tiny. At grazing distance it is a dot of
## colour, which is all it needs to be.
func _flower_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var colors := PackedColorArray()

	_add_taper(verts, indices, colors, Vector3.ZERO, 0.20, 0.011, 0.008, 5,
		Color(0.24, 0.36, 0.14), Color(0.30, 0.44, 0.18))

	var head := Vector3(0.0, 0.20, 0.0)
	var base := verts.size()
	verts.append(head)
	colors.append(Color(1.0, 1.0, 1.0))
	var petals := 5
	for i in petals:
		var a := TAU * float(i) / float(petals)
		verts.append(head + Vector3(cos(a) * 0.05, 0.006, sin(a) * 0.05))
		colors.append(Color(1.0, 1.0, 1.0))
	for i in petals:
		indices.append_array(PackedInt32Array([base, base + 1 + i, base + 1 + (i + 1) % petals]))

	return _finish(verts, indices, colors)


# ------------------------------------------------------------------- geometry

func _add_taper(verts: PackedVector3Array, indices: PackedInt32Array, colors: PackedColorArray,
		origin: Vector3, height: float, r_bottom: float, r_top: float, segments: int,
		c_bottom: Color, c_top: Color) -> void:
	var base := verts.size()
	for level in 2:
		var y := origin.y + height * float(level)
		var r := r_bottom if level == 0 else r_top
		var c := c_bottom if level == 0 else c_top
		for j in segments:
			var a := TAU * float(j) / float(segments)
			verts.append(Vector3(origin.x + cos(a) * r, y, origin.z + sin(a) * r))
			colors.append(c)
	for j in segments:
		var j2 := (j + 1) % segments
		indices.append_array(PackedInt32Array([
			base + j, base + j2, base + segments + j,
			base + j2, base + segments + j2, base + segments + j,
		]))


func _add_cone(verts: PackedVector3Array, indices: PackedInt32Array, colors: PackedColorArray,
		origin: Vector3, height: float, radius: float, segments: int,
		c_bottom: Color, c_top: Color) -> void:
	var base := verts.size()
	for j in segments:
		var a := TAU * float(j) / float(segments)
		verts.append(Vector3(origin.x + cos(a) * radius, origin.y, origin.z + sin(a) * radius))
		colors.append(c_bottom)
	var tip := verts.size()
	verts.append(origin + Vector3(0.0, height, 0.0))
	colors.append(c_top)
	var centre := verts.size()
	verts.append(origin)
	colors.append(c_bottom)
	for j in segments:
		var j2 := (j + 1) % segments
		indices.append_array(PackedInt32Array([base + j, base + j2, tip]))
		indices.append_array(PackedInt32Array([centre, base + j2, base + j]))


func _make_instance(node_name: String, mesh: ArrayMesh, count: int, terrain: MountainTerrain) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count

	var mi := MultiMeshInstance3D.new()
	mi.name = node_name
	mi.multimesh = mm
	# Instance transforms are written after the AABB would have been computed.
	mi.custom_aabb = terrain.bounds()
	add_child(mi)
	return mi


func _finish(verts: PackedVector3Array, indices: PackedInt32Array, colors: PackedColorArray) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in normals.size():
		normals[i] = Vector3.ZERO

	var i := 0
	while i < indices.size():
		var a := indices[i]
		var b := indices[i + 1]
		var c := indices[i + 2]
		var face := (verts[b] - verts[a]).cross(verts[c] - verts[a])
		normals[a] += face
		normals[b] += face
		normals[c] += face
		i += 3
	for j in normals.size():
		normals[j] = normals[j].normalized() if normals[j].length_squared() > 0.0 else Vector3.UP

	# Godot treats the opposite winding as front-facing.
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
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = flipped

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, mat)
	return mesh
