extends CanvasLayer
class_name Hud

@onready var _bar: ProgressBar = $Root/FullnessBar
@onready var _fullness_label: Label = $Root/FullnessLabel
@onready var _prompt: Label = $Root/Prompt
@onready var _moo_flash: Label = $Root/MooFlash

var _grazing: bool = false
var _in_reach: bool = false


func _ready() -> void:
	_prompt.visible = false
	_moo_flash.modulate.a = 0.0


func set_fullness(value: float, maximum: float) -> void:
	_bar.max_value = maximum
	_bar.value = value
	var pct := 0.0 if maximum <= 0.0 else (value / maximum) * 100.0
	_fullness_label.text = "Fullness  %d%%" % roundi(pct)


func set_grazing(grazing: bool) -> void:
	_grazing = grazing
	_refresh_prompt()


func set_grass_in_reach(in_reach: bool) -> void:
	if in_reach == _in_reach:
		return
	_in_reach = in_reach
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _grazing:
		_prompt.text = "munch..."
		_prompt.visible = true
	elif _in_reach:
		_prompt.text = "Hold  E  to graze"
		_prompt.visible = true
	else:
		_prompt.visible = false


func flash_moo() -> void:
	_moo_flash.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_property(_moo_flash, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
