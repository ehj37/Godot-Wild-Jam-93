extends Node

const ORDERED_LEVEL_PATHS: Array[String] = [
	"res://scenes/levels/intro.tscn",
	"res://scenes/levels/non_targets.tscn",
	"res://scenes/levels/multiple_bandit_attack_tiebreaker.tscn",
	"res://scenes/levels/multiple_attackable_player_pieces.tscn",
	"res://scenes/levels/sacrifice.tscn",
	"res://scenes/levels/promotion.tscn",
	"res://scenes/levels/double_cross.tscn",
	"res://scenes/levels/forced_promotion.tscn"
]

var shown_intro_dialogs: bool = false
var shown_bandit_turn_dialog: bool = false
var shown_multi_player_tiebreak_dialog: bool = false
var shown_multi_enemy_tiebreak_dialog: bool = false
var _current_level: int


func start_game() -> void:
	_go_to_level(0)


func next_level() -> void:
	_go_to_level(_current_level + 1)


func _go_to_level(level_number: int) -> void:
	ScreenFadeManager.fade_out()
	await ScreenFadeManager.fade_completed

	var level_path: String = ORDERED_LEVEL_PATHS[level_number]
	var level_packed_scene: PackedScene = load(level_path)
	var level: Level = level_packed_scene.instantiate()
	var tree: SceneTree = get_tree()
	var current_scene: Node = tree.current_scene
	current_scene.queue_free()
	tree.root.add_child(level)
	tree.set_current_scene(level)
	_current_level = level_number

	ScreenFadeManager.fade_in()
	get_tree().paused = false
