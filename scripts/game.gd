extends Node3D

## Scene root. Owns the build order explicitly - terrain first, then grass
## scattered onto it, then the cow dropped onto a spot the terrain picked.
## Relying on _ready() ordering between siblings would be fragile.

@onready var terrain: MountainTerrain = $Terrain
@onready var grass: GrassField = $Grass
@onready var cow: Cow = $Cow
@onready var rig: CameraRig = $CameraRig
@onready var hud: Hud = $Hud


func _ready() -> void:
	var started := Time.get_ticks_msec()

	terrain.generate()
	grass.populate(terrain)

	cow.grass_field = grass
	cow.camera = rig.camera
	cow.global_position = terrain.spawn_point()
	# The gait reads hip positions off the model's global transform, so the cow
	# has to be standing in its final spot before the rig is initialised.
	cow.begin(terrain)
	rig.terrain = terrain
	rig.set_target(cow)

	cow.fullness_changed.connect(hud.set_fullness)
	cow.graze_state_changed.connect(hud.set_grazing)
	cow.mooed.connect(hud.flash_moo)
	hud.set_fullness(cow.fullness, cow.max_fullness)

	print("[cow-simulator] world built in %d ms - %d tufts, spawn %v" % [
		Time.get_ticks_msec() - started, grass.total_count(), cow.global_position
	])


func _process(_delta: float) -> void:
	hud.set_grass_in_reach(cow.can_graze_here())
