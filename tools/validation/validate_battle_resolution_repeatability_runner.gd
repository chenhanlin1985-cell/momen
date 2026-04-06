extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

func _initialize() -> void:
	var repository: ContentRepository = CONTENT_REPOSITORY_SCRIPT.new()
	var failures: Array[String] = []
	for event_id: String in ["9102", "9103", "9202", "9203", "9302", "9303", "9402", "9403", "9502", "9503"]:
		var definition: Dictionary = repository.get_story_event_definition("default_run", event_id)
		if definition.is_empty():
			failures.append("missing event %s" % event_id)
			continue
		if bool(definition.get("repeatable", false)):
			failures.append("%s should not be repeatable" % event_id)
	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		printerr("validate_battle_resolution_repeatability_runner: FAILED")
		quit(1)
		return
	print("validate_battle_resolution_repeatability_runner: OK")
	quit()
