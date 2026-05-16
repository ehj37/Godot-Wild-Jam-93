class_name Bounty

extends PanelContainer

@onready
var _mugshot_container: BoxContainer = $MarginContainer/VBoxContainer/HBoxContainer/MugshotContainer
@onready var _eliminated_icon: Sprite2D = get_node(
	"MarginContainer/VBoxContainer/HBoxContainer/MugshotContainer/EliminatedIcon"
)
@onready var _name_label: Label = get_node(
	"MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/NameContainer/NameLabel"
)
@onready var _crime_label: Label = get_node(
	"MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/CrimeContainer/CrimeLabel"
)
@onready var _last_seen_label: Label = get_node(
	"MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LastSeenContainer/LastSeenLabel"
)


func set_icon(sprite: Sprite2D) -> void:
	_mugshot_container.add_child(sprite)
	# Index of 1: Between color rect (background) and jail bars
	_mugshot_container.move_child(sprite, 1)


func set_piece_name(piece_name: String) -> void:
	_name_label.text = piece_name


func set_crime(description: String) -> void:
	_crime_label.text = description


func set_last_seen(last_seen_description: String) -> void:
	_last_seen_label.text = last_seen_description


func mark_as_eliminated() -> void:
	_eliminated_icon.visible = true
