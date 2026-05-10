@tool

class_name TargetFire

extends Node2D


func set_emitting(value: bool) -> void:
	var particles_red: GPUParticles2D = $GPUParticlesRed
	particles_red.emitting = value
	var particles_orange: GPUParticles2D = $GPUParticlesOrange
	particles_orange.emitting = value
