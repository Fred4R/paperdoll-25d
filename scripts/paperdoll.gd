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
	"res://assets/paperdoll/front/hair_m.svg",
]
const HAIR_FEMALE := [
	"res://assets/paperdoll/front/hair_f.svg",
	"res://assets/paperdoll/front/hair_f_auburn.svg",
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
const BODY_MALE := "res://assets/paperdoll/front/body_m.svg"
const BODY_FEMALE := "res://assets/paperdoll/front/body_f.svg"
const ARM_MALE := "res://assets/paperdoll/front/arm_m.svg"
const ARM_FEMALE := "res://assets/paperdoll/front/arm_f.svg"
const LEG_MALE := "res://assets/paperdoll/front/leg_m.svg"
const LEG_FEMALE := "res://assets/paperdoll/front/leg_f.svg"
const FACE_FEMALE := "res://assets/paperdoll/front/face_f.svg"
const FACE_MALE := "res://assets/paperdoll/front/face_m.svg"
const SHIRT_FRONT_F := "res://assets/paperdoll/front/shirt_f.svg"
const SHIRT_FRONT_M := "res://assets/paperdoll/front/shirt_m.svg"
const SKIRT_FRONT_F := "res://assets/paperdoll/front/skirt_f.svg"
const SLEEVE_FRONT_F := "res://assets/paperdoll/front/sleeve_f.svg"
const SLEEVE_FRONT_M := "res://assets/paperdoll/front/sleeve_m.svg"
const SHOE_FRONT_F := "res://assets/paperdoll/front/shoe_f.svg"
const SHOE_FRONT_M := "res://assets/paperdoll/front/shoe_m.svg"

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

var palette_name := "player"
var _palette: Dictionary = {}
var hair_i := 0
var shirt_i := 0
var pants_i := 0
var _phase := 0.0
var _clip_locked := false
var _side := false
var _back := false
var hair_pivot: Node2D
var _ik: Node2D
var _face_smile := 0.0
var _ease := 1.0
var _ease_from: Dictionary = {}
var hair_tint := Color.WHITE
var nude := false

const PIVOT_NODES := {
	"arm_l": "ArmL",
	"arm_r": "ArmR",
	"elbow_l": "ArmL/Elbow",
	"elbow_r": "ArmR/Elbow",
	"leg_l": "LegL",
	"leg_r": "LegR",
	"knee_l": "LegL/Knee",
	"knee_r": "LegR/Knee",
}

func _ready() -> void:
	hair_pivot = Node2D.new()
	hair_pivot.name = "HairPivot"
	hair_pivot.position = Vector2(64, 20)
	add_child(hair_pivot)
	if hair:
		var kept := hair.position
		hair.reparent(hair_pivot)
		hair.position = kept - hair_pivot.position
	_ik = load("res://scripts/arm_ik.gd").new()
	_ik.name = "ArmIK"
	add_child(_ik)
	_apply()

func set_palette(name: String) -> void:
	palette_name = name
	var file := FileAccess.open("res://data/palettes.json", FileAccess.READ)
	if file == null:
		return
	var all: Dictionary = JSON.parse_string(file.get_as_text())
	_palette = all.get(name, {})
	female = bool(_palette.get("has_skirt", false))
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
	if _clip_locked:
		return
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
		_swing_hair(0.0, blend)
		return
	var left_phase := _phase
	var right_phase := fposmod(_phase + 0.5, 1.0)
	var left := _leg_angle(left_phase)
	var right := _leg_angle(right_phase)
	_swing(leg_l, left)
	_swing(leg_r, right)
	_swing(arm_l, -left * (ARM_SWING / LEG_FWD))
	_swing(arm_r, -right * (ARM_SWING / LEG_FWD))
	# Left shin folds toward the midline (negative). Right shin folds the other way.
	_swing(knee_l, -_knee_flex(left_phase))
	_swing(knee_r, _knee_flex(right_phase))
	_swing(elbow_l, _elbow_flex(right_phase))
	_swing(elbow_r, -_elbow_flex(left_phase))
	_swing_hair(sin(_phase * TAU) * 0.12, blend)

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

func set_hand_targets(left: Vector2, right: Vector2) -> void:
	if _ik:
		_ik.set_targets(left, right)

func nudge_target(hand: String, delta: Vector2) -> void:
	if _ik == null:
		return
	if hand == "hand_l":
		_ik.target_l += delta
	else:
		_ik.target_r += delta
	_ik._place_marks()

func selected_target(hand: String) -> Vector2:
	if _ik == null:
		return Vector2.ZERO
	return _ik.target_l if hand == "hand_l" else _ik.target_r

func set_ik_enabled(enabled: bool) -> void:
	if _ik:
		_ik.set_ik(enabled and not _side and not _back)

func set_target_marks(show: bool) -> void:
	if _ik:
		_ik.set_marks(show)

func set_face_blend(smile: float) -> void:
	_face_smile = clampf(smile, 0.0, 1.0)
	_set_hero_face(_face_smile >= 0.5)

func begin_ease() -> void:
	_ease = 0.0
	_ease_from = {
		"arm_l": arm_l.rotation if arm_l else 0.0,
		"arm_r": arm_r.rotation if arm_r else 0.0,
		"elbow_l": elbow_l.rotation if elbow_l else 0.0,
		"elbow_r": elbow_r.rotation if elbow_r else 0.0,
	}

func _nude_path() -> String:
	if not female:
		return "res://assets/paperdoll/front/nude_m.svg"
	if _back:
		return "res://assets/paperdoll/front/nude_f_back.svg"
	if _side:
		return "res://assets/paperdoll/front/nude_f_side.svg"
	return "res://assets/paperdoll/front/nude_f.svg"

func set_nude(show: bool) -> void:
	nude = show
	_apply()

func set_hair_tint(tint: Color) -> void:
	hair_tint = tint
	if hair:
		hair.modulate = tint

func _process(delta: float) -> void:
	if _ik == null:
		return
	_ik.solve(delta)
	if _ik.use_ik:
		_ik.copy_to(arm_l, elbow_l, arm_r, elbow_r)
	if _ease < 1.0:
		_ease = minf(1.0, _ease + delta / 0.4)
		_blend_from(_ease)

func _blend_from(weight: float) -> void:
	for pivot_name in _ease_from.keys():
		var path: String = PIVOT_NODES.get(pivot_name, "")
		var pivot := get_node_or_null(path) as Node2D
		if pivot:
			pivot.rotation = lerpf(float(_ease_from[pivot_name]), pivot.rotation, weight)

func set_view(view: String) -> void:
	var side := view == "side"
	var back := view == "back"
	if side == _side and back == _back:
		return
	_side = side
	_back = back
	set_ik_enabled(_ik.use_ik if _ik else false)
	_apply()

func set_side_view(side: bool) -> void:
	set_view("side" if side else "front")

func _swing_hair(angle: float, blend: float) -> void:
	if hair_pivot:
		hair_pivot.rotation = lerpf(hair_pivot.rotation, angle, blend)

func set_clip_locked(locked: bool) -> void:
	_clip_locked = locked
	if not locked and female:
		_set_hero_face(true)

func apply_pose(pose: Dictionary) -> void:
	for pivot_name in pose.keys():
		var path: String = PIVOT_NODES.get(pivot_name, "")
		if path.is_empty():
			continue
		var pivot := get_node_or_null(path) as Node2D
		if pivot:
			pivot.rotation = float(pose[pivot_name])
	if pose.has("face") and female:
		_set_hero_face(float(pose["face"]) >= 0.5)

func _swing(pivot: Node2D, angle: float) -> void:
	if pivot:
		pivot.rotation = angle

func _hairs() -> Array:
	return HAIR_FEMALE if female else HAIR_MALE

func _lowers() -> Array:
	return LOWER_FEMALE if female else LOWER_MALE

func _apply() -> void:
	var arm_path := _layer("arm")
	var leg_path := _layer("leg")
	var arm_tex: Texture2D = load(arm_path) if arm_path != "" else null
	var leg_tex: Texture2D = load(leg_path) if leg_path != "" else null
	var pant_tex: Texture2D = load("res://assets/paperdoll/pant_leg.svg")
	if body:
		body.texture = load(_nude_path() if nude else _layer("body"))
	if hair:
		hair.texture = load(_layer("hair"))
		hair.modulate = hair_tint
	if eyes:
		eyes.visible = false
	_set_hero_face(true)
	if shirt:
		var shirt_path := _layer("shirt")
		shirt.visible = shirt_path != "" and not nude
		if shirt.visible:
			shirt.texture = load(shirt_path)
			shirt.modulate = Color.WHITE
	if skirt:
		skirt.visible = bool(_palette.get("has_skirt", false)) and not nude
		if skirt.visible:
			skirt.texture = load(_layer("skirt"))
			skirt.modulate = Color.WHITE
	var shoe_path := _layer("shoe")
	var shoe_tex: Texture2D = load(shoe_path) if shoe_path != "" else null
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
		shoe.texture = shoe_tex
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
		var sleeve_path := _layer("sleeve")
		sleeve.visible = sleeve_path != "" and not nude
		if sleeve.visible:
			sleeve.texture = load(sleeve_path)
			sleeve.modulate = Color.WHITE
			var sleeve_size := sleeve.texture.get_size()
			sleeve.offset = Vector2(-sleeve_size.x * 0.5, 0)

func _layer(part: String) -> String:
	var views: Dictionary = _palette.get(part, {})
	var view := "back" if _back else ("side" if _side else "front")
	var path := str(views.get(view, views.get("front", "")))
	if path == "none" or path.is_empty():
		return ""
	return path

func _female_cloth(kind: String) -> String:
	var rose := shirt_i == 1
	if kind == "skirt":
		if _back:
			return "res://assets/paperdoll/front/skirt_f_back.svg"
		if _side:
			return "res://assets/paperdoll/front/skirt_f_side.svg"
		return "res://assets/paperdoll/front/skirt_f_rose.svg" if rose else SKIRT_FRONT_F
	if _back:
		return "res://assets/paperdoll/front/shirt_f_back.svg"
	if _side:
		return "res://assets/paperdoll/front/shirt_f_side.svg"
	return "res://assets/paperdoll/front/shirt_f_rose.svg" if rose else SHIRT_FRONT_F

func _set_hero_face(smile: bool) -> void:
	var face := get_node_or_null("../../FaceViewport/Face") as Sprite2D
	if face == null:
		return
	if _palette.is_empty():
		return
	if not female and (_side or _back):
		face.visible = false
		return
	if female and _side:
		face.texture = load(_layer("face") if _palette.get("face", {}).get("side", "") == "" else str(_palette["face"]["side"]))
		face.visible = true
		return
	if female and _back:
		face.visible = false
		return
	face.visible = true
	var faces: Dictionary = _palette.get("face", {})
	if female:
		face.texture = load(str(faces.get("front" if smile else "calm", faces.get("front", ""))))
	else:
		face.texture = load(str(faces.get("front", "res://assets/paperdoll/front/face_m_hero.svg")))

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
