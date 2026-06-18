## AnimatronicAI — ИИ одного аниматроника
## Перемещение по графу комнат, атака, отступление
extends Node

signal moved(animatronic_id: String, room_id: String)
signal at_door(animatronic_id: String, door_side: String)
signal attacking(animatronic_id: String)
signal retreated(animatronic_id: String, room_id: String)

@export var animatronic_id: String = "threat_a"
@export var start_room: String = "service"
@export var door_side: String = "left"  # Which door this threat targets

## Route override: if set, follows these rooms in order
@export var route: Array[String] = []

var current_room: String = "service"
var _graph: RoomGraph
var _check_timer: float = 0.0
var _attack_timer: float = -1.0
var _retreat_timer: float = -1.0
var _active: bool = false
var _at_door: bool = false
var _config: NightConfig

# Route tracking
var _route_index: int = 0


func setup(graph: RoomGraph, config: NightConfig) -> void:
	_graph = graph
	_config = config
	current_room = start_room
	_route_index = 0
	_at_door = false
	_attack_timer = -1.0
	_retreat_timer = -1.0
	_check_timer = 0.0


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if not _active or not _graph:
		return

	var speed_mult := SettingsManager.get_speed_multiplier()

	# Handle attack at door
	if _attack_timer >= 0.0:
		_attack_timer -= delta * speed_mult
		if _attack_timer <= 0.0:
			_try_attack()
		return

	# Handle retreat from closed door
	if _retreat_timer >= 0.0:
		_retreat_timer -= delta * speed_mult
		if _retreat_timer <= 0.0:
			_do_retreat()
		return

	# Movement check timer
	_check_timer -= delta * speed_mult
	if _check_timer <= 0.0:
		_check_timer = _config.check_interval_base / speed_mult
		_try_move()


func _try_move() -> void:
	var speed_mult := SettingsManager.get_speed_multiplier()
	var move_chance := _config.move_probability_base * speed_mult

	if randf() > move_chance:
		return

	# Follow route if defined
	if route.size() > 0:
		if _route_index < route.size():
			var next_room := route[_route_index]
			_move_to(next_room)
			_route_index += 1
		return

	# Otherwise, move towards office
	var neighbors := _graph.get_neighbors(current_room)
	if neighbors.is_empty():
		return

	# Prefer moving towards office
	var next: String = neighbors[randi() % neighbors.size()]
	_move_to(next)


func _move_to(room_id: String) -> void:
	current_room = room_id
	moved.emit(animatronic_id, room_id)

	# Check if at door
	var room_node := _graph.get_room(room_id)
	if room_id == "left_corridor" and door_side == "left":
		_at_door = true
		at_door.emit(animatronic_id, door_side)
		_attack_timer = _config.attack_delay
	elif room_id == "right_corridor" and door_side == "right":
		_at_door = true
		at_door.emit(animatronic_id, door_side)
		_attack_timer = _config.attack_delay


func _try_attack() -> void:
	# Check if door is closed
	var power_mgr := _get_power_manager()
	if not power_mgr:
		return

	var door_closed := false
	if door_side == "left":
		door_closed = power_mgr.left_door_closed
	else:
		door_closed = power_mgr.right_door_closed

	if door_closed:
		# Door is closed — start retreat timer
		_retreat_timer = _config.retreat_delay
		_attack_timer = -1.0
	else:
		# Door is open — ATTACK!
		attacking.emit(animatronic_id)
		GameManager.trigger_death()


func _do_retreat() -> void:
	_at_door = false
	_retreat_timer = -1.0

	# Move back 1-2 rooms
	var retreat_rooms: int = randi_range(1, 2)
	for i in retreat_rooms:
		var neighbors := _graph.get_neighbors(current_room)
		# Filter: only go away from office
		var retreat_options: Array = []
		for n in neighbors:
			var room := _graph.get_room(n)
			if room and not room.is_office:
				retreat_options.append(n)

		if retreat_options.is_empty():
			break
		current_room = retreat_options[randi() % retreat_options.size()]

	_route_index = maxi(_route_index - retreat_rooms, 0)
	retreated.emit(animatronic_id, current_room)
	moved.emit(animatronic_id, current_room)


func is_at_door() -> bool:
	return _at_door


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice", &"TabletOpen", &"TabletOpening", &"TabletClosing":
			_active = true
		&"Paused", &"Dead", &"MainMenu":
			_active = false
		&"Win":
			_active = false
		&"PowerOut":
			_active = true


func _get_power_manager() -> Node:
	return get_tree().current_scene.get_node_or_null("PowerManager")
