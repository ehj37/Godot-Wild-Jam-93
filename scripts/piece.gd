@tool

class_name Piece

extends Node2D

@export var is_player: bool = false:
	set(new_value):
		is_player = new_value
		_set_palette()


func _can_reach(_coordinate: Vector2i) -> bool:
	return false


func _ready() -> void:
	_set_palette()


func _set_palette() -> void:
	var sprite: Sprite2D = $Sprite2D
	var shader_material: ShaderMaterial = sprite.material
	shader_material.set_shader_parameter("is_enabled", !is_player)
