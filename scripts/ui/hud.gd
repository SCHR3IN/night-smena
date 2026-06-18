## HUD — отображение времени, энергии и игровых подсказок
extends CanvasLayer

@onready var time_label: Label = $TimeLabel
@onready var power_label: Label = $PowerLabel
@onready var power_bar: ProgressBar = $PowerBar


func _ready() -> void:
	GameManager.state_changed.connect(_on_state_changed)


func update_time(time_str: String) -> void:
	if time_label:
		time_label.text = time_str


func update_power(current: float, max_power: float) -> void:
	var pct := (current / max_power) * 100.0
	if power_label:
		power_label.text = "%d%%" % int(pct)
	if power_bar:
		power_bar.value = pct


func _on_state_changed(new_state: StringName) -> void:
	match new_state:
		&"PlayingOffice", &"TabletOpen", &"TabletOpening", &"TabletClosing":
			visible = true
		&"PowerOut":
			visible = true
			if power_label:
				power_label.text = "0%"
				power_label.add_theme_color_override("font_color", Color.RED)
		&"Dead", &"Win", &"MainMenu", &"Paused":
			pass  # HUD stays visible behind overlays
