## GameScene — главный контроллер игровой ночи
## Собирает все системы и управляет геймплейным циклом
extends Node2D

@onready var office: Node2D = $Office
@onready var time_manager: Node = $TimeManager
@onready var power_manager: Node = $PowerManager
@onready var camera_system: Node = $CameraSystem

# HUD elements
@onready var time_label: Label = $HUD/TimeLabel
@onready var power_label: Label = $HUD/PowerLabel
@onready var power_bar: ProgressBar = $HUD/PowerBar
@onready var hint_label: Label = $HUD/HintLabel
@onready var door_status_left: Label = $HUD/DoorStatusLeft
@onready var door_status_right: Label = $HUD/DoorStatusRight

# Tablet
@onready var tablet_panel: Control = $TabletLayer/TabletPanel
@onready var cam_display: TextureRect = $TabletLayer/TabletPanel/CamDisplay
@onready var cam_name_label: Label = $TabletLayer/TabletPanel/CamNameLabel
@onready var cam_anim_overlay: TextureRect = $TabletLayer/TabletPanel/CamAnimOverlay

# Screamer
@onready var screamer_sprite: TextureRect = $ScreamerLayer/ScreamerSprite

# Overlays
@onready var game_over_panel: Control = $OverlayLayer/GameOverPanel
@onready var victory_panel: Control = $OverlayLayer/VictoryPanel
@onready var pause_panel: Control = $OverlayLayer/PausePanel

# AI
@onready var threat_a: Node = $ThreatA
@onready var threat_b: Node = $ThreatB

var _room_graph: RoomGraph
var _night_config: NightConfig
var _tablet_open: bool = false
var _tablet_animating: bool = false

# Camera textures preloaded
var _cam_textures: Dictionary = {}

# Animatronic textures
var _anim_cam_textures: Dictionary = {}  # anim_id → Texture2D
var _screamer_textures: Dictionary = {}  # anim_id → Texture2D

# Tracking what room each animatronic is in
var _anim_rooms: Dictionary = {}  # anim_id → room_id

# Camera flicker timer for creepy effects
var _cam_flicker_timer: float = 0.0
var _cam_flicker_visible: bool = true


func _ready() -> void:
	_night_config = NightConfig.new()
	_room_graph = RoomGraph.create_default()

	# Setup systems
	time_manager.config = _night_config
	power_manager.config = _night_config
	office.power_manager = power_manager

	# Preload textures
	_preload_cameras()
	_preload_animatronic_textures()

	# Setup AI
	_setup_ai()

	# Connect signals
	time_manager.hour_changed.connect(_on_hour_changed)
	time_manager.night_ended.connect(_on_night_ended)
	power_manager.power_changed.connect(_on_power_changed)
	power_manager.power_depleted.connect(_on_power_depleted)

	if threat_a.has_signal("moved"):
		threat_a.moved.connect(_on_animatronic_moved)
		threat_a.at_door.connect(_on_at_door)
		threat_a.attacking.connect(_on_attack)
	if threat_b.has_signal("moved"):
		threat_b.moved.connect(_on_animatronic_moved)
		threat_b.at_door.connect(_on_at_door)
		threat_b.attacking.connect(_on_attack)

	# Hide overlays
	tablet_panel.visible = false
	game_over_panel.visible = false
	victory_panel.visible = false
	pause_panel.visible = false
	screamer_sprite.visible = false

	# Show hints
	_show_hint("Мышь к краям — осмотр | Q/E — двери | A/D — свет (удерж.) | T — планшет")

	# Start
	GameManager.start_night()


func _process(delta: float) -> void:
	# Update door status indicators
	if office and door_status_left:
		var left_state := "ЗАКР" if office.left_door_closed else "ОТКР"
		door_status_left.text = "[Q] Лев.дверь: %s" % left_state
		if office.left_door_closed:
			door_status_left.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			door_status_left.remove_theme_color_override("font_color")

	if office and door_status_right:
		var right_state := "ЗАКР" if office.right_door_closed else "ОТКР"
		door_status_right.text = "[E] Прав.дверь: %s" % right_state
		if office.right_door_closed:
			door_status_right.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		else:
			door_status_right.remove_theme_color_override("font_color")

	# Camera flicker effect when animatronic is on camera
	if _tablet_open:
		_update_camera_overlay(delta)


func _preload_cameras() -> void:
	var cam_paths := {
		1: "res://assets/sprites/cameras/cam_01_reception.png",
		2: "res://assets/sprites/cameras/cam_02_archive.png",
		3: "res://assets/sprites/cameras/cam_03_workshop.png",
		4: "res://assets/sprites/cameras/cam_04_storage.png",
		5: "res://assets/sprites/cameras/cam_05_left_corridor.png",
		6: "res://assets/sprites/cameras/cam_06_right_corridor.png",
		7: "res://assets/sprites/cameras/cam_07_service.png",
	}
	for cam_id in cam_paths:
		var tex := load(cam_paths[cam_id])
		if tex:
			_cam_textures[cam_id] = tex


func _preload_animatronic_textures() -> void:
	# Camera appearance textures (corridor sprites work for camera feeds too)
	var threat_a_tex := load("res://assets/sprites/animatronics/threat_a_corridor.png")
	var threat_b_tex := load("res://assets/sprites/animatronics/threat_b_corridor.png")
	if threat_a_tex:
		_anim_cam_textures["threat_a"] = threat_a_tex
	if threat_b_tex:
		_anim_cam_textures["threat_b"] = threat_b_tex

	# Screamer textures
	var screamer_a := load("res://assets/sprites/animatronics/screamer_a.png")
	var screamer_b := load("res://assets/sprites/animatronics/screamer_b.png")
	if screamer_a:
		_screamer_textures["threat_a"] = screamer_a
	if screamer_b:
		_screamer_textures["threat_b"] = screamer_b


func _setup_ai() -> void:
	if threat_a.has_method("setup"):
		threat_a.animatronic_id = "threat_a"
		threat_a.start_room = "service"
		threat_a.door_side = "left"
		threat_a.route = ["service", "reception", "archive", "left_corridor"]
		threat_a.setup(_room_graph, _night_config)
		_anim_rooms["threat_a"] = "service"

	if threat_b.has_method("setup"):
		threat_b.animatronic_id = "threat_b"
		threat_b.start_room = "service"
		threat_b.door_side = "right"
		threat_b.route = ["service", "workshop", "storage", "right_corridor"]
		threat_b.setup(_room_graph, _night_config)
		_anim_rooms["threat_b"] = "service"


func _unhandled_input(event: InputEvent) -> void:
	# Tablet toggle
	if event.is_action_pressed("ui_tablet"):
		_toggle_tablet()

	# Pause
	if event.is_action_pressed("ui_pause"):
		if GameManager.current_state == GameManager.State.PAUSED:
			_resume()
		elif GameManager.is_playing():
			_pause()


func _toggle_tablet() -> void:
	if _tablet_animating:
		return
	if _tablet_open:
		_close_tablet()
	elif GameManager.current_state == GameManager.State.PLAYING_OFFICE:
		_open_tablet()


func _open_tablet() -> void:
	_tablet_animating = true
	GameManager.open_tablet()
	power_manager.tablet_open = true

	tablet_panel.visible = true
	tablet_panel.modulate.a = 0.0

	_switch_camera(camera_system.current_camera)

	var open_tween := create_tween()
	open_tween.set_ease(Tween.EASE_OUT)
	open_tween.set_trans(Tween.TRANS_CUBIC)
	open_tween.tween_property(tablet_panel, "modulate:a", 1.0, 0.4)
	await open_tween.finished

	_tablet_open = true
	_tablet_animating = false
	GameManager.tablet_animation_done()


func _close_tablet() -> void:
	_tablet_animating = true
	GameManager.close_tablet()
	power_manager.tablet_open = false

	var close_tween := create_tween()
	close_tween.set_ease(Tween.EASE_IN)
	close_tween.set_trans(Tween.TRANS_CUBIC)
	close_tween.tween_property(tablet_panel, "modulate:a", 0.0, 0.3)
	await close_tween.finished

	tablet_panel.visible = false
	_tablet_open = false
	_tablet_animating = false
	GameManager.tablet_animation_done()


func _switch_camera(cam_id: int) -> void:
	camera_system.switch_camera(cam_id)
	if _cam_textures.has(cam_id):
		cam_display.texture = _cam_textures[cam_id]
	if cam_name_label:
		cam_name_label.text = camera_system.get_camera_name(cam_id)

	# Check if animatronic is in this room → show overlay
	_update_cam_anim_overlay()


func _update_cam_anim_overlay() -> void:
	var current_room: String = camera_system.get_current_room()
	var found_anim: String = ""

	for anim_id in _anim_rooms:
		if _anim_rooms[anim_id] == current_room:
			found_anim = anim_id
			break

	if found_anim != "" and _anim_cam_textures.has(found_anim):
		cam_anim_overlay.texture = _anim_cam_textures[found_anim]
		cam_anim_overlay.visible = true
		_cam_flicker_timer = 0.0
	else:
		cam_anim_overlay.visible = false


func _update_camera_overlay(delta: float) -> void:
	if not cam_anim_overlay.visible:
		return

	# Random flicker effect — makes animatronic appear/disappear on camera
	_cam_flicker_timer += delta
	if _cam_flicker_timer > randf_range(0.3, 1.5):
		_cam_flicker_timer = 0.0
		_cam_flicker_visible = not _cam_flicker_visible
		cam_anim_overlay.modulate.a = 0.85 if _cam_flicker_visible else 0.0

	# Random slight position jitter
	if cam_anim_overlay.visible:
		cam_anim_overlay.position.x = randf_range(-2.0, 2.0)
		cam_anim_overlay.position.y = randf_range(-1.0, 1.0)


# --- Signal handlers ---

func _on_hour_changed(hour: int) -> void:
	time_label.text = "%d:00" % hour
	if hour >= 5:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))


func _on_night_ended() -> void:
	victory_panel.visible = true
	_show_hint("СМЕНА ОКОНЧЕНА! 6:00")


func _on_power_changed(current: float, max_power: float) -> void:
	var pct := (current / max_power) * 100.0
	power_label.text = "%d%%" % int(pct)
	power_bar.value = pct

	if pct < 15.0:
		power_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	elif pct < 30.0:
		power_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	else:
		power_label.remove_theme_color_override("font_color")


func _on_power_depleted() -> void:
	_show_hint("ЭНЕРГИЯ КОНЧИЛАСЬ!")
	if _tablet_open:
		_close_tablet()


func _on_animatronic_moved(_anim_id: String, _room_id: String) -> void:
	# Track position
	_anim_rooms[_anim_id] = _room_id

	# Update camera overlay if tablet is open
	if _tablet_open:
		_update_cam_anim_overlay()

	# Show hint when animatronic is near
	if _room_id in ["left_corridor", "right_corridor"]:
		var side := "ЛЕВОЙ" if _room_id == "left_corridor" else "ПРАВОЙ"
		_show_hint("⚠ Движение у %s двери!" % side)


func _on_at_door(_anim_id: String, _door_side: String) -> void:
	var side_text := "ЛЕВОЙ" if _door_side == "left" else "ПРАВОЙ"
	_show_hint("⚠⚠ УГРОЗА У %s ДВЕРИ! Закрой дверь!" % side_text)


func _on_attack(anim_id: String) -> void:
	_show_screamer(anim_id)


func _show_screamer(anim_id: String) -> void:
	# Show screamer fullscreen
	if _screamer_textures.has(anim_id):
		screamer_sprite.texture = _screamer_textures[anim_id]
	else:
		# Use first available
		for key in _screamer_textures:
			screamer_sprite.texture = _screamer_textures[key]
			break

	screamer_sprite.visible = true

	if _tablet_open:
		tablet_panel.visible = false
		_tablet_open = false

	# Flash effect
	screamer_sprite.modulate = Color(1, 1, 1, 1)
	var flash_tween := create_tween()
	flash_tween.tween_property(screamer_sprite, "modulate", Color(2, 0.5, 0.5, 1), 0.1)
	flash_tween.tween_property(screamer_sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	flash_tween.tween_property(screamer_sprite, "modulate", Color(2, 0.5, 0.5, 1), 0.1)
	flash_tween.tween_interval(0.8)
	flash_tween.tween_callback(_show_game_over)


func _show_game_over() -> void:
	screamer_sprite.visible = false
	game_over_panel.visible = true


func _pause() -> void:
	GameManager.pause_game()
	pause_panel.visible = true


func _resume() -> void:
	GameManager.resume_game()
	pause_panel.visible = false


func _show_hint(text: String) -> void:
	if hint_label:
		hint_label.text = text
		hint_label.modulate.a = 1.0
		var tw := create_tween()
		tw.tween_interval(5.0)
		tw.tween_property(hint_label, "modulate:a", 0.0, 1.0)


# --- Button callbacks ---

func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	GameManager.return_to_menu()


func _on_resume_pressed() -> void:
	_resume()


func is_animatronic_at_door(side: String) -> bool:
	var corridor := "left_corridor" if side == "left" else "right_corridor"
	for anim_id in _anim_rooms:
		if _anim_rooms[anim_id] == corridor:
			return true
	return false
