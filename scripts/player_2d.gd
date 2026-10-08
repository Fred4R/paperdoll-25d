extends CharacterBody2D
## Simple visible marker for Fred. Walks on the painted floor.

@export var speed: float = 180.0
@export var floor_rect: Rect2 = Rect2(80.0, 560.0, 1120.0, 130.0)

var move_locked: bool = false

func _physics_process(_delta: float) -> void:
	if move_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * speed
	move_and_slide()
	global_position.x = clampf(global_position.x, floor_rect.position.x, floor_rect.end.x)
	global_position.y = clampf(global_position.y, floor_rect.position.y, floor_rect.end.y)
