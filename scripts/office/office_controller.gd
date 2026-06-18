## OfficeController — обзор офиса с дверями и светом
## Три панели: лево (дверь+свет), центр (стол), право (дверь+свет)
## Мышь у краёв → поворот. Кнопки Q/E — двери, A/D — свет
extends Node2D

signal view_changed(view_name: StringName)

enum View { LEFT, CENTER, RIGHT }

var current_view: View = View.CENTER
var _target_x: float = 0.0
var _input_enabled: bool = true

const VIEW_WIDTH: float = 640.0
const EDGE_ZONE: float = 100.0  # пикселей от края для поворота
const SCROLL_SPEED: float = 10.0

# Door state
var left_door_closed: bool = false
var right_door_closed: bool = false

# Light state (hold only)
var left_light_on: bool = false
var right_light_on: bool = false

# References (set from game scene)
var power_manager: Node = null


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if not _input_enabled:
		return

	_handle_mouse_look()
	_handle_keyboard()

	# Smooth scroll
	position.x = lerpf(position.x, _target_x, SCROLL_SPEED * delta)


func _handle_mouse_look() -> void:
	var mouse_x := get_viewport().get_mouse_position().x
	var vw := get_viewport().get_visible_rect().size.x

	if mouse_x < EDGE_ZONE:
		_set_view(View.LEFT)
	elif mouse_x > vw - EDGE_ZONE:
		_set_view(View.RIGHT)
	else:
		_set_view(View.CENTER)


func _handle_keyboard() -> void:
	# Doors: Q = left door, E = right door (toggle)
	if Input.is_action_just_pressed("ui_left_door"):
		toggle_door("left")
	if Input.is_action_just_pressed("ui_right_door"):
		toggle_door("right")

	# Lights: A = left light, D = right light (hold)
	var want_left_light := Input.is_action_pressed("ui_left_light")
	var want_right_light := Input.is_action_pressed("ui_right_light")

	if want_left_light != left_light_on:
		left_light_on = want_left_light
		_update_light("left", left_light_on)

	if want_right_light != right_light_on:
		right_light_on = want_right_light
		_update_light("right", right_light_on)


func _set_view(new_view: View) -> void:
	if new_view == current_view:
		return
	current_view = new_view
	match new_view:
		View.LEFT:
			_target_x = VIEW_WIDTH  # Сдвиг вправо → показать левый спрайт
		View.CENTER:
			_target_x = 0.0
		View.RIGHT:
			_target_x = -VIEW_WIDTH  # Сдвиг влево → показать правый спрайт

	var names := {View.LEFT: &"left", View.CENTER: &"center", View.RIGHT: &"right"}
	view_changed.emit(names[new_view])


func toggle_door(side: String) -> void:
	if side == "left":
		left_door_closed = not left_door_closed
		_update_door_visual("left", left_door_closed)
		if power_manager:
			power_manager.left_door_closed = left_door_closed
	else:
		right_door_closed = not right_door_closed
		_update_door_visual("right", right_door_closed)
		if power_manager:
			power_manager.right_door_closed = right_door_closed


func _update_door_visual(side: String, closed: bool) -> void:
	# Update door overlay sprites
	var door_node_name := "LeftDoorClosed" if side == "left" else "RightDoorClosed"
	var corridor_name := "LeftCorridor" if side == "left" else "RightCorridor"
	var door_sprite := get_node_or_null(door_node_name)
	var corridor_sprite := get_node_or_null(corridor_name)

	if door_sprite:
		door_sprite.visible = closed
	if corridor_sprite:
		corridor_sprite.visible = not closed


func _update_light(side: String, on: bool) -> void:
	var light_name := "LeftLight" if side == "left" else "RightLight"
	var light_sprite := get_node_or_null(light_name)

	if light_sprite:
		if on:
			# Only show animatronic sprite if AI is actually at the corridor
			var game_scene = get_tree().current_scene
			if game_scene and game_scene.has_method("is_animatronic_at_door"):
				light_sprite.visible = game_scene.is_animatronic_at_door(side)
			else:
				light_sprite.visible = false
		else:
			light_sprite.visible = false

	if power_manager:
		if side == "left":
			power_manager.left_light_on = on
		else:
			power_manager.right_light_on = on


func force_open_doors() -> void:
	left_door_closed = false
	right_door_closed = false
	_update_door_visual("left", false)
	_update_door_visual("right", false)
	if power_manager:
		power_manager.left_door_closed = false
		power_manager.right_door_closed = false


func force_lights_off() -> void:
	left_light_on = false
	right_light_on = false
	_update_light("left", false)
	_update_light("right", false)


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice":
			_input_enabled = true
		&"TabletOpening", &"TabletOpen", &"TabletClosing":
			_input_enabled = false
			force_lights_off()
		&"PowerOut":
			_input_enabled = false
			force_open_doors()
			force_lights_off()
		&"Paused", &"Dead", &"Win":
			_input_enabled = false
