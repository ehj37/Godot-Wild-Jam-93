@tool

class_name Piece

extends Node2D

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
	"COW TIPPIN",
	"TAX EVASION",
	"FROG CRIMES",
	"SHENANIGANS",
	"ARSON",
	"BANK ROBBERY",
	"NEFARIOUS DEEDS",
	"INSIDER TRADIN",
	"HORSE THEFT",
	"CACTUS VANDALISM",
	"TRAIN ROBBERY",
	"SPEEDIN (ON HORSE)",
	"MOONSHININ",
	"INDECENT LANGUAGE",
	"RIGGED POKER",
	"KIDNAPPED DAMSEL",
	"WITCHCRAFT",
	"BEIN NO GOOD",
	"TOMFOOLERY",
	"TOWN HALL GRAFFITI",
	"DOUBLE CROSSIN",
	"FIBBIN",
	"TELLIN TALL TALES",
	"BLACKMAILIN",
	"TWO STEPPIN"
]

@export var is_player: bool = false:
	set(new_value):
		is_player = new_value
		_set_palette()

@export var is_target: bool = false:
	set(new_value):
		is_target = new_value
		_set_target_particles()

var is_selected: bool = false:
	set(new_value):
		is_selected = new_value
		_set_selected_indicator()

var full_name: String
var crime: String


func is_valid_move(_from: Vector2i, _to: Vector2i, _pieces: Dictionary) -> bool:
	return false


func _ready() -> void:
	_set_palette()
	_set_target_particles()
	_set_selected_indicator()

	full_name = _random_name()
	if is_target:
		crime = _random_crime()


func _set_palette() -> void:
	var sprite: Sprite2D = $Sprite2D
	var shader_material: ShaderMaterial = sprite.material
	shader_material.set_shader_parameter("is_enabled", !is_player)


func _set_target_particles() -> void:
	var target_fire_back: TargetFire = $TargetFireBack
	var target_fire_front: TargetFire = $TargetFireFront
	target_fire_back.set_emitting(is_target)
	target_fire_front.set_emitting(is_target)


func _set_selected_indicator() -> void:
	var selected_indicator: Sprite2D = $SelectedIndicator
	selected_indicator.visible = is_selected


func _random_name() -> String:
	var random_first_name: String = FIRST_NAMES.pick_random()
	var random_last_name: String = LAST_NAMES.pick_random()
	return random_first_name + " " + random_last_name


func _random_crime() -> String:
	return CRIMES.pick_random()
