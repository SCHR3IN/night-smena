## CorridorLightController — свет коридора (удержание кнопки)
extends Node2D

signal light_toggled(side: StringName, is_on: bool)

@export_enum("left", "right") var side: String = "left"
@export var light_sprite: Sprite2D  # Освещённый коридор
@export var light_button: TextureButton

var is_on: bool = false
var _enabled: bool = true


func _ready() -> void:
	_update_visuals()
	GameManager.state_changed.connect(_on_state_changed)


func _process(_delta: float) -> void:
	if not _enabled:
		return

	# Hold-to-light mechanic via keyboard
	var action_name := "ui_left_light" if side == "left" else "ui_right_light"
	var should_be_on := Input.is_action_pressed(action_name)

	if should_be_on != is_on:
		is_on = should_be_on
		_update_visuals()
		light_toggled.emit(StringName(side), is_on)
		_update_power()


func turn_on() -> void:
	if is_on or not _enabled:
		return
	is_on = true
	_update_visuals()
	light_toggled.emit(StringName(side), true)
	_update_power()


func turn_off() -> void:
	if not is_on:
		return
	is_on = false
	_update_visuals()
	light_toggled.emit(StringName(side), false)
	_update_power()


func force_off() -> void:
	is_on = false
	_update_visuals()
	_update_power()


func _update_visuals() -> void:
	if light_sprite:
		light_sprite.visible = is_on


func _update_power() -> void:
	var power := _get_power_manager()
	if not power:
		return
	if side == "left":
		power.left_light_on = is_on
	else:
		power.right_light_on = is_on


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice":
			_enabled = true
		&"TabletOpening", &"TabletOpen", &"TabletClosing":
			_enabled = false
			force_off()
		&"PowerOut":
			_enabled = false
			force_off()
		&"Dead", &"Win":
			_enabled = false


func _get_power_manager() -> Node:
	return get_tree().current_scene.get_node_or_null("PowerManager")
