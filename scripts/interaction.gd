extends Node
## Director. List, freeze, she walks to you, one shared clock, both roles.

const EMBRACE_PATH := "res://data/clips/embrace.json"
const GREETING_PATH := "res://data/clips/greeting.json"
const ClipLibrary := preload("res://scripts/clip_library.gd")
const PROMPT_RADIUS := 1.2
const SLOT_GAP := 0.4
const COOLDOWN := 3.0
const ARRIVE := 0.12

@onready var player: CharacterBody3D = $"../Player"
@onready var npc: CharacterBody3D = $"../NPC1"
@onready var window_mark: Marker3D = $"../Window"
@onready var chair_mark: Marker3D = $"../Chair"
@onready var hint: Label = $"../HUD/Hint"
@onready var prompt: Label = $"../HUD/Prompt"
@onready var list_panel: PanelContainer = $"../HUD/List"
@onready var list_label: Label = $"../HUD/List/Label"

var _clip: Dictionary = {}
var _clips := {}
var _list_open := false
var _approaching := false
var _playing := false
var _clock := 0.0
var _cooldown := 0.0
var _slot := Vector3.ZERO

func _ready() -> void:
	_clips = {
		"embrace": ClipLibrary.load_file(EMBRACE_PATH),
		"greeting": ClipLibrary.load_file(GREETING_PATH),
	}
	_clip = _clips["embrace"]
	list_panel.visible = false
	prompt.visible = false
	if npc and npc.has_method("set_schedule"):
		npc.set_schedule([window_mark.global_position, chair_mark.global_position])
	_set_hint()

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if _list_open:
			_close_list()
			get_viewport().set_input_as_handled()
		elif _approaching:
			_cancel_approach()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and _can_open():
		_open_list()
		get_viewport().set_input_as_handled()
		return
	if _list_open and event is InputEventKey and event.keycode == KEY_1:
		_pick("embrace")
		get_viewport().set_input_as_handled()
	elif _list_open and event is InputEventKey and event.keycode == KEY_2:
		_pick("greeting")
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _playing:
		_clock += delta
		var duration := float(_clip.get("duration", 4.0))
		_apply_clock(minf(_clock, duration))
		if _clock >= duration:
			_finish_clip()
		return
	if _approaching:
		if npc.has_method("approach_done") and npc.approach_done():
			_begin_contact()
		return
	_refresh_prompt()

func _can_open() -> bool:
	if _list_open or _approaching or _playing or _cooldown > 0.0:
		return false
	if player == null or npc == null:
		return false
	if not npc.has_method("can_interrupt") or not npc.can_interrupt():
		return false
	return _flat_distance() <= PROMPT_RADIUS

func _flat_distance() -> float:
	var a := player.global_position
	var b := npc.global_position
	a.y = 0.0
	b.y = 0.0
	return a.distance_to(b)

func _refresh_prompt() -> void:
	var show := _can_open()
	prompt.visible = show
	if show:
		prompt.text = "E  Two clips"

func _open_list() -> void:
	_list_open = true
	prompt.visible = false
	list_panel.visible = true
	list_label.text = "1  Embrace\n2  Greeting\nEsc  Close"
	player.set_mode_frozen(true)
	npc.set_mode_frozen(true)

func _close_list() -> void:
	_list_open = false
	list_panel.visible = false
	player.set_mode_frozen(false)
	npc.set_mode_frozen(false)

func _pick(clip_name: String) -> void:
	_clip = _clips.get(clip_name, _clips["embrace"])
	_list_open = false
	list_panel.visible = false
	if clip_name == "greeting":
		player.set_mode_frozen(false)
		npc.set_mode_frozen(false)
		_begin_contact()
		return
	npc.set_mode_frozen(false)
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	_slot = player.global_position + forward * SLOT_GAP
	_slot.y = npc.global_position.y
	_approaching = true
	player.set_mode_frozen(true)
	npc.begin_approach(_slot, player.global_position)

func _cancel_approach() -> void:
	_approaching = false
	player.set_mode_frozen(false)
	npc.cancel_approach()

func _begin_contact() -> void:
	_approaching = false
	_playing = true
	_clock = 0.0
	npc.begin_clip()
	player.begin_clip()
	_apply_clock(0.0)

func _apply_clock(time_sec: float) -> void:
	player.apply_clip_pose(ClipLibrary.sample(_clip, "player", time_sec))
	npc.apply_clip_pose(ClipLibrary.sample(_clip, "npc", time_sec))

func _finish_clip() -> void:
	_playing = false
	_cooldown = COOLDOWN
	player.end_clip()
	npc.end_clip()
	prompt.visible = false

func _set_hint() -> void:
	hint.text = "Mouse: look    WASD: walk    E: interact    Esc: close list or cancel approach\nClip plays out once she arrives. 3s cooldown.\nFirst person. Embrace or Greeting."
