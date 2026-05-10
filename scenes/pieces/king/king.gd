@tool

class_name King

extends Piece


func is_valid_move(from: Vector2i, to: Vector2i, pieces: Dictionary) -> bool:
	if from == to:
		return false

	var x_diff_magnitude: int = absi(from.x - to.x)
	var y_diff_magnitude: int = absi(from.y - to.y)
	if x_diff_magnitude > 1 || y_diff_magnitude > 1:
		return false

	if pieces.has(to):
		var conflicting_piece: Piece = pieces[to]
		if conflicting_piece.is_player == is_player:
			return false

	return true
