extends Node


func play_effect(audio_stream: AudioStreamOggVorbis) -> void:
	_play(audio_stream, "SoundEffects")


func play_music(audio_stream: AudioStreamOggVorbis, fade_in_time: float) -> void:
	_play(audio_stream, "Music", fade_in_time)


func _play(audio_stream: AudioStreamOggVorbis, bus_name: String, fade_in_time: float = 0.0) -> void:
	var audio_stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_stream_player.stream = audio_stream
	audio_stream_player.bus = bus_name
	add_child(audio_stream_player)
	audio_stream_player.play()
	audio_stream_player.process_mode = Node.PROCESS_MODE_ALWAYS
	if fade_in_time > 0:
		audio_stream_player.volume_linear = 0.0
		var volume_tween: Tween = audio_stream_player.create_tween()
		volume_tween.tween_property(audio_stream_player, "volume_linear", 1.0, fade_in_time)

	audio_stream_player.finished.connect(func() -> void: audio_stream_player.queue_free())
