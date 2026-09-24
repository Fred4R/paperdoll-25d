extends CharacterBody3D
## 3D body that displays a 2D paperdoll via SubViewport → Sprite3D billboard.

@export var move_speed: float = 5.0
@export var gravity: float = 18.0
@export var is_player: bool = false
@export var hair_style: int = 0
@export var shirt_style: int = 0
@export var pants_style: int = 0

@onready var sprite: Sprite3D = $Sprite3D
@onready var viewport: SubViewport = $SubViewport
@onready var paperdoll: Node2D = $SubViewport/Paperdoll

var facing_right := true

func _ready() -> void:
	sprite.texture = viewport.get_texture()
	if paperdoll and paperdoll.has_method("set_look"):
		paperdoll.set_look(hair_style, shirt_style, pants_style)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input_dir := Vector3.ZERO
	if is_player:
		var x := Input.get_axis("move_left", "move_right")
		var z := Input.get_axis("move_forward", "move_back")
		input_dir = Vector3(x, 0.0, z)
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

	if absf(input_dir.x) > 0.05:
		facing_right = input_dir.x > 0.0
		sprite.flip_h = not facing_right

	_bob(delta, input_dir.length() > 0.05)

var _bob_t := 0.0
func _bob(delta: float, moving: bool) -> void:
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
