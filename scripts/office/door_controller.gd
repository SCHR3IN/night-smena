## DoorController — управление одной дверью
## Открытие/закрытие с анимацией и взаимодействие с PowerManager
extends Node2D

signal door_toggled(side: StringName, is_closed: bool)

@export_enum("left", "right") var side: String = "left"
@export var door_closed_sprite: Sprite2D
@export var door_open_sprite: Sprite2D
@export var door_button: TextureButton
@export var config: NightConfig

var is_closed: bool = false
var _animating: bool = false
var _enabled: bool = true


func _ready() -> void:
	if not config:
		config = NightConfig.new()
	_update_visuals()
	GameManager.state_changed.connect(_on_state_changed)
	if door_button:
		door_button.pressed.connect(_on_button_pressed)


func toggle() -> void:
	if _animating or not _enabled:
		return

	_animating = true
	is_closed = not is_closed

	var side_name := StringName(side)
	door_toggled.emit(side_name, is_closed)

	# Notify power manager
	if side == "left":
		get_node("/root/GameManager")
		_get_power_manager().left_door_closed = is_closed
	else:
		_get_power_manager().right_door_closed = is_closed

	# Animate
	var duration := config.door_close_time if is_closed else config.door_open_time
	_update_visuals()

	# Simple tween for animation feel
	var anim_tween := create_tween()
	if is_closed and door_closed_sprite:
		door_closed_sprite.modulate.a = 0.0
		anim_tween.tween_property(door_closed_sprite, "modulate:a", 1.0, duration)
	elif not is_closed and door_open_sprite:
		door_open_sprite.modulate.a = 0.0
		anim_tween.tween_property(door_open_sprite, "modulate:a", 1.0, duration)

	await anim_tween.finished
	_animating = false


func force_open() -> void:
	is_closed = false
	_animating = false
	_update_visuals()
	var side_name := StringName(side)
	door_toggled.emit(side_name, false)
	if side == "left":
		_get_power_manager().left_door_closed = false
	else:
		_get_power_manager().right_door_closed = false


func _update_visuals() -> void:
	if door_closed_sprite:
		door_closed_sprite.visible = is_closed
	if door_open_sprite:
		door_open_sprite.visible = not is_closed


func _on_button_pressed() -> void:
	toggle()


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice":
			_enabled = true
		&"TabletOpening", &"TabletOpen", &"TabletClosing":
			_enabled = false
		&"PowerOut":
			_enabled = false
			force_open()
		&"Dead", &"Win":
			_enabled = false


func _get_power_manager() -> Node:
	return get_tree().current_scene.get_node_or_null("PowerManager")
