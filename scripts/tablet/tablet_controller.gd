## TabletController — открытие/закрытие планшета с камерами
extends CanvasLayer

signal tablet_opened
signal tablet_closed

@export var open_duration: float = 0.5
@export var close_duration: float = 0.4
@export var tablet_panel: Control  # Main tablet UI panel

var is_open: bool = false
var _animating: bool = false


func _ready() -> void:
	visible = false
	if tablet_panel:
		tablet_panel.modulate.a = 0.0
	GameManager.state_changed.connect(_on_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_tablet") and not _animating:
		if is_open:
			close_tablet()
		elif GameManager.current_state == GameManager.State.PLAYING_OFFICE:
			open_tablet()


func open_tablet() -> void:
	if _animating or is_open:
		return
	_animating = true
	GameManager.open_tablet()

	visible = true
	if tablet_panel:
		tablet_panel.modulate.a = 0.0
		var anim_tween := create_tween()
		anim_tween.set_ease(Tween.EASE_OUT)
		anim_tween.set_trans(Tween.TRANS_CUBIC)
		anim_tween.tween_property(tablet_panel, "modulate:a", 1.0, open_duration)
		anim_tween.tween_property(tablet_panel, "position:y", 0.0, open_duration).from(60.0)
		await anim_tween.finished

	is_open = true
	_animating = false
	GameManager.tablet_animation_done()
	tablet_opened.emit()


func close_tablet() -> void:
	if _animating or not is_open:
		return
	_animating = true
	GameManager.close_tablet()

	if tablet_panel:
		var anim_tween := create_tween()
		anim_tween.set_ease(Tween.EASE_IN)
		anim_tween.set_trans(Tween.TRANS_CUBIC)
		anim_tween.tween_property(tablet_panel, "modulate:a", 0.0, close_duration)
		anim_tween.tween_property(tablet_panel, "position:y", 60.0, close_duration)
		await anim_tween.finished

	visible = false
	is_open = false
	_animating = false
	GameManager.tablet_animation_done()
	tablet_closed.emit()


func force_close() -> void:
	visible = false
	is_open = false
	_animating = false
	if tablet_panel:
		tablet_panel.modulate.a = 0.0


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"Dead", &"Win", &"PowerOut":
			if is_open:
				force_close()
		&"MainMenu":
			force_close()
