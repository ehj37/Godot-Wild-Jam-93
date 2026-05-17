extends Level

@onready var _double_cross_dialog: AcknowledgeDialog = $DoubleCrossDialog


func _ready() -> void:
	await get_tree().create_timer(1.5).timeout

	if !LevelManager.shown_double_cross_dialog:
		_double_cross_dialog.visible = true
		get_tree().paused = true
		LevelManager.shown_double_cross_dialog = true


func _on_double_cross_dialog_acknowledged() -> void:
	get_tree().paused = false
