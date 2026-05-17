@tool

class_name ModifierFire

extends Node2D

enum Modifier { TARGET, VIP }

const MODIFIER_TO_LARGE_COLOR: Dictionary = {
	Modifier.TARGET: Color("ff0000"), Modifier.VIP: Color("00ff00")
}

const MODIFIER_TO_SMALL_COLOR: Dictionary = {
	Modifier.TARGET: Color("ffbe00"), Modifier.VIP: Color("ffffff")
}

@export var modifier: Modifier:
	set(new_value):
		modifier = new_value
		_set_flame_color()


func set_emitting(value: bool) -> void:
	var particles_red: GPUParticles2D = $GPUParticlesLarge
	particles_red.emitting = value
	var particles_orange: GPUParticles2D = $GPUParticlesSmall
	particles_orange.emitting = value


func _ready() -> void:
	_set_flame_color()


func _set_flame_color() -> void:
	var particles_large: GPUParticles2D = $GPUParticlesLarge
	var large_process_material: ParticleProcessMaterial = particles_large.process_material
	var large_gradient_texture: GradientTexture1D = large_process_material.color_ramp
	var large_color: Color = MODIFIER_TO_LARGE_COLOR[modifier]
	large_gradient_texture.gradient.set_color(0, large_color)

	var particles_small: GPUParticles2D = $GPUParticlesSmall
	var small_process_material: ParticleProcessMaterial = particles_small.process_material
	var small_color: Color = MODIFIER_TO_SMALL_COLOR[modifier]
	small_process_material.color = small_color
