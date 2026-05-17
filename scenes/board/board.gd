class_name Board

extends Control


class Attack:
	var attacking_piece: Piece
	var attacked_piece: Piece

	@warning_ignore("shadowed_variable")

	func _init(attacking_piece: Piece, attacked_piece: Piece) -> void:
		self.attacking_piece = attacking_piece
		self.attacked_piece = attacked_piece


signal player_turn_over

enum PieceType { PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING }

const CELL_SIDE_LENGTH: int = 42
const ORIGIN: Vector2i = Vector2i(-4 * CELL_SIDE_LENGTH, 4 * CELL_SIDE_LENGTH)
const HORIZONTAL_LABELS: Array[String] = ["A", "B", "C", "D", "E", "F", "G", "H"]
const VERTICAL_LABELS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8"]

@export var tutorial_text: String

var _pieces_by_board_coord: Dictionary = {}
var _piece_to_board_coord: Dictionary = {}
var _selected_piece: Piece
var _listen_for_player_board_inputs: bool = true

@onready var _highlight_squares: TileMapLayer = $HighlightSquares
@onready var _pawn_promotion_dialog: PawnPromotionDialog = $CenterContainer/PawnPromotionDialog
@onready var _turn_dialog: TurnDialog = $CenterContainer/TurnDialog
@onready var _turn_label: Label = $RightPanel/PanelContainer/MarginContainer/TurnLabel
@onready var _tutorial_section: PanelContainer = $RightPanel/TutorialSection
@onready var _tutorial_label: Label = $RightPanel/TutorialSection/MarginContainer/TutorialLabel
@onready var _win_dialog: WinDialog = $CenterContainer/WinDialog
@onready var _vip_removed_dialog: PanelContainer = $CenterContainer/VipRemovedDialog
@onready var _happenins_section: HappeninsSection = $RightPanel/HappeninSection
@onready var _bounty_board: BountyBoard = $RightPanel/BountyBoard
@onready var _reset_button: Button = $ResetButton
@onready var _multi_enemy_tiebreak_dialog: AcknowledgeDialog = $MultiEnemyTiebreakDialog
@onready var _multi_player_tiebreak_dialog: AcknowledgeDialog = $MultiPlayerTiebreakDialog
@onready var _level_number_container: HBoxContainer = $CenterContainer/LevelNumberContainer
@onready var _level_number_label: Label = $CenterContainer/LevelNumberContainer/LevelNumberLabel
@onready
var _total_level_count_label: Label = $CenterContainer/LevelNumberContainer/TotalLevelCountLabel
# PIECE PACKED SCENES
@onready var _queen_packed_scene: PackedScene = preload("res://scenes/pieces/queen/queen.tscn")
@onready var _rook_packed_scene: PackedScene = preload("res://scenes/pieces/rook/rook.tscn")
@onready var _bishop_packed_scene: PackedScene = preload("res://scenes/pieces/bishop/bishop.tscn")
@onready var _knight_packed_scene: PackedScene = preload("res://scenes/pieces/knight/knight.tscn")
# AUDIO STREAMS
@onready
var _piece_move_audio_stream: AudioStreamOggVorbis = preload("res://audio_streams/piece_move.ogg")
@onready
var _piece_take_audio_stream: AudioStreamOggVorbis = preload("res://audio_streams/piece_take.ogg")
@onready var _target_taken_audio_stream: AudioStreamOggVorbis = preload(
	"res://audio_streams/target_taken.ogg"
)
@onready var _piece_selected_audio_stream: AudioStreamOggVorbis = preload(
	"res://audio_streams/piece_selected.ogg"
)
@onready var _piece_unselected_audio_stream: AudioStreamOggVorbis = preload(
	"res://audio_streams/piece_unselected.ogg"
)


static func board_coordinate_to_notation(board_coord: Vector2i) -> String:
	var x_label: String = HORIZONTAL_LABELS[board_coord.x]
	var y_label: String = VERTICAL_LABELS[board_coord.y]
	return x_label + y_label


static func piece_to_type(piece: Piece) -> PieceType:
	var type: PieceType
	if piece is Pawn:
		type = PieceType.PAWN
	elif piece is Rook:
		type = PieceType.ROOK
	elif piece is Knight:
		type = PieceType.KNIGHT
	elif piece is Bishop:
		type = PieceType.BISHOP
	elif piece is King:
		type = PieceType.KING
	elif piece is Queen:
		type = PieceType.QUEEN
	else:
		push_error("Unhandled Piece in Board.piece_to_type: " + str(piece))

	return type


static func piece_type_to_human_readable_name(piece_type: Board.PieceType) -> String:
	var piece_name: String
	match piece_type:
		Board.PieceType.PAWN:
			piece_name = "PAWN"
		Board.PieceType.ROOK:
			piece_name = "ROOK"
		Board.PieceType.KNIGHT:
			piece_name = "KNIGHT"
		Board.PieceType.BISHOP:
			piece_name = "BISHOP"
		Board.PieceType.KING:
			piece_name = "KING"
		Board.PieceType.QUEEN:
			piece_name = "QUEEN"
		_:
			push_error("Unhandled piece type in Board.piece_type_to_human_readable_name")

	return piece_name


# Returns (-1, -1) for coords outside of the board
static func get_board_coordinate(global_coordinate: Vector2) -> Vector2i:
	var x_from_origin: float = global_coordinate.x - ORIGIN.x
	var y_from_origin: float = global_coordinate.y - ORIGIN.y
	if (
		x_from_origin < 0
		|| x_from_origin > 8 * CELL_SIDE_LENGTH
		|| y_from_origin > 0
		|| y_from_origin < -8 * CELL_SIDE_LENGTH
	):
		return Vector2i(-1, -1)

	@warning_ignore("narrowing_conversion")
	return Vector2(x_from_origin / CELL_SIDE_LENGTH, absi(y_from_origin / CELL_SIDE_LENGTH))


func _input(event: InputEvent) -> void:
	if !_listen_for_player_board_inputs:
		return

	if event is InputEventMouseButton:
		var event_mouse_button: InputEventMouseButton = event
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if event_mouse_button.pressed:
				_handle_player_turn_click()


# Prob a way to do this in input handling but if it works it works
func _process(_delta: float) -> void:
	if !_listen_for_player_board_inputs:
		_highlight_squares.visible = false
		return

	_highlight_squares.visible = true
	_highlight_squares.clear()

	var global_mouse_position: Vector2 = get_global_mouse_position()
	var mouse_board_coordinate: Vector2 = get_board_coordinate(global_mouse_position)
	if mouse_board_coordinate == Vector2(-1, -1):
		return

	var tile_map_coords: Vector2i = _highlight_squares.local_to_map(global_mouse_position)
	_highlight_squares.set_cell(tile_map_coords, 0, Vector2.ZERO)


func _ready() -> void:
	var current_level_number: int = LevelManager.current_level_number
	if !LevelManager.displayed_level_numbers.has(current_level_number):
		_level_number_container.modulate.a = 1.0
		LevelManager.displayed_level_numbers.append(current_level_number)

		var total_level_count: int = LevelManager.ORDERED_LEVEL_PATHS.size()
		_level_number_label.text = str(current_level_number + 1)
		_total_level_count_label.text = str(total_level_count)

		var level_number_container_alpha_tween: Tween = _level_number_container.create_tween()
		level_number_container_alpha_tween.tween_property(
			_level_number_container, "modulate:a", 0.0, 3.0
		)
	else:
		_level_number_container.modulate.a = 0.0

	var pieces: Array = find_children("*", "Piece", true, false)
	for piece: Piece in pieces:
		var board_coordinate: Vector2i = get_board_coordinate(piece.global_position)
		_pieces_by_board_coord[board_coordinate] = piece
		_piece_to_board_coord[piece] = board_coordinate
		if piece.is_target():
			_bounty_board.add_bounty(piece, board_coordinate)

	if tutorial_text:
		_tutorial_label.text = tutorial_text
		_tutorial_section.show()
	else:
		_tutorial_section.hide()

	_pawn_promotion_dialog.visible = false
	_turn_dialog.visible = false
	_win_dialog.visible = false
	_vip_removed_dialog.visible = false


func _get_global_position_from_board_coordinate(board_coordinate: Vector2i) -> Vector2:
	var x_offset: float = board_coordinate.x * CELL_SIDE_LENGTH + CELL_SIDE_LENGTH / 2.0
	var y_offset: float = -board_coordinate.y * CELL_SIDE_LENGTH - CELL_SIDE_LENGTH / 2.0
	return Vector2(ORIGIN) + Vector2(x_offset, y_offset)


func _get_player_pieces() -> Array[Piece]:
	var player_pieces_untyped: Array = _pieces_by_board_coord.values().filter(
		func(piece: Piece) -> bool: return piece.is_player
	)
	var player_pieces: Array[Piece]
	player_pieces.assign(player_pieces_untyped)
	return player_pieces


func _get_enemy_pieces() -> Array[Piece]:
	var enemy_pieces_untyped: Array = _pieces_by_board_coord.values().filter(
		func(piece: Piece) -> bool: return !piece.is_player
	)
	var enemy_pieces: Array[Piece]
	enemy_pieces.assign(enemy_pieces_untyped)
	return enemy_pieces


# Returns true if a VIP piece was removed, false otherwise.
# Scuffed, but we're sub three hours on this jam
func _move_piece(piece: Piece, new_board_coordinate: Vector2i) -> bool:
	AudioManager.play_effect(_piece_move_audio_stream)

	var current_board_coordinate: Vector2i = get_board_coordinate(piece.global_position)
	_happenins_section.record_piece_move(
		piece_to_type(piece), current_board_coordinate, new_board_coordinate, piece.is_player
	)
	if piece.is_target():
		_bounty_board.update_bounty_last_seen(piece, new_board_coordinate)

	var piece_to_remove: Piece = _pieces_by_board_coord.get(new_board_coordinate)
	var vip_removed: bool = false
	if piece_to_remove:
		if piece_to_remove.is_target():
			_bounty_board.claim_bounty(piece_to_remove)
			AudioManager.play_effect(_target_taken_audio_stream)
		else:
			AudioManager.play_effect(_piece_take_audio_stream)

		vip_removed = piece_to_remove.is_vip()

		_happenins_section.record_take(piece_to_type(piece_to_remove), piece_to_remove.is_player)
		if piece_to_remove.is_target():
			_happenins_section.record_bounty_claimed()

		_pieces_by_board_coord.erase(new_board_coordinate)
		_piece_to_board_coord.erase(piece_to_remove)
		piece_to_remove.queue_free()

	_pieces_by_board_coord.erase(current_board_coordinate)

	piece.global_position = _get_global_position_from_board_coordinate(new_board_coordinate)
	_pieces_by_board_coord[new_board_coordinate] = piece
	_piece_to_board_coord[piece] = new_board_coordinate

	return vip_removed


func _replace_piece(old_piece: Piece, new_piece: Piece) -> void:
	new_piece.is_player = old_piece.is_player
	new_piece.modifier = old_piece.modifier
	new_piece.is_selected = old_piece.is_selected
	new_piece.global_position = old_piece.global_position
	var board_coord: Vector2i = _piece_to_board_coord[old_piece]
	_piece_to_board_coord[new_piece] = board_coord
	_piece_to_board_coord.erase(old_piece)
	_pieces_by_board_coord[board_coord] = new_piece

	if old_piece == _selected_piece:
		_selected_piece = new_piece

	old_piece.get_parent().add_child(new_piece)
	old_piece.queue_free()


func _win_condition_met() -> bool:
	var target_pieces: Array = _pieces_by_board_coord.values().filter(
		func(piece: Piece) -> bool: return piece.is_target()
	)
	return target_pieces.is_empty()


func _is_promotion_candidate(piece: Piece) -> bool:
	if !(piece is Pawn):
		return false

	var board_coord: Vector2i = _piece_to_board_coord[piece]
	if piece.is_player:
		return board_coord.y == 7

	return board_coord.y == 0


func _handle_player_turn_click() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	var mouse_board_coordinate: Vector2i = get_board_coordinate(mouse_position)
	if _selected_piece:
		if mouse_board_coordinate != Vector2i(-1, -1):
			var piece_at_mouse_board_coordinate: Piece = _pieces_by_board_coord.get(
				mouse_board_coordinate
			)
			if piece_at_mouse_board_coordinate == _selected_piece:
				_selected_piece.is_selected = false
				_selected_piece = null
				AudioManager.play_effect(_piece_unselected_audio_stream)
				return

			if piece_at_mouse_board_coordinate && piece_at_mouse_board_coordinate.is_player:
				_selected_piece.is_selected = false
				_selected_piece = piece_at_mouse_board_coordinate
				AudioManager.play_effect(_piece_selected_audio_stream)
				piece_at_mouse_board_coordinate.is_selected = true
				return

			var current_board_coordinate: Vector2i = get_board_coordinate(
				_selected_piece.global_position
			)
			var is_valid_move: bool = _selected_piece.is_valid_move(
				current_board_coordinate, mouse_board_coordinate, _pieces_by_board_coord
			)
			if is_valid_move:
				# The player has committed to a move at this point, so don't
				# want to pay attention to any other board clicks they do.
				_listen_for_player_board_inputs = false
				var vip_removed: bool = _move_piece(_selected_piece, mouse_board_coordinate)
				if vip_removed:
					_vip_removed_dialog.show()
				elif _win_condition_met():
					_win_dialog.show()
					_reset_button.disabled = true
				else:
					if _is_promotion_candidate(_selected_piece):
						_pawn_promotion_dialog.show()
						var chosen_piece_type: Board.PieceType = await (
							_pawn_promotion_dialog.piece_type_picked
						)

						_happenins_section.record_promotion(chosen_piece_type, true)

						_pawn_promotion_dialog.hide()
						var piece_packed_scene: PackedScene
						match chosen_piece_type:
							Board.PieceType.QUEEN:
								piece_packed_scene = _queen_packed_scene
							Board.PieceType.ROOK:
								piece_packed_scene = _rook_packed_scene
							Board.PieceType.BISHOP:
								piece_packed_scene = _bishop_packed_scene
							Board.PieceType.KNIGHT:
								piece_packed_scene = _knight_packed_scene
							_:
								push_error(
									"Encountered unexpected chosen piece type from pawn promotion dialog."
								)

						var promotion_piece: Piece = piece_packed_scene.instantiate()
						_replace_piece(_selected_piece, promotion_piece)

					player_turn_over.emit()
					_switch_to_enemy_turn()
			else:
				AudioManager.play_effect(_piece_unselected_audio_stream)
		else:
			AudioManager.play_effect(_piece_unselected_audio_stream)

		_selected_piece.is_selected = false
		_selected_piece = null
	else:
		var piece_at_mouse: Piece = _pieces_by_board_coord.get(mouse_board_coordinate)
		if piece_at_mouse && piece_at_mouse.is_player:
			_selected_piece = _pieces_by_board_coord.get(mouse_board_coordinate)
			AudioManager.play_effect(_piece_selected_audio_stream)
			_selected_piece.is_selected = true


func _get_valid_attacks(
	attacking_piece_candidates: Array[Piece], attacked_piece_candidates: Array[Piece]
) -> Array[Attack]:
	# Gross, but should be fine in practice. It's an 8x8 grid with generally few
	# player pieces.
	var possible_attacks: Array[Attack] = []
	for attacked_piece_candidate: Piece in attacked_piece_candidates:
		var attacked_piece_candidate_board_coord: Vector2i = get_board_coordinate(
			attacked_piece_candidate.global_position
		)
		for attacking_piece_candidate: Piece in attacking_piece_candidates:
			var attacking_piece_candidate_board_coord: Vector2i
			if _piece_to_board_coord.has(attacking_piece_candidate):
				attacking_piece_candidate_board_coord = _piece_to_board_coord[attacking_piece_candidate]
			else:
				attacking_piece_candidate_board_coord = get_board_coordinate(
					attacking_piece_candidate.global_position
				)

			if attacking_piece_candidate.is_valid_move(
				attacking_piece_candidate_board_coord,
				attacked_piece_candidate_board_coord,
				_pieces_by_board_coord
			):
				possible_attacks.append(
					Attack.new(attacking_piece_candidate, attacked_piece_candidate)
				)

	return possible_attacks


# Contains tie-breaking logic
func _pick_enemy_attack(possible_attacks: Array[Attack]) -> Attack:
	var possible_attack_count: int = possible_attacks.size()
	match possible_attack_count:
		0:
			return null
		1:
			return possible_attacks[0]
		_:
			var candidate_enemy_pieces: Array = []
			var candidate_player_pieces: Array = []
			for possible_attack: Attack in possible_attacks:
				var enemy_piece: Piece = possible_attack.attacking_piece
				if !candidate_enemy_pieces.has(enemy_piece):
					candidate_enemy_pieces.append(enemy_piece)

				var player_piece: Piece = possible_attack.attacked_piece
				if !candidate_player_pieces.has(player_piece):
					candidate_player_pieces.append(player_piece)

			if candidate_enemy_pieces.size() > 1:
				_on_multi_enemy_tiebreak()

			candidate_enemy_pieces.sort_custom(_compare_pieces)
			var attacking_enemy_piece: Piece = candidate_enemy_pieces[0]
			var attacks_for_enemy_piece: Array = possible_attacks.filter(
				func(a: Attack) -> bool: return a.attacking_piece == attacking_enemy_piece
			)
			if attacks_for_enemy_piece.size() == 1:
				return attacks_for_enemy_piece[0]

			_on_multi_player_tiebreak()

			candidate_player_pieces.sort_custom(_compare_pieces)
			var player_piece_to_attack: Piece = candidate_player_pieces[0]
			var attack_i: int = attacks_for_enemy_piece.find_custom(
				func(attack_for_enemy_piece: Attack) -> bool: return (
					attack_for_enemy_piece.attacked_piece == player_piece_to_attack
				)
			)
			return attacks_for_enemy_piece[attack_i]


func _switch_to_enemy_turn() -> void:
	_listen_for_player_board_inputs = false
	var enemy_pieces: Array[Piece] = _get_enemy_pieces()
	var player_pieces: Array[Piece] = _get_player_pieces()
	var possible_attacks: Array[Attack] = _get_valid_attacks(enemy_pieces, player_pieces)

	if possible_attacks.size() == 0:
		_turn_dialog.text = "NO BANDIT ATTACKS\nPLAYER TURN"
		_turn_dialog.show()
		await get_tree().create_timer(1.0, false).timeout

		_turn_dialog.hide()
		_switch_to_player_turn(false)
		return

	_turn_label.text = "BANDIT TURN"
	_take_enemy_turn(possible_attacks)


func _switch_to_player_turn(show_dialog: bool = true) -> void:
	_turn_label.text = "YER TURN"

	if show_dialog:
		_turn_dialog.text = "PLAYER TURN"
		_turn_dialog.show()
		await get_tree().create_timer(0.75, false).timeout

		_turn_dialog.hide()
	_listen_for_player_board_inputs = true


func _take_enemy_turn(possible_attacks: Array[Attack]) -> void:
	var attack: Attack = _pick_enemy_attack(possible_attacks)

	_turn_dialog.text = "BANDIT TURN"
	_turn_dialog.show()

	await get_tree().create_timer(1.0, false).timeout

	_turn_dialog.hide()

	var enemy_piece: Piece = attack.attacking_piece
	enemy_piece.is_selected = true
	enemy_piece.flash()

	await get_tree().create_timer(1.5, false).timeout

	var player_piece: Piece = attack.attacked_piece
	var player_board_coord: Vector2i = _piece_to_board_coord[player_piece]
	var vip_removed: bool = _move_piece(enemy_piece, player_board_coord)

	if _is_promotion_candidate(enemy_piece):
		var queen: Queen = _queen_packed_scene.instantiate()
		_replace_piece(enemy_piece, queen)
		queen.is_selected = false
	else:
		enemy_piece.is_selected = false

	if vip_removed:
		_vip_removed_dialog.show()
	if _win_condition_met():
		_win_dialog.show()
		_reset_button.disabled = true
	else:
		_switch_to_player_turn()


func _compare_pieces(piece_a: Piece, piece_b: Piece) -> bool:
	var piece_a_board_coord: Vector2i = get_board_coordinate(piece_a.global_position)
	var piece_b_board_coord: Vector2i = get_board_coordinate(piece_b.global_position)
	if piece_a_board_coord.y > piece_b_board_coord.y:
		return true

	if piece_a_board_coord.y < piece_b_board_coord.y:
		return false

	return piece_a_board_coord.x > piece_b_board_coord.x


# Need to be very careful about not showing multiple dialogs at once.
# Dialog system not set up to handle that gracefully.
func _on_multi_player_tiebreak() -> void:
	if !LevelManager.shown_multi_player_tiebreak_dialog:
		_multi_player_tiebreak_dialog.show()
		get_tree().paused = true
		await _multi_player_tiebreak_dialog.acknowledged

		get_tree().paused = false
		LevelManager.shown_multi_player_tiebreak_dialog = true


func _on_multi_enemy_tiebreak() -> void:
	if !LevelManager.shown_multi_enemy_tiebreak_dialog:
		_multi_enemy_tiebreak_dialog.show()
		get_tree().paused = true
		await _multi_enemy_tiebreak_dialog.acknowledged

		get_tree().paused = false
		LevelManager.shown_multi_enemy_tiebreak_dialog = true


func _on_reset_button_pressed() -> void:
	get_tree().reload_current_scene()
