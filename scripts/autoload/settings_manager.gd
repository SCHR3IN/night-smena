## SettingsManager — сохранение и загрузка пользовательских настроек
## Autoload: персистентные настройки между запусками
extends Node

const SETTINGS_PATH := "user://settings.cfg"

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0
var brightness: float = 1.0
var fullscreen: bool = false
var mouse_sensitivity: float = 1.0
var animatronic_speed: int = 1  # 0=slow, 1=normal, 2=fast, 3=nightmare
var subtitles: bool = false
var reduced_screamer: bool = false

const SPEED_MULTIPLIERS: Array[float] = [0.70, 1.00, 1.35, 1.65]
const SPEED_NAMES: Array[String] = ["Медленно", "Нормально", "Быстро", "Кошмар"]

signal settings_changed


func _ready() -> void:
	load_settings()
	_apply_audio_settings()


func get_speed_multiplier() -> float:
	return SPEED_MULTIPLIERS[clampi(animatronic_speed, 0, 3)]


func get_speed_name() -> String:
	return SPEED_NAMES[clampi(animatronic_speed, 0, 3)]


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("display", "brightness", brightness)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("gameplay", "animatronic_speed", animatronic_speed)
	config.set_value("accessibility", "subtitles", subtitles)
	config.set_value("accessibility", "reduced_screamer", reduced_screamer)
	config.save(SETTINGS_PATH)
	_apply_audio_settings()
	settings_changed.emit()


func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	master_volume = config.get_value("audio", "master_volume", 1.0)
	music_volume = config.get_value("audio", "music_volume", 0.7)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	brightness = config.get_value("display", "brightness", 1.0)
	fullscreen = config.get_value("display", "fullscreen", false)
	mouse_sensitivity = config.get_value("input", "mouse_sensitivity", 1.0)
	animatronic_speed = config.get_value("gameplay", "animatronic_speed", 1)
	subtitles = config.get_value("accessibility", "subtitles", false)
	reduced_screamer = config.get_value("accessibility", "reduced_screamer", false)


func _apply_audio_settings() -> void:
	if AudioServer.bus_count > 0:
		AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))
