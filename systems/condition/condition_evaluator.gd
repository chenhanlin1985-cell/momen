class_name ConditionEvaluator
extends RefCounted

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
		"day_range":
			var day: int = run_state.world_state.day
			return day >= int(condition.get("min", 1)) and day <= int(condition.get("max", 999))
		"day_gte":
			return run_state.world_state.day >= int(condition.get("value", 0))
		"phase_is":
			return run_state.world_state.current_phase == str(condition.get("value", ""))
		"last_action_is":
			return run_state.world_state.last_action_id == str(condition.get("value", ""))
		"world_value_gte":
			return int(run_state.world_state.values.get(str(condition.get("key", "")), 0)) >= int(condition.get("value", 0))
		"npc_relation_gte":
			return _get_npc_relation(
				run_state,
				str(condition.get("npc_id", "")),
				str(condition.get("field", "favor"))
			) >= int(condition.get("value", 0))
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
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.id != npc_id:
			continue
		if field == "alert":
			return npc_state.alert
		return npc_state.favor
	return 0

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
			return ["满足其一：" + " / ".join(child_descriptions)]
		_:
			return [_describe_condition(condition)]

func _describe_condition(condition: Dictionary) -> String:
	var condition_type: String = str(condition.get("type", ""))
	match condition_type:
		"resource_gte":
			return "%s >= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"resource_lte":
			return "%s <= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"stat_gte":
			return "%s >= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"tag_present":
			return _describe_tag(str(condition.get("key", "")))
		"knowledge_present":
			return _describe_knowledge(str(condition.get("key", "")))
		"world_value_gte":
			return "%s >= %d" % [_describe_key(str(condition.get("key", ""))), int(condition.get("value", 0))]
		"npc_relation_gte":
			return "%s%s >= %d" % [
				_describe_npc(str(condition.get("npc_id", ""))),
				"警惕" if str(condition.get("field", "favor")) == "alert" else "好感",
				int(condition.get("value", 0))
			]
		"day_range":
			return "天数在第 %d~%d 天" % [int(condition.get("min", 1)), int(condition.get("max", 1))]
		"day_gte":
			return "天数 >= %d" % int(condition.get("value", 0))
		"phase_is":
			return "处于%s阶段" % _describe_phase(str(condition.get("value", "")))
		"last_action_is":
			return "上一行动为%s" % _describe_action(str(condition.get("value", "")))
		_:
			return "满足隐藏条件"

func _describe_key(key: String) -> String:
	var labels: Dictionary = {
		"blood_qi": "血气",
		"spirit_stone": "灵石",
		"spirit_sense": "神识",
		"pollution": "污染",
		"exposure": "暴露",
		"physique": "体魄",
		"mind": "心智",
		"insight": "悟性",
		"occult": "诡感",
		"tact": "手腕",
		"west_well_investigation_progress": "调查推进",
		"investigation_progress": "调查推进",
		"anomaly_progress": "异变推进",
		"clue_fragments": "线索",
		"patrol_level": "巡查等级"
	}
	return str(labels.get(key, key))

func _describe_tag(tag: String) -> String:
	var labels: Dictionary = {
		"heard_west_well_voice": "已听见西井异声",
		"heard_of_west_well": "已经听过西井禁令",
		"missing_is_not_random": "认定失踪并非偶然",
		"records_are_tampered": "发现账册被动过手脚",
		"marked_by_well": "已被西井标记",
		"accepted_whisper": "接受过井下低语"
	}
	return str(labels.get(tag, "获得标签：%s" % tag))

func _describe_knowledge(key: String) -> String:
	var labels: Dictionary = {
		"west_well_is_not_safe": "确认西井异声并非错觉",
		"well_sealed_in_past": "得知西井曾被封过",
		"anomaly_source_identified": "查明西井异常源头"
	}
	return str(labels.get(key, "获得情报：%s" % key))

func _describe_npc(npc_id: String) -> String:
	var labels: Dictionary = {
		"outer_senior_brother": "外门师兄",
		"friendly_peer": "同门",
		"night_patrol_disciple": "夜巡弟子",
		"herb_steward": "药房执事"
	}
	return str(labels.get(npc_id, npc_id))

func _describe_action(action_id: String) -> String:
	var labels: Dictionary = {
		"west_well": "去西井",
		"herb_room": "去药房",
		"corridor": "去回廊",
		"dormitory": "回寝舍"
	}
	return str(labels.get(action_id, action_id))

func _describe_phase(phase: String) -> String:
	var labels: Dictionary = {
		"morning": "晨间",
		"day": "白天行动",
		"night": "夜间异常",
		"closing": "收束"
	}
	return str(labels.get(phase, phase))
