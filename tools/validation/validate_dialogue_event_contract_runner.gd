extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

func _initialize() -> void:
	var content_repository = CONTENT_REPOSITORY_SCRIPT.new()
	var failures: Array[String] = []
	var validated_ids: Array[String] = []

	for event_definition: Dictionary in content_repository.import_story_events_from_csv("res://content/story/act1/csv"):
		var event_id: String = str(event_definition.get("id", event_definition.get("event_id", "")))
		var presentation_type: String = str(event_definition.get("presentation_type", "standard_event"))
		if presentation_type != "dialogue_event":
			continue
		validated_ids.append(event_id)
		var battle_definition: Dictionary = content_repository.get_battle_definition_by_entry_event_id(event_id)
		if battle_definition.is_empty():
			failures.append("%s is dialogue_event but has no battle entry" % event_id)
		var encounter_definition: Dictionary = content_repository.get_dialogue_encounter_definition(event_id)
		if encounter_definition.is_empty():
			failures.append("%s is dialogue_event but has no dialogue encounter" % event_id)

	validated_ids.sort()
	print("dialogue_event ids=%s" % ",".join(validated_ids))

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_dialogue_event_contract_runner: OK")
	quit()
