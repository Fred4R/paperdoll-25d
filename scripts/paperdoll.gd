extends Node2D
## Limb pivots. Gait timing from healthy-adult ranges, not a clinical model.
## Stride 1.68–1.72 m and stance about 60% of the cycle in healthy adults.
## Arms swing opposite the same-side leg (Collins, Adamczyk & Kuo 2009).

const STRIDE_M := 1.7
const STANCE := 0.6
const LEG_FWD := 0.35
const LEG_BACK := -0.2
const ARM_SWING := 0.38

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
const SHIRT_COLORS := [
	Color("4682c8"),
	Color("be3c3c"),
	Color("3c8c50"),
]
const LOWER_MALE := [
	Color("28325a"),
	Color("6e4b28"),
]
const LOWER_FEMALE := [
	Color("28325a"),
	Color("8c2430"),
]
const BODY_MALE := "res://assets/paperdoll/body_male.svg"
const BODY_FEMALE := "res://assets/paperdoll/body_female.svg"
const ARM_MALE := "res://assets/paperdoll/arm_male.svg"
const ARM_FEMALE := "res://assets/paperdoll/arm_female.svg"
const LEG_MALE := "res://assets/paperdoll/leg_male.svg"
const LEG_FEMALE := "res://assets/paperdoll/leg_female.svg"

@onready var body: Sprite2D = $Body
@onready var shirt: Sprite2D = $Shirt
@onready var skirt: Sprite2D = $Skirt
@onready var eyes: Sprite2D = $Eyes
@onready var hair: Sprite2D = $Hair
@onready var leg_l: Node2D = $LegL
@onready var leg_r: Node2D = $LegR
@onready var arm_l: Node2D = $ArmL
@onready var arm_r: Node2D = $ArmR

var female := false
var hair_i := 0
var shirt_i := 0
var pants_i := 0
var _phase := 0.0

func _ready() -> void:
	_apply()

func set_look(p_hair: int, p_shirt: int, p_pants: int, p_female: bool) -> void:
	female = p_female
	hair_i = posmod(p_hair, _hairs().size())
	shirt_i = posmod(p_shirt, SHIRT_COLORS.size())
	pants_i = posmod(p_pants, _lowers().size())
	_apply()

func cycle_hair() -> void:
	hair_i = (hair_i + 1) % _hairs().size()
	_apply()

func cycle_shirt() -> void:
	shirt_i = (shirt_i + 1) % SHIRT_COLORS.size()
	_apply()

func cycle_pants() -> void:
	pants_i = (pants_i + 1) % _lowers().size()
	_apply()

func drive(speed_mps: float, delta: float) -> void:
	var freq := 0.0
	if speed_mps > 0.2:
		freq = speed_mps / STRIDE_M
	_phase = fposmod(_phase + freq * delta, 1.0)
	if freq <= 0.0:
		for pivot in [leg_l, leg_r, arm_l, arm_r]:
			if pivot:
				pivot.rotation = lerpf(pivot.rotation, 0.0, minf(1.0, 8.0 * delta))
		return
	var left := _leg_angle(_phase)
	var right := _leg_angle(fposmod(_phase + 0.5, 1.0))
	_swing(leg_l, left)
	_swing(leg_r, right)
	_swing(arm_l, -left * (ARM_SWING / LEG_FWD))
	_swing(arm_r, -right * (ARM_SWING / LEG_FWD))

func _leg_angle(phase: float) -> float:
	if phase < STANCE:
		return lerpf(LEG_FWD, LEG_BACK, phase / STANCE)
	return lerpf(LEG_BACK, LEG_FWD, (phase - STANCE) / (1.0 - STANCE))

func _swing(pivot: Node2D, angle: float) -> void:
	if pivot:
		pivot.rotation = angle

func _hairs() -> Array:
	return HAIR_FEMALE if female else HAIR_MALE

func _lowers() -> Array:
	return LOWER_FEMALE if female else LOWER_MALE

func _apply() -> void:
	var arm_tex := load(ARM_FEMALE if female else ARM_MALE)
	var leg_tex := load(LEG_FEMALE if female else LEG_MALE)
	if body:
		body.texture = load(BODY_FEMALE if female else BODY_MALE)
	if hair:
		hair.texture = load(_hairs()[hair_i])
	if shirt:
		shirt.modulate = SHIRT_COLORS[shirt_i]
	if skirt:
		skirt.visible = female
		skirt.modulate = _lowers()[pants_i]
	for pivot in [leg_l, leg_r]:
		if pivot == null:
			continue
		pivot.get_node("Skin").texture = leg_tex
		var cloth: Sprite2D = pivot.get_node("Cloth")
		cloth.visible = not female
		cloth.modulate = _lowers()[pants_i]
	for pivot in [arm_l, arm_r]:
		if pivot == null:
			continue
		pivot.get_node("Skin").texture = arm_tex
		pivot.get_node("Sleeve").modulate = SHIRT_COLORS[shirt_i]
