class_name ActionService
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")

var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator


func _init(
	condition_evaluator: ConditionEvaluator,
	run_state_mutator: RunStateMutator
) -> void:
	_condition_evaluator = condition_evaluator
	_run_state_mutator = run_state_mutator


func execute_action(run_state: RunState, action_definition: Dictionary) -> Dictionary:
	if run_state.is_run_over:
		return {"success": false, "message": GAME_TEXT.text("action_service.errors.run_over")}

	var availability_conditions: Array[Dictionary] = Array(
		action_definition.get("availability_conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	if not _condition_evaluator.evaluate_all(run_state, availability_conditions):
		return {"success": false, "message": GAME_TEXT.text("action_service.errors.unavailable")}

	var target_location_id: String = str(action_definition.get("target_location_id", ""))
	if not target_location_id.is_empty():
		_run_state_mutator.set_current_location_id(run_state, target_location_id)
		_run_state_mutator.increment_location_visit_count(run_state, target_location_id)

	_apply_resource_changes(run_state, action_definition.get("base_costs", {}).get("resources", {}), -1)
	_apply_resource_changes(run_state, action_definition.get("base_rewards", {}).get("resources", {}), 1)
	_apply_stat_changes(run_state, action_definition.get("base_rewards", {}).get("stats", {}))
	_apply_tags(run_state, action_definition.get("base_rewards", {}).get("tags", []))

	_run_state_mutator.append_log(
		run_state,
		GAME_TEXT.format_text(
			"action_service.logs.execute",
			[str(action_definition.get("display_name", action_definition.get("id", "")))]
		)
	)
	var feedback_text: String = _build_action_feedback(action_definition)
	if not feedback_text.is_empty():
		_run_state_mutator.append_log(run_state, feedback_text)

	return {
		"success": true,
		"action_id": str(action_definition.get("id", "")),
		"linked_event_pool": Array(action_definition.get("linked_event_pool", []), TYPE_STRING, "", null)
	}


func _apply_resource_changes(run_state: RunState, delta_source: Dictionary, multiplier: int) -> void:
	for key: String in delta_source.keys():
		_run_state_mutator.modify_player_resource(run_state, key, int(delta_source[key]) * multiplier)


func _apply_stat_changes(run_state: RunState, delta_source: Dictionary) -> void:
	for key: String in delta_source.keys():
		_run_state_mutator.modify_player_stat(run_state, key, int(delta_source[key]))


func _apply_tags(run_state: RunState, tag_source: Array) -> void:
	for tag: Variant in tag_source:
		_run_state_mutator.add_player_tag(run_state, str(tag))


func _build_action_feedback(action_definition: Dictionary) -> String:
	var parts: Array[String] = []
	var costs: Dictionary = action_definition.get("base_costs", {}).get("resources", {})
	var rewards: Dictionary = action_definition.get("base_rewards", {}).get("resources", {})
	var stats: Dictionary = action_definition.get("base_rewards", {}).get("stats", {})

	for key: String in costs.keys():
		parts.append("%s -%d" % [_describe_key(key), int(costs[key])])
	for key: String in rewards.keys():
		parts.append("%s +%d" % [_describe_key(key), int(rewards[key])])
	for key: String in stats.keys():
		parts.append("%s +%d" % [_describe_key(key), int(stats[key])])

	return "" if parts.is_empty() else GAME_TEXT.text("action_service.logs.feedback_prefix") + "，".join(parts)


func _describe_key(key: String) -> String:
	var labels: Dictionary = GAME_TEXT.dict("action_service.key_labels")
	return str(labels.get(key, key))
