extends Node3D
## Standing frame. Shows the nearest doll only within 1.2 m.

@onready var portrait: Sprite3D = $Portrait

func _process(_delta: float) -> void:
	var best: Node = null
	var best_d := 1.2
	for body in get_tree().get_nodes_in_group("doll"):
		var flat := global_position
		var other: Vector3 = body.global_position
		flat.y = 0.0
		other.y = 0.0
		var dist := flat.distance_to(other)
		if dist < best_d:
			best_d = dist
			best = body
	portrait.visible = best != null
	if best == null:
		return
	var viewport := best.get_node_or_null("SubViewport") as SubViewport
	if viewport:
		portrait.texture = viewport.get_texture()
