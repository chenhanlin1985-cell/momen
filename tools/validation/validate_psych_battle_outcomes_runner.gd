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

		var success_event_id: String = str(battle_definition.get("result_event_id_success", ""))
		var failure_event_id: String = str(battle_definition.get("result_event_id_failure", ""))
		if success_event_id.is_empty():
			failures.append("%s missing result_event_id_success" % battle_id)
		if failure_event_id.is_empty():
			failures.append("%s missing result_event_id_failure" % battle_id)
		if success_event_id.is_empty() or failure_event_id.is_empty():
			continue

		var success_event: Dictionary = content_repository.get_story_event_definition(RUN_ID, success_event_id)
		var failure_event: Dictionary = content_repository.get_story_event_definition(RUN_ID, failure_event_id)
		if success_event.is_empty():
			failures.append("%s missing success event %s" % [battle_id, success_event_id])
			continue
		if failure_event.is_empty():
			failures.append("%s missing failure event %s" % [battle_id, failure_event_id])
			continue

		var success_options: Array[Dictionary] = Array(success_event.get("options", []), TYPE_DICTIONARY, "", null)
		var failure_options: Array[Dictionary] = Array(failure_event.get("options", []), TYPE_DICTIONARY, "", null)
		if success_options.is_empty():
			failures.append("%s success event %s has no options" % [battle_id, success_event_id])
		if failure_options.is_empty():
			failures.append("%s failure event %s has no options" % [battle_id, failure_event_id])
		if success_options.is_empty() or failure_options.is_empty():
			continue

		var failure_finishes_run: bool = _event_has_finish_run(failure_options)
		if not failure_finishes_run:
			failures.append("%s failure event %s does not finish run" % [battle_id, failure_event_id])
			continue

		print("%s\tsuccess=%s\tfailure=%s\tfailure_finish_run=true" % [
			battle_id,
			success_event_id,
			failure_event_id
		])

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_psych_battle_outcomes_runner: OK")
	quit()

func _event_has_finish_run(options: Array[Dictionary]) -> bool:
	for option_definition: Dictionary in options:
		for effect_definition: Dictionary in Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null):
			if str(effect_definition.get("type", "")) == "finish_run":
				return true
	return false
