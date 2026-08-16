extends Node
class_name CowGait

## Procedural four-legged walk. No skeleton, no animation clips, no addon.
##
## The model generator already knows where every hip socket is, so the only
## missing pieces are: where should each hoof be right now, and where should
## the body sit given where the hooves ended up.
##
## Three things do most of the work:
##
##   1. Lateral-sequence footfall. A cow walks LH, LF, RH, RF - never the
##      diagonal sequence, which is a primate gait.
##   2. Phase advances by DISTANCE, not time. This is what stops the feet
##      ice-skating: if the body has not moved, the cycle has not advanced.
##   3. A planted hoof is pinned to the world position it landed on and does
##      not move again until it lifts. Everything else is derived from that.

## Fraction of the cycle each hoof spends on the ground. Measured dairy cow is
## ~0.68 front / 0.64 hind; one value is close enough at this fidelity.
const DUTY := 0.66

## Cycle offsets per leg, in CowModel's FL/FR/BL/BR order. Back-left leads.
const PHASE_OFFSET := [0.25, 0.75, 0.0, 0.5]

@export var stride_length: float = 1.15
@export var step_lift: float = 0.16
## How far a hoof may drift from its rest position before it steps to correct,
## which is what lets the cow shuffle its feet while turning on the spot.
@export var reposition_threshold: float = 0.42
@export var body_follow: float = 12.0
@export var lean_scale: float = 0.55

var _model: CowModel
var _owner: Node3D
var _terrain: MountainTerrain

var _foot := PackedVector3Array()
var _anchor := PackedVector3Array()
var _target := PackedVector3Array()
var _planted := [true, true, true, true]
var _phase := 0.0
var _cycle := 0.0
var _body_y := 0.0
var _pitch := 0.0
var _roll := 0.0
var _ready_done := false


func setup(model: CowModel, body: Node3D, terrain: MountainTerrain) -> void:
	_model = model
	_owner = body
	_terrain = terrain

	_foot.resize(4)
	_anchor.resize(4)
	_target.resize(4)
	for i in 4:
		var home := _home_of(i)
		_foot[i] = home
		_anchor[i] = home
		_target[i] = home
	_body_y = 0.0
	_ready_done = true
	_apply_legs()


## Rest position of a hoof in world space: straight down from its hip socket,
## dropped onto the terrain.
func _home_of(i: int) -> Vector3:
	var hip: Vector3 = _model.global_transform * CowModel.HIPS[i]
	return Vector3(hip.x, _ground(hip.x, hip.z), hip.z)


func _ground(x: float, z: float) -> float:
	# The terrain is a heightfield we generated, so ask it directly rather than
	# paying for a physics raycast per hoof per frame.
	return _terrain.height_at(x, z) if _terrain != null else 0.0


func update(delta: float, planar_velocity: Vector3, grazing: bool) -> void:
	if not _ready_done:
		return

	var speed := planar_velocity.length()

	# Distance-driven, so a stationary cow has a stationary cycle.
	if speed > 0.05:
		_phase = fposmod(_phase + speed * delta / stride_length, 1.0)
	_cycle = maxf(0.35, stride_length / maxf(speed, 0.01))

	for i in 4:
		_step_leg(i, speed, planar_velocity)

	_settle_body(delta, grazing)
	_apply_legs()


func _step_leg(i: int, speed: float, planar_velocity: Vector3) -> void:
	var p := fposmod(_phase + PHASE_OFFSET[i], 1.0)
	var should_plant := p < DUTY

	# Standing still: a hoof that has drifted too far from under its hip steps
	# back on its own. Without this the cow pivots on locked feet when turning.
	if speed <= 0.05:
		var home := _home_of(i)
		if _planted[i] and Vector2(home.x - _foot[i].x, home.z - _foot[i].z).length() > reposition_threshold:
			should_plant = false
			_anchor[i] = _foot[i]
			_target[i] = home
			_planted[i] = false
			return
		if _planted[i]:
			return

	if should_plant:
		if not _planted[i]:
			_foot[i] = _target[i]
			_planted[i] = true
		return

	if _planted[i]:
		# Lift-off: choose where this hoof is going to land.
		_anchor[i] = _foot[i]
		_target[i] = _predict_landing(i, planar_velocity)
		_planted[i] = false

	var s := clampf((p - DUTY) / (1.0 - DUTY), 0.0, 1.0)
	if speed <= 0.05:
		# Repositioning shuffle runs on its own clock, not the gait cycle.
		s = clampf(s + 0.06, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, s)
	var flat := _anchor[i].lerp(_target[i], eased)
	flat.y = _ground(flat.x, flat.z) + sin(PI * s) * step_lift
	_foot[i] = flat

	if s >= 1.0:
		_planted[i] = true
		_foot[i] = _target[i]


func _predict_landing(i: int, planar_velocity: Vector3) -> Vector3:
	var home := _home_of(i)
	# Land ahead of the hip by roughly half the swing's worth of travel, so the
	# hoof arrives under the body rather than behind it.
	var swing_time := (1.0 - DUTY) * _cycle
	var lead := planar_velocity * swing_time * 0.55
	var spot := home + Vector3(lead.x, 0.0, lead.z)
	spot.y = _ground(spot.x, spot.z)
	return spot


## Body height, pitch and roll come from where the hooves actually are. This is
## what replaces the old sine-wave bob, which had no relationship to the ground.
func _settle_body(delta: float, grazing: bool) -> void:
	var mean_y := 0.0
	for i in 4:
		mean_y += _foot[i].y
	mean_y *= 0.25

	var front := (_foot[CowModel.FL] + _foot[CowModel.FR]) * 0.5
	var back := (_foot[CowModel.BL] + _foot[CowModel.BR]) * 0.5
	var left := (_foot[CowModel.FL] + _foot[CowModel.BL]) * 0.5
	var right := (_foot[CowModel.FR] + _foot[CowModel.BR]) * 0.5

	var wheelbase := maxf(0.4, CowModel.HIPS[CowModel.BL].z - CowModel.HIPS[CowModel.FL].z)
	var track := maxf(0.2, CowModel.HIPS[CowModel.FR].x - CowModel.HIPS[CowModel.FL].x)

	var want_pitch := atan2(front.y - back.y, wheelbase) * lean_scale
	var want_roll := atan2(right.y - left.y, track) * lean_scale
	var want_y := mean_y - _owner.global_position.y

	if grazing:
		want_y -= 0.04

	var k := 1.0 - exp(-body_follow * delta)
	_body_y = lerpf(_body_y, want_y, k)
	_pitch = lerpf(_pitch, want_pitch, k)
	_roll = lerpf(_roll, want_roll, k)

	_model.position.y = _body_y
	_model.rotation.x = _pitch
	_model.rotation.z = _roll


## Two-bone IK. `acos` arguments are clamped because a NaN here silently
## teleports the whole leg out of the world.
func _apply_legs() -> void:
	var l1 := CowModel.UPPER_LEN
	var l2 := CowModel.LOWER_LEN
	var basis := _model.global_transform.basis
	var side_axis := basis.x.normalized()
	var ref := basis.z

	for i in 4:
		var hip: Vector3 = _model.global_transform * CowModel.HIPS[i]
		var to_foot := _foot[i] - hip
		var dist := clampf(to_foot.length(), absf(l1 - l2) * 1.01, (l1 + l2) * 0.995)
		var dir := to_foot.normalized() if to_foot.length_squared() > 1e-8 else Vector3.DOWN

		var cos_a := clampf((l1 * l1 + dist * dist - l2 * l2) / (2.0 * l1 * dist), -1.0, 1.0)
		var a := acos(cos_a)

		# Front knees fold backwards, hind hocks fold forwards. Flipping this
		# sign between the pairs is what makes the silhouette read as a cow
		# rather than as a table.
		var pole := 1.0 if i == CowModel.BL or i == CowModel.BR else -1.0
		var knee_dir := dir.rotated(side_axis, a * pole)
		var knee := hip + knee_dir * l1

		_aim(_model.leg_upper[i], hip, knee, ref)
		_aim(_model.leg_lower[i], knee, _foot[i], ref)
		_model.leg_knee[i].global_position = knee


## Places a segment at `from` with its own -Y axis pointing at `to`.
func _aim(node: Node3D, from: Vector3, to: Vector3, ref: Vector3) -> void:
	var d := to - from
	if d.length_squared() < 1e-8:
		d = Vector3.DOWN
	var y := -d.normalized()
	var x := ref.cross(y)
	if x.length_squared() < 1e-8:
		x = Vector3.RIGHT.cross(y)
	x = x.normalized()
	node.global_transform = Transform3D(Basis(x, y, x.cross(y)), from)


func foot_position(i: int) -> Vector3:
	return _foot[i]


func is_planted(i: int) -> bool:
	return _planted[i]
