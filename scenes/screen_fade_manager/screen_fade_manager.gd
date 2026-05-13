extends CanvasLayer

signal fade_completed

const FADE_OUT_TIME: float = 0.75
const FADE_IN_TIME: float = 1.0

@onready var color_rect: ColorRect = $ColorRect


func fade_out() -> void:
	var alpha_tween: Tween = color_rect.create_tween()
	alpha_tween.tween_property(color_rect, "color:a", 1.0, FADE_OUT_TIME)
	await alpha_tween.finished

	fade_completed.emit()


func fade_in() -> void:
	var alpha_tween: Tween = color_rect.create_tween()
	alpha_tween.tween_property(color_rect, "color:a", 0.0, FADE_IN_TIME)
	await alpha_tween.finished

	fade_completed.emit()


func _ready() -> void:
	color_rect.color.a = 0.0
