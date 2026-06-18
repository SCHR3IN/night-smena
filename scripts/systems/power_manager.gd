## PowerManager — система энергии
extends Node

signal power_changed(current: float, max_power: float)
signal power_depleted

var current_power: float = 100.0
var _active: bool = false

# External states tracked for drain calculation
var left_door_closed: bool = false
var right_door_closed: bool = false
var left_light_on: bool = false
var right_light_on: bool = false
var tablet_open: bool = false

@export var config: NightConfig


func _ready() -> void:
	if not config:
		config = NightConfig.new()
	GameManager.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if not _active or current_power <= 0.0:
		return

	var drain := config.base_drain_rate
	if left_door_closed:
		drain += config.door_drain_rate
	if right_door_closed:
		drain += config.door_drain_rate
	if left_light_on:
		drain += config.light_drain_rate
	if right_light_on:
		drain += config.light_drain_rate
	if tablet_open:
		drain += config.tablet_drain_rate

	current_power = maxf(current_power - drain * delta, 0.0)
	power_changed.emit(current_power, config.max_power)

	if current_power <= 0.0:
		_active = false
		power_depleted.emit()
		GameManager.trigger_power_out()


func start_night() -> void:
	current_power = config.max_power
	left_door_closed = false
	right_door_closed = false
	left_light_on = false
	right_light_on = false
	tablet_open = false
	_active = true
	power_changed.emit(current_power, config.max_power)


func get_percentage() -> float:
	return (current_power / config.max_power) * 100.0


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice":
			if current_power == config.max_power:
				start_night()
			_active = true
			tablet_open = false
		&"TabletOpen", &"TabletOpening":
			tablet_open = true
		&"TabletClosing":
			tablet_open = false
		&"Paused", &"Dead", &"Win", &"MainMenu":
			_active = false
		&"PowerOut":
			_active = false
