class_name Board

extends Sprite2D


class EnemyAttack:
	var enemy_piece: Piece
	var player_piece: Piece

	@warning_ignore("shadowed_variable")

	func _init(enemy_piece: Piece, player_piece: Piece) -> void:
		self.enemy_piece = enemy_piece
		self.player_piece = player_piece


const CELL_SIDE_LENGTH: int = 42
const ORIGIN: Vector2i = Vector2i(-4 * CELL_SIDE_LENGTH, 4 * CELL_SIDE_LENGTH)

var _pieces: Dictionary = {}
var _selected_piece: Piece
var _is_player_turn: bool = true

@onready var _queen_packed_scene: PackedScene = preload("res://scenes/pieces/queen/queen.tscn")
@onready var _rook_packed_scene: PackedScene = preload("res://scenes/pieces/rook/rook.tscn")
@onready var _bishop_packed_scene: PackedScene = preload("res://scenes/pieces/bishop/bishop.tscn")
@onready var _knight_packed_scene: PackedScene = preload("res://scenes/pieces/knight/knight.tscn")
@onready var _pawn_promotion_dialog: PawnPromotionDialog = $PawnPromotionDialog


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
			var mouse_position: Vector2 = get_global_mouse_position()
			var mouse_board_coordinate: Vector2i = get_board_coordinate(mouse_position)
			if event_mouse_button.pressed:
				if _selected_piece:
					if mouse_board_coordinate != Vector2i(-1, -1):
						var current_board_coordinate: Vector2i = get_board_coordinate(
							_selected_piece.global_position
						)
						var is_valid_move: bool = _selected_piece.is_valid_move(
							current_board_coordinate, mouse_board_coordinate, _pieces
						)
						if is_valid_move:
							_move_piece(_selected_piece, mouse_board_coordinate)
							if _win_condition_met():
								print("TODO: Level beaten, do something")
							else:
								_is_player_turn = false
								_take_enemy_turn()

					_selected_piece = null
			else:
				if !_selected_piece:
					var piece_at_mouse: Piece = _pieces.get(mouse_board_coordinate)
					if piece_at_mouse && piece_at_mouse.is_player:
						_selected_piece = _pieces.get(mouse_board_coordinate)


func _ready() -> void:
	var pieces: Array = find_children("*", "Piece", true, false)
	for piece: Piece in pieces:
		var board_coordinates: Vector2i = get_board_coordinate(piece.global_position)
		_pieces[board_coordinates] = piece

	_pawn_promotion_dialog.visible = false


func _move_piece(piece: Piece, new_board_coordinate: Vector2i) -> void:
	var piece_to_remove: Piece = _pieces.get(new_board_coordinate)
	if piece_to_remove:
		_pieces.erase(new_board_coordinate)
		piece_to_remove.queue_free()

	var current_board_coordinate: Vector2i = get_board_coordinate(piece.global_position)
	_pieces.erase(current_board_coordinate)

	var new_global_position: Vector2 = get_global_position_from_board_coordinate(
		new_board_coordinate
	)

	piece.global_position = get_global_position_from_board_coordinate(new_board_coordinate)
	_pieces[new_board_coordinate] = piece

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
			piece.get_parent().add_child(promotion_piece)
			piece.queue_free()
			promotion_piece.global_position = new_global_position
			_pieces[new_board_coordinate] = promotion_piece
		elif !piece.is_player && new_board_coordinate.y == 0:
			var queen: Queen = _queen_packed_scene.instantiate()
			queen.is_player = false
			queen.is_target = piece.is_target
			piece.get_parent().add_child(queen)
			piece.queue_free()
			queen.global_position = new_global_position
			_pieces[new_board_coordinate] = queen


func _win_condition_met() -> bool:
	var target_pieces: Array = _pieces.values().filter(
		func(piece: Piece) -> bool: return piece.is_target
	)
	return target_pieces.is_empty()


func _take_enemy_turn() -> void:
	var player_pieces: Array = _pieces.values().filter(
		func(piece: Piece) -> bool: return piece.is_player
	)
	var enemy_pieces: Array = _pieces.values().filter(
		func(piece: Piece) -> bool: return !piece.is_player
	)
	var piece_to_board_coord: Dictionary = {}

	# Gross, but should be fine in practice. It's an 8x8 grid with generally few
	# player pieces.
	var possible_attacks: Array[EnemyAttack] = []
	for player_piece: Piece in player_pieces:
		var player_board_coord: Vector2i = get_board_coordinate(player_piece.global_position)
		piece_to_board_coord[player_piece] = player_board_coord
		for enemy_piece: Piece in enemy_pieces:
			var enemy_board_coord: Vector2i
			if piece_to_board_coord.has(enemy_piece):
				enemy_board_coord = piece_to_board_coord[enemy_piece]
			else:
				enemy_board_coord = get_board_coordinate(enemy_piece.global_position)
				piece_to_board_coord[enemy_piece] = enemy_board_coord

			if enemy_piece.is_valid_move(enemy_board_coord, player_board_coord, _pieces):
				possible_attacks.append(EnemyAttack.new(enemy_piece, player_piece))

	var possible_attack_count: int = possible_attacks.size()
	match possible_attack_count:
		0:
			print("Enemy has no attacks")
		1:
			print("One possible enemy attack.")
			var attack: EnemyAttack = possible_attacks[0]
			var player_board_coord: Vector2i = piece_to_board_coord[attack.player_piece]
			_move_piece(attack.enemy_piece, player_board_coord)
		_:
			print("Enemy has multiple attacks")
			var candidate_enemy_pieces: Array = []
			var candidate_player_pieces: Array = []
			for attack: EnemyAttack in possible_attacks:
				if !candidate_enemy_pieces.has(attack.enemy_piece):
					candidate_enemy_pieces.append(attack.enemy_piece)

				if !candidate_player_pieces.has(attack.player_piece):
					candidate_player_pieces.append(attack.player_piece)

			candidate_enemy_pieces.sort_custom(_compare_pieces)
			var attacking_enemy_piece: Piece = candidate_enemy_pieces[0]
			var attacks_for_enemy_piece: Array = possible_attacks.filter(
				func(attack: EnemyAttack) -> bool: return (
					attack.enemy_piece == attacking_enemy_piece
				)
			)
			if attacks_for_enemy_piece.size() == 1:
				print("One attack, no further tiebreaking needed")
				var attack: EnemyAttack = attacks_for_enemy_piece[0]
				var player_board_coord: Vector2i = piece_to_board_coord[attack.player_piece]
				_move_piece(attack.enemy_piece, player_board_coord)
			else:
				print("Multiple attacks, further tiebreaking needed")
				candidate_player_pieces.sort_custom(_compare_pieces)
				var player_piece_to_attack: Piece = candidate_enemy_pieces[0]
				var attack_i: int = attacks_for_enemy_piece.find_custom(
					func(attack_for_enemy_piece: EnemyAttack) -> bool: return (
						attack_for_enemy_piece.player_piece == player_piece_to_attack
					)
				)
				var attack: EnemyAttack = attacks_for_enemy_piece[attack_i]
				var player_board_coord: Vector2i = piece_to_board_coord[attack.player_piece]
				_move_piece(attack.enemy_piece, player_board_coord)

	_is_player_turn = true


func _compare_pieces(piece_a: Piece, piece_b: Piece) -> bool:
	var piece_a_board_coord: Vector2i = get_board_coordinate(piece_a.global_position)
	var piece_b_board_coord: Vector2i = get_board_coordinate(piece_b.global_position)
	if piece_a_board_coord.y > piece_b_board_coord.y:
		return true

	if piece_a_board_coord.y < piece_b_board_coord.y:
		return false

	return piece_a_board_coord.x > piece_b_board_coord.x
