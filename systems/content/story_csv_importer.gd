class_name StoryCsvImporter
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")
const EVENTS_FILE: String = "events.csv"
const EVENT_TRIGGERS_FILE: String = "event_triggers.csv"
const EVENT_BLOCKS_FILE: String = "event_blocks.csv"
const EVENT_OPTIONS_FILE: String = "event_options.csv"
const OPTION_CONDITIONS_FILE: String = "option_conditions.csv"
const OPTION_EFFECTS_FILE: String = "option_effects.csv"
const LOCALIZATION_FILE: String = "localization.csv"

func import_directory(csv_dir: String) -> Array[Dictionary]:
	var texts: Dictionary = _load_localization(_join(csv_dir, LOCALIZATION_FILE))
	var event_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, EVENTS_FILE))
	var trigger_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, EVENT_TRIGGERS_FILE))
	var block_rows: Array[Dictionary] = _load_csv_rows(_join(csv_dir, EVENT_BLOCKS_FILE))
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
			"content_category": str(row.get("content_category", "")),
			"time_slot": str(row.get("time_slot", "any")),
			"participants": _split_list(str(row.get("participants", ""))),
			"req_flags": _split_list(str(row.get("req_flags", ""))),
			"block_flags": _split_list(str(row.get("block_flags", ""))),
			"next_hooks": _split_list(str(row.get("next_hooks", ""))),
			"presentation_type": str(row.get("presentation_type", "standard_event")),
			"speaker_npc_id": str(row.get("speaker_npc_id", "")),
			"portrait_key": str(row.get("portrait_key", "")),
			"dialogue_resource_path": str(row.get("dialogue_resource_path", "")),
			"dialogue_start_cue": str(row.get("dialogue_start_cue", "")),
			"combat_enemy_id": str(row.get("combat_enemy_id", "")),
			"combatant_name": _resolve_text(texts, str(row.get("combat_name_key", ""))),
			"combat_guard": _to_int(row.get("combat_guard", "0")),
			"combat_damage": _to_int(row.get("combat_damage", "0")),
			"combat_hp": _to_int(row.get("combat_hp", "0")),
			"combat_escape_target": _to_int(row.get("combat_escape_target", "0")),
			"slot": str(row.get("slot", "phase_entry")),
			"pool_id": str(row.get("pool_id", "")),
			"location_id": str(row.get("location_id", "")),
			"allowed_locations": _split_list(str(row.get("allowed_locations", ""))),
			"schedule_priority": _to_int(row.get("schedule_priority", "0")),
			"random_weight": _to_int(row.get("random_weight", "1")),
			"repeatable": _to_bool(row.get("repeatable", "false")),
			"title": _resolve_text(texts, str(row.get("title_key", ""))),
			"description": _resolve_text(texts, str(row.get("desc_key", ""))),
			"trigger_conditions": _append_flag_requirements(
				_split_list(str(row.get("req_flags", ""))),
				_inject_time_slot_condition(
					str(row.get("time_slot", "any")),
					_build_condition_groups(_filter_rows(trigger_rows, "event_id", event_id))
				)
			),
			"block_conditions": _append_flag_requirements(
				_split_list(str(row.get("block_flags", ""))),
				_build_condition_groups(_filter_rows(block_rows, "event_id", event_id))
			),
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
			"success_result_text": _resolve_text(texts, str(row.get("success_result_key", ""))),
			"failure_result_text": _resolve_text(texts, str(row.get("failure_result_key", ""))),
			"check": _build_option_check(row),
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
		push_error(GAME_TEXT.format_text("story_csv_importer.errors.read_csv_failed", [path], path))
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

func _inject_time_slot_condition(time_slot: String, conditions: Array) -> Array:
	var normalized_slot: String = _normalize_time_slot(time_slot)
	if normalized_slot.is_empty():
		return conditions

	if _has_phase_condition(conditions):
		return conditions

	var with_slot: Array = conditions.duplicate(true)
	with_slot.append({
		"type": "phase_is",
		"value": normalized_slot
	})
	return with_slot

func _append_flag_requirements(flag_keys: Array[String], conditions: Array) -> Array:
	if flag_keys.is_empty():
		return conditions
	var with_flags: Array = conditions.duplicate(true)
	for flag_key: String in flag_keys:
		with_flags.append({
			"type": "flag_present",
			"key": flag_key
		})
	return with_flags

func _has_phase_condition(conditions: Array) -> bool:
	for condition: Variant in conditions:
		if condition is Dictionary:
			var dictionary_condition: Dictionary = condition
			var condition_type: String = str(dictionary_condition.get("type", ""))
			if condition_type == "phase_is":
				return true
			if condition_type == "all_of" or condition_type == "any_of":
				if _has_phase_condition(Array(dictionary_condition.get("conditions", []))):
					return true
	return false

func _normalize_time_slot(time_slot: String) -> String:
	match time_slot:
		"morning":
			return "morning"
		"afternoon":
			return "day"
		"night":
			return "night"
		_:
			return ""

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
				condition[extra_key] = extra[extra_key]

	return condition

func _build_option_check(row: Dictionary) -> Dictionary:
	var system: String = str(row.get("check_system", "")).strip_edges()
	if system.is_empty():
		return {}
	var check: Dictionary = {
		"system": system,
		"source": str(row.get("check_source", "stat")),
		"key": str(row.get("check_key", "")),
		"target": _to_int(row.get("check_target", "0")),
		"bonus": _to_int(row.get("check_bonus", "0"))
	}
	var npc_id: String = str(row.get("check_npc_id", ""))
	if not npc_id.is_empty():
		check["npc_id"] = npc_id
	var field: String = str(row.get("check_field", ""))
	if not field.is_empty():
		check["field"] = field
	return check

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
		if not scope.is_empty():
			effect["scope"] = scope
		var key: String = str(row.get("key", ""))
		if not key.is_empty():
			effect["key"] = key
		var target_id: String = str(row.get("target_id", ""))
		if not target_id.is_empty():
			effect["target_id"] = target_id
			match effect_type:
				"modify_npc_relation", "add_npc_tag", "remove_npc_tag", "set_npc_available":
					effect["npc_id"] = target_id
		var field: String = str(row.get("field", ""))
		if not field.is_empty():
			effect["field"] = field
		var outcome: String = str(row.get("outcome", ""))
		if not outcome.is_empty():
			effect["outcome"] = outcome

		var value_raw: String = str(row.get("delta", row.get("value", "")))
		if not value_raw.is_empty():
			match effect_type:
				"set_tag", "remove_tag", "set_goal_state", "set_location", "unlock_location", "block_location", "unblock_location", "set_flag", "clear_flag":
					effect["value"] = value_raw
				_:
					effect["delta"] = _to_int(value_raw)

		var extra_json: String = str(row.get("extra_json", ""))
		if not extra_json.is_empty():
			var extra: Variant = JSON.parse_string(extra_json)
			if extra is Dictionary:
				for extra_key: Variant in extra.keys():
					effect[extra_key] = extra[extra_key]

		effects.append(effect)
	return effects

func _resolve_text(texts: Dictionary, key: String) -> String:
	if key.is_empty():
		return ""
	return str(texts.get(key, key))

func _split_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for part: String in value.split("|", false):
		var trimmed: String = part.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result

func _to_int(value: Variant) -> int:
	return int(str(value).to_int())

func _to_bool(value: Variant) -> bool:
	var normalized: String = str(value).strip_edges().to_lower()
	return normalized == "true" or normalized == "1" or normalized == "yes"

func _to_typed_value(value: String) -> Variant:
	var normalized: String = value.strip_edges()
	if normalized.is_valid_int():
		return normalized.to_int()
	if normalized.to_lower() == "true":
		return true
	if normalized.to_lower() == "false":
		return false
	return normalized

func _join(base: String, file_name: String) -> String:
	if base.ends_with("/"):
		return base + file_name
	return base + "/" + file_name
