class_name TurnDialog

extends PanelContainer

var text: String:
	set(new_value):
		text = new_value
		var label: Label = $MarginContainer/Label
		label.text = new_value
