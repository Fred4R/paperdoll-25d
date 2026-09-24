extends Node2D
## Limb pivots. Stride 1.68–1.72 m and stance about 60% of the cycle in healthy adults.
## Arms swing opposite the same-side leg (Collins, Adamczyk & Kuo 2009).
## Knee: small bend after heel contact, near extension in midstance, about 60° in swing.
## Elbows stay bent, about 30–42°, instead of locking straight.

const STRIDE_M := 1.7
const STANCE := 0.6
const LEG_FWD := 0.35
const LEG_BACK := -0.2
const ARM_SWING := 0.38
const KNEE_HEEL := 0.05
const KNEE_LOAD := 0.31
const KNEE_MID := 0.09
const KNEE_PRE := 0.70
const KNEE_SWING := 1.05
const ELBOW_REST := 0.52

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
@onready var knee_l: Node2D = $LegL/Knee
@onready var knee_r: Node2D = $LegR/Knee
@onready var elbow_l: Node2D = $ArmL/Elbow
@onready var elbow_r: Node2D = $ArmR/Elbow

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
	var blend := minf(1.0, 8.0 * delta)
	if freq <= 0.0:
		_swing(leg_l, lerpf(leg_l.rotation, 0.0, blend))
		_swing(leg_r, lerpf(leg_r.rotation, 0.0, blend))
		_swing(arm_l, lerpf(arm_l.rotation, 0.0, blend))
		_swing(arm_r, lerpf(arm_r.rotation, 0.0, blend))
		_swing(knee_l, lerpf(knee_l.rotation, -KNEE_HEEL, blend))
		_swing(knee_r, lerpf(knee_r.rotation, KNEE_HEEL, blend))
		_swing(elbow_l, lerpf(elbow_l.rotation, ELBOW_REST, blend))
		_swing(elbow_r, lerpf(elbow_r.rotation, -ELBOW_REST, blend))
		return
	var left_phase := _phase
	var right_phase := fposmod(_phase + 0.5, 1.0)
	var left := _leg_angle(left_phase)
	var right := _leg_angle(right_phase)
	_swing(leg_l, left)
	_swing(leg_r, right)
	_swing(arm_l, -left * (ARM_SWING / LEG_FWD))
	_swing(arm_r, -right * (ARM_SWING / LEG_FWD))
	_swing(knee_l, -_knee_flex(left_phase))
	_swing(knee_r, _knee_flex(right_phase))
	_swing(elbow_l, _elbow_flex(right_phase))
	_swing(elbow_r, -_elbow_flex(left_phase))

func _leg_angle(phase: float) -> float:
	if phase < STANCE:
		return lerpf(LEG_FWD, LEG_BACK, phase / STANCE)
	return lerpf(LEG_BACK, LEG_FWD, (phase - STANCE) / (1.0 - STANCE))

func _knee_flex(phase: float) -> float:
	if phase < 0.12:
		return lerpf(KNEE_HEEL, KNEE_LOAD, phase / 0.12)
	if phase < 0.40:
		return lerpf(KNEE_LOAD, KNEE_MID, (phase - 0.12) / 0.28)
	if phase < STANCE:
		return lerpf(KNEE_MID, KNEE_PRE, (phase - 0.40) / (STANCE - 0.40))
	if phase < 0.78:
		return lerpf(KNEE_PRE, KNEE_SWING, (phase - STANCE) / (0.78 - STANCE))
	return lerpf(KNEE_SWING, KNEE_HEEL, (phase - 0.78) / 0.22)

func _elbow_flex(phase: float) -> float:
	var lift := 0.0
	if phase >= STANCE:
		lift = sin((phase - STANCE) / (1.0 - STANCE) * PI)
	return ELBOW_REST + 0.22 * lift

func _swing(pivot: Node2D, angle: float) -> void:
	if pivot:
		pivot.rotation = angle

func _hairs() -> Array:
	return HAIR_FEMALE if female else HAIR_MALE

func _lowers() -> Array:
	return LOWER_FEMALE if female else LOWER_MALE

func _apply() -> void:
	var arm_tex: Texture2D = load(ARM_FEMALE if female else ARM_MALE)
	var leg_tex: Texture2D = load(LEG_FEMALE if female else LEG_MALE)
	var pant_tex: Texture2D = load("res://assets/paperdoll/pant_leg.svg")
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
		var thigh: Sprite2D = pivot.get_node("Thigh")
		var shin: Sprite2D = pivot.get_node("Knee/Shin")
		thigh.texture = leg_tex
		shin.texture = leg_tex
		var mid := _half(thigh, true)
		_half(shin, false)
		pivot.get_node("Knee").position = Vector2(0, mid)
		var shoe: Sprite2D = pivot.get_node("Knee/Shoe")
		var shoe_size := shoe.texture.get_size()
		shoe.offset = Vector2(-shoe_size.x * 0.5, 0)
		shoe.position = Vector2(0, shin.region_rect.size.y - 2.0)
		var show_pants := not female
		for cloth_path in ["ThighCloth", "Knee/ShinCloth"]:
			var cloth: Sprite2D = pivot.get_node(cloth_path)
			cloth.texture = pant_tex
			cloth.visible = show_pants
			cloth.modulate = _lowers()[pants_i]
			_half(cloth, cloth_path == "ThighCloth")
	for pivot in [arm_l, arm_r]:
		if pivot == null:
			continue
		var upper: Sprite2D = pivot.get_node("Upper")
		var forearm: Sprite2D = pivot.get_node("Elbow/Forearm")
		upper.texture = arm_tex
		forearm.texture = arm_tex
		var mid := _half(upper, true)
		_half(forearm, false)
		pivot.get_node("Elbow").position = Vector2(0, mid)
		var sleeve: Sprite2D = pivot.get_node("Sleeve")
		sleeve.modulate = SHIRT_COLORS[shirt_i]
		var sleeve_size := sleeve.texture.get_size()
		sleeve.offset = Vector2(-sleeve_size.x * 0.5, 0)

func _half(sprite: Sprite2D, top: bool) -> float:
	var size := sprite.texture.get_size()
	var mid := size.y * 0.5
	sprite.centered = false
	sprite.region_enabled = true
	if top:
		sprite.region_rect = Rect2(0, 0, size.x, mid)
	else:
		sprite.region_rect = Rect2(0, mid, size.x, size.y - mid)
	sprite.offset = Vector2(-size.x * 0.5, 0)
	return mid
