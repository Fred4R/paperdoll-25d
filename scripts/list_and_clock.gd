extends Node
## Director. List, freeze, she walks to you, one shared clock, both roles.
## Esc and Close cancel only before contact. A started clip always plays out.

const HUG_PATH := "res://data/animations/hug.json"
const GREETING_PATH := "res://data/animations/greeting.json"
const HAND_HOLD_PATH := "res://data/animations/hand_hold.json"
const AnimationList := preload("res://scripts/animation_list.gd")
const PROMPT_RADIUS := 1.2
const SLOT_GAP := 0.4
const COOLDOWN := 3.0
const ARRIVE := 0.12
const TAP_ARRIVE := 0.25
const TAP_SLOP := 16.0
const REACH_AT := 0.7
## The woman (NPC1) is a neighbor who comes over to draw the north yard gate from the window.
## The women have no names yet. Names an earlier build wrote into saves are cleared back to the node id.
const CLEARED_NAMES := ["Ines", "Woman", "Friend"]
const SIT_LINES := [
	["I come over for this window. It's the only one that sees the yard gate straight on.", "What are you drawing?", "Why the gate?"],
	["The gate. My grandfather hung it. It sticks every winter and nobody else remembers why.", "Tell me.", "Can I see?"],
	["He set it crooked on purpose so it would swing shut by itself. Here, keep this one. I'll start another.", "Thank you.", "Put it on the wall."],
]
const SIT_AGAIN := ["Still crooked. Still shuts by itself.", "Sit a while."]
const SIT_WALK_MAX := 8.0

@onready var player: CharacterBody3D = $"../Player"
@onready var npc: CharacterBody3D = $"../NPC1"
@onready var npc2: CharacterBody3D = $"../NPC2"
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
@onready var list_label: Label = $"../HUD/List/Rows/Label"
@onready var woman_npc: CharacterBody3D = $"../NPC1"
@onready var gate_sketch: MeshInstance3D = get_node_or_null("../GateSketch")

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
var _hand := "hand_r"
var _women: Array = []
var _wardrobe := false
var _last_slot := "nude"
var _records: Dictionary = {}
var _saved_palette := ""
var _tap_woman: CharacterBody3D = null
var _touches := {}
var _bare := false
var _slot := Vector3.ZERO
var _reach_played := false
var _stepping_back: CharacterBody3D = null
var _scene_beat := -1
var _scene_walk := false
var _scene_walk_t := 0.0
var _scene_again := false

func _ready() -> void:
	_clips = {
		"embrace": AnimationList.load_file(HUG_PATH),
		"greeting": AnimationList.load_file(GREETING_PATH),
		"handhold": AnimationList.load_file(HAND_HOLD_PATH),
	}
	_clip = _clips["embrace"]
	list_panel.visible = false
	prompt.visible = false
	_women = [npc, npc2]
	if npc and npc.has_method("set_schedule"):
		npc.set_schedule([window_mark.global_position, chair_mark.global_position])
	if npc2 and npc2.has_method("set_schedule"):
		npc2.set_schedule([gate_mark.global_position, bench_mark.global_position])
	var hud := $"../HUD"
	if hud.has_signal("closed"):
		hud.closed.connect(_on_hud_closed)
	if hud.has_signal("picked"):
		hud.picked.connect(_on_hud_picked)
	if player.has_signal("walk_ended"):
		player.walk_ended.connect(_on_walk_ended)
	_set_hint()
	_load_records()
	_woman_ready()

## A row on the HUD list, or number key 1-9. The last row is Close.
func _on_hud_picked(index: int) -> void:
	if _scene_beat >= 0:
		_scene_reply(index)
		return
	if not _list_open:
		return
	if index < _list_ids.size():
		_pick(str(_list_ids[index]))
	elif index == _list_ids.size():
		$"../HUD".hide_panel()

## Every hide_panel lands here, including a pick. Hand the mouse back to look.
func _on_hud_closed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _wardrobe:
		_close_wardrobe()
	elif _list_open:
		_close_list()
	elif _scene_beat >= 0:
		_end_scene(false)

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	if event.is_action_pressed("ui_cancel"):
		if _wardrobe or _list_open or _scene_beat >= 0:
			$"../HUD".hide_panel()
			get_viewport().set_input_as_handled()
			return
		if _scene_walk:
			_end_scene(false)
			get_viewport().set_input_as_handled()
			return
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
		return
	if event.is_action_pressed("wardrobe") and not _list_open and not _editing and not _playing and not _scene_active():
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
	if event.is_action_pressed("interact") and _near_crate():
		_sit = not _sit
		player.head.position.y = 1.15 if _sit else 1.55
		player.position.y = 0.35 if _sit else 0.1
		player.set_seated(_sit)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interact") and _can_open():
		_open_list()
		get_viewport().set_input_as_handled()
		return
	if (_list_open or _scene_beat >= 0) and event is InputEventKey and event.keycode >= KEY_1 and event.keycode <= KEY_9:
		var index: int = event.keycode - KEY_1
		var rows: int = _scene_rows() if _scene_beat >= 0 else _list_ids.size()
		if index < rows:
			_on_hud_picked(index)
			get_viewport().set_input_as_handled()

## Touch: a short tap (not a drag) on a woman walks him to her; on the floor walks him there.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _tap_idle():
				_touches[event.index] = [event.position, 0.0]
		elif _touches.has(event.index):
			var touch: Array = _touches[event.index]
			_touches.erase(event.index)
			var far := maxf(float(touch[1]), event.position.distance_to(touch[0]))
			if far <= TAP_SLOP and not event.canceled and _tap_idle():
				_tap(event.position)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		var touch: Array = _touches[event.index]
		touch[1] = maxf(float(touch[1]), event.position.distance_to(touch[0]))

func _tap_idle() -> bool:
	return not (_list_open or _approaching or _playing or _editing or _wardrobe or _scene_active())

func _tap(screen_point: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.project_ray_origin(screen_point)
	var to := from + cam.project_ray_normal(screen_point) * 60.0
	var exclude: Array[RID] = [player.get_rid()]
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, exclude)
	var hit := player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var body: Object = hit.get("collider")
	if body != null and body in _women:
		_tap_woman = body as CharacterBody3D
		player.walk_to(_tap_woman.global_position, _tap_stop(_tap_woman))
	else:
		_tap_woman = null
		player.walk_to(hit["position"], ARRIVE)
	get_viewport().set_input_as_handled()

## 0.25 m, or capsule contact plus 5 cm when the two capsules cannot get that close.
func _tap_stop(woman: Node) -> float:
	return maxf(TAP_ARRIVE, _capsule_radius(player) + _capsule_radius(woman) + 0.05)

func _capsule_radius(body: Node) -> float:
	var shape_node := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node and shape_node.shape is CapsuleShape3D:
		return (shape_node.shape as CapsuleShape3D).radius
	return 0.0

## Embrace walk-in stops when the two capsules touch (plus 5 cm), so she never shoves him back.
func _at_contact() -> bool:
	return _flat_distance() <= _tap_stop(npc)

## Same heading formula as her slot turn, used when contact comes before the slot.
func _face_player() -> void:
	var flat := player.global_position - npc.global_position
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		return
	npc.rotation.y = atan2(-flat.x, -flat.z)

func _on_walk_ended(arrived: bool) -> void:
	var woman := _tap_woman
	_tap_woman = null
	if woman == null or not arrived:
		return
	if _can_open():
		_open_list()

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _playing or _editing:
		if _playing:
			_clock += delta
			var duration := float(_clip.get("duration", 4.0))
			_apply_clock(minf(_clock, duration))
			if not _reach_played and _clock >= REACH_AT:
				_play_reach()
			if _clock >= duration:
				_finish_clip()
		return
	_end_step_back()
	if _scene_walk:
		_scene_walk_step(delta)
		return
	if _scene_beat >= 0:
		return
	if _approaching:
		if _at_contact() or (npc.has_method("approach_done") and npc.approach_done()):
			_face_player()
			_begin_contact()
		elif npc.has_method("approach_stuck") and npc.approach_stuck():
			_cancel_approach()
		return
	_refresh_prompt()
	if _tap_woman and player.is_walking():
		player.walk_to(_tap_woman.global_position, _tap_stop(_tap_woman))
	_dusk(delta)
	_step(delta)

func _dusk(delta: float) -> void:
	SaveStore.dusk = minf(1.0, SaveStore.dusk + delta / 180.0)
	var env := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env and env.environment:
		env.environment.ambient_light_energy = lerpf(0.55, 0.18, SaveStore.dusk)

func _step(delta: float) -> void:
	if _sit and player.velocity.length() > 0.2:
		_sit = false
		player.position.y = 0.1
		player.head.position.y = 1.55
		player.set_seated(false)
		return
	if player.velocity.length() < 0.2:
		return
	_step_t -= delta
	if _step_t > 0.0:
		return
	_step_t = 0.45
	var on_path := false
	var path := get_parent().get_node_or_null("Yard/PathArea") as Area3D
	if path:
		on_path = path.overlaps_body(player)
	if reach:
		reach.pitch_scale = 1.3 if on_path else 0.7
		reach.play()

var _step_t := 0.0
var _sit := false

func _near_crate() -> bool:
	var crate := Vector3(2.2, 0.1, 2.5)
	var flat := player.global_position
	flat.y = 0.0
	crate.y = 0.0
	return flat.distance_to(crate) < 1.0

func _can_edit() -> bool:
	return not _list_open and not _approaching and not _playing and not _editing and not _scene_active()

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

func _paired(clip: Dictionary) -> bool:
	var roles: Dictionary = clip.get("roles", {})
	var targets: Dictionary = clip.get("targets", {})
	return roles.has("player") and roles.has("npc") and targets.has("player") and targets.has("npc")

func _apply_targets() -> void:
	var targets: Dictionary = _clip.get("targets", {})
	var player_targets: Dictionary = targets.get("player", targets)
	var npc_targets: Dictionary = targets.get("npc", targets)
	player.set_hand_targets(_pair(player_targets), _pair(player_targets, "hand_r"))
	npc.set_hand_targets(_pair(npc_targets), _pair(npc_targets, "hand_r"))

func _pair(targets: Dictionary, hand: String = "hand_l") -> Vector2:
	var point: Array = targets.get(hand, [-16, 70] if hand == "hand_l" else [144, 70])
	return Vector2(float(point[0]), float(point[1]))

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
	if _list_open or _approaching or _playing or _editing or _cooldown > 0.0 or _scene_active():
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
		var b: Vector3 = candidate.global_position
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
	if show:
		prompt.text = "E  Hug, Greeting"
		prompt.modulate.a = 1.0
		prompt.visible = true
	else:
		prompt.modulate.a = maxf(0.0, prompt.modulate.a - 0.05)
		prompt.visible = prompt.modulate.a > 0.05

## List rows: Hug, Greeting, each paired save in user://clips, then Close.
## Hand hold stays loaded for the editor but is not a sheet row.
func _open_list() -> void:
	_list_open = true
	prompt.visible = false
	_list_ids = ["embrace", "greeting"]
	var lines := ["1  Hug", "2  Greeting"]
	var folder := DirAccess.open("user://clips")
	if folder:
		folder.list_dir_begin()
		var file_name := folder.get_next()
		while file_name != "":
			if file_name.ends_with(".json") and _list_ids.size() < 9:
				var loaded: Dictionary = AnimationList.load_file("user://clips/%s" % file_name)
				if not _paired(loaded):
					file_name = folder.get_next()
					continue
				var id := "user:%s" % file_name
				_clips[id] = loaded
				_list_ids.append(id)
				lines.append("%d  %s" % [_list_ids.size(), file_name.trim_suffix(".json")])
			file_name = folder.get_next()
		folder.list_dir_end()
	lines.append("Close")
	$"../HUD".show_choices(PackedStringArray(lines), "")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.set_mode_frozen(true)
	npc.set_mode_frozen(true)

func _close_list() -> void:
	_list_open = false
	list_panel.visible = false
	player.set_mode_frozen(false)
	npc.set_mode_frozen(false)

## Greeting (built-in or a save named greeting) plays where she stands.
## Any other row walks her to the slot; the clip clock starts at contact.
func _pick(clip_name: String) -> void:
	if clip_name == "sit_with_woman":
		_start_scene()
		return
	## Shirt and skirt stay on for the hug.
	_clip = _clips.get(clip_name, _clips["embrace"])
	_bare = false
	_list_open = false
	$"../HUD".hide_panel()
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
	player.set_preview(true)
	if not _side_view():
		player.begin_ease()
		npc.begin_ease()
	if not _is_embrace():
		_play_reach()
	_apply_clock(0.0)

## Embrace plays its reach sound at 0.7 s on the clip clock; other clips keep it at contact.
func _is_embrace() -> bool:
	return str(_clip.get("name", "")) == "embrace"

func _play_reach() -> void:
	_reach_played = true
	if reach:
		reach.play()

## The step back after a clip ends when she reaches it or the cooldown runs out,
## then she is free again and walks back to the spot she left.
func _end_step_back() -> void:
	if _stepping_back == null:
		return
	if not is_instance_valid(_stepping_back):
		_stepping_back = null
		return
	if _cooldown <= 0.0 or _stepping_back.approach_done() or _stepping_back.approach_stuck():
		_stepping_back.cancel_approach()
		_stepping_back = null

func _apply_clock(time_sec: float) -> void:
	_apply_targets()
	var side := false
	if npc.paperdoll and npc.paperdoll.has_method("set_view"):
		side = npc.paperdoll._side or npc.paperdoll._back
	player.set_ik_enabled(not side)
	npc.set_ik_enabled(not side)
	player.set_face_blend(clampf(time_sec / 0.5, 0.0, 1.0))
	npc.set_face_blend(clampf(time_sec / 0.5, 0.0, 1.0))
	player.apply_clip_pose(AnimationList.sample(_clip, "player", time_sec))
	npc.apply_clip_pose(AnimationList.sample(_clip, "npc", time_sec))

func _side_view() -> bool:
	return npc.paperdoll != null and (npc.paperdoll._side or npc.paperdoll._back)

func _finish_clip() -> void:
	_playing = false
	_cooldown = COOLDOWN
	player.set_preview(false)
	player.end_clip()
	npc.end_clip()
	player.begin_release()
	npc.begin_release()
	if not _side_view():
		player.begin_ease()
		npc.begin_ease()
	if _bare and npc.has_method("set_palette"):
		npc.set_palette(_saved_palette)
		_bare = false
	prompt.visible = false
	var away := npc.global_position - player.global_position
	away.y = 0.0
	if away.length_squared() < 0.01:
		away = Vector3.FORWARD
	npc.begin_approach(player.global_position + away.normalized() * 1.2, player.global_position)
	_stepping_back = npc

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
	for woman in _women:
		if woman:
			SaveStore.save_one(SaveStore.record_for(woman.name))

func _show_wardrobe() -> void:
	var record := SaveStore.record_for(npc.name)
	list_label.text = "Wardrobe  %s\n1  Hair\n2  Shirt\n3  Skirt\n4  Nude\n5  Apply to all women\n6  Name\n7  Generate\n9  Dusk\nEsc close" % record.display_name
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
	var record := SaveStore.record_for(npc.name)
	if code == KEY_1:
		npc.paperdoll.cycle_hair()
		record.hair_override = true
		_last_slot = "hair"
	elif code == KEY_2:
		npc.paperdoll.cycle_shirt()
		record.shirt_override = true
		_last_slot = "shirt"
	elif code == KEY_3:
		npc.paperdoll.cycle_pants()
		record.skirt_override = true
		_last_slot = "skirt"
	elif code == KEY_4:
		var show: bool = not npc.paperdoll.nude
		npc.set_nude(show)
		record.nude = show
		record.chest = show
		record.groin = show
		npc.set_slots(show, show)
		record.nude_override = true
		_last_slot = "nude"
	elif code == KEY_5:
		for woman in _women:
			if woman == null or woman == npc or woman.paperdoll == null:
				continue
			var other := SaveStore.record_for(woman.name)
			if _last_slot == "nude" and other.nude_override:
				continue
			_copy_slot(npc.paperdoll, woman.paperdoll, _last_slot)
			if _last_slot == "nude":
				other.nude = record.nude
	elif code == KEY_6:
		record.display_name = _next_name(record.display_name)
	elif code == KEY_9:
		SaveStore.dusk = fposmod(SaveStore.dusk + 0.2, 1.2)
		SaveStore.save_records()
		if str(npc.name).begins_with("Gen"):
			_women.erase(npc)
			npc.queue_free()
			_close_wardrobe()
	SaveStore.save_records()
	_show_wardrobe()

func _generate_woman() -> void:
	if _women.size() >= 6:
		return
	var scene := load("res://scenes/character_3d.tscn") as PackedScene
	var woman := scene.instantiate() as CharacterBody3D
	woman.name = "Gen%d" % _women.size()
	woman.is_player = false
	woman.palette = "woman_rose"
	get_parent().add_child(woman)
	var occupied: Array = []
	for body in _women:
		if body:
			occupied.append(body.global_position)
	var point: Vector3 = DollMath.spawn_point(occupied, Vector3(4.0, 0.1, 6.0), 1.6)
	woman.global_position = point
	woman.set_schedule([point, point + Vector3(0, 0, -4)])
	var record := SaveStore.record_for(woman.name)
	record.display_name = _next_name(woman.name)
	record.palette = "woman_rose"
	record.nude = false
	record.chest = false
	record.groin = false
	SaveStore.save_one(record)
	_women.append(woman)

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
		var saved := SaveStore.load_one(woman.name)
		if saved == null:
			list_label.text = "Missing record for %s" % woman.name
		elif saved.nude:
			woman.set_nude(true)

func _save_records() -> void:
	SaveStore.last_slot = _last_slot
	SaveStore.records = _records
	SaveStore.save_records()

func _set_hint() -> void:
	hint.text = "Mouse: look    WASD: walk    E: clips    Tab: wardrobe"
	if npc and npc.paperdoll and npc.paperdoll.get("_quarter"):
		hint.text += "    Front fallback"

## The women keep their paperdolls and clothes. The gate sketch stays hidden in this first part.
func _woman_ready() -> void:
	if woman_npc == null:
		return
	var record := SaveStore.record_for(woman_npc.name)
	for body in [woman_npc, npc2]:
		if body:
			var body_record := SaveStore.record_for(body.name)
			if CLEARED_NAMES.has(body_record.display_name):
				body_record.display_name = body_record.id
	_apply_sketch(false)

## Godot 4.3 headless (dummy renderer) logs "Parameter m is null" when a mesh instance is freed
## still holding its mesh; dropping the sketch mesh as the scene exits keeps that log clean.
func _exit_tree() -> void:
	if gate_sketch:
		gate_sketch.mesh = null

func _npc1_name() -> String:
	return SaveStore.record_for(woman_npc.name).display_name

func _apply_sketch(given: bool) -> void:
	if gate_sketch:
		gate_sketch.visible = given
	if given and woman_npc.has_method("set_schedule"):
		woman_npc.set_schedule([chair_mark.global_position])

func _scene_active() -> bool:
	return _scene_beat >= 0 or _scene_walk

func _scene_rows() -> int:
	return 1 if _scene_again else 2

## Sit with the woman: she walks to the chair on her approach walk, sits, then the beats play on the HUD sheet.
## The player stays where he is, frozen in first person, and can still look around.
func _start_scene() -> void:
	_list_open = false
	$"../HUD".hide_panel()
	_scene_again = SaveStore.record_for(woman_npc.name).sketch_given
	_scene_walk = true
	_scene_walk_t = 0.0
	player.set_mode_frozen(true)
	var seat := chair_mark.global_position
	seat.y = woman_npc.global_position.y
	woman_npc.begin_approach(seat, window_mark.global_position)

## She sits when she reaches the chair, or after SIT_WALK_MAX seconds if something blocks her.
func _scene_walk_step(delta: float) -> void:
	_scene_walk_t += delta
	if not woman_npc.approach_done() and not woman_npc.approach_stuck() and _scene_walk_t < SIT_WALK_MAX:
		return
	_scene_walk = false
	woman_npc.begin_clip()
	if woman_npc.paperdoll:
		woman_npc.paperdoll.set_seated(true)
	_show_beat(0)

func _show_beat(beat: int) -> void:
	_scene_beat = beat
	var title := ""
	var lines := PackedStringArray()
	if _scene_again:
		title = "%s: %s" % [_npc1_name(), SIT_AGAIN[0]]
		lines.append("1  %s" % SIT_AGAIN[1])
	else:
		var row: Array = SIT_LINES[beat]
		title = "%s: %s" % [_npc1_name(), row[0]]
		lines.append("1  %s" % row[1])
		lines.append("2  %s" % row[2])
		lines.append("Close")
	$"../HUD".show_choices(lines, title)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

## Either reply advances. The last reply (or Sit a while) ends the scene; Close ends it early without the keep.
func _scene_reply(index: int) -> void:
	if index >= _scene_rows():
		$"../HUD".hide_panel()
		return
	if not _scene_again and _scene_beat + 1 < SIT_LINES.size():
		_show_beat(_scene_beat + 1)
		return
	var kept := not _scene_again
	_scene_beat = -1
	$"../HUD".hide_panel()
	_end_scene(kept)

func _end_scene(kept: bool) -> void:
	var was_walking := _scene_walk
	_scene_beat = -1
	_scene_walk = false
	if was_walking:
		woman_npc.cancel_approach()
	else:
		if woman_npc.paperdoll:
			woman_npc.paperdoll.set_seated(false)
		woman_npc.end_clip()
	player.set_mode_frozen(false)
	if kept:
		_give_sketch()

func _give_sketch() -> void:
	var record := SaveStore.record_for(woman_npc.name)
	record.sketch_given = true
	SaveStore.save_records()
	SaveStore.save_one(record)
	_apply_sketch(true)
