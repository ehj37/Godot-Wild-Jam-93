@tool

class_name Knight

extends Piece


func is_valid_move(from: Vector2i, to: Vector2i, pieces: Dictionary) -> bool:
	var diff: Vector2i = abs(from - to)
	if !(diff.x == 1 && diff.y == 2 || diff.x == 2 && diff.y == 1):
		return false

	if pieces.has(to):
		var conflicting_piece: Piece = pieces[to]
		if conflicting_piece.is_player == is_player:
			return false

	return true
