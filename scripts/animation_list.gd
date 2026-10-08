extends RefCounted
class_name AnimationList
## Pivot-curve clips. Same schema the in-game editor will write to user://clips.

const PIVOTS := [
	"arm_l", "arm_r", "elbow_l", "elbow_r",
	"leg_l", "leg_r", "knee_l", "knee_r",
]

static func load_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Clip missing: %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Clip is not an object: %s" % path)
		return {}
	return parsed

static func sample(clip: Dictionary, role: String, time_sec: float) -> Dictionary:
	var pose := {}
	var roles: Dictionary = clip.get("roles", {})
	var tracks: Dictionary = roles.get(role, {})
	for pivot in PIVOTS:
		var keys: Array = tracks.get(pivot, [])
		if keys.is_empty():
			continue
		pose[pivot] = _sample_keys(keys, time_sec)
	var face_keys: Array = tracks.get("face", [])
	if not face_keys.is_empty():
		pose["face"] = _sample_keys(face_keys, time_sec)
	return pose

static func _sample_keys(keys: Array, time_sec: float) -> float:
	if keys.size() == 1:
		return float(keys[0][1])
	if time_sec <= float(keys[0][0]):
		return float(keys[0][1])
	for i in range(1, keys.size()):
		var t1 := float(keys[i][0])
		if time_sec <= t1:
			var t0 := float(keys[i - 1][0])
			var v0 := float(keys[i - 1][1])
			var v1 := float(keys[i][1])
			if t1 <= t0:
				return v1
			var u := (time_sec - t0) / (t1 - t0)
			return lerpf(v0, v1, DollMath.smoothstep(u))
	return float(keys[keys.size() - 1][1])
