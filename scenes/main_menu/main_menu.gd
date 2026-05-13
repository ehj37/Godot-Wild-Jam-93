extends Node2D

@onready var _main_buttons_container: VBoxContainer = $PanelContainer/MainButtonsContainer
@onready var _start_button: Button = $PanelContainer/MainButtonsContainer/StartButton
@onready var _settings_button: Button = $PanelContainer/MainButtonsContainer/SettingsButton
@onready var _settings_container: VBoxContainer = $PanelContainer/SettingsContainer
@onready var _main_volume_slider: HSlider = get_node(
	"PanelContainer/SettingsContainer/MainAudioContainer/MainVolumeSlider"
)
@onready var _sound_effect_volume_slider: HSlider = get_node(
	"PanelContainer/SettingsContainer/SoundEffectsContainer/SoundEffectVolumeSlider"
)
@onready var _music_volume_slider: HSlider = get_node(
	"PanelContainer/SettingsContainer/MusicContainer/MusicVolumeSlider"
)


func _ready() -> void:
	_main_buttons_container.show()
	_settings_container.hide()

	var master_bus_index: int = AudioServer.get_bus_index("Master")
	_main_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))

	var sound_effects_bus_index: int = AudioServer.get_bus_index("SoundEffects")
	_sound_effect_volume_slider.value = db_to_linear(
		AudioServer.get_bus_volume_db(sound_effects_bus_index)
	)

	var music_bus_index: int = AudioServer.get_bus_index("Music")
	_music_volume_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus_index))


func _on_start_button_pressed() -> void:
	_start_button.disabled = true
	_settings_button.disabled = true
	LevelManager.start_game()


func _on_settings_button_pressed() -> void:
	_main_buttons_container.hide()
	_settings_container.show()


func _on_main_volume_slider_value_changed(value: float) -> void:
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(master_bus_index, value)


func _on_sound_effect_volume_slider_value_changed(value: float) -> void:
	var sound_effects_bus_index: int = AudioServer.get_bus_index("SoundEffects")
	AudioServer.set_bus_volume_linear(sound_effects_bus_index, value)


func _on_music_volume_slider_value_changed(value: float) -> void:
	var music_bus_index: int = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(music_bus_index, value)


func _on_back_button_pressed() -> void:
	_main_buttons_container.show()
	_settings_container.hide()
