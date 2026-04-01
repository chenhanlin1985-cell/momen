@tool
class_name StoryGraphBuilder
extends RefCounted

const RUNS_PATH: String = "res://content/runs/run_definitions.json"
const PHASE_ORDER: Dictionary = {
	"morning": 0,
	"day": 1,
	"night": 2,
	"closing": 3,
	"unknown": 4
}

func build_graph() -> Dictionary:
	var event_definitions: Array[Dictionary] = _load_story_event_definitions()
	var nodes: Dictionary = {}
	var ordered_ids: Array[String] = []
	var group_counts: Dictionary = {}

	event_definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _sort_key(a) < _sort_key(b)
	)

	for definition: Dictionary in event_definitions:
		var node_data: Dictionary = _build_node_data(definition, group_counts)
		var event_id: String = str(node_data.get("id", ""))
		nodes[event_id] = node_data
		ordered_ids.append(event_id)

	return {
		"nodes": nodes,
		"ordered_ids": ordered_ids
	}

func _load_story_event_definitions() -> Array[Dictionary]:
	var run_definitions: Array[Dictionary] = _load_array_file(RUNS_PATH)
	if run_definitions.is_empty():
		return []

	var result: Array[Dictionary] = []
	var seen_ids: Dictionary = {}
	for run_definition: Dictionary in run_definitions:
		for item: Dictionary in _load_run_story_events(run_definition):
			var event_id: String = str(item.get("id", ""))
			if event_id.is_empty() or seen_ids.has(event_id):
				continue
			seen_ids[event_id] = true
			result.append(item)

	return result

func _load_run_story_events(run_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var csv_dir: String = str(run_definition.get("story_csv_dir", ""))
	if not csv_dir.is_empty():
		var importer: StoryCsvImporter = StoryCsvImporter.new()
		var imported: Array[Dictionary] = importer.import_directory(csv_dir)
		if not imported.is_empty():
			result.append_array(imported)
	return result

func _load_array_file(path: String) -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法读取事件定义：%s" % path)
		return []

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("事件定义文件必须是 JSON 数组：%s" % path)
		return []

	var result: Array[Dictionary] = []
	for item: Variant in parsed:
		if item is Dictionary:
			result.append(item.duplicate(true))
	return result

func _build_node_data(definition: Dictionary, group_counts: Dictionary) -> Dictionary:
	var event_id: String = str(definition.get("id", ""))
	var phase: String = _extract_phase(definition)
	var day_value: int = _extract_day_min(definition)
	var group_key: String = "%s:%d" % [phase, day_value]
	var index_in_group: int = int(group_counts.get(group_key, 0))
	group_counts[group_key] = index_in_group + 1

	return {
		"id": event_id,
		"title": str(definition.get("title", "")),
		"description": str(definition.get("description", "")),
		"phase": phase,
		"day_min": day_value,
		"day_max": _extract_day_max(definition),
		"priority": int(definition.get("schedule_priority", definition.get("priority", 0))),
		"repeatable": bool(definition.get("repeatable", false)),
		"event_class": str(definition.get("event_class", "")),
		"slot": str(definition.get("slot", "")),
		"trigger_conditions": Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null),
		"options": Array(definition.get("options", []), TYPE_DICTIONARY, "", null),
		"position": Vector2(
			280.0 * float(day_value),
			220.0 * float(PHASE_ORDER.get(phase, 4)) + 130.0 * float(index_in_group)
		),
		"edges": _extract_edges(definition),
		"effect_summary": _build_effect_summary(definition)
	}

func _extract_phase(definition: Dictionary) -> String:
	for condition: Dictionary in definition.get("trigger_conditions", []):
		if str(condition.get("type", "")) == "phase_is":
			return str(condition.get("value", "unknown"))
	return "unknown"

func _extract_day_min(definition: Dictionary) -> int:
	for condition: Dictionary in definition.get("trigger_conditions", []):
		if str(condition.get("type", "")) == "day_range":
			return int(condition.get("min", 0))
	return 0

func _extract_day_max(definition: Dictionary) -> int:
	for condition: Dictionary in definition.get("trigger_conditions", []):
		if str(condition.get("type", "")) == "day_range":
			return int(condition.get("max", 0))
	return 0

func _extract_edges(definition: Dictionary) -> Array[Dictionary]:
	var edges: Array[Dictionary] = []
	for option_definition: Dictionary in definition.get("options", []):
		for effect: Dictionary in option_definition.get("effects", []):
			if str(effect.get("type", "")) != "add_followup_event":
				continue
			edges.append(
				{
					"from_id": str(definition.get("id", "")),
					"to_id": str(effect.get("key", "")),
					"label": str(option_definition.get("text", option_definition.get("id", "")))
				}
			)
	return edges

func _build_effect_summary(definition: Dictionary) -> Array[String]:
	var summaries: Array[String] = []
	for option_definition: Dictionary in definition.get("options", []):
		var option_title: String = str(option_definition.get("text", option_definition.get("id", "")))
		var effects: Array[String] = []
		for effect: Dictionary in option_definition.get("effects", []):
			effects.append(_describe_effect(effect))
		summaries.append("%s -> %s" % [option_title, "，".join(effects)])
	return summaries

func _describe_effect(effect: Dictionary) -> String:
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"add_followup_event":
			return "后续事件 %s" % str(effect.get("key", ""))
		"modify_world_value":
			return "%s %+d" % [str(effect.get("key", "")), int(effect.get("delta", 0))]
		"modify_resource":
			return "%s %+d" % [str(effect.get("key", "")), int(effect.get("delta", 0))]
		"modify_stat":
			return "%s %+d" % [str(effect.get("key", "")), int(effect.get("delta", 0))]
		"modify_npc_relation":
			return "%s.%s %+d" % [
				str(effect.get("npc_id", "")),
				str(effect.get("field", "")),
				int(effect.get("delta", 0))
			]
		"add_tag":
			return "添加标签 %s" % str(effect.get("key", ""))
		"remove_tag":
			return "移除标签 %s" % str(effect.get("key", ""))
		"add_knowledge":
			return "获得情报 %s" % str(effect.get("key", ""))
		"finish_run":
			return "结束本局"
		_:
			return effect_type

func _sort_key(definition: Dictionary) -> String:
	var phase: String = _extract_phase(definition)
	return "%03d_%03d_%03d_%s" % [
		_extract_day_min(definition),
		int(PHASE_ORDER.get(phase, 4)),
		999 - int(definition.get("schedule_priority", definition.get("priority", 0))),
		str(definition.get("id", ""))
	]
