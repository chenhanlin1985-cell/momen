class_name StoryCsvImporter
extends RefCounted

const EVENTS_FILE: String = "events.csv"
const EVENT_TRIGGERS_FILE: String = "event_triggers.csv"
const EVENT_OPTIONS_FILE: String = "event_options.csv"
const OPTION_CONDITIONS_FILE: String = "option_conditions.csv"
const OPTION_EFFECTS_FILE: String = "option_effects.csv"
const LOCALIZATION_FILE: String = "localization.csv"

func import_directory(csv_dir: String) -> Array[Dictionary]:
	var texts: Dictionary = _load_localization(_join(csv_dir, LOCALIZATION_FILE))
	var event_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, EVENTS_FILE))
	var trigger_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, EVENT_TRIGGERS_FILE))
	var option_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, EVENT_OPTIONS_FILE))
	var option_condition_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, OPTION_CONDITIONS_FILE))
	var option_effect_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, OPTION_EFFECTS_FILE))

	var events_by_id: Dictionary = {}
	for row: Dictionary in event_rows:
		var event_id: String = str(row.get("event_id", ""))
		if event_id.is_empty():
			continue
		events_by_id[event_id] = {
			"id": event_id,
			"story_id": str(row.get("story_id", "")),
			"event_class": str(row.get("event_class", "")),
			"slot": str(row.get("slot", "phase_entry")),
			"pool_id": str(row.get("pool_id", "")),
			"schedule_priority": _to_int(row.get("schedule_priority", "0")),
			"random_weight": _to_int(row.get("random_weight", "1")),
			"repeatable": _to_bool(row.get("repeatable", "false")),
			"title": _resolve_text(texts, str(row.get("title_key", ""))),
			"description": _resolve_text(texts, str(row.get("desc_key", ""))),
			"trigger_conditions": _build_condition_groups(_filter_rows(trigger_rows, "event_id", event_id)),
			"options": []
		}

	var options_by_id: Dictionary = {}
	for row: Dictionary in option_rows:
		var option_id: String = str(row.get("option_id", ""))
		var event_id: String = str(row.get("event_id", ""))
		if option_id.is_empty() or not events_by_id.has(event_id):
			continue
		var option_data: Dictionary = {
			"id": option_id,
			"text": _resolve_text(texts, str(row.get("text_key", ""))),
			"result_text": _resolve_text(texts, str(row.get("result_key", ""))),
			"conditions": _build_condition_groups(_filter_rows(option_condition_rows, "option_id", option_id)),
			"effects": _build_effects(_filter_rows(option_effect_rows, "option_id", option_id))
		}
		options_by_id[option_id] = option_data
		events_by_id[event_id]["options"].append(option_data)

	var result: Array[Dictionary] = []
	for event_id: String in events_by_id.keys():
		result.append(events_by_id[event_id])
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("schedule_priority", 0)) > int(b.get("schedule_priority", 0))
	)
	return result

func _load_localization(path: String) -> Dictionary:
	var rows: Array[Dictionary] = _load_csv_rows(path)
	var texts: Dictionary = {}
	for row: Dictionary in rows:
		var key: String = str(row.get("text_key", ""))
		if key.is_empty():
			continue
		texts[key] = str(row.get("zh_cn", ""))
	return texts

func _load_csv_rows(path: String) -> Array[Dictionary]:
	if not FileAccess.file_exists(path):
		return []

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法读取 CSV：%s" % path)
		return []

	if file.eof_reached():
		return []

	var headers: PackedStringArray = file.get_csv_line()
	var normalized_headers: Array[String] = []
	for header: String in headers:
		normalized_headers.append(header.strip_edges())

	var rows: Array[Dictionary] = []
	while not file.eof_reached():
		var values: PackedStringArray = file.get_csv_line()
		if values.is_empty():
			continue
		var row: Dictionary = {}
		var has_content: bool = false
		for i: int in range(normalized_headers.size()):
			var header: String = normalized_headers[i]
			var value: String = values[i].strip_edges() if i < values.size() else ""
			row[header] = value
			if not value.is_empty():
				has_content = true
		if has_content:
			rows.append(row)
	return rows

func _filter_rows(rows: Array[Dictionary], key: String, expected: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row: Dictionary in rows:
		if str(row.get(key, "")) == expected:
			result.append(row)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _to_int(a.get("order", "0")) < _to_int(b.get("order", "0"))
	)
	return result

func _build_condition_groups(rows: Array[Dictionary]) -> Array:
	if rows.is_empty():
		return []

	var groups: Dictionary = {}
	var ordered_group_ids: Array[String] = []
	for row: Dictionary in rows:
		var group_id: String = str(row.get("group_id", "main"))
		if not groups.has(group_id):
			groups[group_id] = []
			ordered_group_ids.append(group_id)
		groups[group_id].append(_build_condition(row))

	if ordered_group_ids.size() == 1:
		return Array(groups[ordered_group_ids[0]])

	var branches: Array = []
	for group_id: String in ordered_group_ids:
		branches.append({
			"type": "all_of",
			"conditions": groups[group_id]
		})
	return [{
		"type": "any_of",
		"conditions": branches
	}]

func _build_condition(row: Dictionary) -> Dictionary:
	var condition: Dictionary = {
		"type": str(row.get("condition_type", ""))
	}
	var scope: String = str(row.get("scope", ""))
	var key: String = str(row.get("key", ""))
	var value: String = str(row.get("op_value", ""))

	if not scope.is_empty():
		condition["scope"] = scope

	match str(row.get("condition_type", "")):
		"day_range":
			var parts: PackedStringArray = value.split("-")
			condition["min"] = _to_int(parts[0] if not parts.is_empty() else "0")
			condition["max"] = _to_int(parts[1] if parts.size() > 1 else parts[0] if not parts.is_empty() else "0")
		_:
			if not key.is_empty():
				condition["key"] = key
			if not value.is_empty():
				condition["value"] = _to_typed_value(value)

	var npc_id: String = str(row.get("target_id", ""))
	if not npc_id.is_empty() and str(row.get("condition_type", "")) == "npc_relation_gte":
		condition["npc_id"] = npc_id
	var field: String = str(row.get("field", ""))
	if not field.is_empty():
		condition["field"] = field

	var extra_json: String = str(row.get("extra_json", ""))
	if not extra_json.is_empty():
		var extra: Variant = JSON.parse_string(extra_json)
		if extra is Dictionary:
			for extra_key: Variant in extra.keys():
				condition[str(extra_key)] = extra[extra_key]

	return condition

func _build_effects(rows: Array[Dictionary]) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	for row: Dictionary in rows:
		var effect_type: String = str(row.get("effect_type", ""))
		if effect_type.is_empty():
			continue
		var effect: Dictionary = {
			"type": effect_type
		}
		var scope: String = str(row.get("scope", ""))
		var key: String = str(row.get("key", ""))
		var delta: String = str(row.get("delta", ""))
		var target_id: String = str(row.get("target_id", ""))
		var field: String = str(row.get("field", ""))

		if not scope.is_empty():
			effect["scope"] = scope
		if not key.is_empty():
			effect["key"] = key
		if not delta.is_empty():
			effect["delta"] = _to_int(delta)
		if not field.is_empty():
			effect["field"] = field

		match effect_type:
			"modify_npc_relation":
				effect["npc_id"] = target_id
			"finish_run":
				effect["reason_id"] = key if not key.is_empty() else target_id
			_:
				if not target_id.is_empty():
					effect["target_id"] = target_id

		var extra_json: String = str(row.get("extra_json", ""))
		if not extra_json.is_empty():
			var extra: Variant = JSON.parse_string(extra_json)
			if extra is Dictionary:
				for extra_key: Variant in extra.keys():
					effect[str(extra_key)] = extra[extra_key]

		effects.append(effect)
	return effects

func _resolve_text(texts: Dictionary, key: String) -> String:
	if key.is_empty():
		return ""
	return str(texts.get(key, key))

func _to_bool(value: String) -> bool:
	return value.to_lower() == "true" or value == "1"

func _to_int(value: Variant) -> int:
	return int(str(value))

func _to_typed_value(value: String) -> Variant:
	if value.is_valid_int():
		return int(value)
	return value

func _join(base: String, file_name: String) -> String:
	return "%s/%s" % [base.trim_suffix("/"), file_name]
