class_name NpcService
extends RefCounted

const EVENT_EFFECT_EXECUTOR_SCRIPT := preload("res://systems/event/event_effect_executor.gd")
const GAME_TEXT := preload("res://systems/content/game_text.gd")
const STORY_EVENT_INTERACTION_PREFIX: String = "story_npc_event::"

var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator
var _effect_executor: EventEffectExecutor


func _init(
	condition_evaluator: ConditionEvaluator,
	run_state_mutator: RunStateMutator
) -> void:
	_condition_evaluator = condition_evaluator
	_run_state_mutator = run_state_mutator
	_effect_executor = EVENT_EFFECT_EXECUTOR_SCRIPT.new(run_state_mutator)


func get_available_interactions_for_current_location(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[Dictionary]:
	var current_location_id: String = run_state.world_state.current_location_id
	if current_location_id.is_empty():
		return []

	var present_npcs: Dictionary = {}
	for npc_definition: Dictionary in content_repository.get_present_npcs_for_location(run_state, current_location_id):
		present_npcs[str(npc_definition.get("id", ""))] = npc_definition

	var result: Array[Dictionary] = []
	for interaction_definition: Dictionary in content_repository.get_npc_interaction_definitions(run_state.story_id):
		var npc_id: String = str(interaction_definition.get("npc_id", ""))
		if not present_npcs.has(npc_id):
			continue
		if _is_idle_talk_interaction(interaction_definition):
			continue

		var allowed_locations: Array[String] = Array(interaction_definition.get("allowed_locations", []), TYPE_STRING, "", null)
		if not allowed_locations.is_empty() and not allowed_locations.has(current_location_id):
			continue

		var conditions: Array[Dictionary] = Array(interaction_definition.get("availability_conditions", []), TYPE_DICTIONARY, "", null)
		if not _condition_evaluator.evaluate_all(run_state, conditions):
			continue
		if not _is_dialogue_interaction_available(run_state, content_repository, interaction_definition):
			continue
		if not _is_referenced_story_event_available(run_state, content_repository, interaction_definition):
			continue

		var view: Dictionary = interaction_definition.duplicate(true)
		view["npc_display_name"] = str(present_npcs[npc_id].get("display_name", _describe_npc(npc_id)))
		result.append(view)

	result.append_array(_build_manual_story_event_interactions(run_state, content_repository, present_npcs))

	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	return result


func get_idle_interaction_for_npc(
	run_state: RunState,
	content_repository: ContentRepository,
	npc_id: String
) -> Dictionary:
	var current_location_id: String = run_state.world_state.current_location_id
	if current_location_id.is_empty() or npc_id.is_empty():
		return {}

	for interaction_definition: Dictionary in content_repository.get_npc_interaction_definitions(run_state.story_id):
		if str(interaction_definition.get("npc_id", "")) != npc_id:
			continue
		if not _is_idle_talk_interaction(interaction_definition):
			continue

		var allowed_locations: Array[String] = Array(interaction_definition.get("allowed_locations", []), TYPE_STRING, "", null)
		if not allowed_locations.is_empty() and not allowed_locations.has(current_location_id):
			continue

		var conditions: Array[Dictionary] = Array(interaction_definition.get("availability_conditions", []), TYPE_DICTIONARY, "", null)
		if not _condition_evaluator.evaluate_all(run_state, conditions):
			continue

		return interaction_definition.duplicate(true)

	return {}


func interact(run_state: RunState, content_repository: ContentRepository, interaction_id: String) -> Dictionary:
	if run_state.is_run_over:
		return {"success": false, "message": GAME_TEXT.text("npc_service.errors.run_over")}

	if is_story_event_interaction_id(interaction_id):
		return _open_story_event_interaction(run_state, content_repository, interaction_id)

	if run_state.world_state.actions_remaining <= 0:
		return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_unavailable")}

	var interaction_definition: Dictionary = content_repository.get_npc_interaction_definition(interaction_id)
	if interaction_definition.is_empty():
		return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_missing")}
	if not _is_dialogue_interaction_available(run_state, content_repository, interaction_definition):
		return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_unavailable")}
	if not _is_referenced_story_event_available(run_state, content_repository, interaction_definition):
		return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_unavailable")}

	var allowed_here: bool = false
	for item: Dictionary in get_available_interactions_for_current_location(run_state, content_repository):
		if str(item.get("id", "")) != interaction_id:
			continue
		allowed_here = true
		break
	if not allowed_here:
		return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_unavailable")}

	_run_state_mutator.set_last_action_id(run_state, str(interaction_definition.get("trigger_action_id", "npc_interaction")))
	_run_state_mutator.set_last_action_category(run_state, str(interaction_definition.get("interaction_category", "talk")))
	var dialogue_event_id: String = str(interaction_definition.get("dialogue_event_id", ""))
	var npc_name: String = str(interaction_definition.get("npc_display_name", _describe_npc(str(interaction_definition.get("npc_id", "")))))
	_run_state_mutator.append_log(
		run_state,
		GAME_TEXT.format_text(
			"npc_service.logs.interact",
			[npc_name, str(interaction_definition.get("display_name", interaction_id))]
		)
	)
	if not dialogue_event_id.is_empty():
		return {"success": true, "opened_event_id": dialogue_event_id}
	if _to_bool(interaction_definition.get("consumes_action", true)):
		_run_state_mutator.consume_action_point(run_state)

	_effect_executor.apply_effects(run_state, Array(interaction_definition.get("effects", []), TYPE_DICTIONARY, "", null))

	var result_text: String = str(interaction_definition.get("result_text", ""))
	if not result_text.is_empty():
		_run_state_mutator.append_log(run_state, result_text)

	return {"success": true}


func is_story_event_interaction_id(interaction_id: String) -> bool:
	return interaction_id.begins_with(STORY_EVENT_INTERACTION_PREFIX)


func _is_idle_talk_interaction(interaction_definition: Dictionary) -> bool:
	return (
		str(interaction_definition.get("interaction_category", "")) == "talk"
		and str(interaction_definition.get("dialogue_event_id", "")).is_empty()
	)


func _is_dialogue_interaction_available(
	run_state: RunState,
	content_repository: ContentRepository,
	interaction_definition: Dictionary
) -> bool:
	var dialogue_event_id: String = str(interaction_definition.get("dialogue_event_id", ""))
	if dialogue_event_id.is_empty():
		return true
	var event_definition: Dictionary = content_repository.get_story_event_definition(run_state.run_id, dialogue_event_id)
	if event_definition.is_empty():
		return true
	if _to_bool(event_definition.get("repeatable", false)):
		return true
	return not run_state.triggered_event_ids.has(dialogue_event_id)


func _is_referenced_story_event_available(
	run_state: RunState,
	content_repository: ContentRepository,
	interaction_definition: Dictionary
) -> bool:
	var dialogue_event_id: String = str(interaction_definition.get("dialogue_event_id", ""))
	if dialogue_event_id.is_empty():
		return true
	var event_definition: Dictionary = content_repository.get_story_event_definition(run_state.run_id, dialogue_event_id)
	if event_definition.is_empty():
		return true
	return _is_story_event_available(run_state, event_definition)


func _build_manual_story_event_interactions(
	run_state: RunState,
	content_repository: ContentRepository,
	present_npcs: Dictionary
) -> Array[Dictionary]:
	var current_location_id: String = run_state.world_state.current_location_id
	var result: Array[Dictionary] = []
	if current_location_id.is_empty():
		return result
	if run_state.world_state.current_phase != "day":
		return result

	for definition: Dictionary in content_repository.get_story_event_definitions_for_location(run_state.run_id, current_location_id):
		if not _is_manual_story_interaction_candidate(run_state, definition):
			continue

		var npc_id: String = _resolve_story_event_npc_id(definition, present_npcs)
		if npc_id.is_empty():
			continue
		if _has_explicit_dialogue_interaction(content_repository, run_state.story_id, npc_id, str(definition.get("id", ""))):
			continue

		var npc_definition: Dictionary = present_npcs.get(npc_id, {})
		result.append({
			"id": STORY_EVENT_INTERACTION_PREFIX + str(definition.get("id", "")),
			"npc_id": npc_id,
			"npc_display_name": str(npc_definition.get("display_name", _describe_npc(npc_id))),
			"interaction_category": "talk",
			"display_name": str(definition.get("title", definition.get("id", ""))),
			"description": str(definition.get("description", "")),
			"dialogue_event_id": str(definition.get("id", "")),
			"consumes_action": false,
			"sort_order": 500 + max(0, 400 - int(definition.get("schedule_priority", 0))),
			"is_story_event_interaction": true
		})
	return result


func _is_manual_story_interaction_candidate(run_state: RunState, definition: Dictionary) -> bool:
	if str(definition.get("event_class", "")) != "conditional_story":
		return false
	if str(definition.get("slot", "")) != "post_action":
		return false
	if str(definition.get("content_category", "")) != "npc_state":
		return false
	if str(definition.get("time_slot", "")) == "night":
		return false
	return _is_story_event_available(run_state, definition)


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


func _resolve_story_event_npc_id(definition: Dictionary, present_npcs: Dictionary) -> String:
	var speaker_npc_id: String = str(definition.get("speaker_npc_id", ""))
	if not speaker_npc_id.is_empty() and present_npcs.has(speaker_npc_id):
		return speaker_npc_id

	var participants: Array[String] = Array(definition.get("participants", []), TYPE_STRING, "", null)
	for participant_id: String in participants:
		if participant_id == "player":
			continue
		if present_npcs.has(participant_id):
			return participant_id
	return ""


func _has_explicit_dialogue_interaction(
	content_repository: ContentRepository,
	story_id: String,
	npc_id: String,
	dialogue_event_id: String
) -> bool:
	for interaction_definition: Dictionary in content_repository.get_npc_interaction_definitions(story_id):
		if str(interaction_definition.get("npc_id", "")) != npc_id:
			continue
		if str(interaction_definition.get("dialogue_event_id", "")) == dialogue_event_id:
			return true
	return false


func _open_story_event_interaction(
	run_state: RunState,
	content_repository: ContentRepository,
	interaction_id: String
) -> Dictionary:
	for interaction_definition: Dictionary in get_available_interactions_for_current_location(run_state, content_repository):
		if str(interaction_definition.get("id", "")) != interaction_id:
			continue
		var event_id: String = str(interaction_definition.get("dialogue_event_id", ""))
		if event_id.is_empty():
			return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_unavailable")}
		_run_state_mutator.set_last_action_id(run_state, event_id)
		_run_state_mutator.set_last_action_category(run_state, "story_followup")
		_run_state_mutator.append_log(
			run_state,
			GAME_TEXT.format_text(
				"npc_service.logs.interact",
				[
					str(interaction_definition.get("npc_display_name", _describe_npc(str(interaction_definition.get("npc_id", ""))))),
					str(interaction_definition.get("display_name", interaction_id))
				]
			)
		)
		return {"success": true, "opened_event_id": event_id}
	return {"success": false, "message": GAME_TEXT.text("npc_service.errors.interaction_unavailable")}


func _describe_npc(npc_id: String) -> String:
	var labels: Dictionary = GAME_TEXT.dict("npc_service.npc_labels")
	return str(labels.get(npc_id, GAME_TEXT.text("npc_service.npc_labels.default")))

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
