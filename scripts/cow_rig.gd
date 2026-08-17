extends Node3D
class_name CowRig

## Drives the Quaternius cow (CC0) — a rigged, skinned glTF with hand-authored
## clips — in place of the procedural cow in cow_model.gd / cow_gait.gd.
##
## The asset supplies the things it is good at: a better mesh and hand-authored
## Walk / Gallop / Idle / Eating. This script supplies the three things it
## cannot do on its own:
##
##   1. Playback synced to actual ground speed, so the hooves do not skate. Same
##      principle as the procedural gait: drive the cycle from distance, not
##      from wall-clock time.
##   2. Body tilted to the terrain normal. A canned clip keeps the body level
##      while the ground tilts, and that reads wrong no matter how tall the
##      grass is. Grass hides foot contact; it does not hide a level body on a
##      slope.
##   3. Lying down, which no animal in the pack has a clip for (checked all 12).
##
## On (3): the pack's Death clip does end with the cow on the ground, but in
## LATERAL recumbency — flat on its side, legs out — which reads as a dead cow.
## Cattle actually rest STERNALLY: upright on the breastbone, legs folded under,
## head up. So the rest pose is built by folding the legs from the standing rest
## pose instead, which arrives at sternal directly rather than trying to
## un-roll a corpse.

const SOURCE := "res://assets/vendor/quaternius/Cow.gltf"
## Bind pose is 3.58 units tall; this lands the withers at ~1.50 m to match the
## proportions the procedural cow was measured to.
const MODEL_SCALE := 0.419
## The model's origin sits this far below its hooves, in model units.
const ORIGIN_LIFT := 0.9495

## Bones the Godot importer keeps but never evaluates — Blender IK constraints
## do not survive the trip. Listed so nobody wastes time posing them.
const INERT_BONES := [
	"PoleTargetBack.L", "PoleTarget.L", "PoleTargetBack.R", "PoleTarget.R",
	"IKBackLeg.L", "FFB.L", "IKFrontLeg.L", "FF.L",
	"IKBackLeg.R", "FFB.R", "IKFrontLeg.R", "FF.R",
]

@export_group("Locomotion")
## Ground speed at which the Walk clip looks natural at 1x playback.
@export var walk_clip_speed: float = 1.5
## Ground speed at which the Gallop clip looks natural at 1x playback.
@export var gallop_clip_speed: float = 5.5
@export var gallop_above: float = 5.0
@export var min_playback: float = 0.45
@export var max_playback: float = 2.2

@export_group("Terrain")
@export var lean_scale: float = 0.7
@export var lean_follow: float = 8.0

@export_group("Resting")
@export var rest_drop: float = 0.50
@export var rest_speed: float = 1.5
## Fold angles, in degrees, applied on top of each bone's rest pose. Signs and
## axes were found by rendering and correcting, not derived - the rig's local
## bone axes are whatever Blender left them as.
@export var fold_front_upper: float = -58.0
@export var fold_front_lower: float = 104.0
@export var fold_back_upper: float = 52.0
@export var fold_back_lower: float = -96.0
## The barrel sinking takes the head down with it, so the neck has to lift to
## compensate. A resting cow carries her head up; nose-in-the-grass reads as a
## sick animal, which is the single thing that decides whether this pose works.
@export var lift_neck1: float = 34.0
@export var lift_neck2: float = 16.0

@export_group("Markings")
@export var hide_color: Color = Color(0.95, 0.94, 0.91)
@export var spot_color: Color = Color(0.11, 0.10, 0.10)
@export var spot_threshold: float = 0.58
## Object-space tiling. The body is ~7.8 units long, so this and the noise
## frequency below together decide how many patches run down the flank. Aim for
## four or five big ones - anything finer reads as a dalmatian.
@export var spot_tile: float = 0.22

var _instance: Node3D
var _anim: AnimationPlayer
var _skel: Skeleton3D
var _terrain: MountainTerrain

var _yaw := 0.0
var _pitch := 0.0
var _roll := 0.0
var _rest := 0.0
var _clip := ""
var _ready_done := false


func setup(terrain: MountainTerrain) -> void:
	_terrain = terrain

	var packed := load(SOURCE) as PackedScene
	_instance = packed.instantiate() as Node3D
	add_child(_instance)
	_instance.scale = Vector3.ONE * MODEL_SCALE
	_instance.position.y = -ORIGIN_LIFT * MODEL_SCALE

	_anim = _instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var skels := _instance.find_children("*", "Skeleton3D", true, false)
	if not skels.is_empty():
		_skel = skels[0] as Skeleton3D

	_paint_holstein()
	_ready_done = true
	_play("Idle")


## The asset ships seven flat colour materials and no textures, which is why it
## sits so well against flat-shaded terrain - and why it can be repainted freely.
## The body gets a shader that stamps noise-warped patches in object space, so
## the markings wrap the form instead of sitting on it.
func _paint_holstein() -> void:
	if _skel == null:
		return
	var noise := FastNoiseLite.new()
	noise.seed = 11
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	# Frequency is per texel across a 48-cube, so this is ~2.4 cycles per
	# texture repeat. Octaves off: fractal detail is exactly what turns cow
	# patches into speckle.
	noise.frequency = 0.05
	noise.fractal_type = FastNoiseLite.FRACTAL_NONE

	var tex := NoiseTexture3D.new()
	tex.width = 48
	tex.height = 48
	tex.depth = 48
	tex.seamless = true
	tex.noise = noise

	var shader := Shader.new()
	shader.code = """
shader_type spatial;

uniform sampler3D spots;
uniform vec3 hide : source_color;
uniform vec3 spot : source_color;
uniform float threshold;
uniform float tile;

varying vec3 obj;

void vertex() {
	obj = VERTEX;
}

void fragment() {
	float n = texture(spots, obj * tile).r;
	ALBEDO = mix(hide, spot, step(threshold, n));
	ROUGHNESS = 0.82;
	SPECULAR = 0.1;
}
"""
	var hide_mat := ShaderMaterial.new()
	hide_mat.shader = shader
	hide_mat.set_shader_parameter("spots", tex)
	hide_mat.set_shader_parameter("hide", hide_color)
	hide_mat.set_shader_parameter("spot", spot_color)
	hide_mat.set_shader_parameter("threshold", spot_threshold)
	hide_mat.set_shader_parameter("tile", spot_tile)

	for child in _instance.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var mesh := mi.mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var existing := mesh.surface_get_material(s)
			var mat_name := "" if existing == null else existing.resource_name
			match mat_name:
				"Main", "Main_Light":
					mi.set_surface_override_material(s, hide_mat)
				"Hooves":
					mi.set_surface_override_material(s, _flat(Color(0.15, 0.13, 0.13), 0.6))
				"Muzzle":
					mi.set_surface_override_material(s, _flat(Color(0.93, 0.62, 0.61), 0.7))
				"Horns":
					mi.set_surface_override_material(s, _flat(Color(0.85, 0.79, 0.66), 0.55))
				_:
					pass


func _flat(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func update(delta: float, planar_velocity: Vector3, grazing: bool, resting: bool, mooing: bool) -> void:
	if not _ready_done:
		return

	_rest = move_toward(_rest, 1.0 if resting else 0.0, delta * rest_speed)
	var speed := planar_velocity.length()

	_face(delta, planar_velocity)
	_lean(delta)
	_choose_clip(speed, grazing, mooing)
	_pose_rest(delta)


func _face(delta: float, planar: Vector3) -> void:
	if planar.length() > 0.2:
		_yaw = lerp_angle(_yaw, atan2(-planar.x, -planar.z), 1.0 - exp(-8.0 * delta))
	rotation.y = _yaw


## Tilt to the ground. Pitch and roll are the slope resolved along the cow's own
## forward and right axes, so she noses downhill and banks across a contour.
func _lean(delta: float) -> void:
	if _terrain == null:
		return
	var n := _terrain.normal_at(global_position.x, global_position.z)
	var forward := Vector3(-sin(_yaw), 0.0, -cos(_yaw))
	var right := Vector3(cos(_yaw), 0.0, -sin(_yaw))

	var want_pitch := asin(clampf(n.dot(forward), -1.0, 1.0)) * lean_scale
	var want_roll := -asin(clampf(n.dot(right), -1.0, 1.0)) * lean_scale

	var k := 1.0 - exp(-lean_follow * delta)
	_pitch = lerpf(_pitch, want_pitch, k)
	_roll = lerpf(_roll, want_roll, k)
	rotation.x = _pitch
	rotation.z = _roll


func _choose_clip(speed: float, grazing: bool, mooing: bool) -> void:
	if _anim == null:
		return

	# While bedding down the skeleton is posed directly, so the player must not
	# also be writing bone tracks over the top of it.
	if _rest > 0.01:
		if _anim.is_playing():
			_anim.stop()
			_clip = ""
		return

	var want := "Idle"
	var rate := 1.0
	if grazing:
		want = "Eating"
	elif speed > gallop_above:
		want = "Gallop"
		rate = speed / gallop_clip_speed
	elif speed > 0.2:
		want = "Walk"
		# Distance-driven, not time-driven. This is what keeps the hooves from
		# skating when the cow moves faster or slower than the clip assumed.
		rate = speed / walk_clip_speed
	elif mooing:
		want = "Idle_2"

	_anim.speed_scale = clampf(rate, min_playback, max_playback)
	_play(want)


func _play(clip: String) -> void:
	if _anim == null or _clip == clip:
		return
	if not _anim.has_animation(clip):
		return
	var anim := _anim.get_animation(clip)
	anim.loop_mode = Animation.LOOP_LINEAR
	_anim.play(clip)
	_clip = clip


## Sternal rest, folded out of the standing pose rather than borrowed from the
## Death clip. Legs tuck under, the barrel sinks, the head stays up.
func _pose_rest(_delta: float) -> void:
	if _skel == null:
		return
	if _rest <= 0.001:
		if _instance != null:
			_instance.position.y = -ORIGIN_LIFT * MODEL_SCALE
		return

	_fold("FrontUpperLeg.L", fold_front_upper)
	_fold("FrontUpperLeg.R", fold_front_upper)
	_fold("FrontLowerLeg.L", fold_front_lower)
	_fold("FrontLowerLeg.R", fold_front_lower)
	_fold("BackUpperLeg.L", fold_back_upper)
	_fold("BackUpperLeg.R", fold_back_upper)
	_fold("BackLowerLeg.L", fold_back_lower)
	_fold("BackLowerLeg.R", fold_back_lower)
	_fold("Neck1", lift_neck1)
	_fold("Neck2", lift_neck2)

	_instance.position.y = -ORIGIN_LIFT * MODEL_SCALE - rest_drop * _rest


func _fold(bone_name: String, degrees: float) -> void:
	var idx := _skel.find_bone(bone_name)
	if idx < 0:
		return
	var base := _skel.get_bone_rest(idx).basis.get_rotation_quaternion()
	var folded := base * Quaternion(Vector3.RIGHT, deg_to_rad(degrees))
	_skel.set_bone_pose_rotation(idx, base.slerp(folded, _rest))


func is_resting_settled() -> bool:
	return _rest > 0.98
