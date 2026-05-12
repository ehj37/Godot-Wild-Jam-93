class_name PawnPromotionDialog

extends PanelContainer

signal piece_type_picked(piece_type: PieceType)

enum PieceType { QUEEN, ROOK, BISHOP, KNIGHT }


func _on_queen_button_pressed() -> void:
	piece_type_picked.emit(PieceType.QUEEN)


func _on_rook_button_pressed() -> void:
	piece_type_picked.emit(PieceType.ROOK)


func _on_bishop_button_pressed() -> void:
	piece_type_picked.emit(PieceType.BISHOP)


func _on_knight_button_pressed() -> void:
	piece_type_picked.emit(PieceType.KNIGHT)
