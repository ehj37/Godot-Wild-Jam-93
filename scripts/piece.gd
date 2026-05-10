@tool

class_name Piece

extends Node2D

@export var is_player: bool = false:
	set(new_value):
		is_player = new_value
		_set_palette()

@export var is_target: bool = false:
	set(new_value):
		is_target = new_value
		_set_target_particles()


func is_valid_move(_from: Vector2i, _to: Vector2i, _pieces: Dictionary) -> bool:
	return false


func _ready() -> void:
	_set_palette()
	_set_target_particles()


func _set_palette() -> void:
	var sprite: Sprite2D = $Sprite2D
	var shader_material: ShaderMaterial = sprite.material
	shader_material.set_shader_parameter("is_enabled", !is_player)


func _set_target_particles() -> void:
	var target_fire_back: TargetFire = $TargetFireBack
	var target_fire_front: TargetFire = $TargetFireFront
	target_fire_back.set_emitting(is_target)
	target_fire_front.set_emitting(is_target)
