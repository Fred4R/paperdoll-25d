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
@onready var npc3: CharacterBody3D = $"../NPC3"
@onready var path_a: Marker3D = $"../PathA"
@onready var path_b: Marker3D = $"../PathB"
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
var _hand := "hand_r"
var _women: Array = []
var _wardrobe := false
var _last_slot := "nude"
var _records: Dictionary = {}
var _saved_palette := ""

func _ready() -> void:
	_clips = {
		"embrace": ClipLibrary.load_file(EMBRACE_PATH),
		"greeting": ClipLibrary.load_file(GREETING_PATH),
	}
	_clip = _clips["embrace"]
	list_panel.visible = false
	prompt.visible = false
	_women = [npc, npc2, npc3]
	if npc3 and npc3.has_method("set_schedule"):
		npc3.set_schedule([path_a.global_position, path_b.global_position])
		npc3.set_hair_tint(Color(0.72, 0.42, 0.28))
	if npc and npc.has_method("set_schedule"):
		npc.set_schedule([window_mark.global_position, chair_mark.global_position])
	if npc2 and npc2.has_method("set_schedule"):
		npc2.set_schedule([gate_mark.global_position, bench_mark.global_position])
	_set_hint()
	_load_records()

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
		elif _wardrobe:
			_close_wardrobe()
			get_viewport().set_input_as_handled()
		elif _approaching:
			_cancel_approach()
			get_viewport().set_input_as_handled()
		elif _playing:
			_finish_clip()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("wardrobe") and not _list_open and not _editing and not _playing:
		_open_wardrobe()
		get_viewport().set_input_as_handled()
		return
	if _wardrobe and event is InputEventKey:
		_wardrobe_key(event.keycode)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("editor") and _can_edit():
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
	player.set_target_marks(true)
	npc.set_target_marks(true)
	_apply_targets()
	_apply_edit()

func _close_editor() -> void:
	_editing = false
	player.set_preview(false)
	player.end_clip()
	npc.end_clip()
	list_panel.visible = false

func _editor_key(code: int) -> void:
	var duration := float(_clip.get("duration", 4.0))
	if code == KEY_PERIOD:
		_edit_time = minf(duration, _edit_time + 0.1)
	elif code == KEY_COMMA:
		_edit_time = maxf(0.0, _edit_time - 0.1)
	elif code == KEY_RIGHT:
		_nudge_hand(Vector2(8, 0))
	elif code == KEY_LEFT:
		_nudge_hand(Vector2(-8, 0))
	elif code == KEY_UP:
		_nudge_hand(Vector2(0, -8))
	elif code == KEY_DOWN:
		_nudge_hand(Vector2(0, 8))
	elif code == KEY_A:
		_hand = "hand_l" if _hand == "hand_r" else "hand_r"
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
	list_label.text = "Editor  %s  %.1f s\n%s\nArrows move the hand\nComma Period scrub\nA hand   S save\nMarks hide when this closes." % [
		str(_clip.get("name", "clip")), _edit_time, _hand
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

func _nudge_hand(delta: Vector2) -> void:
	player.nudge_target(_hand, delta)
	npc.nudge_target(_hand, delta)

func _apply_targets() -> void:
	var targets: Dictionary = _clip.get("targets", {})
	var left: Array = targets.get("hand_l", [-16, 70])
	var right: Array = targets.get("hand_r", [144, 70])
	var l := Vector2(float(left[0]), float(left[1]))
	var r := Vector2(float(right[0]), float(right[1]))
	player.set_hand_targets(l, r)
	npc.set_hand_targets(l, r)

func _save_edit() -> void:
	DirAccess.make_dir_recursive_absolute("user://clips")
	var name := str(_clip.get("name", "clip"))
	var file := FileAccess.open("user://clips/%s.json" % name, FileAccess.WRITE)
	if file == null:
		list_label.text = "Save failed."
		return
	_clip["targets"] = {
		"hand_l": [player.paperdoll.selected_target("hand_l").x, player.paperdoll.selected_target("hand_l").y],
		"hand_r": [player.paperdoll.selected_target("hand_r").x, player.paperdoll.selected_target("hand_r").y],
	}
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
		prompt.text = "E  Embrace, Greeting"

func _open_list() -> void:
	_list_open = true
	prompt.visible = false
	list_panel.visible = true
	_list_ids = ["embrace", "greeting", "shirtoff"]
	var lines := ["1  Embrace", "2  Greeting", "3  Shirt off"]
	var folder := DirAccess.open("user://clips")
	if folder:
		folder.list_dir_begin()
		var file_name := folder.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and _list_ids.size() < 9:
				var loaded: Dictionary = ClipLibrary.load_file("user://clips/%s" % file_name)
				if not loaded.has("targets"):
					file_name = folder.get_next()
					continue
				var id := "user:%s" % file_name
				_clips[id] = loaded
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
	if clip_name == "shirtoff":
		_clip = _clips["embrace"]
		_bare = true
	else:
		_clip = _clips.get(clip_name, _clips["embrace"])
		_bare = false
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
	if _bare and npc.has_method("set_palette"):
		var current := str(npc.get("palette"))
		_saved_palette = current
		npc.set_palette("woman_rose_bare" if current == "woman_rose" else "woman_dark_bare")
	npc.begin_clip()
	player.begin_clip()
	if not _side_view():
		player.begin_ease()
		npc.begin_ease()
	if reach:
		reach.play()
	_apply_clock(0.0)

func _apply_clock(time_sec: float) -> void:
	_apply_targets()
	var side := false
	if npc.paperdoll and npc.paperdoll.has_method("set_view"):
		side = npc.paperdoll._side or npc.paperdoll._back
	player.set_ik_enabled(not side)
	npc.set_ik_enabled(not side)
	player.set_face_blend(clampf(time_sec / 0.5, 0.0, 1.0))
	npc.set_face_blend(clampf(time_sec / 0.5, 0.0, 1.0))
	player.apply_clip_pose(ClipLibrary.sample(_clip, "player", time_sec))
	npc.apply_clip_pose(ClipLibrary.sample(_clip, "npc", time_sec))

func _side_view() -> bool:
	return npc.paperdoll != null and (npc.paperdoll._side or npc.paperdoll._back)

func _finish_clip() -> void:
	_playing = false
	_cooldown = COOLDOWN
	player.end_clip()
	npc.end_clip()
	if not _side_view():
		player.begin_ease()
		npc.begin_ease()
	if _bare and npc.has_method("set_palette"):
		npc.set_palette(_saved_palette)
		_bare = false
	prompt.visible = false

func _open_wardrobe() -> void:
	_select_nearest()
	if npc == null or _flat_distance() > PROMPT_RADIUS:
		return
	_wardrobe = true
	list_panel.visible = true
	player.set_mode_frozen(true)
	npc.set_mode_frozen(true)
	_show_wardrobe()

func _close_wardrobe() -> void:
	_wardrobe = false
	list_panel.visible = false
	player.set_mode_frozen(false)
	npc.set_mode_frozen(false)
	_save_records()

func _show_wardrobe() -> void:
	list_label.text = "Wardrobe  %s\n1  Hair\n2  Shirt\n3  Skirt\n4  Nude\n5  Apply to all women\n6  Name\nEsc close" % _woman_name(npc)
	_show_icons()

func _show_icons() -> void:
	var icons := ["hair_f", "shirt_f", "skirt_f", "nude_f"]
	for child in list_panel.get_children():
		if str(child.name).begins_with("Icon"):
			child.queue_free()
	for i in icons.size():
		var rect := TextureRect.new()
		rect.name = "Icon%d" % i
		rect.texture = load("res://assets/paperdoll/front/%s.svg" % icons[i])
		rect.position = Vector2(250, 36 + i * 28)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		list_panel.add_child(rect)

func _wardrobe_key(code: int) -> void:
	var id := npc.name
	if not _records.has(id):
		_records[id] = {}
	var record: Dictionary = _records[id]
	if code == KEY_1:
		npc.paperdoll.cycle_hair()
		record["hair"] = true
		_last_slot = "hair"
	elif code == KEY_2:
		npc.paperdoll.cycle_shirt()
		record["shirt"] = true
		_last_slot = "shirt"
	elif code == KEY_3:
		npc.paperdoll.cycle_pants()
		record["skirt"] = true
		_last_slot = "skirt"
	elif code == KEY_4:
		var show := not npc.paperdoll.nude
		npc.set_nude(show)
		record["nude"] = show
		_last_slot = "nude"
	elif code == KEY_5:
		for woman in _women:
			if woman == null or woman == npc or woman.paperdoll == null:
				continue
			_copy_slot(npc.paperdoll, woman.paperdoll, _last_slot)
	elif code == KEY_6:
		record["name"] = _next_name(str(record.get("name", npc.name)))
	_records[id] = record
	_save_records()
	_show_wardrobe()

func _copy_slot(source: Node2D, dest: Node2D, slot: String) -> void:
	if slot == "hair":
		dest.hair_i = source.hair_i
		dest.hair_tint = source.hair_tint
	elif slot == "shirt":
		dest.shirt_i = source.shirt_i
	elif slot == "skirt":
		dest.pants_i = source.pants_i
	else:
		dest.nude = source.nude
	dest._apply()

func _woman_name(body: Node) -> String:
	var record: Dictionary = _records.get(body.name, {})
	return str(record.get("name", body.name))

func _next_name(current: String) -> String:
	var names := ["Ada", "Ruth", "Cora", "June"]
	var index := names.find(current)
	return names[(index + 1) % names.size()]

func _load_records() -> void:
	SaveStore.load_records()
	var parsed: Dictionary = SaveStore.records
	if parsed.is_empty():
		return
	_records = parsed
	_last_slot = SaveStore.last_slot
	for woman in _women:
		if woman == null:
			continue
		var record: Dictionary = _records.get(woman.name, {})
		if record.get("nude", false):
			woman.set_nude(true)

func _save_records() -> void:
	SaveStore.last_slot = _last_slot
	SaveStore.records = _records
	SaveStore.save_records()

func _set_hint() -> void:
	hint.text = "Mouse: look    WASD: walk    E: clips    Tab: wardrobe"
