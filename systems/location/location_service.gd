class_name LocationService
extends RefCounted

const STORY_EVENT_ACTION_PREFIX: String = "story_event::"

var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator


func _init(
	condition_evaluator: ConditionEvaluator,
	run_state_mutator: RunStateMutator
) -> void:
	_condition_evaluator = condition_evaluator
	_run_state_mutator = run_state_mutator


func get_current_location_definition(run_state: RunState, content_repository: ContentRepository) -> Dictionary:
	if run_state.world_state.current_location_id.is_empty():
		return {}
	return content_repository.get_location_definition(run_state.world_state.current_location_id)


func get_available_actions_for_current_location(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[Dictionary]:
	var current_location_id: String = run_state.world_state.current_location_id
	var result: Array[Dictionary] = content_repository.get_visible_actions(
		run_state,
		_condition_evaluator,
		current_location_id
	)
	result.append_array(_build_manual_story_event_actions(run_state, content_repository, current_location_id))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	return result


func get_present_npcs(
	run_state: RunState,
	content_repository: ContentRepository,
	location_id: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if location_id.is_empty():
		return result
	for definition: Dictionary in content_repository.get_present_npcs_for_location(run_state, location_id):
		var availability_conditions: Array[Dictionary] = Array(definition.get("availability_conditions", []), TYPE_DICTIONARY, "", null)
		if not _condition_evaluator.evaluate_all(run_state, availability_conditions):
			continue
		result.append(definition.duplicate(true))
	return result


func get_present_npcs_for_current_location(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[Dictionary]:
	return get_present_npcs(run_state, content_repository, run_state.world_state.current_location_id)


func is_story_event_action_id(action_id: String) -> bool:
	return action_id.begins_with(STORY_EVENT_ACTION_PREFIX)


func resolve_story_event_action_id(action_id: String) -> String:
	if not is_story_event_action_id(action_id):
		return ""
	return action_id.trim_prefix(STORY_EVENT_ACTION_PREFIX)


func _build_manual_story_event_actions(
	run_state: RunState,
	content_repository: ContentRepository,
	location_id: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if location_id.is_empty():
		return result
	if run_state.world_state.current_phase != "day":
		return result

	for definition: Dictionary in content_repository.get_story_event_definitions_for_location(run_state.run_id, location_id):
		if not _is_manual_story_action_candidate(run_state, definition):
			continue
		result.append(_build_story_event_action_view(definition))
	return result


func _is_manual_story_action_candidate(run_state: RunState, definition: Dictionary) -> bool:
	if str(definition.get("event_class", "")) != "conditional_story":
		return false
	if str(definition.get("slot", "")) != "post_action":
		return false
	if str(definition.get("content_category", "")) != "location_content":
		return false
	if str(definition.get("time_slot", "")) == "night":
		return false
	if not _is_story_event_available(run_state, definition):
		return false
	return true


func _is_story_event_available(run_state: RunState, definition: Dictionary) -> bool:
	var event_id: String = str(definition.get("id", ""))
	if event_id.is_empty():
		return false
	if not _to_bool(definition.get("repeatable", false)) and run_state.triggered_event_ids.has(event_id):
		return false

	var block_conditions: Array[Dictionary] = Array(
		definition.get("block_conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	if not block_conditions.is_empty() and _condition_evaluator.evaluate_all(run_state, block_conditions):
		return false

	var conditions: Array[Dictionary] = Array(
		definition.get("trigger_conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	return _condition_evaluator.evaluate_all(run_state, conditions)


func _build_story_event_action_view(definition: Dictionary) -> Dictionary:
	var event_id: String = str(definition.get("id", ""))
	var action_category: String = "combat" if str(definition.get("presentation_type", "")) == "combat_event" else "investigate"
	return {
		"id": STORY_EVENT_ACTION_PREFIX + event_id,
		"trigger_action_id": event_id,
		"action_category": action_category,
		"display_name": str(definition.get("title", event_id)),
		"description": str(definition.get("description", "")),
		"sort_order": 500 + max(0, 400 - int(definition.get("schedule_priority", 0))),
		"is_visible": true,
		"is_story_event_action": true,
		"story_event_id": event_id
	}

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized: String = str(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1" or normalized == "yes"
		_:
			return value != null
