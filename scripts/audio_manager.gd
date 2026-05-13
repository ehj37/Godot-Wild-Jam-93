extends Node


func play_effect(audio_stream: AudioStreamOggVorbis) -> void:
	_play(audio_stream, "SoundEffects")


func play_music(audio_stream: AudioStreamOggVorbis) -> void:
	_play(audio_stream, "Music")


func _play(audio_stream: AudioStreamOggVorbis, bus_name: String) -> void:
	var audio_stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_stream_player.stream = audio_stream
	audio_stream_player.bus = bus_name
	add_child(audio_stream_player)
	audio_stream_player.play()
	audio_stream_player.finished.connect(func() -> void: audio_stream_player.queue_free())
