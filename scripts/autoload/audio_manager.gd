## AudioManager — управление звуком и музыкой
## Autoload: проигрывание SFX, фоновой музыки и эмбиент-слоёв
extends Node

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer

const MAX_SFX_CHANNELS := 8


func _ready() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = -6.0
	add_child(_music_player)

	# Create ambient player
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Music"
	_ambient_player.volume_db = -10.0
	add_child(_ambient_player)

	# Create SFX pool
	for i in MAX_SFX_CHANNELS:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)


func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> void:
	if not stream:
		return
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = volume_db
			player.play()
			return
	# All channels busy — steal the first one
	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].play()


func play_music(stream: AudioStream, fade_in: float = 1.0) -> void:
	if not stream:
		return
	if _music_player.playing:
		var audio_tween := create_tween()
		audio_tween.tween_property(_music_player, "volume_db", -40.0, 0.5)
		await audio_tween.finished
	_music_player.stream = stream
	_music_player.volume_db = -40.0
	_music_player.play()
	var fade_tween := create_tween()
	fade_tween.tween_property(_music_player, "volume_db", -6.0, fade_in)


func stop_music(fade_out: float = 1.0) -> void:
	if not _music_player.playing:
		return
	var audio_tween := create_tween()
	audio_tween.tween_property(_music_player, "volume_db", -40.0, fade_out)
	await audio_tween.finished
	_music_player.stop()


func play_ambient(stream: AudioStream) -> void:
	if not stream:
		return
	_ambient_player.stream = stream
	_ambient_player.play()


func stop_ambient() -> void:
	_ambient_player.stop()


func stop_all() -> void:
	_music_player.stop()
	_ambient_player.stop()
	for player in _sfx_players:
		player.stop()
