extends SceneTree

const STORY_CSV_IMPORTER_SCRIPT := preload("res://systems/content/story_csv_importer.gd")

func _initialize() -> void:
	var importer: StoryCsvImporter = STORY_CSV_IMPORTER_SCRIPT.new()
	var rows: Array[Dictionary] = importer._load_csv_rows("res://content/story/act1/csv/events.csv")
	var failures: Array[String] = []

	for row: Dictionary in rows:
		var event_id: String = str(row.get("event_id", ""))
		var repeatable_value: String = str(row.get("repeatable", ""))
		var desc_key: String = str(row.get("desc_key", ""))
		if repeatable_value.begins_with("evt."):
			failures.append("%s repeatable shifted into title key column" % event_id)
		if desc_key == "generated_from_markdown":
			failures.append("%s desc_key points to generated_from_markdown" % event_id)

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		printerr("validate_story_csv_alignment_runner: FAILED")
		quit(1)
		return

	print("validate_story_csv_alignment_runner: OK")
	quit()
