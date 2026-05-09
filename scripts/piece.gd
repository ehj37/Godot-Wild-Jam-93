class_name Piece

extends Node2D

@export var is_player: bool = false


func _can_reach(_coordinate: Vector2i) -> bool:
	return false
