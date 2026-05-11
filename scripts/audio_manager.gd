extends Node


func play(audio_stream: AudioStreamOggVorbis) -> void:
	var audio_stream_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_stream_player.stream = audio_stream
	add_child(audio_stream_player)
	audio_stream_player.play()
	audio_stream_player.finished.connect(func() -> void: audio_stream_player.queue_free())
