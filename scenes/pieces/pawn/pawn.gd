@tool

class_name Pawn

extends Piece


# gdlint:disable = max-returns
func is_valid_move(from: Vector2i, to: Vector2i, pieces: Dictionary) -> bool:
	if from.y == to.y:
		return false

	if from.y > to.y:
		if is_player:
			return false

	if from.y < to.y:
		if !is_player:
			return false

	var y_diff_magnitude: int = absi(from.y - to.y)
	if y_diff_magnitude == 2:
		if from.x != to.x:
			return false

		if is_player:
			if from.y == 1:
				if pieces.has(Vector2i(from.x, 2)):
					return false
			else:
				return false
		else:
			if from.y == 6:
				if pieces.has(Vector2i(from.x, 5)):
					return false
			else:
				return false

		if pieces.has(to):
			return false
	elif y_diff_magnitude == 1:
		var x_diff_magnitude: int = absi(from.x - to.x)
		match x_diff_magnitude:
			0:
				if pieces.has(to):
					return false
			1:
				if pieces.has(to):
					var conflicting_piece: Piece = pieces[to]
					if conflicting_piece.is_player == is_player:
						return false
				else:
					return false
			_:
				return false
	else:
		return false

	return true
