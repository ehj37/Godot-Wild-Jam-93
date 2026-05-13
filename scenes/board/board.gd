class_name Board

extends Sprite2D


class Attack:
	var attacking_piece: Piece
	var attacked_piece: Piece

	@warning_ignore("shadowed_variable")

	func _init(attacking_piece: Piece, attacked_piece: Piece) -> void:
		self.attacking_piece = attacking_piece
		self.attacked_piece = attacked_piece


const CELL_SIDE_LENGTH: int = 42
const ORIGIN: Vector2i = Vector2i(-4 * CELL_SIDE_LENGTH, 4 * CELL_SIDE_LENGTH)

var _pieces_by_board_coord: Dictionary = {}
var _piece_to_board_coord: Dictionary = {}
var _selected_piece: Piece
var _is_player_turn: bool = true

@onready var _pawn_promotion_dialog: PawnPromotionDialog = $CenterContainer/PawnPromotionDialog
@onready var _turn_dialog: TurnDialog = $CenterContainer/TurnDialog
@onready var _win_dialog: WinDialog = $CenterContainer/WinDialog
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


# Returns (-1, -1) for coords outside of the board
func get_board_coordinate(global_coordinate: Vector2) -> Vector2i:
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


func get_global_position_from_board_coordinate(board_coordinate: Vector2i) -> Vector2:
	var x_offset: float = board_coordinate.x * CELL_SIDE_LENGTH + CELL_SIDE_LENGTH / 2.0
	var y_offset: float = -board_coordinate.y * CELL_SIDE_LENGTH - CELL_SIDE_LENGTH / 2.0
	return Vector2(ORIGIN) + Vector2(x_offset, y_offset)


func _input(event: InputEvent) -> void:
	if !_is_player_turn:
		return

	if event is InputEventMouseButton:
		var event_mouse_button: InputEventMouseButton = event
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if event_mouse_button.pressed:
				_handle_player_turn_click()


func _ready() -> void:
	var pieces: Array = find_children("*", "Piece", true, false)
	for piece: Piece in pieces:
		var board_coordinate: Vector2i = get_board_coordinate(piece.global_position)
		_pieces_by_board_coord[board_coordinate] = piece
		_piece_to_board_coord[piece] = board_coordinate

	_pawn_promotion_dialog.visible = false
	_turn_dialog.visible = false
	_win_dialog.visible = false


# Returns the moved piece, which may or may not be the same as the provided
# piece in the event of pawn promotion.
func _move_piece(piece: Piece, new_board_coordinate: Vector2i) -> Piece:
	AudioManager.play_effect(_piece_move_audio_stream)

	var piece_to_remove: Piece = _pieces_by_board_coord.get(new_board_coordinate)
	if piece_to_remove:
		if piece_to_remove.is_target:
			AudioManager.play_effect(_target_taken_audio_stream)
		else:
			AudioManager.play_effect(_piece_take_audio_stream)

		_pieces_by_board_coord.erase(new_board_coordinate)
		_piece_to_board_coord.erase(piece_to_remove)
		piece_to_remove.queue_free()

	var current_board_coordinate: Vector2i = get_board_coordinate(piece.global_position)
	_pieces_by_board_coord.erase(current_board_coordinate)

	var new_global_position: Vector2 = get_global_position_from_board_coordinate(
		new_board_coordinate
	)
	piece.global_position = get_global_position_from_board_coordinate(new_board_coordinate)
	_pieces_by_board_coord[new_board_coordinate] = piece
	_piece_to_board_coord[piece] = new_board_coordinate

	var moved_piece: Piece = piece
	if piece is Pawn:
		if piece.is_player && new_board_coordinate.y == 7:
			_pawn_promotion_dialog.show()
			var chosen_piece_type: PawnPromotionDialog.PieceType = await (
				_pawn_promotion_dialog.piece_type_picked
			)

			_pawn_promotion_dialog.hide()
			var piece_packed_scene: PackedScene
			match chosen_piece_type:
				PawnPromotionDialog.PieceType.QUEEN:
					piece_packed_scene = _queen_packed_scene
				PawnPromotionDialog.PieceType.ROOK:
					piece_packed_scene = _rook_packed_scene
				PawnPromotionDialog.PieceType.BISHOP:
					piece_packed_scene = _bishop_packed_scene
				PawnPromotionDialog.PieceType.KNIGHT:
					piece_packed_scene = _knight_packed_scene
				_:
					push_error(
						"Encountered unexpected chosen piece type from pawn promotion dialog."
					)

			var promotion_piece: Piece = piece_packed_scene.instantiate()
			promotion_piece.is_player = true
			promotion_piece.is_target = piece.is_target
			promotion_piece.is_selected = piece.is_selected
			piece.get_parent().add_child(promotion_piece)
			_piece_to_board_coord.erase(piece)
			piece.queue_free()
			promotion_piece.global_position = new_global_position
			_pieces_by_board_coord[new_board_coordinate] = promotion_piece
			_piece_to_board_coord[promotion_piece] = new_board_coordinate
			moved_piece = promotion_piece
		elif !piece.is_player && new_board_coordinate.y == 0:
			var queen: Queen = _queen_packed_scene.instantiate()
			queen.is_player = false
			queen.is_target = piece.is_target
			queen.is_selected = piece.is_selected
			piece.get_parent().add_child(queen)
			_piece_to_board_coord.erase(piece)
			piece.queue_free()
			queen.global_position = new_global_position
			_pieces_by_board_coord[new_board_coordinate] = queen
			_piece_to_board_coord[queen] = new_board_coordinate
			moved_piece = queen

	return moved_piece


func _win_condition_met() -> bool:
	var target_pieces: Array = _pieces_by_board_coord.values().filter(
		func(piece: Piece) -> bool: return piece.is_target
	)
	return target_pieces.is_empty()


func _handle_player_turn_click() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()
	var mouse_board_coordinate: Vector2i = get_board_coordinate(mouse_position)
	if _selected_piece:
		if mouse_board_coordinate != Vector2i(-1, -1):
			var piece_at_mouse_board_coordinate: Piece = _pieces_by_board_coord.get(
				mouse_board_coordinate
			)
			if piece_at_mouse_board_coordinate && piece_at_mouse_board_coordinate.is_player:
				_selected_piece.is_selected = false
				_selected_piece = piece_at_mouse_board_coordinate
				piece_at_mouse_board_coordinate.is_selected = true
				return

			var current_board_coordinate: Vector2i = get_board_coordinate(
				_selected_piece.global_position
			)
			var is_valid_move: bool = _selected_piece.is_valid_move(
				current_board_coordinate, mouse_board_coordinate, _pieces_by_board_coord
			)
			if is_valid_move:
				_selected_piece = await _move_piece(_selected_piece, mouse_board_coordinate)

				if _win_condition_met():
					_win_dialog.show()
				else:
					_is_player_turn = false
					_take_enemy_turn()

		_selected_piece.is_selected = false
		_selected_piece = null
	else:
		var piece_at_mouse: Piece = _pieces_by_board_coord.get(mouse_board_coordinate)
		if piece_at_mouse && piece_at_mouse.is_player:
			_selected_piece = _pieces_by_board_coord.get(mouse_board_coordinate)
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

	# Gross, but should be fine in practice. It's an 8x8 grid with generally few
	# player pieces.
	var possible_attacks: Array[Attack] = _get_valid_attacks(enemy_pieces, player_pieces)
	var possible_attack_count: int = possible_attacks.size()
	match possible_attack_count:
		0:
			print("Enemy has no attacks")
		1:
			print("One possible enemy attack.")
			var attack: Attack = possible_attacks[0]
			await get_tree().create_timer(0.5).timeout

			var enemy_piece: Piece = attack.attacking_piece
			enemy_piece.is_selected = true
			await get_tree().create_timer(0.5).timeout

			var player_piece: Piece = attack.attacked_piece
			var player_board_coord: Vector2i = _piece_to_board_coord[player_piece]
			await _move_piece(enemy_piece, player_board_coord)

			enemy_piece.is_selected = false
		_:
			print("Enemy has multiple attacks")
			var candidate_enemy_pieces: Array = []
			var candidate_player_pieces: Array = []
			for attack: Attack in possible_attacks:
				var enemy_piece: Piece = attack.attacking_piece
				if !candidate_enemy_pieces.has(enemy_piece):
					candidate_enemy_pieces.append(enemy_piece)

				var player_piece: Piece = attack.attacked_piece
				if !candidate_player_pieces.has(player_piece):
					candidate_player_pieces.append(player_piece)

			for piece: Piece in candidate_enemy_pieces:
				piece.is_selected = true

			await get_tree().create_timer(0.5).timeout

			candidate_enemy_pieces.sort_custom(_compare_pieces)
			var attacking_enemy_piece: Piece = candidate_enemy_pieces[0]
			var attacks_for_enemy_piece: Array = possible_attacks.filter(
				func(attack: Attack) -> bool: return attack.attacking_piece == attacking_enemy_piece
			)
			if attacks_for_enemy_piece.size() == 1:
				print("One attack, no further tiebreaking needed")
				var attack: Attack = attacks_for_enemy_piece[0]
				var enemy_piece: Piece = attack.attacking_piece
				for piece: Piece in candidate_enemy_pieces:
					piece.is_selected = piece == enemy_piece

				await get_tree().create_timer(0.5).timeout
				var player_piece: Piece = attack.attacked_piece
				var player_board_coord: Vector2i = _piece_to_board_coord[player_piece]
				await _move_piece(enemy_piece, player_board_coord)

				enemy_piece.is_selected = false
			else:
				print("Multiple attacks, further tiebreaking needed")
				candidate_player_pieces.sort_custom(_compare_pieces)
				var player_piece_to_attack: Piece = candidate_enemy_pieces[0]
				var attack_i: int = attacks_for_enemy_piece.find_custom(
					func(attack_for_enemy_piece: Attack) -> bool: return (
						attack_for_enemy_piece.attacked_piece == player_piece_to_attack
					)
				)
				var attack: Attack = attacks_for_enemy_piece[attack_i]
				var enemy_piece: Piece = attack.attacking_piece
				for piece: Piece in candidate_enemy_pieces:
					piece.is_selected = piece == enemy_piece

				await get_tree().create_timer(0.5).timeout

				var player_piece: Piece = attack.attacked_piece
				var player_board_coord: Vector2i = _piece_to_board_coord[player_piece]
				await _move_piece(enemy_piece, player_board_coord)

				enemy_piece.is_selected = false

	_is_player_turn = true


func _compare_pieces(piece_a: Piece, piece_b: Piece) -> bool:
	var piece_a_board_coord: Vector2i = get_board_coordinate(piece_a.global_position)
	var piece_b_board_coord: Vector2i = get_board_coordinate(piece_b.global_position)
	if piece_a_board_coord.y > piece_b_board_coord.y:
		return true

	if piece_a_board_coord.y < piece_b_board_coord.y:
		return false

	return piece_a_board_coord.x > piece_b_board_coord.x


func _on_reset_button_pressed() -> void:
	get_tree().reload_current_scene()
