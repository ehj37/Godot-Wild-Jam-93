extends TextureRect

@export var delay: float = 0.0

@onready var _animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	await get_tree().create_timer(delay).timeout

	_animation_player.play("glimmer")
