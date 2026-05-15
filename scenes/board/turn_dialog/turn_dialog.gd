class_name TurnDialog

extends PanelContainer

@export var is_player_turn: bool:
	set(new_value):
		is_player_turn = new_value
		_update_label()


func _ready() -> void:
	_update_label()


func _update_label() -> void:
	var label: Label = $MarginContainer/Label
	if is_player_turn:
		label.text = "LEARN EM A LESSON"
	else:
		label.text = "BANDITS ARE ABOUT"
