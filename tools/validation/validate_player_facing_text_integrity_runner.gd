extends SceneTree

const STORY_CSV_IMPORTER_SCRIPT := preload("res://systems/content/story_csv_importer.gd")

func _initialize() -> void:
	var importer: StoryCsvImporter = STORY_CSV_IMPORTER_SCRIPT.new()
	var event_rows: Array[Dictionary] = importer._load_csv_rows("res://content/story/act1/csv/events.csv")
	var localization_map: Dictionary = {}
	var failures: Array[String] = []

	var file: FileAccess = FileAccess.open("res://content/story/act1/csv/localization.csv", FileAccess.READ)
	if file == null:
		printerr("validate_player_facing_text_integrity_runner: FAILED to open localization.csv")
		quit(1)
		return
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.is_empty():
			continue
		var key: String = row[0].strip_edges()
		if key.is_empty():
			continue
		var value: String = ""
		if row.size() > 1:
			value = row[1].strip_edges()
		localization_map[key] = value

	for row: Dictionary in event_rows:
		var event_id: String = str(row.get("event_id", ""))
		var title_key: String = str(row.get("title_key", ""))
		var desc_key: String = str(row.get("desc_key", ""))
		if title_key.begins_with("evt.") and str(localization_map.get(title_key, "")).is_empty():
			failures.append("%s missing title localization: %s" % [event_id, title_key])
		if desc_key.begins_with("evt.") and str(localization_map.get(desc_key, "")).is_empty():
			failures.append("%s missing desc localization: %s" % [event_id, desc_key])
		if desc_key == "generated_from_markdown":
			failures.append("%s desc_key leaked generated_from_markdown" % event_id)

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		printerr("validate_player_facing_text_integrity_runner: FAILED")
		quit(1)
		return

	print("validate_player_facing_text_integrity_runner: OK")
	quit()
