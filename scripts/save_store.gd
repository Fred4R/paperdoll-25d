extends Node
## Autoload. user:// survives a scene change.

const PATH := "user://characters.json"

var records: Dictionary = {}
var last_slot := "nude"
var dusk := 0.0

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
	dusk = float(records.get("_dusk", 0.0))

var cast: Dictionary = {}

func record_for(id: String) -> CharacterRecord:
	if not cast.has(id):
		var record := CharacterRecord.new()
		record.id = id
		var raw: Dictionary = records.get(id, {})
		record.display_name = str(raw.get("name", id))
		record.nude = bool(raw.get("nude", false))
		record.nude_override = bool(raw.get("nude_override", false))
		record.chest = bool(raw.get("chest", false))
		record.groin = bool(raw.get("groin", false))
		record.sketch_given = bool(raw.get("sketch_given", false))
		cast[id] = record
	return cast[id]

func save_one(record: CharacterRecord) -> void:
	DirAccess.make_dir_recursive_absolute("user://records")
	var err := ResourceSaver.save(record, "user://records/%s.tres" % record.id)
	if err != OK:
		push_warning("Record save failed for %s" % record.id)

func load_one(id: String) -> CharacterRecord:
	var path := "user://records/%s.tres" % id
	if not FileAccess.file_exists(path):
		return null
	return load(path) as CharacterRecord

func save_records() -> void:
	for id in cast.keys():
		var record: CharacterRecord = cast[id]
		records[id] = {
			"name": record.display_name,
			"nude": record.nude,
			"nude_override": record.nude_override,
			"palette": record.palette,
			"chest": record.chest,
			"groin": record.groin,
			"sketch_given": record.sketch_given,
		}
	records["_last_slot"] = last_slot
	records["_dusk"] = dusk
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(records))
