@tool

class_name Bishop

extends Piece


func is_valid_move(from: Vector2i, to: Vector2i, pieces: Dictionary) -> bool:
	if from == to:
		return false

	var x_diff_magnitude: int = absi(from.x - to.x)
	var y_diff_magnitude: int = absi(from.y - to.y)
	if x_diff_magnitude != y_diff_magnitude:
		return false

	var min_x: int = min(from.x, to.x)
	var max_x: int = max(from.x, to.x)
	var min_y: int = min(from.y, to.y)
	var max_y: int = max(from.y, to.y)

	var diagonal_coords: Array = pieces.keys().filter(
		func(coords: Vector2i) -> bool: var diff: Vector2i = coords - from ; return (
			absi(diff.x) == absi(diff.y)
		)
	)
	var between_coords: Array = diagonal_coords.filter(
		func(coords: Vector2i) -> bool: return (
			coords.x > min_x && coords.x < max_x && coords.y > min_y && coords.y < max_y
		)
	)
	if !between_coords.is_empty():
		return false

	if pieces.has(to):
		var conflicting_piece: Piece = pieces[to]
		if conflicting_piece.is_player == is_player:
			return false

	return true
