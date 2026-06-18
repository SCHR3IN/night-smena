## GameManager — центральная машина состояний игры
## Autoload: управляет переходами между состояниями, запуском и перезапуском смены
extends Node

signal state_changed(new_state: StringName)

enum State {
	MAIN_MENU,
	PLAYING_OFFICE,
	TABLET_OPENING,
	TABLET_OPEN,
	TABLET_CLOSING,
	PAUSED,
	POWER_OUT,
	DEAD,
	WIN
}

const STATE_NAMES: Dictionary = {
	State.MAIN_MENU: &"MainMenu",
	State.PLAYING_OFFICE: &"PlayingOffice",
	State.TABLET_OPENING: &"TabletOpening",
	State.TABLET_OPEN: &"TabletOpen",
	State.TABLET_CLOSING: &"TabletClosing",
	State.PAUSED: &"Paused",
	State.POWER_OUT: &"PowerOut",
	State.DEAD: &"Dead",
	State.WIN: &"Win",
}

var current_state: State = State.MAIN_MENU
var _previous_state: State = State.MAIN_MENU

# Valid transitions map
var _valid_transitions: Dictionary = {
	State.MAIN_MENU: [State.PLAYING_OFFICE],
	State.PLAYING_OFFICE: [
		State.TABLET_OPENING, State.PAUSED,
		State.DEAD, State.POWER_OUT, State.WIN
	],
	State.TABLET_OPENING: [State.TABLET_OPEN, State.DEAD],
	State.TABLET_OPEN: [
		State.TABLET_CLOSING, State.PAUSED,
		State.DEAD, State.POWER_OUT, State.WIN
	],
	State.TABLET_CLOSING: [State.PLAYING_OFFICE, State.DEAD],
	State.PAUSED: [State.PLAYING_OFFICE, State.TABLET_OPEN, State.MAIN_MENU],
	State.POWER_OUT: [State.DEAD],
	State.DEAD: [State.PLAYING_OFFICE, State.MAIN_MENU],
	State.WIN: [State.MAIN_MENU, State.PLAYING_OFFICE],
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func change_state(new_state: State) -> bool:
	if new_state == current_state:
		return false

	if not new_state in _valid_transitions.get(current_state, []):
		push_warning("GameManager: Invalid transition %s → %s" % [
			STATE_NAMES[current_state], STATE_NAMES[new_state]
		])
		return false

	_previous_state = current_state
	current_state = new_state
	state_changed.emit(STATE_NAMES[new_state])

	match new_state:
		State.PAUSED:
			get_tree().paused = true
		State.PLAYING_OFFICE, State.TABLET_OPEN:
			get_tree().paused = false

	return true


func start_night() -> void:
	change_state(State.PLAYING_OFFICE)


func open_tablet() -> void:
	change_state(State.TABLET_OPENING)


func tablet_animation_done() -> void:
	if current_state == State.TABLET_OPENING:
		change_state(State.TABLET_OPEN)
	elif current_state == State.TABLET_CLOSING:
		change_state(State.PLAYING_OFFICE)


func close_tablet() -> void:
	change_state(State.TABLET_CLOSING)


func pause_game() -> void:
	if current_state in [State.PLAYING_OFFICE, State.TABLET_OPEN]:
		change_state(State.PAUSED)


func resume_game() -> void:
	if current_state == State.PAUSED:
		change_state(_previous_state)


func trigger_death() -> void:
	change_state(State.DEAD)


func trigger_power_out() -> void:
	change_state(State.POWER_OUT)


func trigger_win() -> void:
	change_state(State.WIN)


func retry() -> void:
	get_tree().paused = false
	change_state(State.PLAYING_OFFICE)


func return_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
	current_state = State.MAIN_MENU
	state_changed.emit(STATE_NAMES[State.MAIN_MENU])


func is_playing() -> bool:
	return current_state in [
		State.PLAYING_OFFICE, State.TABLET_OPENING,
		State.TABLET_OPEN, State.TABLET_CLOSING
	]
