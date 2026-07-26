extends CharacterBody3D
class_name Cow

signal fullness_changed(value: float, maximum: float)
signal graze_state_changed(grazing: bool)
signal mooed

@export_group("Movement")
@export var walk_speed: float = 4.2
@export var run_speed: float = 9.0
@export var acceleration: float = 20.0
@export var friction: float = 28.0
@export var turn_speed: float = 8.0
@export var gravity: float = 26.0

@export_group("Grazing")
@export var graze_radius: float = 1.3
## Tuft height chewed off per second.
@export var graze_rate: float = 1.2
@export var max_fullness: float = 100.0
@export var start_fullness: float = 35.0
@export var hunger_per_second: float = 0.45

var fullness: float = 35.0
var is_grazing: bool = false

## Assigned by the scene root. Grass is the thing we eat; camera gives us the
## basis for camera-relative movement.
var grass_field: GrassField
var camera: Camera3D

var _moo_cooldown: float = 0.0
var _moo_pose: float = 0.0
var _stride: float = 0.0

@onready var _model: Node3D = $Model
@onready var _neck: Node3D = $Model/Neck
@onready var _moo_player: AudioStreamPlayer3D = $MooPlayer
@onready var _moo_ring: MeshInstance3D = $MooRing


func _ready() -> void:
	fullness = clampf(start_fullness, 0.0, max_fullness)
	_moo_ring.visible = false
	fullness_changed.emit(fullness, max_fullness)


## Where the mouth is: just in front of the model, at ground level.
func mouth_position() -> Vector3:
	return global_position - _model.global_transform.basis.z * 1.05


## True when standing still on grass - drives the HUD prompt.
func can_graze_here() -> bool:
	if grass_field == null or not is_on_floor():
		return false
	return grass_field.has_grass_near(mouth_position(), graze_radius)


func _physics_process(delta: float) -> void:
	_moo_cooldown = maxf(0.0, _moo_cooldown - delta)
	_moo_pose = maxf(0.0, _moo_pose - delta)

	if Input.is_action_just_pressed("moo") and _moo_cooldown <= 0.0:
		_moo()

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var moving := input.length() > 0.15

	var wish := Vector3.ZERO
	if moving and camera != null:
		var b := camera.global_transform.basis
		wish = b.x * input.x + b.z * input.y
		wish.y = 0.0
		wish = wish.normalized()

	var planar := Vector3(velocity.x, 0.0, velocity.z)

	var wants_graze := (
		Input.is_action_pressed("graze")
		and is_on_floor()
		and not moving
		and planar.length() < 1.2
		and grass_field != null
		and grass_field.has_grass_near(mouth_position(), graze_radius)
	)
	_set_grazing(wants_graze)

	if wish != Vector3.ZERO and not is_grazing:
		var speed := run_speed if Input.is_action_pressed("run") else walk_speed
		planar = planar.move_toward(wish * speed, acceleration * delta)
	else:
		var brake := friction * (2.5 if is_grazing else 1.0)
		planar = planar.move_toward(Vector3.ZERO, brake * delta)

	velocity.x = planar.x
	velocity.z = planar.z
	move_and_slide()

	if is_grazing:
		var gained := grass_field.graze(mouth_position(), graze_radius, delta, graze_rate)
		if gained > 0.0:
			fullness = minf(max_fullness, fullness + gained)

	fullness = maxf(0.0, fullness - hunger_per_second * delta)
	fullness_changed.emit(fullness, max_fullness)

	_update_pose(delta, planar)


func _set_grazing(value: bool) -> void:
	if value == is_grazing:
		return
	is_grazing = value
	graze_state_changed.emit(is_grazing)


func _update_pose(delta: float, planar: Vector3) -> void:
	var speed := planar.length()

	if speed > 0.2:
		var target_yaw := atan2(-planar.x, -planar.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, 1.0 - exp(-turn_speed * delta))

	# Hoof bob and body sway, scaled by how fast we are actually moving.
	_stride += speed * delta * 2.4
	var gait := clampf(speed / walk_speed, 0.0, 1.6)
	_model.position.y = sin(_stride * 2.0) * 0.05 * gait
	_model.rotation.z = sin(_stride) * 0.045 * gait

	# Negative X rotation swings the head down toward the ground.
	var target_pitch := 0.0
	if is_grazing:
		target_pitch = deg_to_rad(-52.0)
	elif _moo_pose > 0.0:
		target_pitch = deg_to_rad(22.0)
	_neck.rotation.x = lerpf(_neck.rotation.x, target_pitch, 1.0 - exp(-11.0 * delta))


func _moo() -> void:
	_moo_cooldown = 0.75
	_moo_pose = 0.85
	_moo_player.stream = MooSynth.random_stream()
	_moo_player.pitch_scale = randf_range(0.92, 1.10)
	_moo_player.play()
	_ring_pulse()
	mooed.emit()


## Expanding ring so the moo is visible, not just audible.
func _ring_pulse() -> void:
	var mat := _moo_ring.get_active_material(0)
	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		_moo_ring.material_override = mat

	_moo_ring.visible = true
	_moo_ring.scale = Vector3.ONE * 0.25

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_moo_ring, "scale", Vector3.ONE * 4.5, 0.85).set_ease(Tween.EASE_OUT)
	if mat is StandardMaterial3D:
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.45)
		tween.tween_property(mat, "albedo_color:a", 0.0, 0.85)
	tween.chain().tween_callback(func() -> void: _moo_ring.visible = false)
