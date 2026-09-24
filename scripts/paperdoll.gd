extends Node2D
## Layered 2D paperdoll. Same stack for every character; body set picks male or female.

const HAIR_MALE := [
	"res://assets/paperdoll/hair_short.svg",
	"res://assets/paperdoll/hair_brown.svg",
	"res://assets/paperdoll/hair_black.svg",
]
const HAIR_FEMALE := [
	"res://assets/paperdoll/hair_long_blonde.svg",
	"res://assets/paperdoll/hair_long_brown.svg",
	"res://assets/paperdoll/hair_long_black.svg",
]
const SHIRTS := [
	"res://assets/paperdoll/shirt_blue.svg",
	"res://assets/paperdoll/shirt_red.svg",
	"res://assets/paperdoll/shirt_green.svg",
]
const LOWER_MALE := [
	"res://assets/paperdoll/pants_navy.svg",
	"res://assets/paperdoll/pants_brown.svg",
]
const LOWER_FEMALE := [
	"res://assets/paperdoll/skirt_navy.svg",
	"res://assets/paperdoll/skirt_red.svg",
]
const BODY_MALE := "res://assets/paperdoll/body_male.svg"
const BODY_FEMALE := "res://assets/paperdoll/body_female.svg"

@onready var body: Sprite2D = $Body
@onready var pants: Sprite2D = $Pants
@onready var shirt: Sprite2D = $Shirt
@onready var shoes: Sprite2D = $Shoes
@onready var eyes: Sprite2D = $Eyes
@onready var hair: Sprite2D = $Hair

var female := false
var hair_i := 0
var shirt_i := 0
var pants_i := 0

func _ready() -> void:
	_apply()

func set_look(p_hair: int, p_shirt: int, p_pants: int, p_female: bool) -> void:
	female = p_female
	var hairs := _hairs()
	var lowers := _lowers()
	hair_i = posmod(p_hair, hairs.size())
	shirt_i = posmod(p_shirt, SHIRTS.size())
	pants_i = posmod(p_pants, lowers.size())
	_apply()

func cycle_hair() -> void:
	hair_i = (hair_i + 1) % _hairs().size()
	_apply()

func cycle_shirt() -> void:
	shirt_i = (shirt_i + 1) % SHIRTS.size()
	_apply()

func cycle_pants() -> void:
	pants_i = (pants_i + 1) % _lowers().size()
	_apply()

func _hairs() -> Array:
	return HAIR_FEMALE if female else HAIR_MALE

func _lowers() -> Array:
	return LOWER_FEMALE if female else LOWER_MALE

func _apply() -> void:
	if body:
		body.texture = load(BODY_FEMALE if female else BODY_MALE)
	if hair:
		hair.texture = load(_hairs()[hair_i])
	if shirt:
		shirt.texture = load(SHIRTS[shirt_i])
	if pants:
		pants.texture = load(_lowers()[pants_i])
