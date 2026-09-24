extends Node2D
## Layered 2D paperdoll. Swap textures on named Sprite2D children.

const HAIR := [
	"res://assets/paperdoll/hair_blonde.svg",
	"res://assets/paperdoll/hair_brown.svg",
	"res://assets/paperdoll/hair_black.svg",
]
const SHIRTS := [
	"res://assets/paperdoll/shirt_blue.svg",
	"res://assets/paperdoll/shirt_red.svg",
	"res://assets/paperdoll/shirt_green.svg",
]
const PANTS := [
	"res://assets/paperdoll/pants_navy.svg",
	"res://assets/paperdoll/pants_brown.svg",
]

@onready var body: Sprite2D = $Body
@onready var pants: Sprite2D = $Pants
@onready var shirt: Sprite2D = $Shirt
@onready var shoes: Sprite2D = $Shoes
@onready var eyes: Sprite2D = $Eyes
@onready var hair: Sprite2D = $Hair

var hair_i := 0
var shirt_i := 0
var pants_i := 0

func _ready() -> void:
	_apply()

func set_look(p_hair: int, p_shirt: int, p_pants: int) -> void:
	hair_i = p_hair % HAIR.size()
	shirt_i = p_shirt % SHIRTS.size()
	pants_i = p_pants % PANTS.size()
	_apply()

func cycle_hair() -> void:
	hair_i = (hair_i + 1) % HAIR.size()
	_apply()

func cycle_shirt() -> void:
	shirt_i = (shirt_i + 1) % SHIRTS.size()
	_apply()

func cycle_pants() -> void:
	pants_i = (pants_i + 1) % PANTS.size()
	_apply()

func _apply() -> void:
	if hair:
		hair.texture = load(HAIR[hair_i])
	if shirt:
		shirt.texture = load(SHIRTS[shirt_i])
	if pants:
		pants.texture = load(PANTS[pants_i])
