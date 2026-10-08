extends CharacterBody3D
## 3D body. Paperdoll is a Y-billboard. The local player looks through a head camera.
## Schedule and clip lock are driven by the interaction director.

enum Mode { FREE, FROZEN, APPROACH, CLIP }

@export var move_speed: float = 1.4
@export var gravity: float = 18.0
@export var is_player: bool = false
@export var palette := "player"
@export var female: bool = false
@export var hair_style: int = 0
@export var shirt_style: int = 0
@export var pants_style: int = 0
@export var mouse_sensitivity: float = 0.0025
@export var schedule_wait: float = 3.5

@onready var sprite: Sprite3D = $Sprite3D
@onready var face_billboard: Sprite3D = $Sprite3D/FaceBillboard
@onready var face_viewport: SubViewport = $FaceViewport
@onready var viewport: SubViewport = $SubViewport
@onready var paperdoll: Node2D = $SubViewport/Paperdoll
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var _yaw := 0.0
var _pitch := 0.0
var _mode := Mode.FREE
var _schedule: Array[Vector3] = []
var _spot := 0
var _wait := 0.0
var _approach_target := Vector3.ZERO
var _face_point := Vector3.ZERO
var _resume_spot := 0

func _ready() -> void:
	call_deferred("_bind_viewport")
	if paperdoll and paperdoll.has_method("set_palette"):
		paperdoll.set_palette(palette)
	elif paperdoll and paperdoll.has_method("set_look"):
		paperdoll.set_look(hair_style, shirt_style, pants_style, female)
	add_to_group("doll")
	if is_player:
		add_to_group("player")
		sprite.layers = 2
		face_billboard.layers = 2
		camera.current = true
		camera.cull_mask = camera.cull_mask & ~2
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false
		head.visible = false
	_wait = schedule_wait

func _bind_viewport() -> void:
	sprite.texture = viewport.get_texture()
	face_billboard.texture = face_viewport.get_texture()

var _preview_on := false

func set_palette(name: String) -> void:
	palette = name
	if paperdoll and paperdoll.has_method("set_palette"):
		paperdoll.set_palette(name)

func set_preview(show: bool) -> void:
	if not is_player:
		return
	_preview_on = show
	var layer := 1 if show else 2
	sprite.layers = layer
	face_billboard.layers = layer

func set_schedule(points: Array) -> void:
	_schedule.clear()
	for point in points:
		_schedule.append(point)
	_spot = 0
	_resume_spot = 0
	_wait = 0.4

func can_interrupt() -> bool:
	return not is_player and (_mode == Mode.FREE)

func set_mode_frozen(frozen: bool) -> void:
	if frozen:
		_mode = Mode.FROZEN
		velocity.x = 0.0
		velocity.z = 0.0
	elif _mode == Mode.FROZEN:
		_mode = Mode.FREE

func begin_approach(target: Vector3, face_point: Vector3) -> void:
	_resume_spot = _spot
	_approach_target = target
	_face_point = face_point
	_mode = Mode.APPROACH
	collision_mask = 1

func approach_done() -> bool:
	var flat := global_position
	var goal := _approach_target
	flat.y = 0.0
	goal.y = 0.0
	return flat.distance_to(goal) <= 0.12

func cancel_approach() -> void:
	_mode = Mode.FREE
	collision_mask = 3
	_spot = _resume_spot
	_wait = 0.2

func begin_clip() -> void:
	_mode = Mode.CLIP
	velocity.x = 0.0
	velocity.z = 0.0
	if not is_player:
		collision_mask = 1
		sprite.flip_h = false
	if paperdoll and paperdoll.has_method("set_clip_locked"):
		paperdoll.set_clip_locked(true)

func end_clip() -> void:
	if paperdoll and paperdoll.has_method("set_clip_locked"):
		paperdoll.set_clip_locked(false)
	collision_mask = 3
	_mode = Mode.FREE
	if not is_player:
		_spot = _resume_spot
		_wait = 0.2

func set_target_marks(show: bool) -> void:
	if paperdoll and paperdoll.has_method("set_target_marks"):
		paperdoll.set_target_marks(show)

func set_hand_targets(left: Vector2, right: Vector2) -> void:
	if paperdoll and paperdoll.has_method("set_hand_targets"):
		paperdoll.set_hand_targets(left, right)

func nudge_target(hand: String, delta: Vector2) -> void:
	if paperdoll and paperdoll.has_method("nudge_target"):
		paperdoll.nudge_target(hand, delta)

func set_ik_enabled(enabled: bool) -> void:
	if paperdoll and paperdoll.has_method("set_ik_enabled"):
		paperdoll.set_ik_enabled(enabled)

func set_face_blend(amount: float) -> void:
	if paperdoll and paperdoll.has_method("set_face_blend"):
		paperdoll.set_face_blend(amount)

func begin_release() -> void:
	if paperdoll and paperdoll.has_method("begin_release"):
		paperdoll.begin_release()

func set_slots(show_chest: bool, show_groin: bool) -> void:
	if paperdoll and paperdoll.has_method("set_slots"):
		paperdoll.set_slots(show_chest, show_groin)
	if paperdoll and paperdoll.has_method("begin_ease"):
		paperdoll.begin_ease()

func set_nude(show: bool) -> void:
	if paperdoll and paperdoll.has_method("set_nude"):
		paperdoll.set_nude(show)

func set_hair_tint(tint: Color) -> void:
	if paperdoll and paperdoll.has_method("set_hair_tint"):
		paperdoll.set_hair_tint(tint)
	if paperdoll and paperdoll.has_method("set_hair_tint"):
		paperdoll.set_hair_tint(tint)

func apply_clip_pose(pose: Dictionary) -> void:
	if paperdoll and paperdoll.has_method("apply_pose"):
		paperdoll.apply_pose(pose)

func _unhandled_input(event: InputEvent) -> void:
	if not is_player:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
		rotation.y = _yaw
		head.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel") and _mode == Mode.FREE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector3.ZERO
	if is_player:
		input_dir = _player_input()
	else:
		input_dir = _npc_input(delta)

	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.z * move_speed
	move_and_slide()

	if not is_player or _preview_on:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var to_cam := cam.global_position - global_position
			to_cam.y = 0.0
			if _mode != Mode.CLIP and input_dir.length_squared() > 0.002:
				var side := input_dir.cross(Vector3.UP).dot(to_cam)
				sprite.flip_h = side < 0.0
			if paperdoll and paperdoll.has_method("set_view") and to_cam.length_squared() > 0.01:
				var forward := -global_transform.basis.z
				forward.y = 0.0
				if forward.length_squared() > 0.0001:
					var facing := forward.normalized().dot(to_cam.normalized())
					paperdoll.set_view(DollMath.view_from_dot(facing))

	_bob(delta, input_dir.length() > 0.05 and _mode != Mode.CLIP)
	if paperdoll and paperdoll.has_method("drive") and _mode != Mode.CLIP:
		paperdoll.drive(Vector2(velocity.x, velocity.z).length(), delta)

func _player_input() -> Vector3:
	if _mode != Mode.FREE:
		return Vector3.ZERO
	var x := Input.get_axis("move_left", "move_right")
	var z := Input.get_axis("move_forward", "move_back")
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.0001:
		forward = forward.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	if right.length_squared() > 0.0001:
		right = right.normalized()
	var input_dir := right * x + forward * z
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	if Input.is_action_just_pressed("cycle_hair") and paperdoll:
		paperdoll.cycle_hair()
	if Input.is_action_just_pressed("cycle_shirt") and paperdoll:
		paperdoll.cycle_shirt()
	if Input.is_action_just_pressed("cycle_pants") and paperdoll:
		paperdoll.cycle_pants()
	return input_dir

func _npc_input(delta: float) -> Vector3:
	if _mode == Mode.FROZEN or _mode == Mode.CLIP:
		return Vector3.ZERO
	if _mode == Mode.APPROACH:
		var to_slot := _approach_target - global_position
		to_slot.y = 0.0
		if to_slot.length() <= 0.12:
			_face(_face_point)
			return Vector3.ZERO
		return _avoid(DollMath.arrive(to_slot, 0.6))
	return _schedule_input(delta)

func _schedule_input(delta: float) -> Vector3:
	if _schedule.is_empty():
		return Vector3.ZERO
	var goal := _schedule[_spot]
	var to_goal := goal - global_position
	to_goal.y = 0.0
	if to_goal.length() > 0.2:
		if _player_near():
			return Vector3.ZERO
		return _avoid(DollMath.arrive(to_goal, 0.8))
	_wait -= delta
	if _wait <= 0.0:
		_spot = (_spot + 1) % _schedule.size()
		_wait = schedule_wait
	return Vector3.ZERO

func _avoid(desired: Vector3) -> Vector3:
	var push := Vector3.ZERO
	for body in get_tree().get_nodes_in_group("doll"):
		if body == self:
			continue
		var away := global_position - body.global_position
		away.y = 0.0
		var dist := away.length()
		if dist < 0.7 and dist > 0.001:
			push += away.normalized() * (0.7 - dist)
	return DollMath.avoid(desired, push)

func _player_near() -> bool:
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return false
	var flat := global_position
	var other: Vector3 = players[0].global_position
	flat.y = 0.0
	other.y = 0.0
	return flat.distance_to(other) <= 1.2

func _face(point: Vector3) -> void:
	var flat := point - global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return
	rotation.y = atan2(flat.x, flat.z)

var _bob_t := 0.0
func _bob(delta: float, moving: bool) -> void:
	if is_player:
		return
	if moving:
		_bob_t += delta * 10.0
		sprite.position.y = 0.95 + sin(_bob_t) * 0.04
	else:
		sprite.position.y = lerpf(sprite.position.y, 0.95, 8.0 * delta)
