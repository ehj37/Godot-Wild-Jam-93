class_name TurnDialog

extends PanelContainer

@export var is_player_turn: bool:
	set(new_value):
		is_player_turn = new_value
		_update_entity_label()


func _ready() -> void:
	_update_entity_label()


func _update_entity_label() -> void:
	var entity_label: Label = $LabelContainer/EntityLabel
	if is_player_turn:
		entity_label.text = "PLAYER"
	else:
		entity_label.text = "ENEMY"
