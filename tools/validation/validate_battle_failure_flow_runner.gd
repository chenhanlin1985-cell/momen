extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

const RUN_ID := "default_run"
const PSYCH_BATTLE_IDS: Array[String] = ["9101", "9201", "9301", "9401"]

func _initialize() -> void:
	var content_repository = CONTENT_REPOSITORY_SCRIPT.new()
	var failures: Array[String] = []

	for battle_id: String in PSYCH_BATTLE_IDS:
		var battle_definition: Dictionary = content_repository.get_battle_definition(battle_id)
		if battle_definition.is_empty():
			failures.append("%s missing battle definition" % battle_id)
			continue
		var failure_event_id: String = str(battle_definition.get("result_event_id_failure", ""))
		if failure_event_id.is_empty():
			failures.append("%s missing result_event_id_failure" % battle_id)
			continue
		var failure_event: Dictionary = content_repository.get_story_event_definition(RUN_ID, failure_event_id)
		if failure_event.is_empty():
			failures.append("%s missing failure event %s" % [battle_id, failure_event_id])
			continue
		var options: Array[Dictionary] = Array(failure_event.get("options", []), TYPE_DICTIONARY, "", null)
		if options.is_empty():
			failures.append("%s failure event %s has no options" % [battle_id, failure_event_id])
			continue
		var has_finish_run: bool = false
		for option_definition: Dictionary in options:
			for effect_definition: Dictionary in Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null):
				if str(effect_definition.get("type", "")) == "finish_run":
					has_finish_run = true
					break
			if has_finish_run:
				break
		if not has_finish_run:
			failures.append("%s failure event %s does not finish run" % [battle_id, failure_event_id])
			continue
		print("%s\tfailure_event=%s\tfinish_run=true" % [battle_id, failure_event_id])

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_battle_failure_flow_runner: OK")
	quit()
