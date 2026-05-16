class_name BountyBoard

extends PanelContainer

const FIRST_NAMES: Array[String] = [
	"STEAMBOAT",
	"TUG",
	"NELSON",
	"TUCKER",
	"JOHN",
	"WILLIAM",
	"JAMES",
	"GEORGE",
	"CHARLES",
	"HENRY",
	"WALTER",
	"WYATT",
	"SKIP",
	"TUNGSTEN",
	"EDWARD",
	"CLARENCE",
	"ERNEST",
	"DUTCH",
	"ROBINSON",
	"ELLIOTT",
	"SAMUEL"
]

const LAST_NAMES: Array[String] = [
	"O'DOYLE",
	"SMITH",
	"BROWN",
	"CLARK",
	"ROBINSON",
	"KELLY",
	"EVANS",
	"ROGERS",
	"MORRIS",
	"FISCHER",
	"ELLIS",
	"SULLIVAN",
	"PRICE",
	"CHAPMAN",
	"NELSON",
	"WEBSTER",
	"BUTLER",
	"SANDERS",
	"COBB",
	"GRIMES",
	"KELLEY",
	"ELLIOTT"
]

const CRIMES: Array[String] = [
	"STOLE PACK OF GUM",
	"LOITERING",
	"COW TIPPING",
	"TAX EVASION",
	"FROG CRIMES",
	"SHENANIGANS",
	"ARSON",
	"BANK ROBBERY",
	"NEFARIOUS DEEDS",
	"INSIDER TRADING",
	"HORSE THEFT",
	"CACTUS VANDALISM",
	"TRAIN ROBBERY",
	"SPEEDING (ON HORSE)",
	"MOONSHININ",
	"INDECENT LANGUAGE",
	"RIGGED POKER",
	"KIDNAPPED DAMSEL",
	"WITCHCRAFT",
	"BEIN NO GOOD",
	"TOMFOOLERY",
]

var _piece_to_bounty: Dictionary = {}

@onready var _bounty_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/bounty.tscn"
)
@onready var _bishop_icon_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/icons/bishop_bounty_icon/bishop_bounty_icon.tscn"
)
@onready var _king_icon_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/icons/king_bounty_icon/king_bounty_icon.tscn"
)
@onready var _knight_icon_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/icons/knight_bounty_icon/knight_bounty_icon.tscn"
)
@onready var _pawn_icon_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/icons/pawn_bounty_icon/pawn_bounty_icon.tscn"
)
@onready var _queen_icon_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/icons/queen_bounty_icon/queen_bounty_icon.tscn"
)
@onready var _rook_icon_packed_scene: PackedScene = preload(
	"res://scenes/board/bounty_board/bounty/icons/rook_bounty_icon/rook_bounty_icon.tscn"
)
@onready var _bounties_container: VBoxContainer = $MarginContainer/VBoxContainer/BountiesContainer


func add_bounty(piece: Piece, board_coordinate: Vector2i) -> void:
	var bounty: Bounty = _bounty_packed_scene.instantiate()
	_bounties_container.add_child(bounty)
	_piece_to_bounty[piece] = bounty

	var piece_type: Board.PieceType = Board.piece_to_type(piece)
	var piece_icon_packed_scene: PackedScene
	match piece_type:
		Board.PieceType.PAWN:
			piece_icon_packed_scene = _pawn_icon_packed_scene
		Board.PieceType.ROOK:
			piece_icon_packed_scene = _rook_icon_packed_scene
		Board.PieceType.KNIGHT:
			piece_icon_packed_scene = _knight_icon_packed_scene
		Board.PieceType.BISHOP:
			piece_icon_packed_scene = _bishop_icon_packed_scene
		Board.PieceType.QUEEN:
			piece_icon_packed_scene = _queen_icon_packed_scene
		Board.PieceType.KING:
			piece_icon_packed_scene = _king_icon_packed_scene
		_:
			push_error("Unhandled piece type in BountyBoard#add_bounty")

	var piece_icon: Sprite2D = piece_icon_packed_scene.instantiate()
	bounty.set_icon(piece_icon)
	bounty.set_piece_name(_random_name())
	bounty.set_crime(_random_crime())

	var board_coordinate_in_notation: String = Board.board_coordinate_to_notation(board_coordinate)
	bounty.set_last_seen(board_coordinate_in_notation)
	bounty.set_last_seen(board_coordinate_in_notation)


func update_bounty_last_seen(piece: Piece, new_board_coordinate: Vector2i) -> void:
	var bounty: Bounty = _piece_to_bounty.get(piece)
	if !bounty:
		push_warning("Attempted to update last seen for a piece without a tracked bounty.")
		return

	var board_coordinate_in_notation: String = Board.board_coordinate_to_notation(
		new_board_coordinate
	)
	bounty.set_last_seen(board_coordinate_in_notation)


func claim_bounty(piece: Piece) -> void:
	var bounty: Bounty = _piece_to_bounty.get(piece)
	if !bounty:
		push_warning("Attempted to claim bounty for a piece without a tracked bounty.")
		return

	bounty.mark_as_eliminated()
	bounty.set_last_seen("SIX FEET DEEP")


func _random_name() -> String:
	var random_first_name: String = FIRST_NAMES.pick_random()
	var random_last_name: String = LAST_NAMES.pick_random()
	return random_first_name + " " + random_last_name


func _random_crime() -> String:
	return CRIMES.pick_random()
