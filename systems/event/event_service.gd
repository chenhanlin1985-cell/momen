class_name EventService
extends RefCounted

const EVENT_EFFECT_EXECUTOR_SCRIPT := preload("res://systems/event/event_effect_executor.gd")
const STORY_EVENT_SCHEDULER_SCRIPT := preload("res://systems/event/story_event_scheduler.gd")

var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator
var _effect_executor
var _story_scheduler

func _init(
	condition_evaluator: ConditionEvaluator,
	run_state_mutator: RunStateMutator
) -> void:
	_condition_evaluator = condition_evaluator
	_run_state_mutator = run_state_mutator
	_effect_executor = EVENT_EFFECT_EXECUTOR_SCRIPT.new(run_state_mutator)
	_story_scheduler = STORY_EVENT_SCHEDULER_SCRIPT.new(condition_evaluator)

func collect_action_followups(
	run_state: RunState,
	content_repository: ContentRepository,
	action_definition: Dictionary,
	action_result: Dictionary
) -> void:
	_run_state_mutator.set_last_action_id(run_state, str(action_definition.get("id", "")))

	if content_repository.get_story_event_definitions(run_state.run_id).is_empty():
		for event_id: String in action_result.get("linked_event_pool", []):
			_run_state_mutator.queue_followup_event(run_state, event_id)

	var risk_weight: int = int(action_definition.get("risk_weight", 0))
	if risk_weight > 0:
		_run_state_mutator.append_log(run_state, "事件张力上升：风险权重 %d。" % risk_weight)

func resolve_current_or_next_event(
	run_state: RunState,
	content_repository: ContentRepository,
	slot: String = "phase_entry"
) -> void:
	if run_state.is_run_over or not run_state.current_event_id.is_empty():
		return

	var next_definition: Dictionary = _story_scheduler.find_next_event(run_state, content_repository, slot)
	if not next_definition.is_empty():
		_run_state_mutator.set_current_event(run_state, str(next_definition.get("id", "")))
		return

	var queued_event_id: String = _get_next_queued_event_id(run_state, content_repository)
	if not queued_event_id.is_empty():
		_run_state_mutator.set_current_event(run_state, queued_event_id)

func choose_option(
	run_state: RunState,
	content_repository: ContentRepository,
	option_id: String
) -> Dictionary:
	var event_definition: Dictionary = get_current_event_definition(run_state, content_repository)
	if event_definition.is_empty():
		return {"success": false, "message": "当前没有可结算的事件。"}

	var option_definition: Dictionary = _find_option_definition(event_definition, option_id)
	if option_definition.is_empty():
		return {"success": false, "message": "未找到事件选项。"}

	var conditions: Array[Dictionary] = Array(
		option_definition.get("conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	if not _condition_evaluator.evaluate_all(run_state, conditions):
		return {"success": false, "message": "当前不满足该选项条件。"}

	var event_id: String = str(event_definition.get("id", ""))
	var result_text: String = str(option_definition.get("result_text", ""))
	_effect_executor.apply_effects(
		run_state,
		Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null)
	)
	_run_state_mutator.mark_event_triggered(run_state, event_id)
	_run_state_mutator.clear_current_event(run_state)

	if not result_text.is_empty():
		_run_state_mutator.append_log(run_state, result_text)

	return {"success": true}

func get_current_event_definition(
	run_state: RunState,
	content_repository: ContentRepository
) -> Dictionary:
	if run_state.current_event_id.is_empty():
		return {}
	var story_definition: Dictionary = content_repository.get_story_event_definition(
		run_state.run_id,
		run_state.current_event_id
	)
	if not story_definition.is_empty():
		return story_definition
	return content_repository.get_event_definition(run_state.current_event_id)

func get_current_event_option_views(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[Dictionary]:
	var event_definition: Dictionary = get_current_event_definition(run_state, content_repository)
	if event_definition.is_empty():
		return []

	var result: Array[Dictionary] = []
	for option_definition: Dictionary in event_definition.get("options", []):
		var conditions: Array[Dictionary] = Array(
			option_definition.get("conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		var is_available: bool = _condition_evaluator.evaluate_all(run_state, conditions)
		var unmet: Array[String] = _condition_evaluator.get_unmet_descriptions(run_state, conditions)
		result.append(
			{
				"id": str(option_definition.get("id", "")),
				"text": str(option_definition.get("text", "")),
				"is_available": is_available,
				"unmet_text": "" if unmet.is_empty() else "需要：" + "，".join(unmet)
			}
		)
	return result

func get_event_hints(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[String]:
	var hints: Array[String] = []
	var definitions: Array[Dictionary] = content_repository.get_story_event_definitions(run_state.run_id)
	var class_order: Dictionary = {
		"ending_check": 400,
		"fixed_story": 300,
		"conditional_story": 200,
		"random_filler": 100
	}
	definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_class: int = int(class_order.get(str(a.get("event_class", "")), 0))
		var b_class: int = int(class_order.get(str(b.get("event_class", "")), 0))
		if a_class == b_class:
			return int(a.get("schedule_priority", 0)) > int(b.get("schedule_priority", 0))
		return a_class > b_class
	)
	for definition: Dictionary in definitions:
		if not _is_hint_candidate(run_state, definition):
			continue
		var conditions: Array[Dictionary] = Array(
			definition.get("trigger_conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		var unmet: Array[String] = _condition_evaluator.get_unmet_descriptions(run_state, conditions)
		if unmet.is_empty():
			continue
		hints.append("%s: %s" % [
			str(definition.get("title", "")),
			", ".join(unmet)
		])
		if hints.size() >= 3:
			break
	return hints

func _get_next_queued_event_id(
	run_state: RunState,
	content_repository: ContentRepository
) -> String:
	for event_id: String in run_state.queued_event_ids:
		var definition: Dictionary = content_repository.get_event_definition(event_id)
		if definition.is_empty():
			continue
		if _is_legacy_event_available(run_state, definition):
			_run_state_mutator.dequeue_followup_event(run_state, event_id)
			return event_id
	return ""

func _is_legacy_event_available(run_state: RunState, definition: Dictionary) -> bool:
	var event_id: String = str(definition.get("id", ""))
	var repeatable: bool = bool(definition.get("repeatable", false))
	if not repeatable and run_state.triggered_event_ids.has(event_id):
		return false
	var conditions: Array[Dictionary] = Array(
		definition.get("trigger_conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	return _condition_evaluator.evaluate_all(run_state, conditions)

func _find_option_definition(event_definition: Dictionary, option_id: String) -> Dictionary:
	for option_definition: Dictionary in event_definition.get("options", []):
		if str(option_definition.get("id", "")) == option_id:
			return option_definition
	return {}

func _is_hint_candidate(run_state: RunState, definition: Dictionary) -> bool:
	var event_id: String = str(definition.get("id", ""))
	if run_state.triggered_event_ids.has(event_id) or run_state.current_event_id == event_id:
		return false
	var day_condition_match: bool = false
	for condition: Dictionary in definition.get("trigger_conditions", []):
		if str(condition.get("type", "")) != "day_range":
			continue
		var min_day: int = int(condition.get("min", 1))
		var max_day: int = int(condition.get("max", 999))
		day_condition_match = run_state.world_state.day >= min_day and run_state.world_state.day <= max_day
		break
	return day_condition_match
