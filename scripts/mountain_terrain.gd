extends StaticBody3D
class_name MountainTerrain

## Procedural alpine basin: rolling plains in the middle, a ring of mountains
## around the rim, and low passes carved through the ring so it reads as a
## valley rather than a bowl.
##
## The plains are the playable surface - a cow needs flat ground to graze on
## and a horizon worth looking at, not a cone to stand on top of.
##
## height_at() is the single source of truth for the surface: the mesh, the
## collider, the grass scatter, the spawn search and the camera's ground
## clamp all read from it, so they cannot drift out of sync.

@export var world_size: float = 240.0
## Cells per side. Vertices = (resolution + 1)^2, triangles = resolution^2 * 2.
@export var resolution: int = 160
## Vertical scale of the rolling plain. This is the ground the cow lives on.
@export var plain_amplitude: float = 5.5
## Vertical scale of the surrounding peaks.
@export var peak_height: float = 76.0
## Normalised radius (0 = centre, 1 = rim) where the foothills start rising.
@export_range(0.05, 0.95) var mountain_start: float = 0.40
## How much the passes cut the ring down. 1.0 = unbroken wall of rock.
@export_range(0.0, 1.0) var pass_depth: float = 0.72
@export var snow_line: float = 34.0
## Surfaces with normal.y below this read as bare rock.
@export var rock_slope: float = 0.74
@export var noise_seed: int = 20260726

var _plain: FastNoiseLite
var _ridge: FastNoiseLite
var _passes: FastNoiseLite
var _detail: FastNoiseLite

@onready var _mesh_instance: MeshInstance3D = $Mesh
@onready var _collision: CollisionShape3D = $Collision


func _build_noise() -> void:
	# Gentle, long-wavelength undulation. Never steep enough to block a cow.
	_plain = FastNoiseLite.new()
	_plain.seed = noise_seed
	_plain.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_plain.frequency = 1.0 / 70.0
	_plain.fractal_type = FastNoiseLite.FRACTAL_FBM
	_plain.fractal_octaves = 4
	_plain.fractal_lacunarity = 2.0
	_plain.fractal_gain = 0.45

	# Ridged fractal gives sharp alpine crests rather than blobby hills.
	_ridge = FastNoiseLite.new()
	_ridge.seed = noise_seed + 7919
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_ridge.frequency = 1.0 / 95.0
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.fractal_octaves = 5
	_ridge.fractal_lacunarity = 2.15
	_ridge.fractal_gain = 0.5

	# Very broad noise that decides which sectors of the ring are low passes.
	_passes = FastNoiseLite.new()
	_passes.seed = noise_seed + 31337
	_passes.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_passes.frequency = 1.0 / 130.0
	_passes.fractal_type = FastNoiseLite.FRACTAL_FBM
	_passes.fractal_octaves = 2

	_detail = FastNoiseLite.new()
	_detail.seed = noise_seed + 104729
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_detail.frequency = 1.0 / 14.0


## World-space surface height at (x, z). Deterministic, cheap, no allocation.
func height_at(x: float, z: float) -> float:
	if _plain == null:
		_build_noise()

	var plain := _plain.get_noise_2d(x, z) * plain_amplitude
	plain += _detail.get_noise_2d(x, z) * 0.55

	var d := clampf(Vector2(x, z).length() / (world_size * 0.5), 0.0, 1.0)
	# smoothstep gives walkable foothills instead of a wall dropped on the map.
	var mask := smoothstep(mountain_start, 1.0, d)
	mask *= mask

	# Knock whole sectors of the ring down into passes and valley mouths.
	var gap := clampf(_passes.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
	mask *= lerpf(1.0 - pass_depth, 1.0, gap)

	var crest := clampf(_ridge.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
	crest = pow(crest, 1.25)

	return plain + crest * peak_height * mask


## Normal via central differences on height_at().
func normal_at(x: float, z: float) -> Vector3:
	var e := 0.75
	var hl := height_at(x - e, z)
	var hr := height_at(x + e, z)
	var hb := height_at(x, z - e)
	var hf := height_at(x, z + e)
	return Vector3(hl - hr, 2.0 * e, hb - hf).normalized()


## Radius out to which grass is worth scattering. Lets the grass field skip
## the whole mountain ring without paying for a height sample per cell.
func grazing_radius() -> float:
	return world_size * 0.5 * (mountain_start + 0.16)


func _color_at(h: float, ny: float, x: float, z: float) -> Color:
	const GRASS_DARK := Color(0.24, 0.36, 0.13)
	const GRASS_LIGHT := Color(0.48, 0.60, 0.24)
	const ROCK := Color(0.35, 0.33, 0.32)
	const SNOW := Color(0.92, 0.94, 0.97)
	const SOIL := Color(0.29, 0.23, 0.15)

	var t := clampf(_detail.get_noise_2d(x, z) * 0.5 + 0.5, 0.0, 1.0)
	var c := GRASS_DARK.lerp(GRASS_LIGHT, t)
	# Hollows on the plain go slightly darker and browner, like damp ground.
	c = c.lerp(SOIL, clampf((-1.0 - h) / 7.0, 0.0, 0.32))

	var steep := clampf((rock_slope - ny) / 0.26, 0.0, 1.0)
	c = c.lerp(ROCK, steep)

	# Snow accumulates with altitude but will not cling to cliff faces.
	var snowy := clampf((h - snow_line) / 13.0, 0.0, 1.0)
	snowy *= clampf((ny - 0.45) / 0.28, 0.0, 1.0)
	return c.lerp(SNOW, snowy)


func generate() -> void:
	_build_noise()

	var side := resolution + 1
	var vert_count := side * side
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	verts.resize(vert_count)
	norms.resize(vert_count)
	cols.resize(vert_count)
	uvs.resize(vert_count)

	var step := world_size / float(resolution)
	var half := world_size * 0.5

	for zi in side:
		for xi in side:
			var wx := -half + xi * step
			var wz := -half + zi * step
			var h := height_at(wx, wz)
			var n := normal_at(wx, wz)
			var i := zi * side + xi
			verts[i] = Vector3(wx, h, wz)
			norms[i] = n
			cols[i] = _color_at(h, n.y, wx, wz)
			uvs[i] = Vector2(float(xi), float(zi)) / float(resolution)

	var indices := PackedInt32Array()
	indices.resize(resolution * resolution * 6)
	var k := 0
	for zi in resolution:
		for xi in resolution:
			var a := zi * side + xi
			var b := a + 1
			var c := a + side
			var d := c + 1
			# Winding matters for physics, not just rendering: Godot derives
			# each collision face's plane from vertex order, so reversing
			# these makes the floor normals point down and the player sinks.
			indices[k] = a
			indices[k + 1] = b
			indices[k + 2] = c
			indices[k + 3] = b
			indices[k + 4] = d
			indices[k + 5] = c
			k += 6

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mat.metallic = 0.0
	# Must stay single-sided: a double-sided terrain writes its underside into
	# the shadow map, which shadows the lit surface and flattens the whole
	# world to ambient. The camera is kept above ground by CameraRig instead.
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	mesh.surface_set_material(0, mat)

	_mesh_instance.mesh = mesh
	_collision.shape = mesh.create_trimesh_shape()


## A flat patch of plain to drop the cow onto, off-centre so the peaks fill
## the horizon rather than sitting evenly all around.
func spawn_point() -> Vector3:
	var r := world_size * 0.16
	var samples := 240
	for i in samples:
		var a := TAU * float(i) / float(samples)
		var x := cos(a) * r
		var z := sin(a) * r
		if normal_at(x, z).y > 0.985:
			return Vector3(x, height_at(x, z) + 0.4, z)
	return Vector3(r, height_at(r, 0.0) + 0.4, 0.0)


func bounds() -> AABB:
	var half := world_size * 0.5
	return AABB(
		Vector3(-half, -40.0, -half),
		Vector3(world_size, peak_height + 80.0, world_size)
	)
