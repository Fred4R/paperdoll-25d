extends Node2D
## One woman drawn from three front-view frames: idle, greeting, hug.

const IDLE := preload("res://assets/2d/woman_idle.png")
const GREETING := preload("res://assets/2d/woman_greeting.png")
const HUG := preload("res://assets/2d/woman_hug.png")

@onready var sprite: Sprite2D = $Sprite

var _frame_timer: float = 0.0
var _active_frame: String = "idle"

func _ready() -> void:
	_apply_texture(IDLE)
	_active_frame = "idle"

func _process(delta: float) -> void:
	if _frame_timer <= 0.0:
		return
	_frame_timer -= delta
	if _frame_timer <= 0.0:
		show_idle()

func show_idle() -> void:
	_frame_timer = 0.0
	_active_frame = "idle"
	_apply_texture(IDLE)

func show_greeting(seconds: float = 2.0) -> void:
	_active_frame = "greeting"
	_apply_texture(GREETING)
	_frame_timer = seconds

func show_hug(seconds: float = 4.0) -> void:
	_active_frame = "hug"
	_apply_texture(HUG)
	_frame_timer = seconds

func current_frame() -> String:
	return _active_frame

func _apply_texture(tex: Texture2D) -> void:
	sprite.texture = tex
	# Feet at this node's origin so Y-sort uses standing height on the floor.
	var size := tex.get_size()
	sprite.centered = false
	sprite.offset = Vector2(-size.x * 0.5, -size.y)
