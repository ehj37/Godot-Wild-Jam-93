extends Level

@onready var _vip_dialog: AcknowledgeDialog = $VipDialog


func _ready() -> void:
	await get_tree().create_timer(1.5).timeout

	if !LevelManager.shown_vip_intro_dialog:
		_vip_dialog.visible = true
		get_tree().paused = true
		LevelManager.shown_vip_intro_dialog = true


func _on_vip_dialog_acknowledged() -> void:
	get_tree().paused = false
