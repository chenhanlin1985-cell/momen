extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

func _initialize() -> void:
	var repo = CONTENT_REPOSITORY_SCRIPT.new()
	var missing_lines: Array[String] = []
	for event_definition: Dictionary in repo.get_story_event_definitions("default_run"):
		for option_definition: Dictionary in Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null):
			var option_id: String = str(option_definition.get("id", ""))
			var option_text: String = str(option_definition.get("text", ""))
			var result_text: String = str(option_definition.get("result_text", ""))
			var success_text: String = str(option_definition.get("success_result_text", ""))
			var failure_text: String = str(option_definition.get("failure_result_text", ""))
			if _looks_like_localization_key(option_text):
				missing_lines.append("%s option text unresolved: %s" % [option_id, option_text])
			if _looks_like_localization_key(result_text):
				missing_lines.append("%s result text unresolved: %s" % [option_id, result_text])
			if _looks_like_localization_key(success_text):
				missing_lines.append("%s success text unresolved: %s" % [option_id, success_text])
			if _looks_like_localization_key(failure_text):
				missing_lines.append("%s failure text unresolved: %s" % [option_id, failure_text])
	if missing_lines.is_empty():
		print("All story event option texts resolved")
		quit()
		return
	for line: String in missing_lines:
		push_error(line)
	quit(1)

func _looks_like_localization_key(text: String) -> bool:
	return text.begins_with("opt.") or text.begins_with("evt.")
