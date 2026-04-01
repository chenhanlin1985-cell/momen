class_name EndingService
extends RefCounted

const ENDING_RESULT_SCRIPT := preload("res://core/models/ending_result.gd")

var _condition_evaluator: ConditionEvaluator

func _init(condition_evaluator: ConditionEvaluator) -> void:
	_condition_evaluator = condition_evaluator

func resolve_ending(
	run_state: RunState,
	ending_definitions: Array[Dictionary]
) -> RefCounted:
	var sorted_definitions: Array[Dictionary] = ending_definitions.duplicate(true)
	sorted_definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)

	for definition: Dictionary in sorted_definitions:
		var conditions: Array[Dictionary] = Array(
			definition.get("conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		if _condition_evaluator.evaluate_all(run_state, conditions):
			return ENDING_RESULT_SCRIPT.from_dict(definition)

	return ENDING_RESULT_SCRIPT.from_dict({})

func resolve_story_flow_ending(
	run_state: RunState,
	flow_definition: Dictionary,
	ending_definitions: Array[Dictionary]
) -> RefCounted:
	if not should_resolve_story_flow(run_state, flow_definition):
		return ENDING_RESULT_SCRIPT.from_dict({})

	var nodes: Array[Dictionary] = Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null)
	if nodes.is_empty():
		return ENDING_RESULT_SCRIPT.from_dict({})

	var final_resolution_node: Dictionary = {}
	for node_definition: Dictionary in nodes:
		if Array(node_definition.get("resolution_checks", []), TYPE_DICTIONARY, "", null).is_empty():
			continue
		if final_resolution_node.is_empty() or int(node_definition.get("day", 0)) >= int(final_resolution_node.get("day", 0)):
			final_resolution_node = node_definition

	if final_resolution_node.is_empty():
		return ENDING_RESULT_SCRIPT.from_dict({})

	var gate_check: Dictionary = Dictionary(final_resolution_node.get("gate_check", {}))
	if not gate_check.is_empty() and not _condition_evaluator.evaluate(run_state, gate_check):
		return _resolve_flow_fallback(final_resolution_node, ending_definitions)

	for resolution_check: Dictionary in Array(final_resolution_node.get("resolution_checks", []), TYPE_DICTIONARY, "", null):
		if not _flags_satisfied(run_state, Array(resolution_check.get("requires_flags", []), TYPE_STRING, "", null)):
			continue

		var ending_id: String = str(resolution_check.get("ending_id", ""))
		if ending_id.is_empty():
			continue

		var ending_definition: Dictionary = _find_ending_definition(ending_definitions, ending_id)
		if ending_definition.is_empty():
			continue

		var ending_conditions: Array[Dictionary] = Array(
			ending_definition.get("conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		if _condition_evaluator.evaluate_all(run_state, ending_conditions):
			return ENDING_RESULT_SCRIPT.from_dict(ending_definition)

	return _resolve_flow_fallback(final_resolution_node, ending_definitions)

func _resolve_flow_fallback(final_resolution_node: Dictionary, ending_definitions: Array[Dictionary]) -> RefCounted:
	var fallback_ending_id: String = str(final_resolution_node.get("fallback_ending_id", ""))
	if not fallback_ending_id.is_empty():
		var fallback_definition: Dictionary = _find_ending_definition(ending_definitions, fallback_ending_id)
		if not fallback_definition.is_empty():
			return ENDING_RESULT_SCRIPT.from_dict(fallback_definition)

	return ENDING_RESULT_SCRIPT.from_dict({})

func should_resolve_story_flow(run_state: RunState, flow_definition: Dictionary) -> bool:
	var end_reason: String = run_state.end_reason
	if end_reason == "ending_check" or end_reason == "ending_resolution":
		return true

	var final_resolution_day: int = _get_final_resolution_day(flow_definition)
	if final_resolution_day <= 0:
		return false

	return end_reason == "survived_cycle" and run_state.world_state.day >= final_resolution_day

func _get_final_resolution_day(flow_definition: Dictionary) -> int:
	var latest_day: int = -1
	for node_definition: Dictionary in Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null):
		var resolution_checks: Array[Dictionary] = Array(node_definition.get("resolution_checks", []), TYPE_DICTIONARY, "", null)
		if resolution_checks.is_empty():
			continue
		latest_day = max(latest_day, int(node_definition.get("day", 0)))
	return latest_day

func _flags_satisfied(run_state: RunState, required_flags: Array[String]) -> bool:
	for flag_key: String in required_flags:
		if not _to_bool(run_state.world_state.global_flags.get(flag_key, false)):
			return false
	return true

func _find_ending_definition(ending_definitions: Array[Dictionary], ending_id: String) -> Dictionary:
	for definition: Dictionary in ending_definitions:
		if str(definition.get("id", "")) == ending_id:
			return definition
	return {}

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
