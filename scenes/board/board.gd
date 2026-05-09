class_name Board

extends Node2D

const CELL_SIDE_LENGTH: int = 42
const ORIGIN: Vector2i = Vector2i(-4 * CELL_SIDE_LENGTH, 4 * CELL_SIDE_LENGTH)

var _pieces: Dictionary = {}
var _selected_piece: Piece


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
	if event is InputEventMouseButton:
		var event_mouse_button: InputEventMouseButton = event
		if event_mouse_button.button_index == MOUSE_BUTTON_LEFT:
			var mouse_position: Vector2 = get_global_mouse_position()
			var board_coordinate: Vector2i = get_board_coordinate(mouse_position)
			if event_mouse_button.pressed:
				if _selected_piece:
					if board_coordinate == Vector2i(-1, -1) || _pieces.has(board_coordinate):
						pass
					else:
						var current_board_coordinate: Vector2i = get_board_coordinate(
							_selected_piece.global_position
						)
						_pieces.erase(current_board_coordinate)
						_pieces[board_coordinate] = _selected_piece
						_selected_piece.global_position = get_global_position_from_board_coordinate(
							board_coordinate
						)

					_selected_piece = null
			else:
				if !_selected_piece:
					_selected_piece = _pieces.get(board_coordinate, null)


func _ready() -> void:
	for child: Node2D in get_children():
		if child is Piece:
			var board_coordinates: Vector2i = get_board_coordinate(child.global_position)
			_pieces[board_coordinates] = child
