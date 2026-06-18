## TimeManager — отсчёт игрового времени от 1:00 до 6:00
extends Node

signal hour_changed(hour: int)
signal night_ended

var current_hour: int = 1
var _elapsed: float = 0.0
var _running: bool = false

@export var config: NightConfig


func _ready() -> void:
	if not config:
		config = NightConfig.new()
	GameManager.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if not _running:
		return

	_elapsed += delta
	var new_hour: int = config.start_hour + int(_elapsed / config.seconds_per_hour)
	new_hour = mini(new_hour, config.end_hour)

	if new_hour != current_hour:
		current_hour = new_hour
		hour_changed.emit(current_hour)

		if current_hour >= config.end_hour:
			_running = false
			night_ended.emit()
			GameManager.trigger_win()


func start_night() -> void:
	current_hour = config.start_hour
	_elapsed = 0.0
	_running = true
	hour_changed.emit(current_hour)


func stop() -> void:
	_running = false


func get_time_string() -> String:
	return "%d:00" % current_hour


func get_progress() -> float:
	var total := float(config.end_hour - config.start_hour) * config.seconds_per_hour
	return clampf(_elapsed / total, 0.0, 1.0)


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice":
			if current_hour == config.start_hour and _elapsed == 0.0:
				start_night()
			_running = true
		&"TabletOpening", &"TabletOpen", &"TabletClosing":
			_running = true  # Время идёт при открытом планшете
		&"PowerOut":
			_running = true  # Время идёт даже при отключении
		&"Paused", &"Dead", &"Win", &"MainMenu":
			_running = false
