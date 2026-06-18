## OfficeController — управление обзором офиса
## Плавный поворот камеры между тремя ракурсами: лево, центр, право
extends Node2D

signal view_changed(view_name: StringName)

enum View { LEFT, CENTER, RIGHT }

@export var center_sprite: Sprite2D
@export var left_sprite: Sprite2D
@export var right_sprite: Sprite2D
@export var transition_speed: float = 8.0

var current_view: View = View.CENTER
var _target_x: float = 0.0
var _view_width: float = 640.0
var _mouse_edge_zone: float = 80.0  # пикселей от края для поворота
var _input_enabled: bool = true

const VIEW_NAMES: Dictionary = {
	View.LEFT: &"left",
	View.CENTER: &"center",
	View.RIGHT: &"right",
}


func _ready() -> void:
	_view_width = get_viewport().get_visible_rect().size.x
	_setup_sprites()
	GameManager.state_changed.connect(_on_state_changed)


func _setup_sprites() -> void:
	# Center at 0, Left at -640, Right at +640
	if center_sprite:
		center_sprite.position.x = 0
	if left_sprite:
		left_sprite.position.x = -_view_width
	if right_sprite:
		right_sprite.position.x = _view_width


func _process(delta: float) -> void:
	if not _input_enabled:
		return

	_handle_mouse_look()
	_smooth_scroll(delta)


func _handle_mouse_look() -> void:
	var mouse_x := get_viewport().get_mouse_position().x
	var viewport_w := get_viewport().get_visible_rect().size.x

	if mouse_x < _mouse_edge_zone:
		_set_view(View.LEFT)
	elif mouse_x > viewport_w - _mouse_edge_zone:
		_set_view(View.RIGHT)
	else:
		_set_view(View.CENTER)


func _set_view(new_view: View) -> void:
	if new_view == current_view:
		return
	current_view = new_view
	match new_view:
		View.LEFT:
			_target_x = _view_width
		View.CENTER:
			_target_x = 0.0
		View.RIGHT:
			_target_x = -_view_width
	view_changed.emit(VIEW_NAMES[new_view])


func _smooth_scroll(delta: float) -> void:
	position.x = lerpf(position.x, _target_x, transition_speed * delta)


func set_input_enabled(enabled: bool) -> void:
	_input_enabled = enabled


func force_center() -> void:
	current_view = View.CENTER
	_target_x = 0.0
	position.x = 0.0


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice":
			_input_enabled = true
		&"TabletOpening", &"TabletOpen", &"TabletClosing":
			_input_enabled = false
		&"Paused", &"Dead", &"Win", &"PowerOut":
			_input_enabled = false
