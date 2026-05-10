@tool

class_name Rook

extends Piece


func is_valid_move(from: Vector2i, to: Vector2i, pieces: Dictionary) -> bool:
	if from == to:
		return false

	if from.x == to.x:
		var min_y: int = min(from.y, to.y)
		var max_y: int = max(from.y, to.y)
		var between_coords: Array = pieces.keys().filter(
			func(coords: Vector2i) -> bool: return (
				coords.x == to.x && coords.y > min_y && coords.y < max_y
			)
		)
		if !between_coords.is_empty():
			return false
	elif from.y == to.y:
		var min_x: int = min(from.x, to.x)
		var max_x: int = max(from.x, to.x)
		var between_coords: Array = pieces.keys().filter(
			func(coords: Vector2i) -> bool: return (
				coords.y == to.y && coords.x > min_x && coords.x < max_x
			)
		)
		if !between_coords.is_empty():
			return false
	else:
		return false

	if pieces.has(to):
		var conflicting_piece: Piece = pieces[to]
		if conflicting_piece.is_player == is_player:
			return false

	return true
