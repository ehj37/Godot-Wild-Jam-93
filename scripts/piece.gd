@tool

class_name Piece

extends Node2D

enum Modifier { NONE, TARGET, VIP }

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
	"CHEATIN AT POKER",
	"KIDNAPPED DAMSEL",
	"WITCHCRAFT",
	"BEIN NO GOOD",
	"TOMFOOLERY",
	"TOWN HALL GRAFFITI",
	"DOUBLE CROSSIN",
	"FIBBIN",
	"TELLIN TALL TALES",
	"BLACKMAILIN",
	"TWO STEPPIN",
	"SCALLYWAGGIN",
	"SKULLDUGGERY",
	"GRAVE PILLAGIN",
	"THIEVIN",
	"PUBLIC INTOXICATION",
	"PARKIN TICKETS",
	"SNAKE OIL PEDDLIN"
]

const FLASH_DURATION: float = 0.5

@export var is_player: bool = false:
	set(new_value):
		is_player = new_value
		_set_palette()

@export var modifier: Modifier:
	set(new_value):
		modifier = new_value
		_set_particles()

var is_selected: bool = false:
	set(new_value):
		is_selected = new_value
		_set_selected_indicator()

var full_name: String
var crime: String

@onready var _flash_color_rect: ColorRect = $Sprite2D/FlashColorRect
@onready var _flash_audio_stream: AudioStreamOggVorbis = preload("res://audio_streams/flash.ogg")


func is_target() -> bool:
	return modifier == Modifier.TARGET


func is_vip() -> bool:
	return modifier == Modifier.VIP


func is_valid_move(_from: Vector2i, _to: Vector2i, _pieces_by_board_coordinate: Dictionary) -> bool:
	return false


func flash() -> void:
	var alpha_tween: Tween = create_tween()
	_flash_color_rect.color.a = 1.0
	alpha_tween.tween_property(_flash_color_rect, "color:a", 0.0, FLASH_DURATION)
	AudioManager.play_effect(_flash_audio_stream)


func _ready() -> void:
	_set_palette()
	_set_selected_indicator()
	_set_particles()

	full_name = _random_name()
	if is_target():
		crime = _random_crime()


func _set_palette() -> void:
	var sprite: Sprite2D = $Sprite2D
	var shader_material: ShaderMaterial = sprite.material
	shader_material.set_shader_parameter("is_enabled", !is_player)


func _set_particles() -> void:
	var modifier_fire_back: ModifierFire = $ModifierFireBack
	var modifier_fire_front: ModifierFire = $ModifierFireFront
	if modifier == Modifier.NONE:
		modifier_fire_back.set_emitting(false)
		modifier_fire_front.set_emitting(false)
	elif is_target():
		modifier_fire_back.set_emitting(true)
		modifier_fire_front.set_emitting(true)
		modifier_fire_back.modifier = ModifierFire.Modifier.TARGET
		modifier_fire_front.modifier = ModifierFire.Modifier.TARGET
	elif is_vip():
		modifier_fire_back.set_emitting(true)
		modifier_fire_front.set_emitting(true)
		modifier_fire_back.modifier = ModifierFire.Modifier.VIP
		modifier_fire_front.modifier = ModifierFire.Modifier.VIP


func _set_selected_indicator() -> void:
	var selected_indicator: Sprite2D = $SelectedIndicator
	selected_indicator.visible = is_selected


func _random_name() -> String:
	var random_first_name: String = FIRST_NAMES.pick_random()
	var random_last_name: String = LAST_NAMES.pick_random()
	return random_first_name + " " + random_last_name


func _random_crime() -> String:
	return CRIMES.pick_random()
