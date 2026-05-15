class_name Happenin

extends PanelContainer

@onready var _label: Label = $MarginContainer/Label


func set_text(text: String) -> void:
	_label.text = text


func set_text_alpha(a: float) -> void:
	_label.add_theme_color_override("font_color", Color(Color.WHITE, a))
