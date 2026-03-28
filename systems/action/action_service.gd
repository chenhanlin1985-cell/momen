class_name ActionService
extends RefCounted

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
		return {"success": false, "message": "本局已经结束。"}
	if run_state.world_state.actions_remaining <= 0:
		return {"success": false, "message": "今日行动次数已用尽。"}

	var availability_conditions: Array[Dictionary] = Array(
		action_definition.get("availability_conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	if not _condition_evaluator.evaluate_all(run_state, availability_conditions):
		return {"success": false, "message": "当前不满足该行动条件。"}

	_apply_resource_changes(
		run_state,
		action_definition.get("base_costs", {}).get("resources", {}),
		-1
	)
	_apply_resource_changes(
		run_state,
		action_definition.get("base_rewards", {}).get("resources", {}),
		1
	)
	_apply_stat_changes(
		run_state,
		action_definition.get("base_rewards", {}).get("stats", {})
	)
	_apply_tags(
		run_state,
		action_definition.get("base_rewards", {}).get("tags", [])
	)

	_run_state_mutator.consume_action_point(run_state)
	_run_state_mutator.append_log(
		run_state,
		"执行行动: %s" % str(action_definition.get("display_name", action_definition.get("id", "")))
	)
	var feedback_text: String = _build_action_feedback(action_definition)
	if not feedback_text.is_empty():
		_run_state_mutator.append_log(run_state, feedback_text)

	return {
		"success": true,
		"action_id": str(action_definition.get("id", "")),
		"linked_event_pool": Array(action_definition.get("linked_event_pool", []), TYPE_STRING, "", null)
	}

func _apply_resource_changes(
	run_state: RunState,
	delta_source: Dictionary,
	multiplier: int
) -> void:
	for key: String in delta_source.keys():
		_run_state_mutator.modify_player_resource(
			run_state,
			key,
			int(delta_source[key]) * multiplier
		)

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

	return "" if parts.is_empty() else "行动反馈: " + "，".join(parts)

func _describe_key(key: String) -> String:
	var labels: Dictionary = {
		"blood_qi": "血气",
		"spirit_stone": "灵石",
		"spirit_sense": "神识",
		"clue_fragments": "线索",
		"pollution": "污染",
		"exposure": "暴露",
		"mind": "心智",
		"tact": "手腕",
		"insight": "悟性"
	}
	return str(labels.get(key, key))
