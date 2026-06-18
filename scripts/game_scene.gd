## GameScene — основная игровая сцена
## Собирает все системы: офис, планшет, HUD, ИИ, время, энергия
extends Node2D

@onready var office: Node2D = $Office
@onready var time_manager: Node = $TimeManager
@onready var power_manager: Node = $PowerManager
@onready var camera_system: Node = $CameraSystem
@onready var hud: CanvasLayer = $HUD
@onready var tablet: CanvasLayer = $Tablet
@onready var threat_a: Node = $ThreatA
@onready var threat_b: Node = $ThreatB

var _room_graph: RoomGraph
var _night_config: NightConfig


func _ready() -> void:
	_night_config = NightConfig.new()
	_room_graph = RoomGraph.create_default()

	# Setup systems
	time_manager.config = _night_config
	power_manager.config = _night_config

	# Setup AI
	threat_a.animatronic_id = "threat_a"
	threat_a.start_room = "service"
	threat_a.door_side = "left"
	threat_a.route = ["service", "reception", "archive", "left_corridor"]
	threat_a.setup(_room_graph, _night_config)

	threat_b.animatronic_id = "threat_b"
	threat_b.start_room = "service"
	threat_b.door_side = "right"
	threat_b.route = ["service", "workshop", "storage", "right_corridor"]
	threat_b.setup(_room_graph, _night_config)

	# Connect signals
	time_manager.hour_changed.connect(_on_hour_changed)
	power_manager.power_changed.connect(_on_power_changed)
	threat_a.moved.connect(_on_animatronic_moved)
	threat_b.moved.connect(_on_animatronic_moved)
	threat_a.at_door.connect(_on_animatronic_at_door)
	threat_b.at_door.connect(_on_animatronic_at_door)

	# Start the night
	GameManager.start_night()


func _on_hour_changed(hour: int) -> void:
	hud.update_time("%d:00" % hour)


func _on_power_changed(current: float, max_power: float) -> void:
	hud.update_power(current, max_power)


func _on_animatronic_moved(anim_id: String, room_id: String) -> void:
	# Update camera feed if watching that room
	pass  # Camera system handles display


func _on_animatronic_at_door(anim_id: String, door_side: String) -> void:
	# Play warning sound
	pass  # Audio manager handles


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		if GameManager.current_state == GameManager.State.PAUSED:
			GameManager.resume_game()
		elif GameManager.is_playing():
			GameManager.pause_game()

	# Door controls (keyboard)
	if event.is_action_pressed("ui_left_door") and GameManager.current_state == GameManager.State.PLAYING_OFFICE:
		var left_door := office.get_node_or_null("LeftDoor")
		if left_door:
			left_door.toggle()

	if event.is_action_pressed("ui_right_door") and GameManager.current_state == GameManager.State.PLAYING_OFFICE:
		var right_door := office.get_node_or_null("RightDoor")
		if right_door:
			right_door.toggle()
