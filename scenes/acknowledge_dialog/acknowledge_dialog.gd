@tool

class_name AcknowledgeDialog

extends PanelContainer

signal acknowledged

@export var body_text: String:
	set(new_value):
		body_text = new_value
		var label: Label = $MarginContainer/VBoxContainer/Label
		label.text = new_value
		
@export var button_text: String:
	set(new_value):
		button_text = new_value
		var button: Button = $MarginContainer/VBoxContainer/Button
		button.text = new_value


func _on_button_pressed() -> void:
	hide()
	acknowledged.emit()
