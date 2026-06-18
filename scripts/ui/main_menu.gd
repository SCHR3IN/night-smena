## MainMenu — главное меню игры
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var settings_button: Button = $VBoxContainer/SettingsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var title_label: Label = $TitleLabel
@onready var subtitle_label: Label = $SubtitleLabel


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

	# Animate title
	if title_label:
		var tween := create_tween().set_loops()
		tween.tween_property(title_label, "modulate:a", 0.7, 2.0)
		tween.tween_property(title_label, "modulate:a", 1.0, 2.0)


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _on_settings() -> void:
	# TODO: Open settings overlay
	pass


func _on_quit() -> void:
	get_tree().quit()
