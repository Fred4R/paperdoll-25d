extends Node2D
## Two-bone IK on Bone2D. The paperdoll sprites copy these rotations.

var upper_l: Bone2D
var lower_l: Bone2D
var upper_r: Bone2D
var lower_r: Bone2D
var target_l := Vector2(-16, 70)
var target_r := Vector2(144, 70)
var use_ik := false
var mark_l: Polygon2D
var mark_r: Polygon2D

func _ready() -> void:
	var skeleton := Skeleton2D.new()
	skeleton.name = "ArmSkeleton"
	add_child(skeleton)
	upper_l = _bone(skeleton, "UpperL", Vector2(42, 64))
	lower_l = _bone(upper_l, "LowerL", Vector2(0, 31))
	upper_r = _bone(skeleton, "UpperR", Vector2(86, 64))
	lower_r = _bone(upper_r, "LowerR", Vector2(0, 31))
	mark_l = _mark()
	mark_r = _mark()
	add_child(mark_l)
	add_child(mark_r)
	_place_marks()

func _bone(parent: Node, bone_name: String, rest: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = rest
	bone.rest = Transform2D(0, rest)
	parent.add_child(bone)
	return bone

func _mark() -> Polygon2D:
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 4), Vector2(-4, 4)])
	mark.color = Color(0.9, 0.75, 0.3, 0.9)
	mark.visible = false
	return mark

func set_targets(left: Vector2, right: Vector2) -> void:
	target_l = left
	target_r = right
	_place_marks()

func set_ik(enabled: bool) -> void:
	use_ik = enabled

func set_marks(show: bool) -> void:
	mark_l.visible = show
	mark_r.visible = show
	_place_marks()

func _place_marks() -> void:
	mark_l.position = target_l
	mark_r.position = target_r

func solve() -> void:
	if not use_ik:
		return
	_solve(upper_l, lower_l, target_l, true)
	_solve(upper_r, lower_r, target_r, false)

func _solve(upper: Bone2D, lower: Bone2D, target: Vector2, left: bool) -> void:
	var shoulder: Vector2 = upper.position
	var to_target := target - shoulder
	var reach := to_target.length()
	var len_a := 31.0
	var len_b := 31.0
	reach = clampf(reach, 4.0, len_a + len_b - 1.0)
	var cos_elbow := clampf((len_a * len_a + len_b * len_b - reach * reach) / (2.0 * len_a * len_b), -1.0, 1.0)
	var elbow := PI - acos(cos_elbow)
	if left:
		elbow = -elbow
	var cos_shoulder := clampf((len_a * len_a + reach * reach - len_b * len_b) / (2.0 * len_a * reach), -1.0, 1.0)
	var shoulder_offset := acos(cos_shoulder)
	if not left:
		shoulder_offset = -shoulder_offset
	upper.rotation = to_target.angle() + shoulder_offset - PI * 0.5
	lower.rotation = elbow

func copy_to(arm_l: Node2D, elbow_l: Node2D, arm_r: Node2D, elbow_r: Node2D) -> void:
	if arm_l:
		arm_l.rotation = upper_l.rotation
	if elbow_l:
		elbow_l.rotation = lower_l.rotation
	if arm_r:
		arm_r.rotation = upper_r.rotation
	if elbow_r:
		elbow_r.rotation = lower_r.rotation
