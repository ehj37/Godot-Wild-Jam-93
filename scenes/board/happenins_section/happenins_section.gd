class_name HappeninsSection

extends PanelContainer

const MAX_HAPPENIN_COUNT: int = 5

var _displayed_happenins: Array[Happenin] = []

@onready var _happenin_packed_scene: PackedScene = preload(
	"res://scenes/board/happenins_section/happenins/happenin/happenin.tscn"
)
@onready var _happenins_container: VBoxContainer = $MarginContainer/VBoxContainer/Happenins


func record_piece_move(
	piece_type: Board.PieceType, from: Vector2i, to: Vector2i, is_player: bool
) -> void:
	var happenin: Happenin = _add_happenin()

	var prefix: String
	if is_player:
		prefix = "PLAYER"
	else:
		prefix = "BANDIT"

	var piece_name: String = Board.piece_type_to_human_readable_name(piece_type)
	var from_in_notation: String = Board.board_coordinate_to_notation(from)
	var to_in_notation: String = Board.board_coordinate_to_notation(to)
	happenin.set_text(prefix + " " + piece_name + ":" + from_in_notation + " TO " + to_in_notation)


func record_take(taken_piece_type: Board.PieceType, is_player: bool) -> void:
	var happenin: Happenin = _add_happenin()

	var prefix: String
	if is_player:
		prefix = "PLAYER"
	else:
		prefix = "BANDIT"

	var piece_name: String = Board.piece_type_to_human_readable_name(taken_piece_type)
	happenin.set_text(prefix + " " + piece_name + " TAKEN")


func record_promotion(piece_type: Board.PieceType, is_player: bool) -> void:
	var happenin: Happenin = _add_happenin()

	var prefix: String
	if is_player:
		prefix = "PLAYER"
	else:
		prefix = "BANDIT"

	var piece_name: String = Board.piece_type_to_human_readable_name(piece_type)
	happenin.set_text(prefix + " PAWN PROMOTED TO " + piece_name)


func record_bounty_claimed() -> void:
	var happenin: Happenin = _add_happenin()
	happenin.set_text("BOUNTY CLAIMED")


func _add_happenin() -> Happenin:
	var happenin: Happenin = _happenin_packed_scene.instantiate()
	_happenins_container.add_child(happenin)
	_happenins_container.move_child(happenin, 0)
	_displayed_happenins.append(happenin)
	if _displayed_happenins.size() > MAX_HAPPENIN_COUNT:
		var oldest_happenin: Happenin = _displayed_happenins.pop_front()
		oldest_happenin.queue_free()

	var displayed_happenins_count: int = _displayed_happenins.size()
	var loop_alpha: float = 1.0
	for i: int in displayed_happenins_count:
		var displayed_happenin: Happenin = _displayed_happenins[displayed_happenins_count - i - 1]
		displayed_happenin.set_text_alpha(loop_alpha)
		loop_alpha -= (1.0 / float(MAX_HAPPENIN_COUNT))

	return happenin
