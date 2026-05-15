class_name UpgradedButton

extends Button

@onready var _button_hover_audio_stream: AudioStreamOggVorbis = preload(
	"res://audio_streams/button_hover.ogg"
)
@onready var _button_unhover_audio_stream: AudioStreamOggVorbis = preload(
	"res://audio_streams/button_unhover.ogg"
)


func _on_mouse_entered() -> void:
	AudioManager.play_effect(_button_hover_audio_stream)


func _on_mouse_exited() -> void:
	if !disabled:
		AudioManager.play_effect(_button_unhover_audio_stream)
