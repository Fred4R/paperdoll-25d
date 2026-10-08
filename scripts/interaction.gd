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
@onready var npc2: CharacterBody3D = $"../NPC2"
@onready var window_mark: Marker3D = $"../Window"
@onready var chair_mark: Marker3D = $"../Chair"
@onready var gate_mark: Marker3D = $"../Gate"
@onready var bench_mark: Marker3D = $"../Bench"
@onready var reach: AudioStreamPlayer = $"../Reach"
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
var _list_ids: Array = []
var _editing := false
var _edit_time := 0.0
var _edit_role := "npc"
var _edit_pivot := "arm_r"
var _women: Array = []

func _ready() -> void:
	_clips = {
		"embrace": ClipLibrary.load_file(EMBRACE_PATH),
		"greeting": ClipLibrary.load_file(GREETING_PATH),
	}
	_clip = _clips["embrace"]
	list_panel.visible = false
	prompt.visible = false
	_women = [npc, npc2]
	if npc and npc.has_method("set_schedule"):
		npc.set_schedule([window_mark.global_position, chair_mark.global_position])
	if npc2 and npc2.has_method("set_schedule"):
		npc2.set_schedule([gate_mark.global_position, bench_mark.global_position])
	_set_hint()

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if _editing:
			_close_editor()
			get_viewport().set_input_as_handled()
		elif _list_open:
			_close_list()
			get_viewport().set_input_as_handled()
		elif _approaching:
			_cancel_approach()
			get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.keycode == KEY_C and _can_edit():
		_open_editor()
		get_viewport().set_input_as_handled()
		return
	if _editing and event is InputEventKey:
		_editor_key(event.keycode)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and _can_open():
		_open_list()
		get_viewport().set_input_as_handled()
		return
	if _list_open and event is InputEventKey and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var index := event.keycode - KEY_1
		if index < _list_ids.size():
			_pick(str(_list_ids[index]))
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _playing or _editing:
		if _playing:
			_clock += delta
			var duration := float(_clip.get("duration", 4.0))
			_apply_clock(minf(_clock, duration))
			if str(_clip.get("name", "")) == "embrace" and _clock >= 0.7 and not _reach_played:
				_reach_played = true
				if reach:
					reach.play()
			if _clock >= duration:
				_finish_clip()
		return
	if _approaching:
		if npc.has_method("approach_done") and npc.approach_done():
			_begin_contact()
		return
	_refresh_prompt()

func _can_edit() -> bool:
	return not _list_open and not _approaching and not _playing and not _editing

func _open_editor() -> void:
	_editing = true
	_edit_time = 0.0
	_clip = _duplicate(_clips["embrace"])
	player.set_mode_frozen(true)
	npc.set_mode_frozen(true)
	player.begin_clip()
	npc.begin_clip()
	player.set_preview(true)
	_apply_edit()

func _close_editor() -> void:
	_editing = false
	player.set_preview(false)
	player.end_clip()
	npc.end_clip()
	list_panel.visible = false

func _editor_key(code: int) -> void:
	var duration := float(_clip.get("duration", 4.0))
	if code == KEY_RIGHT:
		_edit_time = minf(duration, _edit_time + 0.1)
	elif code == KEY_LEFT:
		_edit_time = maxf(0.0, _edit_time - 0.1)
	elif code == KEY_UP:
		_nudge(0.1)
	elif code == KEY_DOWN:
		_nudge(-0.1)
	elif code == KEY_A:
		var pivots := ["arm_l", "arm_r", "elbow_l", "elbow_r"]
		_edit_pivot = pivots[(pivots.find(_edit_pivot) + 1) % pivots.size()]
	elif code == KEY_R:
		_edit_role = "player" if _edit_role == "npc" else "npc"
	elif code == KEY_1:
		_clip = _duplicate(_clips["embrace"])
		_edit_time = 0.0
	elif code == KEY_2:
		_clip = _duplicate(_clips["greeting"])
		_edit_time = 0.0
	elif code == KEY_S:
		_save_edit()
		return
	_apply_edit()

func _apply_edit() -> void:
	_apply_clock(_edit_time)
	list_panel.visible = true
	list_label.text = "Editor  %s  %.1f s\n%s  %s\nLeft Right scrub   Up Down nudge\nA arm or elbow   R role   S save\nYou stay visible. Esc closes." % [
		str(_clip.get("name", "clip")), _edit_time, _edit_role, _edit_pivot
	]

func _nudge(amount: float) -> void:
	var roles: Dictionary = _clip.get("roles", {})
	var tracks: Dictionary = roles.get(_edit_role, {})
	var keys: Array = tracks.get(_edit_pivot, []).duplicate(true)
	var placed := false
	for i in keys.size():
		if absf(float(keys[i][0]) - _edit_time) < 0.05:
			keys[i][1] = float(keys[i][1]) + amount
			placed = true
			break
	if not placed:
		keys.append([_edit_time, amount])
		keys.sort_custom(func(a, b): return float(a[0]) < float(b[0]))
	tracks[_edit_pivot] = keys
	roles[_edit_role] = tracks
	_clip["roles"] = roles

func _save_edit() -> void:
	DirAccess.make_dir_recursive_absolute("user://clips")
	var name := str(_clip.get("name", "clip"))
	var file := FileAccess.open("user://clips/%s.json" % name, FileAccess.WRITE)
	if file == null:
		list_label.text = "Save failed."
		return
	file.store_string(JSON.stringify(_clip, "  "))
	list_label.text = "Saved user://clips/%s.json" % name

func _duplicate(source: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(source))

func _can_open() -> bool:
	if _list_open or _approaching or _playing or _editing or _cooldown > 0.0:
		return false
	if player == null:
		return false
	_select_nearest()
	if npc == null or not npc.has_method("can_interrupt") or not npc.can_interrupt():
		return false
	return _flat_distance() <= PROMPT_RADIUS

func _select_nearest() -> void:
	var best: CharacterBody3D = null
	var best_d := PROMPT_RADIUS
	for candidate in _women:
		if candidate == null or not candidate.has_method("can_interrupt") or not candidate.can_interrupt():
			continue
		var a := player.global_position
		var b := candidate.global_position
		a.y = 0.0
		b.y = 0.0
		var d := a.distance_to(b)
		if d <= best_d:
			best_d = d
			best = candidate
	if best:
		npc = best

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
	_list_ids = ["embrace", "greeting"]
	var lines := ["1  Embrace", "2  Greeting"]
	var folder := DirAccess.open("user://clips")
	if folder:
		folder.list_dir_begin()
		var file_name := folder.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and _list_ids.size() < 9:
				var id := "user:%s" % file_name
				_clips[id] = ClipLibrary.load_file("user://clips/%s" % file_name)
				_list_ids.append(id)
				lines.append("%d  %s" % [_list_ids.size(), file_name.trim_suffix(".json")])
			file_name = folder.get_next()
		folder.list_dir_end()
	lines.append("Esc  Close")
	list_label.text = "\n".join(lines)
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
	if str(_clip.get("name", "")) == "greeting":
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
	_reach_played = false
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
