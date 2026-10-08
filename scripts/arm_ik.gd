extends Node2D
## Official two-bone IK. Godot 4 SkeletonModificationStack2D executes the solve.

var target_l := Vector2(-16, 70)
var target_r := Vector2(144, 70)
var use_ik := false
var mark_l: Polygon2D
var mark_r: Polygon2D
var _skeleton: Skeleton2D
var _upper_l: Bone2D
var _lower_l: Bone2D
var _upper_r: Bone2D
var _lower_r: Bone2D

func _ready() -> void:
	var skeleton := Skeleton2D.new()
	skeleton.name = "ArmSkeleton"
	add_child(skeleton)
	_upper_l = _bone(skeleton, "UpperL", Vector2(42, 64))
	_lower_l = _bone(_upper_l, "LowerL", Vector2(0, 31))
	_upper_r = _bone(skeleton, "UpperR", Vector2(86, 64))
	_lower_r = _bone(_upper_r, "LowerR", Vector2(0, 31))
	var aim_l := _aim(skeleton, "AimL", target_l)
	var aim_r := _aim(skeleton, "AimR", target_r)
	_skeleton = skeleton
	_stack = SkeletonModificationStack2D.new()
	skeleton.set_modification_stack(_stack)
	_stack.add_modification(_ik(_upper_l, _lower_l, aim_l, true))
	_stack.add_modification(_ik(_upper_r, _lower_r, aim_r, false))
	_stack.enable_all_modifications(true)
	_stack.setup()
	mark_l = _mark()
	mark_r = _mark()
	add_child(mark_l)
	add_child(mark_r)
	_place_marks()

func _bone(parent: Node, bone_name: String, rest: Vector2) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = bone_name
	bone.position = rest
	bone.rest = Transform2D(0.0, rest)
	parent.add_child(bone)
	return bone

func _aim(parent: Node, aim_name: String, point: Vector2) -> Node2D:
	var aim := Marker2D.new()
	aim.name = aim_name
	aim.position = point
	parent.add_child(aim)
	return aim

func _ik(upper: Bone2D, lower: Bone2D, aim: Node2D, left: bool) -> SkeletonModification2DTwoBoneIK:
	var ik := SkeletonModification2DTwoBoneIK.new()
	ik.set_joint_one_bone2d_node(upper.get_path())
	ik.set_joint_two_bone2d_node(lower.get_path())
	ik.target_nodepath = aim.get_path()
	ik.flip_bend_direction = not left
	ik.target_minimum_distance = 12.0
	return ik

func _mark() -> Polygon2D:
	var mark := Polygon2D.new()
	mark.polygon = PackedVector2Array([
		Vector2(4, 0), Vector2(3, 3), Vector2(0, 4), Vector2(-3, 3),
		Vector2(-4, 0), Vector2(-3, -3), Vector2(0, -4), Vector2(3, -3)
	])
	mark.color = Color(0.9, 0.75, 0.3, 0.9)
	mark.visible = false
	return mark

func set_targets(left: Vector2, right: Vector2) -> void:
	target_l = left
	target_r = right
	var aim_l := get_node_or_null("ArmSkeleton/AimL") as Node2D
	var aim_r := get_node_or_null("ArmSkeleton/AimR") as Node2D
	if aim_l:
		aim_l.position = left
	if aim_r:
		aim_r.position = right
	_place_marks()

func set_ik(enabled: bool) -> void:
	use_ik = enabled

func set_marks(show: bool) -> void:
	mark_l.visible = show
	mark_r.visible = show
	_place_marks()

func _place_marks() -> void:
	if mark_l:
		mark_l.position = target_l
	if mark_r:
		mark_r.position = target_r

func solve(delta: float) -> void:
	if _skeleton == null or not use_ik:
		return
	_skeleton.execute_modifications(delta, 0)

func copy_to(arm_l: Node2D, elbow_l: Node2D, arm_r: Node2D, elbow_r: Node2D) -> void:
	if arm_l and _upper_l:
		arm_l.rotation = _upper_l.rotation
	if elbow_l and _lower_l:
		elbow_l.rotation = _lower_l.rotation
	if arm_r and _upper_r:
		arm_r.rotation = _upper_r.rotation
	if elbow_r and _lower_r:
		elbow_r.rotation = _lower_r.rotation
