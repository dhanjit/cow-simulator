extends Node3D
class_name CameraRig

## Orbiting third-person camera. Deliberately not a SpringArm3D - an explicit
## raycast makes the pull-in behaviour on steep terrain obvious and tunable.

@export var distance: float = 8.0
@export var min_distance: float = 2.5
@export var max_distance: float = 18.0
@export var zoom_step: float = 0.9
@export var height_offset: float = 1.5
@export var mouse_sensitivity: float = 0.0032
@export var follow_speed: float = 9.0
@export var min_pitch_deg: float = -70.0
@export var max_pitch_deg: float = 22.0
## Opening camera angle. The whole pitch of this game is the view, so the
## first frame should not be pointed at an arbitrary patch of grass.
@export var start_yaw_deg: float = 0.0
@export var start_pitch_deg: float = -16.0
## Layer 1 is terrain. The cow is on layer 2 and is excluded explicitly.
@export_flags_3d_physics var collision_mask: int = 1
## Minimum gap between the camera and the ground beneath it.
@export var ground_clearance: float = 0.7

## Optional. When set, the camera is clamped against the terrain heightfield
## as well as the raycast - the ray only catches what is between focus and
## camera, which misses the ground directly under the camera on a down-slope.
var terrain: MountainTerrain

var _yaw: float = 0.0
var _pitch: float = -0.28
var _focus: Vector3 = Vector3.ZERO
var _target: Node3D

@onready var camera: Camera3D = $Camera3D


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_yaw = deg_to_rad(start_yaw_deg)
	_pitch = clampf(deg_to_rad(start_pitch_deg), deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))


func set_target(node: Node3D) -> void:
	_target = node
	_focus = node.global_position + Vector3.UP * height_offset
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = clampf(distance - zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = clampf(distance + zoom_step, min_distance, max_distance)
		elif event.button_index == MOUSE_BUTTON_LEFT and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event.is_action_pressed("free_cursor"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)


func _process(delta: float) -> void:
	if _target == null:
		return
	var wanted := _target.global_position + Vector3.UP * height_offset
	_focus = _focus.lerp(wanted, 1.0 - exp(-follow_speed * delta))
	_apply()


func _apply() -> void:
	# pitch = 0 sits level behind the target; negative pitch lifts the camera.
	var dir := Vector3(0.0, 0.0, 1.0).rotated(Vector3.RIGHT, _pitch).rotated(Vector3.UP, _yaw)
	var wanted := _focus + dir * distance

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(_focus, wanted)
	query.collision_mask = collision_mask
	if _target is CollisionObject3D:
		query.exclude = [(_target as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		wanted = (hit["position"] as Vector3) + (hit["normal"] as Vector3) * 0.35

	if terrain != null:
		wanted.y = maxf(wanted.y, terrain.height_at(wanted.x, wanted.z) + ground_clearance)

	camera.global_position = wanted
	if wanted.distance_squared_to(_focus) > 0.0025:
		camera.look_at(_focus, Vector3.UP)
