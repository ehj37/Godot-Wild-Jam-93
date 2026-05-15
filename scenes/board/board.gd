class_name Board

extends Control


class Attack:
	var attacking_piece: Piece
	var attacked_piece: Piece

	@warning_ignore("shadowed_variable")

	func _init(attacking_piece: Piece, attacked_piece: Piece) -> void:
		self.attacking_piece = attacking_piece
		self.attacked_piece = attacked_piece


enum PieceType { PAWN, ROOK, KNIGHT, BISHOP, QUEEN, KING }

const CELL_SIDE_LENGTH: int = 42
const ORIGIN: Vector2i = Vector2i(-4 * CELL_SIDE_LENGTH, 4 * CELL_SIDE_LENGTH)
const HORIZONTAL_LABELS: Array[String] = ["A", "B", "C", "D", "E", "F", "F", "H"]
const VERTICAL_LABELS: Array[String] = ["1", "2", "3", "4", "5", "6", "7", "8"]

var _pieces_by_board_coord: Dictionary = {}
var _piece_to_board_coord: Dictionary = {}
var _selected_piece: Piece
var _listen_for_player_board_inputs: bool = true

@onready var _pawn_promotion_dialog: PawnPromotionDialog = $CenterContainer/PawnPromotionDialog
@onready var _turn_dialog: TurnDialog = $CenterContainer/TurnDialog
@onready var _win_dialog: WinDialog = $CenterContainer/WinDialog
@onready var _happenins_section: HappeninsSection = $RightPanel/HappeninSection
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


func _input(event: InputEvent) -> void:
	if !_listen_for_player_board_inputs:
		return

	if event is InputEventMouseButton:
		var event_mouse_button: InputEventMouseButton = event
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if event_mouse_button.pressed:
				_handle_player_turn_click()


func _ready() -> void:
	var pieces: Array = find_children("*", "Piece", true, false)
	for piece: Piece in pieces:
		var board_coordinate: Vector2i = _get_board_coordinate(piece.global_position)
		_pieces_by_board_coord[board_coordinate] = piece
		_piece_to_board_coord[piece] = board_coordinate

	_pawn_promotion_dialog.visible = false
	_turn_dialog.visible = false
	_win_dialog.visible = false


# Returns (-1, -1) for coords outside of the board
func _get_board_coordinate(global_coordinate: Vector2) -> Vector2i:
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


func _get_global_position_from_board_coordinate(board_coordinate: Vector2i) -> Vector2:
	var x_offset: float = board_coordinate.x * CELL_SIDE_LENGTH + CELL_SIDE_LENGTH / 2.0
	var y_offset: float = -board_coordinate.y * CELL_SIDE_LENGTH - CELL_SIDE_LENGTH / 2.0
	return Vector2(ORIGIN) + Vector2(x_offset, y_offset)


func _move_piece(piece: Piece, new_board_coordinate: Vector2i) -> void:
	AudioManager.play_effect(_piece_move_audio_stream)

	var current_board_coordinate: Vector2i = _get_board_coordinate(piece.global_position)
	_happenins_section.record_piece_move(
		piece_to_type(piece), current_board_coordinate, new_board_coordinate, piece.is_player
	)

	var piece_to_remove: Piece = _pieces_by_board_coord.get(new_board_coordinate)
	if piece_to_remove:
		if piece_to_remove.is_target:
			AudioManager.play_effect(_target_taken_audio_stream)
		else:
			AudioManager.play_effect(_piece_take_audio_stream)

		_happenins_section.record_take(piece_to_type(piece_to_remove), piece_to_remove.is_player)

		_pieces_by_board_coord.erase(new_board_coordinate)
		_piece_to_board_coord.erase(piece_to_remove)
		piece_to_remove.queue_free()

	_pieces_by_board_coord.erase(current_board_coordinate)

	piece.global_position = _get_global_position_from_board_coordinate(new_board_coordinate)
	_pieces_by_board_coord[new_board_coordinate] = piece
	_piece_to_board_coord[piece] = new_board_coordinate


func _replace_piece(old_piece: Piece, new_piece: Piece) -> void:
	new_piece.is_player = old_piece.is_player
	new_piece.is_target = old_piece.is_target
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
		func(piece: Piece) -> bool: return piece.is_target
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
	var mouse_board_coordinate: Vector2i = _get_board_coordinate(mouse_position)
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

			var current_board_coordinate: Vector2i = _get_board_coordinate(
				_selected_piece.global_position
			)
			var is_valid_move: bool = _selected_piece.is_valid_move(
				current_board_coordinate, mouse_board_coordinate, _pieces_by_board_coord
			)
			if is_valid_move:
				# The player has committed to a move at this point, so don't
				# want to pay attention to any other board clicks they do.
				_listen_for_player_board_inputs = false

				_move_piece(_selected_piece, mouse_board_coordinate)

				if _win_condition_met():
					_win_dialog.show()
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

					_take_enemy_turn()
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
		var attacked_piece_candidate_board_coord: Vector2i = _get_board_coordinate(
			attacked_piece_candidate.global_position
		)
		for attacking_piece_candidate: Piece in attacking_piece_candidates:
			var attacking_piece_candidate_board_coord: Vector2i
			if _piece_to_board_coord.has(attacking_piece_candidate):
				attacking_piece_candidate_board_coord = _piece_to_board_coord[attacking_piece_candidate]
			else:
				attacking_piece_candidate_board_coord = _get_board_coordinate(
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


func _take_enemy_turn() -> void:
	_turn_dialog.is_player_turn = false
	_turn_dialog.show()
	await get_tree().create_timer(1.0).timeout

	_turn_dialog.hide()

	# I love GDScript it's great
	var enemy_pieces_untyped: Array = _pieces_by_board_coord.values().filter(
		func(piece: Piece) -> bool: return !piece.is_player
	)
	var player_pieces_untyped: Array = _pieces_by_board_coord.values().filter(
		func(piece: Piece) -> bool: return piece.is_player
	)
	var enemy_pieces: Array[Piece]
	enemy_pieces.assign(enemy_pieces_untyped)
	var player_pieces: Array[Piece]
	player_pieces.assign(player_pieces_untyped)

	var attack: Attack

	# Gross, but should be fine in practice. It's an 8x8 grid with generally few
	# player pieces.
	var possible_attacks: Array[Attack] = _get_valid_attacks(enemy_pieces, player_pieces)
	var possible_attack_count: int = possible_attacks.size()
	match possible_attack_count:
		0:
			print("Enemy has no attacks")
		1:
			print("One possible enemy attack.")
			attack = possible_attacks[0]

		_:
			print("Enemy has multiple attacks")
			var candidate_enemy_pieces: Array = []
			var candidate_player_pieces: Array = []
			for possible_attack: Attack in possible_attacks:
				var enemy_piece: Piece = possible_attack.attacking_piece
				if !candidate_enemy_pieces.has(enemy_piece):
					candidate_enemy_pieces.append(enemy_piece)

				var player_piece: Piece = possible_attack.attacked_piece
				if !candidate_player_pieces.has(player_piece):
					candidate_player_pieces.append(player_piece)

			# Show every piece that could attack as selected
			for piece: Piece in candidate_enemy_pieces:
				piece.is_selected = true

			await get_tree().create_timer(0.5).timeout

			candidate_enemy_pieces.sort_custom(_compare_pieces)
			var attacking_enemy_piece: Piece = candidate_enemy_pieces[0]
			var attacks_for_enemy_piece: Array = possible_attacks.filter(
				func(a: Attack) -> bool: return a.attacking_piece == attacking_enemy_piece
			)
			if attacks_for_enemy_piece.size() == 1:
				print("One attack, no further tiebreaking needed")
				attack = attacks_for_enemy_piece[0]
			else:
				print("Multiple attacks, further tiebreaking needed")
				candidate_player_pieces.sort_custom(_compare_pieces)
				var player_piece_to_attack: Piece = candidate_enemy_pieces[0]
				var attack_i: int = attacks_for_enemy_piece.find_custom(
					func(attack_for_enemy_piece: Attack) -> bool: return (
						attack_for_enemy_piece.attacked_piece == player_piece_to_attack
					)
				)
				attack = attacks_for_enemy_piece[attack_i]

			for piece: Piece in candidate_enemy_pieces:
				piece.is_selected = piece == attack.attacking_piece

	if attack:
		await get_tree().create_timer(0.5).timeout

		var enemy_piece: Piece = attack.attacking_piece
		enemy_piece.is_selected = true
		await get_tree().create_timer(0.5).timeout

		var player_piece: Piece = attack.attacked_piece
		var player_board_coord: Vector2i = _piece_to_board_coord[player_piece]
		_move_piece(enemy_piece, player_board_coord)

		if _is_promotion_candidate(enemy_piece):
			var queen: Queen = _queen_packed_scene.instantiate()
			_replace_piece(enemy_piece, queen)
			queen.is_selected = false
		else:
			enemy_piece.is_selected = false

	if _win_condition_met():
		_win_dialog.show()
	else:
		_listen_for_player_board_inputs = true
		# TODO: Show turn dialog for player


func _compare_pieces(piece_a: Piece, piece_b: Piece) -> bool:
	var piece_a_board_coord: Vector2i = _get_board_coordinate(piece_a.global_position)
	var piece_b_board_coord: Vector2i = _get_board_coordinate(piece_b.global_position)
	if piece_a_board_coord.y > piece_b_board_coord.y:
		return true

	if piece_a_board_coord.y < piece_b_board_coord.y:
		return false

	return piece_a_board_coord.x > piece_b_board_coord.x


func _on_reset_button_pressed() -> void:
	get_tree().reload_current_scene()
