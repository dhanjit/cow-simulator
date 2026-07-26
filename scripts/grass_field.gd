extends MultiMeshInstance3D
class_name GrassField

## Thousands of grazeable tufts in a single draw call.
##
## Rendering: one MultiMesh, one tuft mesh (a handful of tapered triangles).
## Queries: a uniform-grid spatial hash, so grazing costs O(tufts nearby)
## instead of O(total tufts). Eating shrinks a tuft's transform to zero;
## regrowth is a FIFO queue read with a head index, so no O(n) pop_front.

## Average metres between tufts. Drives density directly.
@export var spacing: float = 0.72
## Hard ceiling so a bigger world cannot blow up the vertex budget.
@export var max_tufts: int = 30000
@export var cell_size: float = 4.0
@export var regrow_delay: float = 35.0
@export var regrow_speed: float = 0.25
## Nutrition awarded per full tuft consumed.
@export var nutrition_per_tuft: float = 0.6

## Below this height a tuft counts as eaten. graze() and has_grass_near()
## must share it: if "still has grass" were a lower bar than "consumed", the
## cow would stop grazing just short of finishing a tuft, and that tuft would
## never die, never disappear and never queue for regrowth.
const EATEN_EPSILON := 0.06
## Tufts only grow on ground flatter than this.
@export var min_normal_y: float = 0.75
## Tufts stop this far below the terrain's snow line.
@export var snow_margin: float = 5.0
@export var scatter_seed: int = 424242

var _pos: PackedVector3Array = PackedVector3Array()
var _yaw: PackedFloat32Array = PackedFloat32Array()
var _size: PackedFloat32Array = PackedFloat32Array()
## 1.0 = full tuft, 0.0 = eaten down to the roots.
var _height: PackedFloat32Array = PackedFloat32Array()

var _cells: Dictionary = {}
var _regrow_at: PackedFloat32Array = PackedFloat32Array()
var _regrow_idx: PackedInt32Array = PackedInt32Array()
var _regrow_head: int = 0
var _growing: PackedInt32Array = PackedInt32Array()

var _time: float = 0.0
var _alive: int = 0


func populate(terrain: MountainTerrain) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = scatter_seed

	var half := terrain.world_size * 0.5 - 2.0
	var ceiling := terrain.snow_line - snow_margin
	var steps := int((half * 2.0) / spacing)
	var placed := 0

	# Grass belongs on the plain and the foothills, not up the mountain ring.
	# Testing radius first skips ~70% of cells before touching the noise.
	var reach := terrain.grazing_radius()
	var reach2 := reach * reach

	# Buckets are built as plain Arrays (unambiguously by reference) and
	# frozen into PackedInt32Arrays afterwards for the read-only hot loop.
	var buckets: Dictionary = {}

	_pos.resize(0)
	_yaw.resize(0)
	_size.resize(0)
	_height.resize(0)

	# Jittered grid rather than rejection sampling: uniform coverage, and the
	# cost is bounded by grid cells instead of by how much ground is rejected.
	for gz in steps:
		if placed >= max_tufts:
			break
		for gx in steps:
			if placed >= max_tufts:
				break
			var x := -half + (float(gx) + rng.randf()) * spacing
			var z := -half + (float(gz) + rng.randf()) * spacing
			if x * x + z * z > reach2:
				continue
			var h := terrain.height_at(x, z)
			# Height test first - it is a quarter the cost of the slope test.
			# Only an upper bound: the plain oscillates either side of y=0, so
			# a lower bound would strip grass off half the pasture.
			if h > ceiling:
				continue
			if terrain.normal_at(x, z).y < min_normal_y:
				continue
			_pos.append(Vector3(x, h, z))
			_yaw.append(rng.randf_range(0.0, TAU))
			_size.append(rng.randf_range(0.7, 1.15))
			_height.append(1.0)
			var key := Vector2i(floori(x / cell_size), floori(z / cell_size))
			if not buckets.has(key):
				buckets[key] = []
			(buckets[key] as Array).append(placed)
			placed += 1

	_cells.clear()
	for key in buckets:
		_cells[key] = PackedInt32Array(buckets[key])

	_alive = placed

	_regrow_at.resize(0)
	_regrow_idx.resize(0)
	_regrow_head = 0
	_growing.resize(0)

	var mm := MultiMesh.new()
	# These three must be set before instance_count.
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _build_tuft_mesh()
	mm.instance_count = placed
	multimesh = mm

	var tint := RandomNumberGenerator.new()
	tint.seed = scatter_seed + 13
	for i in placed:
		var shade := tint.randf_range(0.86, 1.10)
		mm.set_instance_color(i, Color(shade * 0.96, shade, shade * 0.86, 1.0))
		_write_instance(i)

	# The MultiMesh AABB is computed once; instance transforms change at
	# runtime, so pin a custom AABB to stop tufts popping out under culling.
	custom_aabb = terrain.bounds()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _write_instance(i: int) -> void:
	var s := _height[i]
	if s <= 0.0:
		multimesh.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), _pos[i]))
		return
	# Chewed tufts get shorter and draw in a little, like a nibbled patch.
	var spread := _size[i] * lerpf(0.62, 1.0, s)
	var basis := Basis(Vector3.UP, _yaw[i]).scaled(Vector3(spread, _size[i] * s, spread))
	multimesh.set_instance_transform(i, Transform3D(basis, _pos[i]))


func _process(delta: float) -> void:
	_time += delta

	while _regrow_head < _regrow_idx.size() and _regrow_at[_regrow_head] <= _time:
		_growing.append(_regrow_idx[_regrow_head])
		_regrow_head += 1

	if _growing.is_empty():
		return

	var still := PackedInt32Array()
	for idx in _growing:
		_height[idx] = minf(1.0, _height[idx] + regrow_speed * delta)
		_write_instance(idx)
		if _height[idx] < 1.0:
			still.append(idx)
		else:
			_alive += 1
	_growing = still


## Chew every live tuft inside `radius` of `world_pos`. Returns the nutrition
## actually consumed this frame, which is proportional to what was chewed off.
func graze(world_pos: Vector3, radius: float, delta: float, rate: float) -> float:
	var eaten := 0.0
	var r2 := radius * radius
	var span := int(ceil(radius / cell_size))
	var base := Vector2i(floori(world_pos.x / cell_size), floori(world_pos.z / cell_size))

	for cz in range(base.y - span, base.y + span + 1):
		for cx in range(base.x - span, base.x + span + 1):
			var key := Vector2i(cx, cz)
			if not _cells.has(key):
				continue
			var bucket: PackedInt32Array = _cells[key]
			for idx in bucket:
				if _height[idx] <= 0.0:
					continue
				var p := _pos[idx]
				var dx := p.x - world_pos.x
				var dz := p.z - world_pos.z
				if dx * dx + dz * dz > r2:
					continue
				var chew := minf(rate * delta, _height[idx])
				_height[idx] -= chew
				eaten += chew * nutrition_per_tuft
				if _height[idx] <= EATEN_EPSILON:
					# Award the stub rather than dropping it on the floor.
					eaten += _height[idx] * nutrition_per_tuft
					_height[idx] = 0.0
					_alive -= 1
					_regrow_at.append(_time + regrow_delay)
					_regrow_idx.append(idx)
				_write_instance(idx)
	return eaten


## Cheap existence check for the "hold E to graze" prompt.
func has_grass_near(world_pos: Vector3, radius: float) -> bool:
	var r2 := radius * radius
	var span := int(ceil(radius / cell_size))
	var base := Vector2i(floori(world_pos.x / cell_size), floori(world_pos.z / cell_size))
	for cz in range(base.y - span, base.y + span + 1):
		for cx in range(base.x - span, base.x + span + 1):
			var key := Vector2i(cx, cz)
			if not _cells.has(key):
				continue
			var bucket: PackedInt32Array = _cells[key]
			for idx in bucket:
				if _height[idx] <= EATEN_EPSILON:
					continue
				var p := _pos[idx]
				var dx := p.x - world_pos.x
				var dz := p.z - world_pos.z
				if dx * dx + dz * dz <= r2:
					return true
	return false


func alive_count() -> int:
	return _alive


func total_count() -> int:
	return _pos.size()


## One tuft = a fan of thin tapered blades. No texture, no alpha, no atlas -
## the silhouette alone reads as grass, which keeps the art budget at zero.
func _build_tuft_mesh() -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = 991

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()

	const BLADES := 7
	const BASE_COL := Color(0.16, 0.28, 0.08)
	const TIP_COL := Color(0.47, 0.64, 0.22)

	for i in BLADES:
		var a := TAU * (float(i) / float(BLADES)) + rng.randf_range(-0.35, 0.35)
		var dir := Vector3(cos(a), 0.0, sin(a))
		var side := Vector3(-sin(a), 0.0, cos(a))
		var w := rng.randf_range(0.028, 0.052)
		var h := rng.randf_range(0.24, 0.44)
		var lean := rng.randf_range(0.05, 0.18)
		var root := dir * rng.randf_range(0.0, 0.09)

		var v0 := root - side * w
		var v1 := root + side * w
		var v2 := root + dir * lean + Vector3.UP * h
		var n := Vector3.UP.lerp(dir, 0.3).normalized()

		verts.append(v0)
		verts.append(v1)
		verts.append(v2)
		norms.append(n)
		norms.append(n)
		norms.append(n)
		cols.append(BASE_COL)
		cols.append(BASE_COL)
		cols.append(TIP_COL)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_COLOR] = cols

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 1.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	# Single-sided triangles would vanish when viewed from behind.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0, mat)
	return mesh
