extends CharacterBody3D
## 3D body. Paperdoll is a Y-billboard. The local player looks through a head camera.

@export var move_speed: float = 1.4
@export var gravity: float = 18.0
@export var is_player: bool = false
@export var female: bool = false
@export var hair_style: int = 0
@export var shirt_style: int = 0
@export var pants_style: int = 0
@export var mouse_sensitivity: float = 0.0025

@onready var sprite: Sprite3D = $Sprite3D
@onready var viewport: SubViewport = $SubViewport
@onready var paperdoll: Node2D = $SubViewport/Paperdoll
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var _yaw := 0.0
var _pitch := 0.0

func _ready() -> void:
	# ViewportTexture is local to the scene and can be wrong before the root is ready.
	call_deferred("_bind_viewport")
	if paperdoll and paperdoll.has_method("set_look"):
		paperdoll.set_look(hair_style, shirt_style, pants_style, female)
	if is_player:
		# Own billboard stays in the world (same system as NPCs) but is not drawn
		# into this camera, or the Y-billboard fills the view.
		sprite.layers = 2
		camera.current = true
		camera.cull_mask = camera.cull_mask & ~2
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		camera.current = false
		head.visible = false

func _bind_viewport() -> void:
	sprite.texture = viewport.get_texture()

func _unhandled_input(event: InputEvent) -> void:
	if not is_player:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity
		_pitch = clampf(_pitch, deg_to_rad(-80.0), deg_to_rad(80.0))
		rotation.y = _yaw
		head.rotation.x = _pitch
	elif event.is_action_pressed("ui_cancel"):
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
		input_dir = right * x + forward * z
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()

		if Input.is_action_just_pressed("cycle_hair") and paperdoll:
			paperdoll.cycle_hair()
		if Input.is_action_just_pressed("cycle_shirt") and paperdoll:
			paperdoll.cycle_shirt()
		if Input.is_action_just_pressed("cycle_pants") and paperdoll:
			paperdoll.cycle_pants()
	else:
		input_dir = _npc_wander(delta)

	velocity.x = input_dir.x * move_speed
	velocity.z = input_dir.z * move_speed
	move_and_slide()

	# Side art faces texture +x. Flip the billboard when travel is to the camera's left.
	var face_right := true
	if input_dir.length_squared() > 0.002:
		var cam := get_viewport().get_camera_3d()
		if cam:
			var cam_right := cam.global_transform.basis.x
			cam_right.y = 0.0
			var along := input_dir.dot(cam_right)
			if absf(along) > 0.2:
				face_right = along > 0.0
			elif sprite.flip_h:
				face_right = false
		sprite.flip_h = not face_right
	else:
		sprite.flip_h = false

	_bob(delta, input_dir.length() > 0.05)
	if paperdoll and paperdoll.has_method("drive"):
		var planar := Vector2(velocity.x, velocity.z).length()
		paperdoll.drive(planar, delta, face_right)

var _bob_t := 0.0
func _bob(delta: float, moving: bool) -> void:
	if is_player:
		return
	if moving:
		_bob_t += delta * 10.0
		sprite.position.y = 0.95 + sin(_bob_t) * 0.04
	else:
		sprite.position.y = lerpf(sprite.position.y, 0.95, 8.0 * delta)

var _wander_dir := Vector3.ZERO
var _wander_timer := 0.0
func _npc_wander(delta: float) -> Vector3:
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(1.2, 3.0)
		if randf() < 0.35:
			_wander_dir = Vector3.ZERO
		else:
			var a := randf() * TAU
			_wander_dir = Vector3(cos(a), 0.0, sin(a))
	if global_position.length() > 8.0:
		_wander_dir = -global_position.normalized()
		_wander_dir.y = 0.0
	return _wander_dir
