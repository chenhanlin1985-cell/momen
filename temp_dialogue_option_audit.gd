extends SceneTree


func _init() -> void:
	var repo := ContentRepository.new()
	var defs := repo.get_story_event_definitions("default_run")
	for definition: Dictionary in defs:
		if str(definition.get("presentation_type", "")) != "dialogue_event":
			continue
		var event_id: String = str(definition.get("id", ""))
		var option_count: int = Array(definition.get("options", []), TYPE_DICTIONARY, "", null).size()
		print(
			"dialogue_event=",
			event_id,
			" options=",
			option_count,
			" resource=",
			str(definition.get("dialogue_resource_path", ""))
		)
	quit()
