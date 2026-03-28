extends SceneTree

const STORY_ID: String = "act1_well_whisper"
const CSV_DIR: String = "res://content/story/act1/csv"
const JSON_PATHS: Array[String] = [
	"res://content/story/act1/fixed_events.json",
	"res://content/story/act1/conditional_events.json",
	"res://content/story/act1/random_event_pools.json"
]

func _init() -> void:
	var repository: ContentRepository = ContentRepository.new()
	var imported: Array[Dictionary] = repository.import_story_events_from_csv(CSV_DIR)
	var csv_ids: Array[String] = []
	for event_def: Dictionary in imported:
		csv_ids.append(str(event_def.get("id", "")))
	csv_ids.sort()

	var json_ids: Array[String] = []
	for path: String in JSON_PATHS:
		for event_def: Dictionary in _load_array_file(path):
			if str(event_def.get("story_id", STORY_ID)) != STORY_ID:
				continue
			json_ids.append(str(event_def.get("id", "")))
	json_ids.sort()

	var missing_in_csv: Array[String] = []
	for event_id: String in json_ids:
		if not csv_ids.has(event_id):
			missing_in_csv.append(event_id)

	var missing_in_json: Array[String] = []
	for event_id: String in csv_ids:
		if not json_ids.has(event_id):
			missing_in_json.append(event_id)

	print("JSON count: %d" % json_ids.size())
	print("CSV count: %d" % csv_ids.size())
	print("Missing in CSV: %s" % ", ".join(missing_in_csv))
	print("Missing in JSON: %s" % ", ".join(missing_in_json))
	quit()

func _load_array_file(path: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		return []
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []
	var result: Array[Dictionary] = []
	for item: Variant in parsed:
		if item is Dictionary:
			result.append(item.duplicate(true))
	return result
