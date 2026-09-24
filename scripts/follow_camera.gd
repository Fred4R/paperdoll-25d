extends Camera3D
## Soft follow behind / above the player for a 2.5D read.

@export var target_path: NodePath
@export var offset := Vector3(0.0, 6.5, 8.0)
@export var look_ahead := Vector3(0.0, 0.6, 0.0)
@export var follow_speed := 6.0

var _target: Node3D

func _ready() -> void:
	if target_path:
		_target = get_node_or_null(target_path)

func _process(delta: float) -> void:
	if _target == null:
		return
	var desired := _target.global_position + offset
	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))
	look_at(_target.global_position + look_ahead, Vector3.UP)
