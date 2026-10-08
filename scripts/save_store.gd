extends Node
## Autoload. user:// survives a scene change.

const PATH := "user://characters.json"

var records: Dictionary = {}
var last_slot := "nude"

func _ready() -> void:
	load_records()

func load_records() -> void:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	records = parsed
	last_slot = str(records.get("_last_slot", "nude"))

func save_records() -> void:
	records["_last_slot"] = last_slot
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(records))

func record_for(id: String) -> Dictionary:
	if not records.has(id) or typeof(records[id]) != TYPE_DICTIONARY:
		records[id] = {}
	return records[id]
