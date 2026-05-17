extends Level

@onready var _howdy_dialog: AcknowledgeDialog = $TutorialDialogContainer/HowdyDialog
@onready var _bandit_turn_dialog: AcknowledgeDialog = $TutorialDialogContainer/BanditTurnDialog


func _ready() -> void:
	await get_tree().create_timer(1.5).timeout

	if !LevelManager.shown_intro_dialogs:
		_howdy_dialog.visible = true
		get_tree().paused = true
		LevelManager.shown_intro_dialogs = true


func _on_game_start_dialog_acknowledged() -> void:
	get_tree().paused = false


func _on_board_player_turn_over() -> void:
	if !LevelManager.shown_bandit_turn_dialog:
		_bandit_turn_dialog.show()
		get_tree().paused = true
		await _bandit_turn_dialog.acknowledged

		get_tree().paused = false
		LevelManager.shown_bandit_turn_dialog = true
