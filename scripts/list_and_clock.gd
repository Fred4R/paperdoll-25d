extends Node
## List of hug and greeting, shared clock, open with E near a woman.

const GREETING_SECONDS := 2.0
const HUG_SECONDS := 4.0
const HUG_WAIT_SECONDS := 3.0
const NEAR_RANGE := 90.0
const HUG_STAND_OFFSET := Vector2(0.0, 48.0)

@onready var player: CharacterBody2D = $"../World/Player"
@onready var world: Node2D = $"../World"
@onready var prompt: Label = $"../UI/Prompt"
@onready var list_panel: Control = $"../UI/List"
@onready var reach_player: AudioStreamPlayer = $"../ReachSound"

var list_open: bool = false
var busy: bool = false
var wait_left: float = 0.0
var target: Node2D = null
var _hug_time_left: float = 0.0
var _hug_partner: Node2D = null

func _ready() -> void:
	list_panel.visible = false
	prompt.visible = false
	_wire_list_buttons()

func _process(delta: float) -> void:
	if wait_left > 0.0:
		wait_left = maxf(0.0, wait_left - delta)
	if _hug_time_left > 0.0:
		_hug_time_left -= delta
		if _hug_time_left <= 0.0:
			_finish_hug()
	if busy or list_open:
		prompt.visible = false
		return
	var near := _nearest_woman()
	if near != null:
		prompt.text = "E  Hug, Greeting"
		prompt.visible = true
	else:
		prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_list"):
		if list_open:
			close_list()
			get_viewport().set_input_as_handled()
			return
		if busy or wait_left > 0.0:
			return
		var near := _nearest_woman()
		if near == null:
			return
		open_list(near)
		get_viewport().set_input_as_handled()
		return
	if not list_open:
		return
	# While the list is open, only 1 / 2 / close may fire — never clothes keys.
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:
				pick_hug()
				get_viewport().set_input_as_handled()
			KEY_2:
				pick_greeting()
				get_viewport().set_input_as_handled()
			KEY_3, KEY_ESCAPE:
				close_list()
				get_viewport().set_input_as_handled()

func open_list(woman: Node2D) -> void:
	target = woman
	list_open = true
	list_panel.visible = true
	player.move_locked = true

func close_list() -> void:
	list_open = false
	list_panel.visible = false
	target = null
	if not busy:
		player.move_locked = false

func pick_greeting() -> void:
	if not list_open or target == null or busy:
		return
	var woman := target
	close_list()
	busy = true
	player.move_locked = true
	if woman.has_method("show_greeting"):
		woman.show_greeting(GREETING_SECONDS)
	await get_tree().create_timer(GREETING_SECONDS).timeout
	busy = false
	player.move_locked = false

func pick_hug() -> void:
	if not list_open or target == null or busy:
		return
	var woman := target
	close_list()
	busy = true
	player.move_locked = true
	# Stand a short step in front of her (lower on the floor = closer to camera).
	player.global_position = woman.global_position + HUG_STAND_OFFSET
	player.global_position.x = clampf(
		player.global_position.x, player.floor_rect.position.x, player.floor_rect.end.x
	)
	player.global_position.y = clampf(
		player.global_position.y, player.floor_rect.position.y, player.floor_rect.end.y
	)
	if reach_player.stream != null:
		reach_player.play()
	if woman.has_method("show_hug"):
		woman.show_hug(HUG_SECONDS)
	_hug_partner = woman
	_hug_time_left = HUG_SECONDS

func _finish_hug() -> void:
	_hug_time_left = 0.0
	if _hug_partner != null and _hug_partner.has_method("show_idle"):
		_hug_partner.show_idle()
	_hug_partner = null
	busy = false
	wait_left = HUG_WAIT_SECONDS
	player.move_locked = false

func _nearest_woman() -> Node2D:
	var best: Node2D = null
	var best_d := NEAR_RANGE
	for child in world.get_children():
		if child == player:
			continue
		if not (child is Node2D):
			continue
		if not child.has_method("show_idle"):
			continue
		var d := player.global_position.distance_to(child.global_position)
		if d <= best_d:
			best_d = d
			best = child
	return best

func _wire_list_buttons() -> void:
	var hug_btn := list_panel.get_node_or_null("Rows/Hug") as BaseButton
	var greet_btn := list_panel.get_node_or_null("Rows/Greeting") as BaseButton
	var close_btn := list_panel.get_node_or_null("Rows/Close") as BaseButton
	if hug_btn:
		hug_btn.pressed.connect(pick_hug)
	if greet_btn:
		greet_btn.pressed.connect(pick_greeting)
	if close_btn:
		close_btn.pressed.connect(close_list)
