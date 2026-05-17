extends Control

const FADE_IN_TIME: float = 2.5
const POST_FADE_TIME: float = 1.5

@onready var _label_container: VBoxContainer = $CenterContainer/LabelContainer


func _ready() -> void:
	var labels: Array = _label_container.get_children()
	for label: Label in labels:
		label.modulate.a = 0.0

	await get_tree().create_timer(1.0).timeout

	for label: Label in labels:
		var alpha_tween: Tween = get_tree().create_tween()
		alpha_tween.tween_property(label, "modulate:a", 1.0, FADE_IN_TIME)
		await alpha_tween.finished

		await get_tree().create_timer(POST_FADE_TIME).timeout
