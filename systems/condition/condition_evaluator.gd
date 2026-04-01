class_name ConditionEvaluator
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")
const LOCATION_RUNTIME_STATE_SCRIPT := preload("res://core/models/location_runtime_state.gd")

func evaluate_all(run_state: RunState, conditions: Array[Dictionary]) -> bool:
	for condition: Dictionary in conditions:
		if not evaluate(run_state, condition):
			return false
	return true

func get_unmet_descriptions(run_state: RunState, conditions: Array[Dictionary]) -> Array[String]:
	var descriptions: Array[String] = []
	for condition: Dictionary in conditions:
		descriptions.append_array(_get_unmet_description_list(run_state, condition))
	return descriptions

func evaluate(run_state: RunState, condition: Dictionary) -> bool:
	var condition_type: String = str(condition.get("type", ""))
	match condition_type:
		"stat_gte":
			return _get_player_stat(run_state, str(condition.get("key", ""))) >= int(condition.get("value", 0))
		"resource_gte":
			return _get_player_resource(run_state, str(condition.get("key", ""))) >= int(condition.get("value", 0))
		"resource_lte":
			return _get_player_resource(run_state, str(condition.get("key", ""))) <= int(condition.get("value", 0))
		"tag_present":
			return _has_tag(run_state, str(condition.get("scope", "player")), str(condition.get("key", "")))
		"flag_present":
			return _to_bool(run_state.world_state.global_flags.get(str(condition.get("key", "")), false))
		"flag_not_present":
			return not _to_bool(run_state.world_state.global_flags.get(str(condition.get("key", "")), false))
		"day_range":
			var day: int = run_state.world_state.day
			return day >= int(condition.get("min", 1)) and day <= int(condition.get("max", 999))
		"day_gte":
			return run_state.world_state.day >= int(condition.get("value", 0))
		"phase_is":
			return _normalize_phase(run_state.world_state.current_phase) == _normalize_phase(str(condition.get("value", "")))
		"last_action_is":
			return run_state.world_state.last_action_id == str(condition.get("value", ""))
		"last_action_category_is":
			return run_state.world_state.last_action_category == str(condition.get("value", ""))
		"current_location_is":
			return run_state.world_state.current_location_id == str(condition.get("value", ""))
		"location_unlocked":
			return _get_location_runtime(run_state, str(condition.get("location_id", condition.get("value", "")))).is_unlocked
		"location_blocked":
			return _get_location_runtime(run_state, str(condition.get("location_id", condition.get("value", "")))).is_blocked
		"location_tag_present":
			return _get_location_runtime(run_state, str(condition.get("location_id", ""))).tags.has(str(condition.get("key", "")))
		"location_value_gte":
			var runtime_state: Variant = _get_location_runtime(run_state, str(condition.get("location_id", "")))
			return int(runtime_state.values.get(str(condition.get("key", "")), 0)) >= int(condition.get("value", 0))
		"world_value_gte":
			return int(run_state.world_state.values.get(str(condition.get("key", "")), 0)) >= int(condition.get("value", 0))
		"npc_relation_gte":
			return _get_npc_relation(
				run_state,
				str(condition.get("npc_id", "")),
				str(condition.get("field", "favor"))
			) >= int(condition.get("value", 0))
		"npc_available":
			return _get_npc_state(run_state, str(condition.get("npc_id", condition.get("value", "")))).is_available
		"npc_at_location":
			return _get_npc_state(run_state, str(condition.get("npc_id", ""))).current_location_id == str(condition.get("value", ""))
		"npc_tag_present":
			return _get_npc_state(run_state, str(condition.get("npc_id", ""))).tags.has(str(condition.get("key", "")))
		"knowledge_present":
			return run_state.player_state.knowledge.has(str(condition.get("key", "")))
		"all_of":
			return evaluate_all(
				run_state,
				Array(condition.get("conditions", []), TYPE_DICTIONARY, "", null)
			)
		"any_of":
			for child: Dictionary in condition.get("conditions", []):
				if evaluate(run_state, child):
					return true
			return false
		_:
			return true

func _get_player_stat(run_state: RunState, key: String) -> int:
	return int(run_state.player_state.stats.get(key, 0))

func _get_player_resource(run_state: RunState, key: String) -> int:
	return int(run_state.player_state.resources.get(key, 0))

func _has_tag(run_state: RunState, scope: String, key: String) -> bool:
	if scope == "world":
		return run_state.world_state.tags.has(key)
	return run_state.player_state.tags.has(key)

func _get_npc_relation(run_state: RunState, npc_id: String, field: String) -> int:
	var npc_state: NpcState = _get_npc_state(run_state, npc_id)
	if field == "alert":
		return npc_state.alert
	return npc_state.favor

func _get_npc_state(run_state: RunState, npc_id: String) -> NpcState:
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.id != npc_id:
			continue
		return npc_state
	return NpcState.new()

func _get_location_runtime(run_state: RunState, location_id: String) -> Variant:
	var runtime_state: Variant = run_state.world_state.location_states.get(location_id)
	if runtime_state is RefCounted and runtime_state.has_method("to_dict"):
		return runtime_state
	if runtime_state is Dictionary:
		var restored: Variant = LOCATION_RUNTIME_STATE_SCRIPT.new().apply_dict(runtime_state)
		run_state.world_state.location_states[location_id] = restored
		return restored
	var fallback_state: Variant = LOCATION_RUNTIME_STATE_SCRIPT.new()
	fallback_state.id = location_id
	run_state.world_state.location_states[location_id] = fallback_state
	return fallback_state

func _get_unmet_description_list(run_state: RunState, condition: Dictionary) -> Array[String]:
	if evaluate(run_state, condition):
		return []

	var condition_type: String = str(condition.get("type", ""))
	match condition_type:
		"all_of":
			return get_unmet_descriptions(
				run_state,
				Array(condition.get("conditions", []), TYPE_DICTIONARY, "", null)
			)
		"any_of":
			var child_descriptions: Array[String] = []
			for child: Dictionary in condition.get("conditions", []):
				child_descriptions.append(_describe_condition(child))
			return [GAME_TEXT.text("condition_evaluator.any_of_prefix") + " / ".join(child_descriptions)]
		_:
			return [_describe_condition(condition)]

func _describe_condition(condition: Dictionary) -> String:
	var condition_type: String = str(condition.get("type", ""))
	var templates: Dictionary = GAME_TEXT.dict("condition_evaluator.description_templates")
	match condition_type:
		"resource_gte":
			return "%s >= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"resource_lte":
			return "%s <= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"stat_gte":
			return "%s >= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"tag_present":
			return _describe_tag(str(condition.get("key", "")))
		"flag_present":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.flag_present", [_describe_flag(str(condition.get("key", "")))], str(templates.get("flag_present", "")))
		"flag_not_present":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.flag_not_present", [_describe_flag(str(condition.get("key", "")))], str(templates.get("flag_not_present", "")))
		"knowledge_present":
			return _describe_knowledge(str(condition.get("key", "")))
		"world_value_gte":
			return "%s >= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"npc_relation_gte":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.npc_relation_gte",
				[
					_describe_npc(str(condition.get("npc_id", ""))),
					_describe_relation_label(str(condition.get("field", "favor"))),
					int(condition.get("value", 0))
				],
				str(templates.get("npc_relation_gte", ""))
			)
		"npc_available":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.npc_available",
				[_describe_npc(str(condition.get("npc_id", condition.get("value", ""))))],
				str(templates.get("npc_available", ""))
			)
		"npc_at_location":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.npc_at_location",
				[
					_describe_npc(str(condition.get("npc_id", ""))),
					_describe_location(str(condition.get("value", "")))
				],
				str(templates.get("npc_at_location", ""))
			)
		"npc_tag_present":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.npc_tag_present",
				[
					_describe_npc(str(condition.get("npc_id", ""))),
					str(condition.get("key", ""))
				],
				str(templates.get("npc_tag_present", ""))
			)
		"day_range":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.day_range", [int(condition.get("min", 1)), int(condition.get("max", 1))], str(templates.get("day_range", "")))
		"day_gte":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.day_gte", [int(condition.get("value", 0))], str(templates.get("day_gte", "")))
		"phase_is":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.phase_is", [_describe_phase(str(condition.get("value", "")))], str(templates.get("phase_is", "")))
		"last_action_is":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.last_action_is", [_describe_action(str(condition.get("value", "")))], str(templates.get("last_action_is", "")))
		"last_action_category_is":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.last_action_category_is", [_describe_action_category(str(condition.get("value", "")))], str(templates.get("last_action_category_is", "")))
		"current_location_is":
			return GAME_TEXT.format_text("condition_evaluator.description_templates.current_location_is", [_describe_location(str(condition.get("value", "")))], str(templates.get("current_location_is", "")))
		"location_unlocked":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.location_unlocked",
				[_describe_location(str(condition.get("location_id", condition.get("value", ""))))],
				str(templates.get("location_unlocked", ""))
			)
		"location_blocked":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.location_blocked",
				[_describe_location(str(condition.get("location_id", condition.get("value", ""))))],
				str(templates.get("location_blocked", ""))
			)
		"location_tag_present":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.location_tag_present",
				[
					_describe_location(str(condition.get("location_id", ""))),
					str(condition.get("key", ""))
				],
				str(templates.get("location_tag_present", ""))
			)
		"location_value_gte":
			return GAME_TEXT.format_text(
				"condition_evaluator.description_templates.location_value_gte",
				[
					_describe_location(str(condition.get("location_id", ""))),
					_describe_key(str(condition.get("key", ""))),
					int(condition.get("value", 0))
				],
				str(templates.get("location_value_gte", ""))
			)
		_:
			return GAME_TEXT.text("condition_evaluator.description_templates.hidden")

func _describe_key(key: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.key_labels").get(key, key))

func _describe_tag(tag: String) -> String:
	var fallback_template: String = GAME_TEXT.text("condition_evaluator.tag_fallback")
	return str(GAME_TEXT.dict("condition_evaluator.tag_labels").get(tag, GAME_TEXT.format_text("condition_evaluator.tag_fallback", [tag], fallback_template)))

func _describe_flag(flag_key: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.flag_labels").get(flag_key, flag_key))

func _describe_knowledge(key: String) -> String:
	var fallback_template: String = GAME_TEXT.text("condition_evaluator.knowledge_fallback")
	return str(GAME_TEXT.dict("condition_evaluator.knowledge_labels").get(key, GAME_TEXT.format_text("condition_evaluator.knowledge_fallback", [key], fallback_template)))

func _describe_npc(npc_id: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.npc_labels").get(npc_id, npc_id))

func _describe_action(action_id: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.action_labels").get(action_id, action_id))

func _describe_action_category(action_category: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.action_category_labels").get(action_category, action_category))

func _describe_location(location_id: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.location_labels").get(location_id, location_id))

func _describe_phase(phase: String) -> String:
	var normalized_phase: String = _normalize_phase(phase)
	return str(GAME_TEXT.dict("condition_evaluator.phase_labels").get(normalized_phase, normalized_phase))

func _normalize_phase(phase: String) -> String:
	match phase.strip_edges().to_lower():
		"afternoon":
			return "day"
		_:
			return phase.strip_edges().to_lower()

func _describe_relation_label(field: String) -> String:
	return str(GAME_TEXT.dict("condition_evaluator.relation_labels").get(field, field))

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
