extends Node
class_name CowLife

## The small involuntary motions that make an animal look alive rather than
## driven. None of this is gameplay - it is entirely about the cow never being
## completely still.
##
## Everything here is on its own clock. Nothing is locked to the stride, because
## a real cow's tail and ears are not synchronised with its feet, and anything
## that beats in time with the walk immediately reads as machinery.

@export var tail_sway_speed: float = 1.15
@export var tail_sway_amount: float = 0.16
@export var chew_speed: float = 4.2
@export var neck_follow: float = 11.0

## Neck pitch targets, in degrees. Negative swings the muzzle toward the ground.
const PITCH_GRAZE := -72.0
const PITCH_MOO := 22.0
## Bedded down the head is carried a little lower and more level.
const PITCH_REST := -14.0
## Rotation alone cannot reach the grass: hip height minus neck length still
## leaves the muzzle in mid air, so the shoulder drops too.
const GRAZE_NECK_DROP := Vector3(0.0, -0.30, -0.10)

var _model: CowModel
var _neck: Node3D
var _neck_rest: Vector3

var _rng := RandomNumberGenerator.new()
var _t := 0.0
var _chew := 0.0
var _chew_left := 0.0
var _next_chew := 6.0
var _swish := 0.0
var _next_swish := 4.0
var _blink := 0.0
var _next_blink := 3.0
var _look_target := 0.0
var _look := 0.0
var _next_look := 5.0
var _ear := [0.0, 0.0]
var _next_ear := 2.5
var _ready_done := false


func setup(model: CowModel, neck: Node3D) -> void:
	_model = model
	_neck = neck
	_neck_rest = neck.position
	_rng.randomize()
	_ready_done = true


func update(delta: float, grazing: bool, mooing: bool, speed: float, resting: bool) -> void:
	if not _ready_done:
		return
	_t += delta
	_tick_neck(delta, grazing, mooing, speed, resting)
	_tick_tail(delta, speed)
	_tick_ears(delta)
	_tick_eyes(delta)


# ------------------------------------------------------------------ neck/head

func _tick_neck(delta: float, grazing: bool, mooing: bool, speed: float, resting: bool) -> void:
	# Cud-chewing. Grazing chews constantly; a lying cow ruminates almost
	# continuously, which is most of what a resting cow is actually doing.
	if grazing:
		_chew_left = 0.4
	else:
		_next_chew -= delta
		if _next_chew <= 0.0 and speed < 0.4:
			_chew_left = _rng.randf_range(4.0, 9.0) if resting else _rng.randf_range(2.5, 6.0)
			_next_chew = _rng.randf_range(2.0, 5.0) if resting else _rng.randf_range(9.0, 20.0)
	if _chew_left > 0.0:
		_chew_left -= delta
		_chew += delta * chew_speed
	var chew_offset := sin(_chew) * (0.035 if _chew_left > 0.0 else 0.0)

	# Idle glances. A grazing or walking cow keeps its head where it is; a
	# resting one looks around more, since that is all there is to do.
	_next_look -= delta
	if _next_look <= 0.0:
		_next_look = _rng.randf_range(3.0, 8.0) if resting else _rng.randf_range(4.0, 11.0)
		_look_target = 0.0 if (grazing or speed > 0.4) else _rng.randf_range(-0.5, 0.5)
	if grazing or speed > 0.4:
		_look_target = 0.0
	_look = lerpf(_look, _look_target, 1.0 - exp(-2.5 * delta))

	var pitch := 0.0
	if grazing:
		pitch = deg_to_rad(PITCH_GRAZE)
	elif mooing:
		pitch = deg_to_rad(PITCH_MOO)
	elif resting:
		pitch = deg_to_rad(PITCH_REST)
	# A walking cow carries its head a little lower than a standing one.
	pitch += -0.06 * clampf(speed / 4.0, 0.0, 1.5)

	var k := 1.0 - exp(-neck_follow * delta)
	_neck.rotation.x = lerpf(_neck.rotation.x, pitch + chew_offset, k)
	_neck.rotation.y = lerpf(_neck.rotation.y, _look, k)

	var want := _neck_rest + (GRAZE_NECK_DROP if grazing else Vector3.ZERO)
	_neck.position = _neck.position.lerp(want, k)


# ----------------------------------------------------------------------- tail

func _tick_tail(delta: float, speed: float) -> void:
	if _model.tail_joints.is_empty():
		return

	# Occasional sharp flick, as if at a fly.
	_next_swish -= delta
	if _next_swish <= 0.0:
		_next_swish = _rng.randf_range(3.0, 9.0)
		_swish = _rng.randf_range(0.5, 1.0) * (1.0 if _rng.randf() < 0.5 else -1.0)
	_swish = move_toward(_swish, 0.0, delta * 1.6)

	var sway := sin(_t * tail_sway_speed) * tail_sway_amount
	var walk_wag := sin(_t * (1.4 + speed * 0.5)) * 0.05 * clampf(speed / 4.0, 0.0, 1.0)

	for i in _model.tail_joints.size():
		var joint: Node3D = _model.tail_joints[i]
		# Phase lag down the chain turns a rigid sweep into a whip.
		var lag := float(i) * 0.55
		var amount := (sway + walk_wag) * (0.4 + float(i) * 0.3)
		var flick := _swish * sin(_t * 9.0 - lag) * (0.25 + float(i) * 0.35)
		var target_z := sin(_t * tail_sway_speed - lag) * 0.0 + amount + flick
		if i == 0:
			joint.rotation.z = lerpf(joint.rotation.z, target_z * 0.5, 1.0 - exp(-9.0 * delta))
		else:
			joint.rotation.z = lerpf(joint.rotation.z, target_z, 1.0 - exp(-9.0 * delta))
			joint.rotation.x = lerpf(joint.rotation.x, flick * 0.3, 1.0 - exp(-9.0 * delta))


# ------------------------------------------------------------------ ears/eyes

func _tick_ears(delta: float) -> void:
	if _model.ear_pivots.is_empty():
		return
	_next_ear -= delta
	if _next_ear <= 0.0:
		_next_ear = _rng.randf_range(1.5, 6.0)
		_ear[_rng.randi_range(0, 1)] = _rng.randf_range(0.35, 0.7)

	for i in _model.ear_pivots.size():
		var idx := mini(i, _ear.size() - 1)
		_ear[idx] = move_toward(_ear[idx], 0.0, delta * 2.4)
		var pivot: Node3D = _model.ear_pivots[i]
		pivot.rotation.z = sin(_t * 16.0) * _ear[idx] * 0.5


func _tick_eyes(delta: float) -> void:
	if _model.eyes.is_empty():
		return
	_next_blink -= delta
	if _next_blink <= 0.0:
		_next_blink = _rng.randf_range(2.5, 7.0)
		_blink = 0.16

	var squash := 1.0
	if _blink > 0.0:
		_blink -= delta
		squash = 0.12
	for eye in _model.eyes:
		var e: MeshInstance3D = eye
		e.scale.y = lerpf(e.scale.y, squash, 1.0 - exp(-26.0 * delta))
