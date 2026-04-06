@tool
extends EditorScript

const MD_DIR = "res://content/story/act1/md/"
const OUT_FILE = "res://content/story/act1/md/_parsed_markdown_debug.json"
const WRITER_DRAFT_OUT_FILE = "res://content/story/act1/md/generated_writer_drafts.md"
const FRIENDLY_PEER_ARC_MD_OUT_FILE = "res://content/story/act1/md/archive/liu_current_arc.md"
const DIALOGUE_MANIFEST_PATH = "res://content/dialogue/encounters/_manifest.json"
const STORY_CSV_DIR = "res://content/story/act1/csv"
const DEFAULT_STORY_ID = "01"
const EVENT_ID_MAP_PATH = "res://content/story/act1/event_id_map.json"
const NPC_NAME_MAP_PATH = "res://content/story/act1/npc_name_map.json"
const LOCATION_NAME_MAP_PATH = "res://content/story/act1/location_name_map.json"
const STATUS_KEY_MAP_PATH = "res://content/story/act1/status_key_map.json"
const AUTHOR_FOLDER_MAP_PATH = "res://content/story/act1/md/active/_folder_map.json"
const BATTLE_CARD_DEFINITIONS_PATH = "res://content/battle/card_definitions.json"
const DEFAULT_INTRUSION_SPECS := [
	{
		"id": "greed",
		"label": "贪",
		"desc": "TODO：补充「贪」的植入描述。",
		"hint": "TODO：补充植入「贪」后的即时反馈。",
		"log": "你把贪念压进了对方心里。"
	},
	{
		"id": "wrath",
		"label": "嗔",
		"desc": "TODO：补充「嗔」的植入描述。",
		"hint": "TODO：补充植入「嗔」后的即时反馈。",
		"log": "你把嗔念压进了对方心里。"
	},
	{
		"id": "delusion",
		"label": "痴",
		"desc": "TODO：补充「痴」的植入描述。",
		"hint": "TODO：补充植入「痴」后的即时反馈。",
		"log": "你把痴念压进了对方心里。"
	}
]
const CLASS_LABELS := {
	"固定剧情事件": "fixed_story",
	"条件剧情事件": "conditional_story",
	"随机扰动事件": "random_filler",
	"结局校验事件": "ending_check"
}
const PRESENTATION_LABELS := {
	"普通事件": "standard_event",
	"紧凑抉择事件": "compact_choice_event",
	"概要事件": "summary_event",
	"三段式对话事件": "dialogue_event",
	"结局事件": "ending_event",
	"战斗事件": "combat_event"
}
const SLOT_LABELS := {
	"阶段开始时": "phase_entry",
	"行动后": "post_action"
}
const TIME_LABELS := {
	"晨间": "morning",
	"白天": "day",
	"午后": "day",
	"夜间": "night"
}
const STAT_LABELS := {
	"体魄": "physique",
	"心智": "mind",
	"悟性": "insight",
	"诡感": "occult",
	"手腕": "tact",
	"physique": "physique",
	"mind": "mind",
	"insight": "insight",
	"occult": "occult",
	"tact": "tact"
}
const RELATION_FIELD_LABELS := {
	"好感": "favor",
	"警惕": "alert",
	"favor": "favor",
	"alert": "alert"
}
const FLAG_LABELS := {
	"已持有族兄遗物": "has_cousin_relic",
	"已知族兄秘密": "knows_cousin_secret",
	"已向王麻子交钱": "wang_extortion_paid",
	"已熬过试药": "survived_pill_test",
	"已接受疯长老庇护": "accepted_elder_patronage",
	"已学会敛息法": "learned_blood_stealth",
	"已接触王麻子": "met_wang_deacon",
	"已接触疯长老": "met_mad_elder",
	"已确认族兄之死有异": "cousin_death_linked",
	"柳飞霞已起疑": "liu_suspicion_seeded",
	"已与柳飞霞建立暗线": "liu_contact_established",
	"柳飞霞存在背叛风险": "liu_betrayal_risk",
	"柳飞霞已成为线人": "liu_informant_active",
	"柳飞霞已转而针对王麻子": "liu_against_wang",
	"王麻子暗线已暴露": "wang_secret_channel_exposed",
	"死于柳飞霞之手": "death_used_by_liu",
	"已进入旧账室": "entered_records_room",
	"已打退血役": "blood_runner_beaten",
	"已走疯长老线": "route_seek_senior",
	"已走账册线": "route_records",
	"已走化骨池线": "route_well",
	"已选择暂避锋芒": "route_lie_low",
	"已确认失踪传闻属实": "missing_rumor_confirmed"
}

var _compile_warnings: Array[String] = []
var _compile_errors: Array[String] = []
var _event_id_map: Dictionary = {}
var _runtime_event_id_map: Dictionary = {}
var _npc_name_map: Dictionary = {}
var _location_name_map: Dictionary = {}
var _status_map_by_scope: Dictionary = {}
var _author_folder_label_map: Dictionary = {}
var _battle_card_name_map: Dictionary = {}

func _run() -> void:
	var result: Dictionary = compile_markdown()
	for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
		push_error(error_text)
	if not _to_bool(result.get("success", false)):
		return
	print("Compiled %d events to %s" % [int(result.get("event_count", 0)), OUT_FILE])
	for warning_text: String in Array(result.get("warnings", []), TYPE_STRING, "", null):
		push_warning(warning_text)

func compile_markdown(write_output: bool = true) -> Dictionary:
	print("Starting Markdown compilation...")
	_compile_warnings.clear()
	_compile_errors.clear()
	_event_id_map = _load_event_id_map()
	_npc_name_map = _load_named_id_map(NPC_NAME_MAP_PATH, "NPC")
	_location_name_map = _load_named_id_map(LOCATION_NAME_MAP_PATH, "地点")
	_status_map_by_scope = _load_status_key_map()
	_author_folder_label_map = _load_author_folder_label_map()
	_battle_card_name_map = _load_battle_card_name_map()
	_runtime_event_id_map = _load_runtime_event_id_map()
	var events: Array = []
	var source_files: Array[String] = get_source_markdown_paths()
	if source_files.is_empty():
		_compile_errors.append("未找到可编译的 Markdown 文件：%s" % MD_DIR)
	for path: String in source_files:
		var parsed_events: Array = parse_md_file(path)
		events.append_array(parsed_events)
	if not _compile_errors.is_empty():
		return {
			"success": false,
			"errors": _compile_errors.duplicate(),
			"warnings": _compile_warnings.duplicate(),
			"event_count": 0,
			"source_files": source_files
		}
	if not write_output:
		return {
			"success": true,
			"errors": PackedStringArray(),
			"warnings": _compile_warnings.duplicate(),
			"event_count": events.size(),
			"source_files": source_files,
			"output_path": OUT_FILE,
			"events": events
		}
	var json_str: String = JSON.stringify(events, "\t")
	var file: FileAccess = FileAccess.open(OUT_FILE, FileAccess.WRITE)
	if file == null:
		return {
			"success": false,
			"errors": PackedStringArray(["无法写入编译产物：%s" % OUT_FILE]),
			"warnings": _compile_warnings.duplicate(),
			"event_count": events.size(),
			"source_files": source_files
		}
	file.store_string(json_str)
	file.close()
	return {
		"success": true,
		"errors": PackedStringArray(),
		"warnings": _compile_warnings.duplicate(),
		"event_count": events.size(),
		"source_files": source_files,
		"output_path": OUT_FILE
	}

func compile_writer_drafts(write_output: bool = true) -> Dictionary:
	var result: Dictionary = compile_markdown(false)
	if not _to_bool(result.get("success", false)):
		return result
	var events: Array[Dictionary] = []
	for item: Variant in Array(result.get("events", [])):
		if item is Dictionary:
			events.append(Dictionary(item).duplicate(true))
	var draft_text: String = _build_writer_draft_document(events)
	if not write_output:
		result["writer_draft_output_path"] = WRITER_DRAFT_OUT_FILE
		result["writer_draft_text"] = draft_text
		return result
	var file: FileAccess = FileAccess.open(WRITER_DRAFT_OUT_FILE, FileAccess.WRITE)
	if file == null:
		return {
			"success": false,
			"errors": PackedStringArray(["无法写入当前项目草稿包：%s" % WRITER_DRAFT_OUT_FILE]),
			"warnings": _compile_warnings.duplicate(),
			"event_count": events.size(),
			"source_files": Array(result.get("source_files", []), TYPE_STRING, "", null)
		}
	file.store_string(draft_text)
	file.close()
	result["writer_draft_output_path"] = WRITER_DRAFT_OUT_FILE
	result["writer_draft_text"] = draft_text
	return result

func apply_current_dialogue_assets(write_output: bool = true) -> Dictionary:
	var result: Dictionary = compile_markdown(false)
	if not _to_bool(result.get("success", false)):
		return result
	var events: Array[Dictionary] = []
	for item: Variant in Array(result.get("events", [])):
		if item is Dictionary:
			events.append(Dictionary(item).duplicate(true))
	var manifest_entries: Array[Dictionary] = _load_json_array(DIALOGUE_MANIFEST_PATH)
	if manifest_entries.is_empty():
		return {
			"success": false,
			"errors": PackedStringArray(["未找到可用的 dialogue manifest：%s" % DIALOGUE_MANIFEST_PATH]),
			"warnings": _compile_warnings.duplicate(),
			"event_count": events.size(),
			"source_files": Array(result.get("source_files", []), TYPE_STRING, "", null)
		}
	var updated_files: PackedStringArray = []
	var applied_event_ids: PackedStringArray = []
	for event_definition: Dictionary in events:
		if not _should_apply_dialogue_assets(event_definition):
			continue
		var participants: Array[String] = Array(event_definition.get("participants", []), TYPE_STRING, "", null)
		if participants.is_empty():
			_compile_warnings.append("对话草稿缺少 primary NPC，已跳过：%s" % str(event_definition.get("title", event_definition.get("id", ""))))
			continue
		var npc_id: String = participants[0]
		var manifest_entry: Dictionary = _resolve_dialogue_manifest_entry(manifest_entries, npc_id)
		if manifest_entry.is_empty():
			_compile_warnings.append("未在 dialogue manifest 里找到 NPC 对应文件，已跳过：%s" % npc_id)
			continue
		var logic_path: String = str(manifest_entry.get("logic_path", "")).strip_edges()
		var text_path: String = str(manifest_entry.get("text_path", "")).strip_edges()
		if logic_path.is_empty() or text_path.is_empty():
			_compile_warnings.append("dialogue manifest 缺少 logic/text 路径，已跳过：%s" % npc_id)
			continue
		var encounters: Array[Dictionary] = _load_json_array(logic_path)
		var texts: Dictionary = _load_json_dictionary(text_path)
		var generated_encounter: Dictionary = _build_generated_encounter(event_definition)
		var changed_logic: bool = _upsert_generated_encounter(encounters, generated_encounter)
		var changed_texts: bool = _merge_generated_texts(texts, event_definition, generated_encounter)
		if write_output:
			if changed_logic:
				_write_json_value(logic_path, encounters)
				updated_files.append(logic_path)
			if changed_texts:
				_write_json_value(text_path, texts)
				updated_files.append(text_path)
		elif changed_logic:
			updated_files.append(logic_path)
		elif changed_texts:
			updated_files.append(text_path)
		applied_event_ids.append(str(generated_encounter.get("event_id", "")))
	result["dialogue_asset_files"] = updated_files
	result["dialogue_asset_event_ids"] = applied_event_ids
	result["dialogue_asset_manifest_path"] = DIALOGUE_MANIFEST_PATH
	return result

func apply_current_csv_assets(write_output: bool = true) -> Dictionary:
	var result: Dictionary = compile_markdown(false)
	if not _to_bool(result.get("success", false)):
		return result
	var events: Array[Dictionary] = []
	for item: Variant in Array(result.get("events", [])):
		if item is Dictionary:
			events.append(Dictionary(item).duplicate(true))
	var events_path: String = "%s/events.csv" % STORY_CSV_DIR
	var triggers_path: String = "%s/event_triggers.csv" % STORY_CSV_DIR
	var options_path: String = "%s/event_options.csv" % STORY_CSV_DIR
	var option_conditions_path: String = "%s/option_conditions.csv" % STORY_CSV_DIR
	var option_effects_path: String = "%s/option_effects.csv" % STORY_CSV_DIR
	var localization_path: String = "%s/localization.csv" % STORY_CSV_DIR
	var events_table: Dictionary = _load_csv_table(events_path)
	var triggers_table: Dictionary = _load_csv_table(triggers_path)
	var options_table: Dictionary = _load_csv_table(options_path)
	var option_conditions_table: Dictionary = _load_csv_table(option_conditions_path)
	var option_effects_table: Dictionary = _load_csv_table(option_effects_path)
	var localization_table: Dictionary = _load_localization_table(localization_path)
	var updated_files: PackedStringArray = []
	var applied_event_ids: PackedStringArray = []
	var generated_option_ids: PackedStringArray = []
	for event_definition: Dictionary in events:
		var event_id: String = _build_draft_event_id(event_definition)
		var option_ids: Array[String] = _generated_option_ids_for_event(event_definition)
		var existing_event_row: Dictionary = _find_csv_row_by_id(events_table, "event_id", event_id)
		_replace_csv_rows_for_event(events_table, "event_id", event_id, [_build_event_csv_row(event_definition, existing_event_row)])
		_replace_csv_rows_for_event(triggers_table, "event_id", event_id, _build_trigger_csv_rows(event_definition))
		_replace_csv_rows_for_event(options_table, "event_id", event_id, _build_option_csv_rows(event_definition))
		_replace_csv_rows_for_options(option_conditions_table, option_ids, _build_option_condition_csv_rows(event_definition))
		_replace_csv_rows_for_options(option_effects_table, option_ids, _build_option_effect_csv_rows(event_definition))
		_upsert_localization_rows(localization_table, _build_localization_csv_rows(event_definition))
		applied_event_ids.append(event_id)
		generated_option_ids.append_array(option_ids)
	if write_output:
		_write_csv_table(events_path, events_table)
		updated_files.append(events_path)
		_write_csv_table(triggers_path, triggers_table)
		updated_files.append(triggers_path)
		_write_csv_table(options_path, options_table)
		updated_files.append(options_path)
		_write_csv_table(option_conditions_path, option_conditions_table)
		updated_files.append(option_conditions_path)
		_write_csv_table(option_effects_path, option_effects_table)
		updated_files.append(option_effects_path)
		_write_csv_table(localization_path, localization_table)
		updated_files.append(localization_path)
	result["csv_asset_files"] = updated_files
	result["csv_asset_event_ids"] = applied_event_ids
	result["csv_asset_option_ids"] = generated_option_ids
	return result

func apply_current_project_assets(write_output: bool = true) -> Dictionary:
	var dialogue_result: Dictionary = apply_current_dialogue_assets(write_output)
	if not _to_bool(dialogue_result.get("success", false)):
		return dialogue_result
	var csv_result: Dictionary = apply_current_csv_assets(write_output)
	if not _to_bool(csv_result.get("success", false)):
		return csv_result
	return {
		"success": true,
		"errors": PackedStringArray(),
		"warnings": _compile_warnings.duplicate(),
		"event_count": int(csv_result.get("event_count", dialogue_result.get("event_count", 0))),
		"dialogue_asset_files": dialogue_result.get("dialogue_asset_files", PackedStringArray()),
		"dialogue_asset_event_ids": dialogue_result.get("dialogue_asset_event_ids", PackedStringArray()),
		"csv_asset_files": csv_result.get("csv_asset_files", PackedStringArray()),
		"csv_asset_event_ids": csv_result.get("csv_asset_event_ids", PackedStringArray())
	}

func get_source_markdown_paths() -> Array[String]:
	var result: Array[String] = []
	_collect_source_markdown_paths(MD_DIR.trim_suffix("/"), result)
	result.sort()
	return result

func _collect_source_markdown_paths(directory_path: String, result: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(directory_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name: String = dir.get_next()
	while entry_name != "":
		var full_path: String = "%s/%s" % [directory_path, entry_name]
		if dir.current_is_dir():
			if _should_skip_markdown_directory(entry_name):
				entry_name = dir.get_next()
				continue
			_collect_source_markdown_paths(full_path, result)
		elif _is_source_markdown_file(entry_name):
			result.append(full_path)
		entry_name = dir.get_next()

func _should_skip_markdown_directory(directory_name: String) -> bool:
	var normalized: String = directory_name.strip_edges().to_lower()
	return normalized == "archive" or normalized == "_archive" or normalized == "exports" or normalized.begins_with(".")

func _is_source_markdown_file(file_name: String) -> bool:
	if not file_name.ends_with(".md"):
		return false
	if file_name.begins_with("decompiled_") or file_name.begins_with("generated_"):
		return false
	return true

func get_output_path() -> String:
	return OUT_FILE

func get_writer_draft_output_path() -> String:
	return WRITER_DRAFT_OUT_FILE

func get_friendly_peer_arc_output_path() -> String:
	return FRIENDLY_PEER_ARC_MD_OUT_FILE

func get_markdown_dir() -> String:
	return MD_DIR

func get_markdown_authoring_dir() -> String:
	return "%sactive/" % MD_DIR

func get_mapping_paths() -> Dictionary:
	return {
		"event_id_map": EVENT_ID_MAP_PATH,
		"npc_name_map": NPC_NAME_MAP_PATH,
		"location_name_map": LOCATION_NAME_MAP_PATH,
		"status_key_map": STATUS_KEY_MAP_PATH
	}

func export_friendly_peer_current_arc_markdown(write_output: bool = true) -> Dictionary:
	var event_ids: Array[String] = [
		"2001",
		"2002",
		"2102"
	]
	return export_event_ids_to_markdown(event_ids, FRIENDLY_PEER_ARC_MD_OUT_FILE, write_output)

func export_event_ids_to_markdown(event_ids: Array[String], output_path: String, write_output: bool = true) -> Dictionary:
	_compile_warnings.clear()
	_compile_errors.clear()
	_event_id_map = _load_event_id_map()
	_npc_name_map = _load_named_id_map(NPC_NAME_MAP_PATH, "NPC")
	_location_name_map = _load_named_id_map(LOCATION_NAME_MAP_PATH, "地点")
	_status_map_by_scope = _load_status_key_map()
	_author_folder_label_map = _load_author_folder_label_map()
	_battle_card_name_map = _load_battle_card_name_map()
	_runtime_event_id_map = _load_runtime_event_id_map()
	var bundles: Array[Dictionary] = _load_current_event_bundles(_normalize_event_ids_for_export(event_ids))
	if not _compile_errors.is_empty():
		return {
			"success": false,
			"errors": _compile_errors.duplicate(),
			"warnings": _compile_warnings.duplicate(),
			"event_count": 0
		}
	var markdown_text: String = _build_export_markdown_document(bundles)
	if not write_output:
		return {
			"success": true,
			"errors": PackedStringArray(),
			"warnings": _compile_warnings.duplicate(),
			"event_count": bundles.size(),
			"output_path": output_path,
			"markdown_text": markdown_text,
			"bundles": bundles
		}
	var file: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if file == null:
		return {
			"success": false,
			"errors": PackedStringArray(["无法写入导出的 Markdown：%s" % output_path]),
			"warnings": _compile_warnings.duplicate(),
			"event_count": bundles.size()
		}
	file.store_string(markdown_text)
	file.close()
	return {
		"success": true,
		"errors": PackedStringArray(),
		"warnings": _compile_warnings.duplicate(),
		"event_count": bundles.size(),
		"output_path": output_path,
		"bundles": bundles
	}

func parse_md_file(path: String) -> Array:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Cannot read file: " + path)
		return []
	
	var content = file.get_as_text()
	file.close()
	
	var event_blocks = content.split("# [事件]", false)
	var events = []
	
	var effect_regex = RegEx.new()
	effect_regex.compile("\\$([^$]+)\\$")
	
	for block in event_blocks:
		var lines = block.split("\n")
		if lines.is_empty():
			continue
			
		var header_line = lines[0].strip_edges()
		if header_line.is_empty():
			continue
		if header_line.begins_with("#"):
			continue
			
		var explicit_internal_id: String = _find_block_internal_id(lines)
		var event_id = ""
		if not explicit_internal_id.is_empty():
			event_id = explicit_internal_id
		else:
			event_id = _resolve_event_id(path, header_line)
		if event_id.is_empty():
			continue
		var event = {
			"id": event_id,
			"title": header_line if not _is_numeric_id(header_line) else "",
			"content_category": "npc_state",
			"event_class": "fixed_story",
			"presentation_type": "standard_event",
			"slot": "phase_entry",
			"time_slot": "day",
			"trigger_conditions": [],
			"block_conditions": [],
			"participants": _infer_participants_from_path(path),
			"req_flags": [],
			"block_flags": [],
			"description": "",
			"opening_text": "",
			"opening_portrait_label": "",
			"observation_text": "",
			"observation_portrait_label": "",
			"talk_portrait_label": "",
			"intrusion_texts": {},
			"intrusion_portrait_labels": {},
			"options": [],
			"intrusion_options": {}
		}
		
		var i = 1
		var desc_lines = []
		var opening_lines = []
		var observation_lines = []
		var current_prelude_section = "description"
		var intrusion_buffers: Dictionary = {}
		var options = []
		var intrusion_option_sets: Dictionary = {}
		var option_index: int = 0
		var current_option = null
		var current_branch = "main"
		var current_option_intrusion_id := ""
		var branch_desc = []
		
		while i < lines.size():
			var line = lines[i].strip_edges()
			if line.is_empty():
				i += 1
				continue
				
			if line.begins_with("@"):
				var colon_idx = line.find(":")
				if colon_idx != -1:
					var key = line.substr(1, colon_idx - 1).strip_edges()
					var val = line.substr(colon_idx + 1).strip_edges()
					apply_metadata(event, key, val)
				i += 1
				continue

			if _apply_dialogue_portrait_marker(event, line):
				i += 1
				continue

			var section_marker: Dictionary = _parse_dialogue_section_marker(line)
			if not section_marker.is_empty():
				if current_option != null:
					save_branch_text(current_option, current_branch, branch_desc)
					current_option = null
					current_branch = "main"
					branch_desc.clear()
				current_prelude_section = str(section_marker.get("section", "description"))
				if section_marker.has("talk_intrusion_id"):
					current_option_intrusion_id = str(section_marker.get("talk_intrusion_id", ""))
				var intrusion_id: String = str(section_marker.get("intrusion_id", ""))
				if not intrusion_id.is_empty() and not intrusion_buffers.has(intrusion_id):
					intrusion_buffers[intrusion_id] = {
						"desc": [],
						"hint": [],
						"log": []
					}
				i += 1
				continue
			
			if line.begins_with("=>"):
				if current_option != null:
					save_branch_text(current_option, current_branch, branch_desc)
				else:
					event["description"] = "\n".join(desc_lines).strip_edges()
					event["opening_text"] = "\n".join(opening_lines).strip_edges()
					event["observation_text"] = "\n".join(observation_lines).strip_edges()
					event["intrusion_texts"] = _finalize_intrusion_buffers(intrusion_buffers)
				
				option_index += 1
				current_option = create_new_option(line, _build_draft_event_id(event), option_index)
				if current_option_intrusion_id.is_empty():
					options.append(current_option)
				else:
					if not intrusion_option_sets.has(current_option_intrusion_id):
						intrusion_option_sets[current_option_intrusion_id] = []
					var current_intrusion_options: Array = Array(intrusion_option_sets.get(current_option_intrusion_id, []))
					current_intrusion_options.append(current_option)
					intrusion_option_sets[current_option_intrusion_id] = current_intrusion_options
				current_branch = "main"
				branch_desc.clear()
				i += 1
				continue
				
			if current_option != null:
				if line.begins_with("要求:"):
					var requirement_text: String = line.trim_prefix("要求:").strip_edges()
					current_option["conditions"].append_array(parse_conditions(requirement_text))
					i += 1
					continue
				if line.begins_with("[成功]"):
					save_branch_text(current_option, current_branch, branch_desc)
					current_branch = "success"
					branch_desc.clear()
					var req = line.get_slice("(", 1).get_slice(")", 0).strip_edges()
					if not req.is_empty():
						_apply_branch_metadata(current_option, current_branch, req, event)
				elif line.begins_with("[失败]"):
					save_branch_text(current_option, current_branch, branch_desc)
					current_branch = "failure"
					branch_desc.clear()
				else:
					var matches = effect_regex.search_all(line)
					if not matches.is_empty():
						var clean_line = line
						for m in matches:
							var effects_str = m.get_string(1)
							var effects = parse_effects(effects_str, current_branch)
							current_option["effects"].append_array(effects)
							clean_line = clean_line.replace(m.get_string(0), "").strip_edges()
						if not clean_line.is_empty():
							branch_desc.append(clean_line)
					else:
						branch_desc.append(line)
			else:
				match current_prelude_section:
					"opening":
						opening_lines.append(line)
					"observe":
						observation_lines.append(line)
					_:
						if current_prelude_section.begins_with("intrusion:"):
							var intrusion_id: String = current_prelude_section.trim_prefix("intrusion:")
							_append_intrusion_buffer_line(intrusion_buffers, intrusion_id, "desc", line)
						elif current_prelude_section.begins_with("intrusion_hint:"):
							var hint_intrusion_id: String = current_prelude_section.trim_prefix("intrusion_hint:")
							_append_intrusion_buffer_line(intrusion_buffers, hint_intrusion_id, "hint", line)
						elif current_prelude_section.begins_with("intrusion_log:"):
							var log_intrusion_id: String = current_prelude_section.trim_prefix("intrusion_log:")
							_append_intrusion_buffer_line(intrusion_buffers, log_intrusion_id, "log", line)
						else:
							desc_lines.append(line)
					
			i += 1
			
		if current_option != null:
			save_branch_text(current_option, current_branch, branch_desc)
		else:
			event["description"] = "\n".join(desc_lines).strip_edges()
		event["opening_text"] = "\n".join(opening_lines).strip_edges()
		event["observation_text"] = "\n".join(observation_lines).strip_edges()
		event["intrusion_texts"] = _finalize_intrusion_buffers(intrusion_buffers)
		event["intrusion_options"] = _finalize_intrusion_options(intrusion_option_sets)
		for option_definition: Dictionary in options:
			_finalize_option(option_definition)
			
		event["options"] = options
		_apply_event_structure_defaults(event)
		events.append(event)
		
	return events

func _apply_event_structure_defaults(event: Dictionary) -> void:
	var has_dialogue_structure: bool = (
		not str(event.get("opening_text", "")).strip_edges().is_empty()
		or not str(event.get("observation_text", "")).strip_edges().is_empty()
		or not Dictionary(event.get("intrusion_texts", {})).is_empty()
		or not Dictionary(event.get("intrusion_options", {})).is_empty()
	)
	var presentation_type: String = str(event.get("presentation_type", "standard_event"))
	var has_battle_entry: bool = not str(event.get("battle_id", "")).strip_edges().is_empty()
	if has_dialogue_structure and presentation_type == "standard_event" and has_battle_entry:
		event["presentation_type"] = "dialogue_event"
		return
	if presentation_type == "dialogue_event" and not has_battle_entry:
		event["presentation_type"] = "standard_event"
		_warn("事件 %s 标记为 dialogue_event 但没有 battle_id，已自动降级为 standard_event" % str(event.get("id", "")))

func apply_metadata(event: Dictionary, key: String, val: String):
	if key == "条件":
		event["trigger_conditions"] = parse_conditions(val)
	elif key == "NPC":
		event["participants"] = _parse_npc_list(val)
	elif key == "参与者":
		event["participants"] = _parse_npc_list(val)
	elif key == "要求状态":
		_append_required_npc_state(event, val)
	elif key == "需要状态":
		event["req_flags"] = _parse_flag_list(val)
		event["trigger_conditions"] = _append_flag_conditions(event["trigger_conditions"], event["req_flags"])
	elif key == "排除状态":
		event["block_flags"] = _parse_flag_list(val)
		event["block_conditions"] = _append_flag_conditions(event["block_conditions"], event["block_flags"])
	elif key == "地点":
		event["location_id"] = _resolve_location_id(val)
	elif key == "标题" or key == "事件标题":
		event["title"] = val
	elif key == "编号" or key == "事件编号" or key == "内部编号" or key == "ID":
		if _is_numeric_id(val):
			event["id"] = val
		else:
			_error("编号必须是纯数字：%s" % val)
	elif key == "剧情分类" or key == "事件分类":
		event["event_class"] = _parse_label_value(val, CLASS_LABELS, "剧情分类")
	elif key == "内容分类":
		event["content_category"] = _parse_content_category(val)
	elif key == "表现形式":
		event["presentation_type"] = _parse_label_value(val, PRESENTATION_LABELS, "表现形式")
	elif key == "触发阶段":
		event["slot"] = _parse_label_value(val, SLOT_LABELS, "触发阶段")
	elif key == "触发时间" or key == "时间":
		var parsed_time: String = _parse_label_value(val, TIME_LABELS, "触发时间")
		event["time_slot"] = parsed_time
		_append_phase_condition(event, parsed_time)

func save_branch_text(option: Dictionary, branch: String, lines: Array):
	if lines.is_empty():
		return
	var text = "\n".join(lines).strip_edges()
	if branch == "main":
		option["result_text"] = text
	elif branch == "success":
		option["success_result_text"] = text
	elif branch == "failure":
		option["failure_result_text"] = text

func _parse_dialogue_section_marker(line: String) -> Dictionary:
	if line == "[开场]":
		return {"section": "opening"}
	if line == "[观察]":
		return {"section": "observe"}
	if line == "[对话]":
		return {"section": "description", "talk_intrusion_id": ""}
	if line.begins_with("[对话:") and line.ends_with("]"):
		var raw_talk_intrusion: String = line.trim_prefix("[对话:").trim_suffix("]").strip_edges()
		return {
			"section": "description",
			"talk_intrusion_id": _normalize_intrusion_id(raw_talk_intrusion),
			"intrusion_id": _normalize_intrusion_id(raw_talk_intrusion)
		}
	if line.begins_with("[入侵:") and line.ends_with("]"):
		var raw_intrusion: String = line.trim_prefix("[入侵:").trim_suffix("]").strip_edges()
		return {"section": "intrusion:%s" % _normalize_intrusion_id(raw_intrusion), "intrusion_id": _normalize_intrusion_id(raw_intrusion)}
	if line.begins_with("[入侵提示:") and line.ends_with("]"):
		var raw_hint_intrusion: String = line.trim_prefix("[入侵提示:").trim_suffix("]").strip_edges()
		return {"section": "intrusion_hint:%s" % _normalize_intrusion_id(raw_hint_intrusion), "intrusion_id": _normalize_intrusion_id(raw_hint_intrusion)}
	if line.begins_with("[入侵记录:") and line.ends_with("]"):
		var raw_log_intrusion: String = line.trim_prefix("[入侵记录:").trim_suffix("]").strip_edges()
		return {"section": "intrusion_log:%s" % _normalize_intrusion_id(raw_log_intrusion), "intrusion_id": _normalize_intrusion_id(raw_log_intrusion)}
	return {}

func _apply_dialogue_portrait_marker(event: Dictionary, line: String) -> bool:
	if not line.begins_with("[") or not line.ends_with("]") or line.find(":") == -1:
		return false
	var raw_body: String = line.trim_prefix("[").trim_suffix("]").strip_edges()
	var parts: PackedStringArray = raw_body.split(":", false, 1)
	if parts.size() != 2:
		return false
	var marker_name: String = parts[0].strip_edges()
	var marker_value: String = parts[1].strip_edges()
	if marker_name == "开场表情":
		event["opening_portrait_label"] = marker_value
		return true
	if marker_name == "观察表情":
		event["observation_portrait_label"] = marker_value
		return true
	if marker_name == "对话表情":
		event["talk_portrait_label"] = marker_value
		return true
	if marker_name == "入侵表情":
		var pair_parts: PackedStringArray = marker_value.split("=", false, 1)
		if pair_parts.size() != 2:
			return false
		var intrusion_id: String = _normalize_intrusion_id(pair_parts[0].strip_edges())
		var portrait_label: String = pair_parts[1].strip_edges()
		var portrait_map: Dictionary = Dictionary(event.get("intrusion_portrait_labels", {}))
		portrait_map[intrusion_id] = portrait_label
		event["intrusion_portrait_labels"] = portrait_map
		return true
	return false

func _normalize_intrusion_id(value: String) -> String:
	match value.strip_edges().to_lower():
		"贪", "greed":
			return "greed"
		"嗔", "wrath":
			return "wrath"
		"痴", "delusion":
			return "delusion"
		_:
			return _slugify_identifier(value)

func _ensure_intrusion_buffer(buffers: Dictionary, intrusion_id: String) -> void:
	if buffers.has(intrusion_id):
		return
	buffers[intrusion_id] = {
		"desc": [],
		"hint": [],
		"log": []
	}

func _append_intrusion_buffer_line(buffers: Dictionary, intrusion_id: String, field_name: String, line: String) -> void:
	_ensure_intrusion_buffer(buffers, intrusion_id)
	var buffer: Dictionary = Dictionary(buffers.get(intrusion_id, {}))
	var lines: Array = Array(buffer.get(field_name, []))
	lines.append(line)
	buffer[field_name] = lines
	buffers[intrusion_id] = buffer

func _finalize_intrusion_buffers(buffers: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for intrusion_id: Variant in buffers.keys():
		var buffer: Dictionary = Dictionary(buffers[intrusion_id])
		result[str(intrusion_id)] = {
			"desc": "\n".join(Array(buffer.get("desc", []))).strip_edges(),
			"hint": "\n".join(Array(buffer.get("hint", []))).strip_edges(),
			"log": "\n".join(Array(buffer.get("log", []))).strip_edges()
		}
	return result

func _finalize_intrusion_options(option_sets: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for intrusion_id: Variant in option_sets.keys():
		var finalized_options: Array[Dictionary] = []
		for option_variant: Variant in Array(option_sets.get(intrusion_id, [])):
			var option_definition: Dictionary = Dictionary(option_variant)
			_finalize_option(option_definition)
			finalized_options.append(option_definition)
		result[str(intrusion_id)] = finalized_options
	return result

func create_new_option(line: String, event_id: String, option_index: int) -> Dictionary:
	var opt := {
		"id": "%s_opt_%02d" % [event_id, option_index],
		"text": "",
		"result_text": "",
		"success_result_text": "",
		"failure_result_text": "",
		"conditions": [],
		"effects": []
	}
	var content = line.substr(2).strip_edges()
	if content.begins_with("[") and "]" in content:
		var bracket_content = content.get_slice("[", 1).get_slice("]", 0)
		if ":" in bracket_content:
			var parts = bracket_content.split(":", false, 1)
			opt["mode_label"] = parts[0].strip_edges()
			opt["text"] = parts[1].strip_edges()
			_apply_mode_defaults(opt)
		else:
			opt["text"] = bracket_content.strip_edges()
			
		if "(" in content and ")" in content:
			var paren_content = content.get_slice("(", 1).get_slice(")", 0)
			_apply_option_metadata(opt, paren_content.strip_edges())
	else:
		opt["text"] = content
	return opt

func parse_conditions(val: String) -> Array:
	var conds = []
	var parts = val.split(",", false)
	for p in parts:
		p = p.strip_edges()
		if "turn <" in p:
			var max_turn = p.replace("turn <", "").strip_edges().to_int()
			conds.append({"type": "day_range", "min": 1, "max": max_turn - 1})
		elif p.begins_with("第 ") and p.ends_with(" 天及以后"):
			var min_text: String = p.trim_prefix("第 ").trim_suffix(" 天及以后").strip_edges()
			conds.append({"type": "day_gte", "value": min_text.to_int()})
		elif p.begins_with("第 ") and p.find(" 天到第 ") != -1 and p.ends_with(" 天"):
			var body: String = p.trim_prefix("第 ").trim_suffix(" 天")
			var range_parts: PackedStringArray = body.split(" 天到第 ", false)
			if range_parts.size() == 2:
				conds.append({"type": "day_range", "min": range_parts[0].to_int(), "max": range_parts[1].to_int()})
		elif p.begins_with("第 ") and p.ends_with(" 天"):
			var day_text: String = p.trim_prefix("第 ").trim_suffix(" 天").strip_edges()
			conds.append({"type": "day_range", "min": day_text.to_int(), "max": day_text.to_int()})
		elif "global." in p and "==" in p:
			var flag_key = p.get_slice("global.", 1).get_slice("==", 0).strip_edges()
			var flag_val = p.get_slice("==", 1).strip_edges() == "true"
			conds.append({"type": "flag_present" if flag_val else "flag_not_present", "key": flag_key})
		elif p.begins_with("已拥有【") and p.ends_with("】"):
			var label: String = p.trim_prefix("已拥有【").trim_suffix("】").strip_edges()
			conds.append({"type": "flag_present", "key": _parse_status_key(label, "flag")})
		elif p.begins_with("已满足【") and p.ends_with("】"):
			var done_label: String = p.trim_prefix("已满足【").trim_suffix("】").strip_edges()
			conds.append({"type": "flag_present", "key": _parse_status_key(done_label, "flag")})
		elif p.begins_with("时间为【") and p.ends_with("】"):
			var time_label: String = p.trim_prefix("时间为【").trim_suffix("】").strip_edges()
			conds.append({"type": "phase_is", "value": _parse_label_value(time_label, TIME_LABELS, "时间条件")})
		elif p.begins_with("地点为【") and p.ends_with("】"):
			var location_label: String = p.trim_prefix("地点为【").trim_suffix("】").strip_edges()
			conds.append({"type": "current_location_is", "value": _resolve_location_id(location_label)})
		else:
			_warn("未识别条件表达式: %s" % p)
	return conds

func parse_effects(val: String, outcome: String = "") -> Array:
	var effects = []
	var parts = val.split(",", false)
	for p in parts:
		p = p.strip_edges()
		if ":" in p:
			var kv = p.split(":", false, 1)
			var k = kv[0].strip_edges()
			var v = kv[1].strip_edges()
			
			if k == "宿主气血" or k == "气血":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "blood_qi", "delta": v.to_int()}, outcome))
			elif k == "暴露度":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "exposure", "delta": v.to_int()}, outcome))
			elif k == "MP" or k == "神识":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "spirit_sense", "delta": v.to_int()}, outcome))
			elif k == "线索碎片" or k == "线索":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "clue_fragments", "delta": v.to_int()}, outcome))
			elif k == "灵石":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "spirit_stone", "delta": v.to_int()}, outcome))
			elif k == "污染度":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "pollution", "delta": v.to_int()}, outcome))
			elif k == "天魔经验" or k == "经验":
				effects.append(_with_outcome({"type": "modify_resource", "scope": "player", "key": "experience", "delta": v.to_int()}, outcome))
			elif k == "增加标记":
				effects.append(_with_outcome({"type": "add_tag", "scope": "player", "key": _parse_status_key(v, "player_tag")}, outcome))
			elif k == "移除标记":
				effects.append(_with_outcome({"type": "remove_tag", "scope": "player", "key": _parse_status_key(v, "player_tag")}, outcome))
			elif k == "获得状态":
				effects.append(_with_outcome({"type": "set_flag", "key": _parse_status_key(v, "flag"), "value": true}, outcome))
			elif k == "移除状态":
				effects.append(_with_outcome({"type": "clear_flag", "key": _parse_status_key(v, "flag")}, outcome))
			elif k == "获得卡牌" or k == "获得魔念卡":
				effects.append(_with_outcome({"type": "add_battle_card", "key": _resolve_battle_card_id(v)}, outcome))
			elif k == "移除卡牌" or k == "删除卡牌":
				effects.append(_with_outcome({"type": "remove_battle_card", "key": _resolve_battle_card_id(v)}, outcome))
			elif k == "NPC关系":
				var relation_match := RegEx.new()
				relation_match.compile("^(.+?)\\.([^\\s]+)\\s*([+-]?\\d+)$")
				var relation_result: RegExMatch = relation_match.search(v)
				if relation_result != null:
					effects.append(_with_outcome({
						"type": "modify_npc_relation",
						"npc_id": _resolve_npc_id(relation_result.get_string(1).strip_edges()),
						"field": _parse_relation_field(relation_result.get_string(2).strip_edges()),
						"delta": relation_result.get_string(3).to_int()
					}, outcome))
				else:
					_warn("未识别 NPC关系 效果格式: %s" % v)
			elif k == "结束本局":
				var reason_id: String = v if not v.is_empty() else "event_resolution"
				effects.append(_with_outcome({"type": "finish_run", "reason_id": reason_id}, outcome))
			elif k == "解锁地点":
				effects.append(_with_outcome({"type": "unlock_location", "target_id": _resolve_location_id(v)}, outcome))
			elif k == "封锁地点":
				effects.append(_with_outcome({"type": "block_location", "target_id": _resolve_location_id(v)}, outcome))
			elif k == "解除封锁":
				effects.append(_with_outcome({"type": "unblock_location", "target_id": _resolve_location_id(v)}, outcome))
			elif k == "NPC状态":
				var npc_parts = v.split("=", false, 1)
				if npc_parts.size() == 2:
					effects.append(_with_outcome({
						"type": "add_npc_tag",
						"npc_id": _resolve_npc_id(npc_parts[0].strip_edges()),
						"key": _parse_status_key(npc_parts[1].strip_edges(), "npc_tag")
					}, outcome))
			else:
				_warn("未识别效果别名: %s" % k)
		elif p == "结束本局":
			effects.append(_with_outcome({"type": "finish_run", "reason_id": "event_resolution"}, outcome))
	return effects

func _resolve_event_id(path: String, header_line: String) -> String:
	if _is_numeric_id(header_line):
		return header_line
	if _event_id_map.has(header_line):
		return str(_event_id_map[header_line])
	_error("事件《%s》缺少数字ID映射，请先在 %s 中补充。文件：%s" % [header_line, EVENT_ID_MAP_PATH, path])
	return ""

func _find_block_internal_id(lines: Array) -> String:
	for index: int in range(1, lines.size()):
		var line: String = str(lines[index]).strip_edges()
		if line.is_empty():
			continue
		if not line.begins_with("@"):
			break
		var colon_idx: int = line.find(":")
		if colon_idx == -1:
			continue
		var key: String = line.substr(1, colon_idx - 1).strip_edges()
		var value: String = line.substr(colon_idx + 1).strip_edges()
		if (key == "编号" or key == "事件编号" or key == "内部编号" or key == "ID") and _is_numeric_id(value):
			return value
	return ""

func _looks_like_internal_id(value: String) -> bool:
	if value.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^[a-z0-9_]+$")
	return regex.search(value) != null

func _slugify_identifier(value: String) -> String:
	var normalized := value.to_snake_case().strip_edges().to_lower()
	var cleaned := ""
	for i in normalized.length():
		var char := normalized[i]
		if (char >= "a" and char <= "z") or (char >= "0" and char <= "9") or char == "_":
			cleaned += char
	if cleaned.is_empty():
		return "md_%s" % value.sha1_text().substr(0, 8)
	return cleaned

func _parse_label_value(value: String, mapping: Dictionary, label_name: String) -> String:
	if mapping.has(value):
		return _normalize_time_slot(str(mapping[value]))
	if mapping.values().has(value):
		return _normalize_time_slot(value)
	_warn("%s 存在未登记值: %s" % [label_name, value])
	return _normalize_time_slot(value)

func _normalize_time_slot(value: String) -> String:
	var trimmed: String = value.strip_edges()
	if trimmed == "afternoon":
		return "day"
	return trimmed

func _parse_flag_label(value: String) -> String:
	if FLAG_LABELS.has(value):
		return str(FLAG_LABELS[value])
	return _parse_status_key(value, "flag")

func _parse_flag_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for part in value.split(",", false):
		var trimmed: String = part.strip_edges()
		if trimmed.is_empty():
			continue
		result.append(_parse_flag_label(trimmed))
	return result

func _append_flag_conditions(conditions: Array, flag_keys: Array[String]) -> Array:
	var result: Array = conditions.duplicate(true)
	for flag_key: String in flag_keys:
		result.append({"type": "flag_present", "key": flag_key})
	return result

func _append_phase_condition(event: Dictionary, phase_value: String) -> void:
	phase_value = _normalize_time_slot(phase_value)
	var conditions: Array = event.get("trigger_conditions", [])
	for condition in conditions:
		if condition is Dictionary and str(condition.get("type", "")) == "phase_is":
			condition["value"] = phase_value
			event["trigger_conditions"] = conditions
			return
	conditions.append({"type": "phase_is", "value": phase_value})
	event["trigger_conditions"] = conditions

func _warn(message: String) -> void:
	if _compile_warnings.has(message):
		return
	_compile_warnings.append(message)

func _error(message: String) -> void:
	if _compile_errors.has(message):
		return
	_compile_errors.append(message)

func _load_event_id_map() -> Dictionary:
	var file: FileAccess = FileAccess.open(EVENT_ID_MAP_PATH, FileAccess.READ)
	if file == null:
		_error("未找到事件ID映射表：%s" % EVENT_ID_MAP_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_error("事件ID映射表格式错误，必须是数组：%s" % EVENT_ID_MAP_PATH)
		return {}
	var mapping: Dictionary = {}
	var used_ids: Dictionary = {}
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var title: String = str(item.get("title", "")).strip_edges()
		var event_id: String = str(item.get("id", "")).strip_edges()
		if title.is_empty() or event_id.is_empty():
			continue
		if not _is_numeric_id(event_id):
			_error("事件ID必须为纯数字，当前为 %s（%s）" % [event_id, title])
			continue
		if mapping.has(title):
			_error("事件中文名重复映射：%s" % title)
			continue
		if used_ids.has(event_id):
			_error("事件数字ID重复：%s（%s / %s）" % [event_id, used_ids[event_id], title])
			continue
		mapping[title] = event_id
		used_ids[event_id] = title
	return mapping

func _load_named_id_map(path: String, label_name: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		_error("未找到%s映射表：%s" % [label_name, path])
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_error("%s映射表格式错误，必须是数组：%s" % [label_name, path])
		return {}
	var mapping: Dictionary = {}
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var title: String = str(item.get("title", "")).strip_edges()
		var target_id: String = str(item.get("id", "")).strip_edges()
		if title.is_empty() or target_id.is_empty():
			continue
		mapping[title] = target_id
		for alias: Variant in item.get("aliases", []):
			var alias_text: String = str(alias).strip_edges()
			if not alias_text.is_empty():
				mapping[alias_text] = target_id
	return mapping

func _load_status_key_map() -> Dictionary:
	var file: FileAccess = FileAccess.open(STATUS_KEY_MAP_PATH, FileAccess.READ)
	if file == null:
		_error("未找到状态映射表：%s" % STATUS_KEY_MAP_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_error("状态映射表格式错误，必须是数组：%s" % STATUS_KEY_MAP_PATH)
		return {}
	var result := {
		"flag": {},
		"player_tag": {},
		"npc_tag": {}
	}
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var scope: String = str(item.get("scope", "")).strip_edges()
		var title: String = str(item.get("title", "")).strip_edges()
		var key: String = str(item.get("key", "")).strip_edges()
		if scope.is_empty() or title.is_empty() or key.is_empty():
			continue
		if not result.has(scope):
			result[scope] = {}
		result[scope][title] = key
		for alias: Variant in item.get("aliases", []):
			var alias_text: String = str(alias).strip_edges()
			if not alias_text.is_empty():
				result[scope][alias_text] = key
	return result

func _parse_npc_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for part in value.split(",", false):
		var trimmed := part.strip_edges()
		if trimmed.is_empty():
			continue
		result.append(_resolve_npc_id(trimmed))
	return result

func _resolve_npc_id(value: String) -> String:
	if _npc_name_map.has(value):
		return str(_npc_name_map[value])
	return value

func _load_author_folder_label_map() -> Dictionary:
	var file: FileAccess = FileAccess.open(AUTHOR_FOLDER_MAP_PATH, FileAccess.READ)
	if file == null:
		_warn("未找到作者目录说明表：%s" % AUTHOR_FOLDER_MAP_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_warn("作者目录说明表格式错误：%s" % AUTHOR_FOLDER_MAP_PATH)
		return {}
	var result: Dictionary = {}
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var folder: String = str(item.get("folder", "")).strip_edges()
		var label: String = str(item.get("label", "")).strip_edges()
		if folder.is_empty() or label.is_empty():
			continue
		result[folder] = label
	return result

func _load_battle_card_name_map() -> Dictionary:
	var file: FileAccess = FileAccess.open(BATTLE_CARD_DEFINITIONS_PATH, FileAccess.READ)
	if file == null:
		_warn("未找到心战卡牌定义：%s" % BATTLE_CARD_DEFINITIONS_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		_warn("心战卡牌定义格式错误：%s" % BATTLE_CARD_DEFINITIONS_PATH)
		return {}
	var result: Dictionary = {}
	for item: Variant in parsed:
		if not item is Dictionary:
			continue
		var card_id: String = str(item.get("id", "")).strip_edges()
		var display_name: String = str(item.get("display_name", "")).strip_edges()
		if card_id.is_empty():
			continue
		result[card_id] = card_id
		if not display_name.is_empty():
			result[display_name] = card_id
	return result

func _resolve_battle_card_id(value: String) -> String:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return ""
	if _battle_card_name_map.has(trimmed):
		return str(_battle_card_name_map[trimmed])
	return trimmed

func _infer_participants_from_path(path: String) -> Array[String]:
	var folder_name: String = path.get_base_dir().get_file()
	if folder_name.is_empty() or folder_name == "00":
		return []
	var label: String = str(_author_folder_label_map.get(folder_name, "")).strip_edges()
	if label.is_empty():
		return []
	var npc_id: String = _resolve_npc_id(label)
	if npc_id.is_empty() or npc_id == label and not _npc_name_map.has(label):
		_warn("作者目录 %s 没有对应的人物映射：%s" % [folder_name, label])
		return []
	return [npc_id]

func _resolve_location_id(value: String) -> String:
	if _location_name_map.has(value):
		return str(_location_name_map[value])
	return value

func _parse_status_key(value: String, scope: String) -> String:
	var scope_mapping: Dictionary = Dictionary(_status_map_by_scope.get(scope, {}))
	if scope_mapping.has(value):
		return str(scope_mapping[value])
	if scope == "flag" and FLAG_LABELS.has(value):
		return str(FLAG_LABELS[value])
	if _looks_like_internal_id(value) or _is_numeric_id(value):
		return value
	_warn("状态映射表未登记，已按自动 key 处理：%s（%s）" % [scope, value])
	return _slugify_identifier(value)

func _append_required_npc_state(event: Dictionary, value: String) -> void:
	var participants: Array = event.get("participants", [])
	if participants.is_empty():
		_warn("要求状态缺少参与者，已忽略：%s" % value)
		return
	var first_npc: String = str(participants[0])
	var conditions: Array = event.get("trigger_conditions", [])
	conditions.append({
		"type": "npc_tag_present",
		"npc_id": first_npc,
		"key": _parse_status_key(value, "npc_tag")
	})
	event["trigger_conditions"] = conditions

func _parse_content_category(value: String) -> String:
	match value:
		"人物状态", "npc_state":
			return "npc_state"
		"主线骨架", "main_story":
			return "main_story"
		"地点内容", "location_content":
			return "location_content"
		"随机扰动", "random_disturbance":
			return "random_disturbance"
		"灰市交易", "black_market_trade":
			return "black_market_trade"
		_:
			_warn("未识别内容分类: %s" % value)
			return "npc_state"

func _build_writer_draft_document(events: Array[Dictionary]) -> String:
	var sections: Array[String] = [
		"# 当前项目剧情草稿包",
		"",
		"这份文件不是运行时产物，而是给当前项目使用的桥接草稿包。",
		"目标是把 Markdown 作者稿翻译成当前项目真正维护的三层：CSV / encounter / texts。",
		""
	]
	for event_definition: Dictionary in events:
		sections.append(_build_writer_draft_section(event_definition))
		sections.append("")
	return "\n".join(sections).strip_edges() + "\n"


func _build_writer_draft_section(event_definition: Dictionary) -> String:
	var event_numeric_id: String = str(event_definition.get("id", ""))
	var draft_id: String = _build_draft_event_id(event_definition)
	var title: String = str(event_definition.get("title", draft_id))
	var presentation_type: String = str(event_definition.get("presentation_type", "standard_event"))
	var content_category: String = str(event_definition.get("content_category", "npc_state"))
	var time_slot: String = str(event_definition.get("time_slot", "day"))
	var slot: String = str(event_definition.get("slot", "phase_entry"))
	var location_id: String = str(event_definition.get("location_id", ""))
	var participants: Array[String] = Array(event_definition.get("participants", []), TYPE_STRING, "", null)
	var primary_npc_id: String = participants[0] if not participants.is_empty() else ""
	var primary_npc_label: String = _map_id_to_label(primary_npc_id, _npc_name_map) if not primary_npc_id.is_empty() else "-"
	var description: String = str(event_definition.get("description", "")).strip_edges()
	var opening_text: String = str(event_definition.get("opening_text", "")).strip_edges()
	var observation_text: String = str(event_definition.get("observation_text", "")).strip_edges()
	var intrusion_texts: Dictionary = Dictionary(event_definition.get("intrusion_texts", {}))
	var options: Array[Dictionary] = Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null)
	var lines: Array[String] = [
		"## %s" % title,
		"",
		"- 剧情编号: `%s`" % event_numeric_id,
		"- 表现形式: `%s`" % _reverse_lookup_label(PRESENTATION_LABELS, presentation_type),
		"- 内容分类: `%s`" % content_category,
		"- 触发阶段: `%s`" % _reverse_lookup_label(SLOT_LABELS, slot),
		"- 触发时间: `%s`" % _reverse_lookup_label(TIME_LABELS, time_slot),
		"- 关联人物: `%s`" % primary_npc_label,
		"- 地点: `%s`" % (_map_id_to_label(location_id, _location_name_map) if not location_id.is_empty() else "-"),
		"",
		"### 作者摘要",
		"description = %s" % _single_line_for_doc(description),
	]
	if not options.is_empty():
		lines.append("")
		lines.append("### 对话骨架")
		for index: int in range(options.size()):
			var option_definition: Dictionary = options[index]
			lines.append("option_%02d.text = %s" % [index + 1, _single_line_for_doc(str(option_definition.get("text", "")).strip_edges())])
			lines.append("option_%02d.result = %s" % [index + 1, _single_line_for_doc(str(option_definition.get("result_text", "")).strip_edges())])
			var success_text: String = str(option_definition.get("success_result_text", "")).strip_edges()
			var failure_text: String = str(option_definition.get("failure_result_text", "")).strip_edges()
			if not success_text.is_empty():
				lines.append("option_%02d.success = %s" % [index + 1, _single_line_for_doc(success_text)])
			if not failure_text.is_empty():
				lines.append("option_%02d.failure = %s" % [index + 1, _single_line_for_doc(failure_text)])

	var title_key: String = "evt.%s.title" % draft_id
	var desc_key: String = "evt.%s.desc" % draft_id
	lines.append("")
	lines.append("### CSV 草稿")
	lines.append("events.csv")
	lines.append("<编译后自动定位>,<story_id>,<event_class>,%s,%s,<参与者由目录推断>,,%s,%s,<speaker_visual>,,,%s,,%s,,300,1,false,%s,%s,generated_from_markdown,,,,,,,," % [content_category, time_slot, presentation_type, slot, location_id, title_key, desc_key])
	lines.append("")
	lines.append("event_triggers.csv")
	lines.append("%s,main,1,phase_is,,,%s,,," % [draft_id, time_slot])
	var trigger_order: int = 2
	for condition in Array(event_definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null):
		var trigger_line: String = _build_trigger_csv_hint(draft_id, trigger_order, condition)
		if not trigger_line.is_empty():
			lines.append(trigger_line)
			trigger_order += 1
	lines.append("")
	lines.append("event_options.csv")
	for index: int in range(options.size()):
		var option_id: String = "%s_opt_%02d" % [draft_id, index + 1]
		lines.append("%s,%s,%d,opt.%s.text,opt.%s.result," % [option_id, draft_id, index + 1, option_id, option_id])
	lines.append("")
	lines.append("option_effects.csv")
	for index: int in range(options.size()):
		var option_id: String = "%s_opt_%02d" % [draft_id, index + 1]
		var effect_lines: Array[String] = _build_effect_csv_hints(option_id, options[index])
		if effect_lines.is_empty():
			lines.append("%s,1,TODO_EFFECT,,,,,," % option_id)
		else:
			lines.append_array(effect_lines)
	lines.append("")
	lines.append("localization.csv")
	lines.append("%s,%s" % [title_key, _csv_escape(title)])
	lines.append("%s,%s" % [desc_key, _csv_escape(description)])
	for index: int in range(options.size()):
		var option_definition: Dictionary = options[index]
		var option_id: String = "%s_opt_%02d" % [draft_id, index + 1]
		lines.append("opt.%s.text,%s" % [option_id, _csv_escape(str(option_definition.get("text", "")))])
		lines.append("opt.%s.result,%s" % [option_id, _csv_escape(str(option_definition.get("result_text", "")))])

	if presentation_type == "dialogue_event" or content_category == "npc_state":
		lines.append("")
		lines.append("### Encounter/Text 草稿")
		lines.append("logic.event_id = %s" % draft_id)
		lines.append("logic.opening_text_id = %s.opening" % draft_id)
		lines.append("logic.observation_text_id = %s.observe" % draft_id)
		lines.append("texts.%s.opening = %s" % [draft_id, _single_line_for_doc(opening_text if not opening_text.is_empty() else description)])
		lines.append("texts.%s.observe = %s" % [draft_id, _single_line_for_doc(observation_text)])
		for intrusion_spec: Dictionary in DEFAULT_INTRUSION_SPECS:
			var intrusion_id: String = str(intrusion_spec.get("id", ""))
			var parsed_intrusion: Dictionary = Dictionary(intrusion_texts.get(intrusion_id, {}))
			lines.append("texts.%s.%s.desc = %s" % [draft_id, intrusion_id, _single_line_for_doc(str(parsed_intrusion.get("desc", str(intrusion_spec.get("desc", "")))))])
			lines.append("texts.%s.%s.hint = %s" % [draft_id, intrusion_id, _single_line_for_doc(str(parsed_intrusion.get("hint", str(intrusion_spec.get("hint", "")))))])
			lines.append("texts.%s.%s.log = %s" % [draft_id, intrusion_id, _single_line_for_doc(str(parsed_intrusion.get("log", str(intrusion_spec.get("log", "")))))])
		var intrusion_option_sets: Dictionary = Dictionary(event_definition.get("intrusion_options", {}))
		for intrusion_id: Variant in intrusion_option_sets.keys():
			var override_options: Array = Array(intrusion_option_sets[intrusion_id])
			for option_index: int in range(override_options.size()):
				var override_option: Dictionary = Dictionary(override_options[option_index])
				lines.append("texts.%s.%s.opt_%02d.text = %s" % [draft_id, str(intrusion_id), option_index + 1, _single_line_for_doc(str(override_option.get("text", "")))])
				lines.append("texts.%s.%s.opt_%02d.result = %s" % [draft_id, str(intrusion_id), option_index + 1, _single_line_for_doc(str(override_option.get("result_text", "")))])
	lines.append("notes = 如果这是当前新对话系统要走的事件，请把 Markdown 选项改写成观察/入侵/对话三段结构，再补入侵改写。")

	lines.append("")
	lines.append("### 接线提醒")
	lines.append("- 请把上面的草稿分发到 csv / encounters / texts")
	lines.append("- 运行时只保留当前主结构，不再直接载入 Markdown 产物")
	lines.append("- Markdown 在当前项目里只是作者输入层，不再是第二套运行时事件源")
	return "\n".join(lines)


func _build_draft_event_id(event_definition: Dictionary) -> String:
	var numeric_id: String = str(event_definition.get("id", "")).strip_edges()
	if _is_numeric_id(numeric_id):
		if _runtime_event_id_map.has(numeric_id):
			return str(_runtime_event_id_map[numeric_id])
		return numeric_id
	var runtime_event_id: String = str(event_definition.get("runtime_event_id", "")).strip_edges()
	if not runtime_event_id.is_empty():
		return runtime_event_id
	var participants: Array[String] = Array(event_definition.get("participants", []), TYPE_STRING, "", null)
	var npc_id: String = participants[0] if not participants.is_empty() else "story"
	var title: String = str(event_definition.get("title", "draft"))
	return "%s_%s" % [npc_id, _slugify_identifier(title)]

func _load_current_event_bundles(event_ids: Array[String]) -> Array[Dictionary]:
	var events_table: Dictionary = _load_csv_table("%s/events.csv" % STORY_CSV_DIR)
	var triggers_table: Dictionary = _load_csv_table("%s/event_triggers.csv" % STORY_CSV_DIR)
	var options_table: Dictionary = _load_csv_table("%s/event_options.csv" % STORY_CSV_DIR)
	var option_conditions_table: Dictionary = _load_csv_table("%s/option_conditions.csv" % STORY_CSV_DIR)
	var option_effects_table: Dictionary = _load_csv_table("%s/option_effects.csv" % STORY_CSV_DIR)
	var localization_table: Dictionary = _load_localization_table("%s/localization.csv" % STORY_CSV_DIR)
	var localization_map: Dictionary = _localization_rows_to_map(localization_table)
	var trigger_rows_by_event: Dictionary = _group_csv_rows_by_field(triggers_table, "event_id")
	var option_rows_by_event: Dictionary = _group_csv_rows_by_field(options_table, "event_id")
	var option_condition_rows_by_option: Dictionary = _group_csv_rows_by_field(option_conditions_table, "option_id")
	var option_effect_rows_by_option: Dictionary = _group_csv_rows_by_field(option_effects_table, "option_id")
	var encounter_map: Dictionary = _load_current_encounter_map()
	var event_rows: Dictionary = {}
	for row_variant: Variant in Array(events_table.get("rows", [])):
		var row: Dictionary = Dictionary(row_variant)
		var event_id: String = str(row.get("event_id", "")).strip_edges()
		if not event_id.is_empty():
			event_rows[event_id] = row.duplicate(true)
	var bundles: Array[Dictionary] = []
	for event_id: String in event_ids:
		if not event_rows.has(event_id):
			_error("当前项目中找不到事件：%s" % event_id)
			continue
		var event_row: Dictionary = Dictionary(event_rows[event_id]).duplicate(true)
		bundles.append(_build_event_bundle_from_rows(
			event_row,
			Array(trigger_rows_by_event.get(event_id, [])),
			Array(option_rows_by_event.get(event_id, [])),
			option_condition_rows_by_option,
			option_effect_rows_by_option,
			localization_map,
			Dictionary(encounter_map.get(event_id, {})).duplicate(true)
		))
	return bundles

func _localization_rows_to_map(table: Dictionary) -> Dictionary:
	var map: Dictionary = {}
	for row_variant: Variant in Array(table.get("rows", [])):
		var row: Dictionary = Dictionary(row_variant)
		var key: String = str(row.get("text_key", "")).strip_edges()
		if key.is_empty():
			continue
		map[key] = str(row.get("zh_cn", ""))
	return map

func _group_csv_rows_by_field(table: Dictionary, field_name: String) -> Dictionary:
	var grouped: Dictionary = {}
	for row_variant: Variant in Array(table.get("rows", [])):
		var row: Dictionary = Dictionary(row_variant)
		var key: String = str(row.get(field_name, "")).strip_edges()
		if key.is_empty():
			continue
		if not grouped.has(key):
			grouped[key] = []
		var rows: Array = Array(grouped[key])
		rows.append(row.duplicate(true))
		grouped[key] = rows
	return grouped

func _load_current_encounter_map() -> Dictionary:
	var manifest_entries: Array[Dictionary] = _load_json_array(DIALOGUE_MANIFEST_PATH)
	var encounter_map: Dictionary = {}
	for manifest_entry: Dictionary in manifest_entries:
		var logic_path: String = str(manifest_entry.get("logic_path", "")).strip_edges()
		var text_path: String = str(manifest_entry.get("text_path", "")).strip_edges()
		if logic_path.is_empty() or text_path.is_empty():
			continue
		var encounters: Array[Dictionary] = _load_json_array(logic_path)
		var texts: Dictionary = _load_json_dictionary(text_path)
		for encounter_definition: Dictionary in encounters:
			var event_id: String = str(encounter_definition.get("event_id", "")).strip_edges()
			if event_id.is_empty():
				continue
			encounter_map[event_id] = {
				"encounter": encounter_definition.duplicate(true),
				"texts": texts.duplicate(true)
			}
	return encounter_map

func _build_event_bundle_from_rows(
	event_row: Dictionary,
	trigger_rows: Array,
	option_rows: Array,
	option_condition_rows_by_option: Dictionary,
	option_effect_rows_by_option: Dictionary,
	localization_map: Dictionary,
	encounter_payload: Dictionary
) -> Dictionary:
	var event_id: String = str(event_row.get("event_id", ""))
	var bundle: Dictionary = {
		"id": _resolve_export_internal_id(str(event_row.get("title_key", "")), event_id, localization_map),
		"runtime_event_id": event_id,
		"title": _resolve_localized_text(localization_map, str(event_row.get("title_key", "")), event_id),
		"description": _resolve_localized_text(localization_map, str(event_row.get("desc_key", "")), ""),
		"event_class": str(event_row.get("event_class", "conditional_story")),
		"content_category": str(event_row.get("content_category", "npc_state")),
		"presentation_type": str(event_row.get("presentation_type", "standard_event")),
		"slot": str(event_row.get("slot", "phase_entry")),
		"time_slot": _normalize_time_slot(str(event_row.get("time_slot", "day"))),
		"location_id": str(event_row.get("location_id", "")),
		"participants": _parse_pipe_list(str(event_row.get("participants", ""))),
		"trigger_conditions": _build_conditions_from_rows(trigger_rows),
		"options": _build_option_bundles_from_rows(
			event_id,
			option_rows,
			option_condition_rows_by_option,
			option_effect_rows_by_option,
			localization_map
		),
		"opening_text": "",
		"opening_portrait_label": "",
		"observation_text": "",
		"observation_portrait_label": "",
		"talk_portrait_label": "",
		"intrusion_texts": {},
		"intrusion_portrait_labels": {},
		"intrusion_options": {}
	}
	if not encounter_payload.is_empty():
		var encounter_definition: Dictionary = Dictionary(encounter_payload.get("encounter", {}))
		var texts: Dictionary = Dictionary(encounter_payload.get("texts", {}))
		bundle["opening_text"] = str(texts.get(str(encounter_definition.get("opening_text_id", "")), "")).strip_edges()
		bundle["opening_portrait_label"] = str(encounter_definition.get("opening_portrait_label", "")).strip_edges()
		bundle["observation_text"] = str(texts.get(str(encounter_definition.get("observation_text_id", "")), "")).strip_edges()
		bundle["observation_portrait_label"] = str(encounter_definition.get("observation_portrait_label", "")).strip_edges()
		bundle["talk_portrait_label"] = str(encounter_definition.get("talk_portrait_label", "")).strip_edges()
		bundle["intrusion_texts"] = _build_intrusion_text_bundle(event_id, encounter_definition, texts)
		bundle["intrusion_portrait_labels"] = _build_intrusion_portrait_label_bundle(encounter_definition)
		bundle["intrusion_options"] = _build_intrusion_option_bundle(event_id, encounter_definition, texts, Array(bundle.get("options", [])))
	return bundle

func _resolve_export_internal_id(title_key: String, fallback_event_id: String, localization_map: Dictionary = {}) -> String:
	var runtime_match := RegEx.new()
	runtime_match.compile("(?:^|_)(\\d+)$")
	var matched_runtime: RegExMatch = runtime_match.search(fallback_event_id)
	if matched_runtime != null:
		return matched_runtime.get_string(1)
	var localized_title: String = _resolve_localized_text(localization_map, title_key, "").strip_edges()
	if not localized_title.is_empty() and _event_id_map.has(localized_title):
		return str(_event_id_map[localized_title])
	if _is_numeric_id(fallback_event_id):
		return fallback_event_id
	return ""

func _load_runtime_event_id_map() -> Dictionary:
	var events_table: Dictionary = _load_csv_table("%s/events.csv" % STORY_CSV_DIR)
	var localization_table: Dictionary = _load_localization_table("%s/localization.csv" % STORY_CSV_DIR)
	var localization_map: Dictionary = _localization_rows_to_map(localization_table)
	var mapping: Dictionary = {}
	for row_variant: Variant in Array(events_table.get("rows", [])):
		var row: Dictionary = Dictionary(row_variant)
		var runtime_event_id: String = str(row.get("event_id", "")).strip_edges()
		if runtime_event_id.is_empty():
			continue
		var internal_id: String = _resolve_export_internal_id(str(row.get("title_key", "")), runtime_event_id, localization_map)
		if _is_numeric_id(internal_id):
			mapping[internal_id] = runtime_event_id
	return mapping

func _normalize_event_ids_for_export(event_ids: Array[String]) -> Array[String]:
	var normalized: Array[String] = []
	for event_id: String in event_ids:
		var trimmed: String = event_id.strip_edges()
		if trimmed.is_empty():
			continue
		if _is_numeric_id(trimmed) and _runtime_event_id_map.has(trimmed):
			normalized.append(str(_runtime_event_id_map[trimmed]))
		else:
			normalized.append(trimmed)
	return normalized

func _parse_pipe_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for item: String in value.split("|", false):
		var trimmed: String = item.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result

func _resolve_localized_text(localization_map: Dictionary, text_key: String, fallback: String) -> String:
	if localization_map.has(text_key):
		return str(localization_map[text_key]).strip_edges()
	return fallback

func _build_conditions_from_rows(trigger_rows: Array) -> Array[Dictionary]:
	var ordered_rows: Array = trigger_rows.duplicate(true)
	ordered_rows.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(Dictionary(a).get("order", "0")) < int(Dictionary(b).get("order", "0"))
	)
	var conditions: Array[Dictionary] = []
	for row_variant: Variant in ordered_rows:
		var row: Dictionary = Dictionary(row_variant)
		var condition_type: String = str(row.get("condition_type", ""))
		match condition_type:
			"phase_is":
				continue
			"day_range":
				var range_parts: PackedStringArray = str(row.get("op_value", "")).split("-", false)
				if range_parts.size() == 2:
					conditions.append({"type": "day_range", "min": range_parts[0].to_int(), "max": range_parts[1].to_int()})
			"day_gte":
				conditions.append({"type": "day_gte", "value": str(row.get("op_value", "")).to_int()})
			"flag_present", "flag_not_present":
				conditions.append({"type": condition_type, "key": str(row.get("key", ""))})
			"current_location_is":
				conditions.append({"type": "current_location_is", "value": str(row.get("op_value", ""))})
			"npc_tag_present":
				conditions.append({
					"type": "npc_tag_present",
					"npc_id": str(row.get("target_id", "")),
					"key": str(row.get("key", ""))
				})
			_:
				if not str(row.get("extra_json", "")).strip_edges().is_empty():
					var parsed: Variant = JSON.parse_string(str(row.get("extra_json", "")))
					if parsed is Dictionary:
						conditions.append(Dictionary(parsed).duplicate(true))
	return conditions

func _build_option_bundles_from_rows(
	event_id: String,
	option_rows: Array,
	option_condition_rows_by_option: Dictionary,
	option_effect_rows_by_option: Dictionary,
	localization_map: Dictionary
) -> Array[Dictionary]:
	var ordered_rows: Array = option_rows.duplicate(true)
	ordered_rows.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(Dictionary(a).get("order", "0")) < int(Dictionary(b).get("order", "0"))
	)
	var options: Array[Dictionary] = []
	for row_variant: Variant in ordered_rows:
		var row: Dictionary = Dictionary(row_variant)
		var option_id: String = str(row.get("option_id", ""))
		options.append({
			"id": option_id,
			"text": _resolve_localized_text(localization_map, str(row.get("text_key", "")), str(row.get("text_key", ""))),
			"result_text": _resolve_localized_text(localization_map, str(row.get("result_key", "")), ""),
			"success_result_text": _resolve_localized_text(localization_map, str(row.get("success_result_key", "")), ""),
			"failure_result_text": _resolve_localized_text(localization_map, str(row.get("failure_result_key", "")), ""),
			"check": _build_option_check_from_row(row),
			"conditions": _build_option_conditions_from_rows(Array(option_condition_rows_by_option.get(option_id, []))),
			"effects": _build_option_effects_from_rows(Array(option_effect_rows_by_option.get(option_id, [])))
		})
	return options

func _build_option_check_from_row(row: Dictionary) -> Dictionary:
	var system: String = str(row.get("check_system", "")).strip_edges()
	if system.is_empty():
		return {}
	return {
		"system": system,
		"source": str(row.get("check_source", "")),
		"key": str(row.get("check_key", "")),
		"target": _to_int_or_string(str(row.get("check_target", ""))),
		"bonus": _to_int_or_string(str(row.get("check_bonus", ""))),
		"npc_id": str(row.get("check_npc_id", "")),
		"field": str(row.get("check_field", ""))
	}

func _build_option_conditions_from_rows(condition_rows: Array) -> Array[Dictionary]:
	var ordered_rows: Array = condition_rows.duplicate(true)
	ordered_rows.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(Dictionary(a).get("order", "0")) < int(Dictionary(b).get("order", "0"))
	)
	var conditions: Array[Dictionary] = []
	for row_variant: Variant in ordered_rows:
		var row: Dictionary = Dictionary(row_variant)
		var condition_type: String = str(row.get("condition_type", ""))
		match condition_type:
			"resource_gte":
				conditions.append({"type": "resource_gte", "key": str(row.get("key", "")), "value": str(row.get("op_value", "")).to_int()})
			"flag_present", "flag_not_present":
				conditions.append({"type": condition_type, "key": str(row.get("key", ""))})
			_:
				if not str(row.get("extra_json", "")).strip_edges().is_empty():
					var parsed: Variant = JSON.parse_string(str(row.get("extra_json", "")))
					if parsed is Dictionary:
						conditions.append(Dictionary(parsed).duplicate(true))
	return conditions

func _build_option_effects_from_rows(effect_rows: Array) -> Array[Dictionary]:
	var ordered_rows: Array = effect_rows.duplicate(true)
	ordered_rows.sort_custom(func(a: Variant, b: Variant) -> bool:
		return int(Dictionary(a).get("order", "0")) < int(Dictionary(b).get("order", "0"))
	)
	var effects: Array[Dictionary] = []
	for row_variant: Variant in ordered_rows:
		var row: Dictionary = Dictionary(row_variant)
		var effect: Dictionary = {
			"type": str(row.get("effect_type", "")),
			"scope": str(row.get("scope", "")),
			"key": str(row.get("key", "")),
			"delta": _to_float_or_int(str(row.get("delta", ""))),
			"target_id": str(row.get("target_id", "")),
			"field": str(row.get("field", "")),
			"outcome": str(row.get("outcome", ""))
		}
		if effect["type"] == "modify_npc_relation":
			effect["npc_id"] = str(row.get("target_id", ""))
		if not str(row.get("extra_json", "")).strip_edges().is_empty():
			var parsed: Variant = JSON.parse_string(str(row.get("extra_json", "")))
			if parsed is Dictionary:
				for extra_key: Variant in Dictionary(parsed).keys():
					effect[str(extra_key)] = Dictionary(parsed)[extra_key]
		effects.append(_trim_empty_dictionary(effect))
	return effects

func _trim_empty_dictionary(value: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key_variant: Variant in value.keys():
		var key: String = str(key_variant)
		var item: Variant = value[key]
		if item is String and String(item).strip_edges().is_empty():
			continue
		result[key] = item
	return result

func _to_int_or_string(value: String) -> Variant:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed.is_valid_int():
		return trimmed.to_int()
	return trimmed

func _to_float_or_int(value: String) -> Variant:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return ""
	if trimmed.is_valid_int():
		return trimmed.to_int()
	if trimmed.is_valid_float():
		return trimmed.to_float()
	return trimmed

func _build_intrusion_text_bundle(event_id: String, encounter_definition: Dictionary, texts: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for intrusion_variant: Variant in Array(encounter_definition.get("intrusions", [])):
		var intrusion: Dictionary = Dictionary(intrusion_variant)
		var intrusion_id: String = str(intrusion.get("id", "")).strip_edges()
		if intrusion_id.is_empty():
			continue
		result[intrusion_id] = {
			"label": str(texts.get(str(intrusion.get("label_id", "")), "")),
			"domain": str(texts.get(str(intrusion.get("domain_label_id", "")), "")),
			"desc": str(texts.get(str(intrusion.get("description_id", "")), "")),
			"hint": str(texts.get(str(intrusion.get("selected_hint_text_id", "")), "")),
			"log": str(texts.get(str(intrusion.get("apply_log_text_id", "")), ""))
		}
	return result

func _build_intrusion_portrait_label_bundle(encounter_definition: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for intrusion_variant: Variant in Array(encounter_definition.get("intrusions", [])):
		var intrusion: Dictionary = Dictionary(intrusion_variant)
		var intrusion_id: String = str(intrusion.get("id", "")).strip_edges()
		if intrusion_id.is_empty():
			continue
		var portrait_label: String = str(intrusion.get("selected_portrait_label", "")).strip_edges()
		if portrait_label.is_empty():
			continue
		result[intrusion_id] = portrait_label
	return result

func _build_intrusion_option_bundle(event_id: String, encounter_definition: Dictionary, texts: Dictionary, base_options: Array) -> Dictionary:
	var result: Dictionary = {}
	for intrusion_variant: Variant in Array(encounter_definition.get("intrusions", [])):
		var intrusion: Dictionary = Dictionary(intrusion_variant)
		var intrusion_id: String = str(intrusion.get("id", "")).strip_edges()
		if intrusion_id.is_empty():
			continue
		var override_map: Dictionary = Dictionary(intrusion.get("option_overrides", {}))
		if override_map.is_empty():
			continue
		var overrides: Array[Dictionary] = []
		for base_option_variant: Variant in base_options:
			var base_option: Dictionary = Dictionary(base_option_variant)
			var option_id: String = str(base_option.get("id", "")).strip_edges()
			if option_id.is_empty() or not override_map.has(option_id):
				continue
			var override_entry: Dictionary = Dictionary(override_map[option_id])
			overrides.append({
				"id": option_id,
				"text": _fallback_text_value(texts, str(override_entry.get("text_id", "")), str(base_option.get("text", ""))),
				"result_text": _fallback_text_value(texts, str(override_entry.get("result_text_id", "")), str(base_option.get("result_text", ""))),
				"effects": Array(override_entry.get("effects", [])).duplicate(true)
			})
		if not overrides.is_empty():
			result[intrusion_id] = overrides
	return result

func _fallback_text_value(texts: Dictionary, text_id: String, fallback: String) -> String:
	var resolved: String = str(texts.get(text_id, "")).strip_edges()
	if not resolved.is_empty():
		return resolved
	return fallback.strip_edges()

func _build_export_markdown_document(event_bundles: Array[Dictionary]) -> String:
	var sections: Array[String] = [
		"# 当前柳线主剧本",
		"",
		"> 这份文件由当前项目结构反向导出，后续应优先在这里改文案，再写回 `CSV + encounters + texts`。",
		""
	]
	for bundle: Dictionary in event_bundles:
		sections.append(_build_export_markdown_event_section(bundle))
		sections.append("")
	return "\n".join(sections).strip_edges() + "\n"

func _build_export_markdown_event_section(bundle: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("# [事件] %s" % str(bundle.get("title", bundle.get("runtime_event_id", ""))))
	lines.append("@编号: %s" % str(bundle.get("id", "")))
	lines.append("@剧情分类: %s" % _reverse_lookup_label(CLASS_LABELS, str(bundle.get("event_class", "conditional_story"))))
	lines.append("@内容分类: %s" % str(bundle.get("content_category", "npc_state")))
	lines.append("@表现形式: %s" % _reverse_lookup_label(PRESENTATION_LABELS, str(bundle.get("presentation_type", "standard_event"))))
	lines.append("@触发阶段: %s" % _reverse_lookup_label(SLOT_LABELS, str(bundle.get("slot", "phase_entry"))))
	lines.append("@触发时间: %s" % _reverse_lookup_label(TIME_LABELS, _normalize_time_slot(str(bundle.get("time_slot", "day")))))
	var location_id: String = str(bundle.get("location_id", "")).strip_edges()
	if not location_id.is_empty():
		lines.append("@地点: %s" % _map_id_to_label(location_id, _location_name_map))
	var conditions_line: String = _conditions_to_markdown(Array(bundle.get("trigger_conditions", [])))
	if not conditions_line.is_empty():
		lines.append("@条件: %s" % conditions_line)
	lines.append("")
	lines.append("[开场]")
	lines.append(str(bundle.get("opening_text", "")).strip_edges())
	lines.append("")
	lines.append("[观察]")
	lines.append(str(bundle.get("observation_text", "")).strip_edges())
	var intrusion_texts: Dictionary = Dictionary(bundle.get("intrusion_texts", {}))
	for intrusion_id: String in ["greed", "wrath", "delusion"]:
		var intrusion: Dictionary = Dictionary(intrusion_texts.get(intrusion_id, {}))
		if intrusion.is_empty():
			continue
		lines.append("")
		lines.append("[入侵: %s]" % _intrusion_label(intrusion_id))
		lines.append(str(intrusion.get("desc", "")).strip_edges())
		lines.append("")
		lines.append("[入侵提示: %s]" % _intrusion_label(intrusion_id))
		lines.append(str(intrusion.get("hint", "")).strip_edges())
		lines.append("")
		lines.append("[入侵记录: %s]" % _intrusion_label(intrusion_id))
		lines.append(str(intrusion.get("log", "")).strip_edges())
	lines.append("")
	lines.append("[对话]")
	lines.append_array(_options_to_markdown(Array(bundle.get("options", []))))
	var intrusion_options: Dictionary = Dictionary(bundle.get("intrusion_options", {}))
	for intrusion_id: String in ["greed", "wrath", "delusion"]:
		var options: Array = Array(intrusion_options.get(intrusion_id, []))
		if options.is_empty():
			continue
		lines.append("")
		lines.append("[对话: %s]" % _intrusion_label(intrusion_id))
		lines.append_array(_options_to_markdown(options))
	return "\n".join(lines).strip_edges()

func _map_id_to_label(value: String, mapping: Dictionary) -> String:
	for label_variant: Variant in mapping.keys():
		if str(mapping[label_variant]) == value:
			return str(label_variant)
	return value

func _map_ids_to_labels(values: Array[String], mapping: Dictionary) -> Array[String]:
	var labels: Array[String] = []
	for value: String in values:
		labels.append(_map_id_to_label(value, mapping))
	return labels

func _reverse_lookup_label(mapping: Dictionary, internal_value: String) -> String:
	for label_variant: Variant in mapping.keys():
		if str(mapping[label_variant]) == internal_value:
			return str(label_variant)
	return internal_value

func _conditions_to_markdown(conditions: Array) -> String:
	var parts: Array[String] = []
	for condition_variant: Variant in conditions:
		var condition: Dictionary = Dictionary(condition_variant)
		match str(condition.get("type", "")):
			"day_gte":
				parts.append("第 %d 天及以后" % int(condition.get("value", 0)))
			"day_range":
				var min_day: int = int(condition.get("min", 0))
				var max_day: int = int(condition.get("max", 0))
				if min_day == max_day:
					parts.append("第 %d 天" % min_day)
				else:
					parts.append("第 %d 天到第 %d 天" % [min_day, max_day])
			"flag_present":
				parts.append("global.%s == true" % str(condition.get("key", "")))
			"flag_not_present":
				parts.append("global.%s == false" % str(condition.get("key", "")))
			"current_location_is":
				parts.append("地点为【%s】" % _map_id_to_label(str(condition.get("value", "")), _location_name_map))
			"npc_tag_present":
				parts.append("%s具备【%s】" % [
					_map_id_to_label(str(condition.get("npc_id", "")), _npc_name_map),
					_status_key_to_label(str(condition.get("key", "")), "npc_tag")
				])
	return ", ".join(parts)

func _options_to_markdown(options: Array) -> Array[String]:
	var lines: Array[String] = []
	for option_variant: Variant in options:
		var option: Dictionary = Dictionary(option_variant)
		lines.append("=> [%s]" % str(option.get("text", "")).strip_edges())
		var result_text: String = str(option.get("result_text", "")).strip_edges()
		if not result_text.is_empty():
			lines.append(result_text)
		var effect_line: String = _effects_to_markdown(Array(option.get("effects", [])))
		if not effect_line.is_empty():
			lines.append(effect_line)
		lines.append("")
	if not lines.is_empty() and lines[-1].is_empty():
		lines.remove_at(lines.size() - 1)
	return lines

func _effects_to_markdown(effects: Array) -> String:
	var parts: Array[String] = []
	for effect_variant: Variant in effects:
		var effect: Dictionary = Dictionary(effect_variant)
		match str(effect.get("type", "")):
			"modify_resource":
				var resource_label_map := {
					"blood_qi": "宿主气血",
					"exposure": "暴露度",
					"spirit_sense": "神识",
					"clue_fragments": "线索碎片",
					"spirit_stone": "灵石",
					"pollution": "污染度",
					"experience": "天魔经验"
				}
				var key: String = str(effect.get("key", ""))
				var label: String = str(resource_label_map.get(key, key))
				var delta_value: Variant = effect.get("delta", "")
				var delta_text: String = str(delta_value)
				if not delta_text.begins_with("-"):
					delta_text = "+%s" % delta_text
				parts.append("%s: %s" % [label, delta_text])
			"set_flag":
				parts.append("获得状态: %s" % _status_key_to_label(str(effect.get("key", "")), "flag"))
			"clear_flag":
				parts.append("移除状态: %s" % _status_key_to_label(str(effect.get("key", "")), "flag"))
			"add_tag":
				parts.append("增加标记: %s" % _status_key_to_label(str(effect.get("key", "")), "player_tag"))
			"remove_tag":
				parts.append("移除标记: %s" % _status_key_to_label(str(effect.get("key", "")), "player_tag"))
			"add_battle_card":
				parts.append("获得卡牌: %s" % _map_id_to_label(str(effect.get("key", "")), _battle_card_name_map))
			"remove_battle_card":
				parts.append("移除卡牌: %s" % _map_id_to_label(str(effect.get("key", "")), _battle_card_name_map))
			"modify_npc_relation":
				var delta_variant: Variant = effect.get("delta", "")
				var relation_delta: String = str(delta_variant)
				if not relation_delta.begins_with("-"):
					relation_delta = "+%s" % relation_delta
				parts.append("NPC关系: %s.%s %s" % [
					_map_id_to_label(str(effect.get("npc_id", effect.get("target_id", ""))), _npc_name_map),
					_reverse_lookup_label(RELATION_FIELD_LABELS, str(effect.get("field", ""))),
					relation_delta
				])
			"add_npc_tag":
				parts.append("NPC状态: %s = %s" % [
					_map_id_to_label(str(effect.get("npc_id", effect.get("target_id", ""))), _npc_name_map),
					_status_key_to_label(str(effect.get("key", "")), "npc_tag")
				])
			"finish_run":
				parts.append("结束本局: %s" % str(effect.get("reason_id", "event_resolution")))
	return "" if parts.is_empty() else "$%s$" % ", ".join(parts)

func _status_key_to_label(key: String, scope: String) -> String:
	var scope_mapping: Dictionary = Dictionary(_status_map_by_scope.get(scope, {}))
	for label_variant: Variant in scope_mapping.keys():
		if str(scope_mapping[label_variant]) == key:
			return str(label_variant)
	return key

func _intrusion_label(intrusion_id: String) -> String:
	match intrusion_id:
		"greed":
			return "贪"
		"wrath":
			return "嗔"
		"delusion":
			return "痴"
		_:
			return intrusion_id

func _resolved_option_id(event_definition: Dictionary, option_definition: Dictionary, order: int) -> String:
	var explicit_option_id: String = str(option_definition.get("id", "")).strip_edges()
	if not explicit_option_id.is_empty():
		return explicit_option_id
	return _generated_option_id(_build_draft_event_id(event_definition), order)

func _option_text_suffix(option_id: String, event_id: String, order: int) -> String:
	var prefix: String = "%s_" % event_id
	if option_id.begins_with(prefix):
		return option_id.trim_prefix(prefix)
	if option_id == _generated_option_id(event_id, order):
		return "opt_%02d" % order
	return option_id


func _build_trigger_csv_hint(event_id: String, order: int, condition: Dictionary) -> String:
	var condition_type: String = str(condition.get("type", ""))
	match condition_type:
		"day_range":
			return "%s,main,%d,day_range,,,%s-%s,,," % [event_id, order, str(condition.get("min", "")), str(condition.get("max", ""))]
		"day_gte":
			return "%s,main,%d,day_gte,,,%s,,," % [event_id, order, str(condition.get("value", ""))]
		"flag_present":
			return "%s,main,%d,flag_present,,,%s,,," % [event_id, order, str(condition.get("key", ""))]
		"flag_not_present":
			return "%s,main,%d,flag_not_present,,,%s,,," % [event_id, order, str(condition.get("key", ""))]
		"npc_tag_present":
			return "%s,main,%d,npc_tag_present,,,%s,%s,," % [event_id, order, str(condition.get("key", "")), str(condition.get("npc_id", ""))]
		"current_location_is":
			return "%s,main,%d,current_location_is,,,%s,,," % [event_id, order, str(condition.get("value", ""))]
		"phase_is":
			return ""
		_:
			return "%s,main,%d,%s,,,,,," % [event_id, order, condition_type]


func _build_effect_csv_hints(option_id: String, option_definition: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var order: int = 1
	for effect_definition: Dictionary in Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null):
		var effect_type: String = str(effect_definition.get("type", ""))
		var scope: String = str(effect_definition.get("scope", ""))
		var key: String = str(effect_definition.get("key", ""))
		var delta: String = str(effect_definition.get("delta", ""))
		var npc_id: String = str(effect_definition.get("npc_id", ""))
		var outcome: String = str(effect_definition.get("outcome", ""))
		var extra: String = " # outcome=%s" % outcome if not outcome.is_empty() else ""
		lines.append("%s,%d,%s,%s,%s,%s,%s,,%s" % [option_id, order, effect_type, scope, key, delta, npc_id, extra])
		order += 1
	return lines

func _should_apply_dialogue_assets(event_definition: Dictionary) -> bool:
	var presentation_type: String = str(event_definition.get("presentation_type", ""))
	var content_category: String = str(event_definition.get("content_category", ""))
	return presentation_type == "dialogue_event" or content_category == "npc_state"

func _resolve_dialogue_manifest_entry(entries: Array[Dictionary], npc_id: String) -> Dictionary:
	for entry: Dictionary in entries:
		if _dialogue_manifest_entry_matches_npc(entry, npc_id):
			return entry
	return {}

func _dialogue_manifest_entry_matches_npc(entry: Dictionary, npc_id: String) -> bool:
	var logic_path: String = str(entry.get("logic_path", "")).strip_edges()
	if logic_path.is_empty():
		return false
	var stem: String = logic_path.get_file().trim_suffix(".json").trim_suffix("_logic")
	return npc_id == stem or npc_id.begins_with(stem) or stem.begins_with(npc_id)

func _build_generated_encounter(event_definition: Dictionary) -> Dictionary:
	var event_id: String = _build_draft_event_id(event_definition)
	var intrusion_option_sets: Dictionary = Dictionary(event_definition.get("intrusion_options", {}))
	var intrusion_portrait_labels: Dictionary = Dictionary(event_definition.get("intrusion_portrait_labels", {}))
	var encounter: Dictionary = {
		"event_id": event_id,
		"opening_text_id": "%s.opening" % event_id,
		"observation_text_id": "%s.observe" % event_id,
		"opening_portrait_label": str(event_definition.get("opening_portrait_label", "")).strip_edges(),
		"observation_portrait_label": str(event_definition.get("observation_portrait_label", "")).strip_edges(),
		"talk_portrait_label": str(event_definition.get("talk_portrait_label", "")).strip_edges(),
		"intrusions": []
	}
	for intrusion_spec: Dictionary in DEFAULT_INTRUSION_SPECS:
		var intrusion_id: String = str(intrusion_spec.get("id", ""))
		var intrusion_entry: Dictionary = {
			"id": intrusion_id,
			"label_id": "%s.%s.label" % [event_id, intrusion_id],
			"domain_label_id": "%s.%s.domain" % [event_id, intrusion_id],
			"description_id": "%s.%s.desc" % [event_id, intrusion_id],
			"selected_hint_text_id": "%s.%s.hint" % [event_id, intrusion_id],
			"apply_log_text_id": "%s.%s.log" % [event_id, intrusion_id]
		}
		var selected_portrait_label: String = str(intrusion_portrait_labels.get(intrusion_id, "")).strip_edges()
		if not selected_portrait_label.is_empty():
			intrusion_entry["selected_portrait_label"] = selected_portrait_label
		var override_map: Dictionary = _build_intrusion_option_overrides(event_definition, intrusion_id, Array(intrusion_option_sets.get(intrusion_id, [])))
		if not override_map.is_empty():
			intrusion_entry["option_overrides"] = override_map
		encounter["intrusions"].append(intrusion_entry)
	return encounter

func _upsert_generated_encounter(encounters: Array[Dictionary], generated_encounter: Dictionary) -> bool:
	var event_id: String = str(generated_encounter.get("event_id", ""))
	for index: int in range(encounters.size()):
		var existing: Dictionary = encounters[index]
		if str(existing.get("event_id", "")) != event_id:
			continue
		var changed: bool = false
		if str(existing.get("opening_text_id", "")) != str(generated_encounter.get("opening_text_id", "")):
			existing["opening_text_id"] = generated_encounter.get("opening_text_id", "")
			changed = true
		if str(existing.get("observation_text_id", "")) != str(generated_encounter.get("observation_text_id", "")):
			existing["observation_text_id"] = generated_encounter.get("observation_text_id", "")
			changed = true
		if str(existing.get("opening_portrait_label", "")) != str(generated_encounter.get("opening_portrait_label", "")):
			existing["opening_portrait_label"] = generated_encounter.get("opening_portrait_label", "")
			changed = true
		if str(existing.get("observation_portrait_label", "")) != str(generated_encounter.get("observation_portrait_label", "")):
			existing["observation_portrait_label"] = generated_encounter.get("observation_portrait_label", "")
			changed = true
		if str(existing.get("talk_portrait_label", "")) != str(generated_encounter.get("talk_portrait_label", "")):
			existing["talk_portrait_label"] = generated_encounter.get("talk_portrait_label", "")
			changed = true
		var merged_intrusions: Array[Dictionary] = _merge_generated_intrusions(
			Array(existing.get("intrusions", [])),
			Array(generated_encounter.get("intrusions", []))
		)
		if JSON.stringify(existing.get("intrusions", [])) != JSON.stringify(merged_intrusions):
			existing["intrusions"] = merged_intrusions
			changed = true
		encounters[index] = existing
		return changed
	encounters.append(generated_encounter)
	return true

func _merge_generated_intrusions(existing_intrusions_raw: Array, generated_intrusions_raw: Array) -> Array[Dictionary]:
	var existing_by_id: Dictionary = {}
	var order: Array[String] = []
	for intrusion_variant: Variant in existing_intrusions_raw:
		var intrusion: Dictionary = Dictionary(intrusion_variant).duplicate(true)
		var intrusion_id: String = str(intrusion.get("id", ""))
		if intrusion_id.is_empty():
			continue
		existing_by_id[intrusion_id] = intrusion
		order.append(intrusion_id)
	for generated_variant: Variant in generated_intrusions_raw:
		var generated_intrusion: Dictionary = Dictionary(generated_variant).duplicate(true)
		var generated_id: String = str(generated_intrusion.get("id", ""))
		if generated_id.is_empty():
			continue
		if not existing_by_id.has(generated_id):
			existing_by_id[generated_id] = generated_intrusion
			order.append(generated_id)
			continue
		var merged: Dictionary = Dictionary(existing_by_id[generated_id]).duplicate(true)
		for field_name: Variant in generated_intrusion.keys():
			var field_key: String = str(field_name)
			if field_key == "option_overrides":
				var generated_overrides: Dictionary = Dictionary(generated_intrusion.get("option_overrides", {})).duplicate(true)
				if generated_overrides.is_empty():
					merged.erase("option_overrides")
				else:
					# Generated Markdown events own their override payloads end-to-end.
					# Replacing the whole map prevents stale hash keys or old effects from surviving merges.
					merged["option_overrides"] = generated_overrides
			else:
				merged[field_key] = generated_intrusion[field_name]
		existing_by_id[generated_id] = merged
	var result: Array[Dictionary] = []
	for intrusion_id: String in order:
		result.append(Dictionary(existing_by_id[intrusion_id]).duplicate(true))
	return result

func _merge_generated_texts(texts: Dictionary, event_definition: Dictionary, generated_encounter: Dictionary) -> bool:
	var changed: bool = false
	var event_id: String = str(generated_encounter.get("event_id", ""))
	var opening_text_id: String = str(generated_encounter.get("opening_text_id", ""))
	var observation_text_id: String = str(generated_encounter.get("observation_text_id", ""))
	var opening_text: String = str(event_definition.get("opening_text", "")).strip_edges()
	if opening_text.is_empty():
		opening_text = str(event_definition.get("description", "")).strip_edges()
	var observation_text: String = str(event_definition.get("observation_text", "")).strip_edges()
	var intrusion_texts: Dictionary = Dictionary(event_definition.get("intrusion_texts", {}))
	if texts.get(opening_text_id, "") != opening_text:
		texts[opening_text_id] = opening_text
		changed = true
	if observation_text.is_empty():
		observation_text = "TODO：补充观察阶段描写。"
	if texts.get(observation_text_id, "") != observation_text:
		texts[observation_text_id] = observation_text
		changed = true
	for intrusion_spec: Dictionary in DEFAULT_INTRUSION_SPECS:
		var intrusion_id: String = str(intrusion_spec.get("id", ""))
		changed = _set_missing_text_key(texts, "%s.%s.label" % [event_id, intrusion_id], str(intrusion_spec.get("label", ""))) or changed
		changed = _set_missing_text_key(texts, "%s.%s.domain" % [event_id, intrusion_id], "魔念") or changed
		var parsed_intrusion_texts: Dictionary = Dictionary(intrusion_texts.get(intrusion_id, {}))
		changed = _set_preferred_text_key(texts, "%s.%s.desc" % [event_id, intrusion_id], str(parsed_intrusion_texts.get("desc", str(intrusion_spec.get("desc", ""))))) or changed
		changed = _set_preferred_text_key(texts, "%s.%s.hint" % [event_id, intrusion_id], str(parsed_intrusion_texts.get("hint", str(intrusion_spec.get("hint", ""))))) or changed
		changed = _set_preferred_text_key(texts, "%s.%s.log" % [event_id, intrusion_id], str(parsed_intrusion_texts.get("log", str(intrusion_spec.get("log", ""))))) or changed
	var base_options: Array[Dictionary] = Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null)
	var intrusion_option_sets: Dictionary = Dictionary(event_definition.get("intrusion_options", {}))
	for intrusion_id: Variant in intrusion_option_sets.keys():
		var intrusion_options: Array = Array(intrusion_option_sets[intrusion_id])
		for option_index: int in range(min(base_options.size(), intrusion_options.size())):
			var base_option: Dictionary = base_options[option_index]
			var option_id: String = _resolved_option_id(event_definition, base_option, option_index + 1)
			var override_option: Dictionary = Dictionary(intrusion_options[option_index])
			var option_suffix: String = _option_text_suffix(option_id, event_id, option_index + 1)
			var text_key: String = "%s.%s.%s.text" % [event_id, str(intrusion_id), option_suffix]
			var result_key: String = "%s.%s.%s.result" % [event_id, str(intrusion_id), option_suffix]
			changed = _set_preferred_text_key(texts, text_key, str(override_option.get("text", "")).strip_edges()) or changed
			changed = _set_preferred_text_key(texts, result_key, str(override_option.get("result_text", "")).strip_edges()) or changed
	return changed

func _set_missing_text_key(texts: Dictionary, key: String, value: String) -> bool:
	if texts.has(key):
		return false
	texts[key] = value
	return true

func _set_preferred_text_key(texts: Dictionary, key: String, value: String) -> bool:
	if value.strip_edges().is_empty():
		return false
	if texts.get(key, "") == value:
		return false
	texts[key] = value
	return true

func _build_intrusion_option_overrides(event_definition: Dictionary, intrusion_id: String, intrusion_options: Array) -> Dictionary:
	var base_options: Array[Dictionary] = Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null)
	var result: Dictionary = {}
	var event_id: String = _build_draft_event_id(event_definition)
	for option_index: int in range(min(base_options.size(), intrusion_options.size())):
		var base_option: Dictionary = base_options[option_index]
		var override_option: Dictionary = Dictionary(intrusion_options[option_index])
		var base_option_id: String = _resolved_option_id(event_definition, base_option, option_index + 1)
		var option_suffix: String = _option_text_suffix(base_option_id, event_id, option_index + 1)
		var override_entry: Dictionary = {}
		if not str(override_option.get("text", "")).strip_edges().is_empty():
			override_entry["text_id"] = "%s.%s.%s.text" % [event_id, intrusion_id, option_suffix]
		if not str(override_option.get("result_text", "")).strip_edges().is_empty():
			override_entry["result_text_id"] = "%s.%s.%s.result" % [event_id, intrusion_id, option_suffix]
		var override_effects: Array = Array(override_option.get("effects", []))
		if not override_effects.is_empty():
			override_entry["effects"] = override_effects.duplicate(true)
		if override_entry.is_empty():
			continue
		result[base_option_id] = override_entry
	return result

func _load_json_array(path: String) -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []
	var result: Array[Dictionary] = []
	for item: Variant in parsed:
		if item is Dictionary:
			result.append(Dictionary(item).duplicate(true))
	return result

func _load_json_dictionary(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return Dictionary(parsed).duplicate(true)

func _write_json_value(path: String, value: Variant) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_error("无法写入 JSON 文件：%s" % path)
		return
	file.store_string(JSON.stringify(value, "\t"))
	file.close()

func _load_csv_table(path: String) -> Dictionary:
	if path.ends_with("localization.csv"):
		return _load_localization_table(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"header": PackedStringArray(), "rows": []}
	var text: String = file.get_as_text()
	file.close()
	var lines: PackedStringArray = text.replace("\r\n", "\n").replace("\r", "\n").split("\n")
	if lines.is_empty():
		return {"header": PackedStringArray(), "rows": []}
	var header: PackedStringArray = _parse_csv_line(lines[0])
	var rows: Array[Dictionary] = []
	for index: int in range(1, lines.size()):
		var line: String = lines[index]
		if line.strip_edges().is_empty():
			continue
		var values: PackedStringArray = _parse_csv_line(line)
		var row: Dictionary = {}
		for column_index: int in range(header.size()):
			var column_name: String = header[column_index]
			row[column_name] = values[column_index] if column_index < values.size() else ""
		rows.append(row)
	return {"header": header, "rows": rows}

func _load_localization_table(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"header": PackedStringArray(["text_key", "zh_cn"]), "rows": []}
	var text: String = file.get_as_text()
	file.close()
	var header: PackedStringArray = PackedStringArray(["text_key", "zh_cn"])
	var header_line: String = "text_key,zh_cn"
	var normalized_text: String = text.replace("\r\n", "\n").replace("\r", "\n")
	var lines: PackedStringArray = normalized_text.split("\n")
	if lines.size() > 2:
		var parsed_rows: Array[Dictionary] = []
		for index: int in range(1, lines.size()):
			var line: String = lines[index]
			if line.strip_edges().is_empty():
				continue
			var values: PackedStringArray = _parse_csv_line(line)
			if values.is_empty():
				continue
			parsed_rows.append({
				"text_key": values[0] if values.size() > 0 else "",
				"zh_cn": values[1] if values.size() > 1 else ""
			})
		return {"header": header, "rows": parsed_rows}
	var body: String = normalized_text
	if body.begins_with(header_line):
		body = body.substr(header_line.length()).lstrip("\n")
	var pattern := RegEx.new()
	pattern.compile("((?:evt|opt)\\.[A-Za-z0-9._]+),(.*?)(?=(?:(?:evt|opt)\\.[A-Za-z0-9._]+,)|\\z)")
	var rows: Array[Dictionary] = []
	for match: RegExMatch in pattern.search_all(body):
		var text_key: String = match.get_string(1).strip_edges()
		var value: String = match.get_string(2).strip_edges()
		if text_key.is_empty():
			continue
		rows.append({
			"text_key": text_key,
			"zh_cn": value
		})
	return {"header": header, "rows": rows}

func _write_csv_table(path: String, table: Dictionary) -> void:
	var header: PackedStringArray = PackedStringArray(table.get("header", PackedStringArray()))
	var rows: Array = Array(table.get("rows", []))
	var lines: PackedStringArray = []
	lines.append(_compose_csv_line(header))
	for row_variant: Variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		var values: PackedStringArray = []
		for column_name: String in header:
			values.append(str(row.get(column_name, "")))
		lines.append(_compose_csv_line(values))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_error("无法写入 CSV 文件：%s" % path)
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()

func _parse_csv_line(line: String) -> PackedStringArray:
	var values: PackedStringArray = []
	var current := ""
	var in_quotes := false
	var index := 0
	while index < line.length():
		var char := line[index]
		if char == "\"":
			if in_quotes and index + 1 < line.length() and line[index + 1] == "\"":
				current += "\""
				index += 2
				continue
			in_quotes = not in_quotes
		elif char == "," and not in_quotes:
			values.append(current)
			current = ""
		else:
			current += char
		index += 1
	values.append(current)
	return values

func _compose_csv_line(values: PackedStringArray) -> String:
	var escaped: PackedStringArray = []
	for value: String in values:
		var text: String = value
		if text.contains(",") or text.contains("\"") or text.contains("\n"):
			text = "\"%s\"" % text.replace("\"", "\"\"")
		escaped.append(text)
	return ",".join(escaped)

func _replace_csv_rows_for_event(table: Dictionary, id_field: String, event_id: String, new_rows: Array[Dictionary]) -> void:
	var rows: Array = Array(table.get("rows", []))
	var filtered: Array[Dictionary] = []
	for row_variant: Variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get(id_field, "")) == event_id:
			continue
		filtered.append(row)
	filtered.append_array(new_rows)
	table["rows"] = filtered

func _find_csv_row_by_id(table: Dictionary, id_field: String, target_id: String) -> Dictionary:
	for row_variant: Variant in Array(table.get("rows", [])):
		var row: Dictionary = Dictionary(row_variant)
		if str(row.get(id_field, "")) == target_id:
			return row.duplicate(true)
	return {}

func _replace_csv_rows_for_options(table: Dictionary, option_ids: Array[String], new_rows: Array[Dictionary]) -> void:
	var option_id_set: Dictionary = {}
	for option_id: String in option_ids:
		option_id_set[option_id] = true
	var rows: Array = Array(table.get("rows", []))
	var filtered: Array[Dictionary] = []
	for row_variant: Variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		if option_id_set.has(str(row.get("option_id", ""))):
			continue
		filtered.append(row)
	filtered.append_array(new_rows)
	table["rows"] = filtered

func _upsert_localization_rows(table: Dictionary, new_rows: Array[Dictionary]) -> void:
	var rows: Array = Array(table.get("rows", []))
	var key_to_row: Dictionary = {}
	for row_variant: Variant in rows:
		var row: Dictionary = Dictionary(row_variant)
		var existing_key: String = str(row.get("text_key", "")).strip_edges()
		if existing_key.is_empty():
			continue
		key_to_row[existing_key] = row
	for row: Dictionary in new_rows:
		var new_key: String = str(row.get("text_key", "")).strip_edges()
		if new_key.is_empty():
			continue
		key_to_row[new_key] = row
	var merged_rows: Array[Dictionary] = []
	for existing_row_variant: Variant in rows:
		var existing_row: Dictionary = Dictionary(existing_row_variant)
		var text_key: String = str(existing_row.get("text_key", ""))
		if text_key.strip_edges().is_empty():
			continue
		if key_to_row.has(text_key):
			merged_rows.append(Dictionary(key_to_row[text_key]))
			key_to_row.erase(text_key)
		else:
			merged_rows.append(existing_row)
	for remaining_key: Variant in key_to_row.keys():
		merged_rows.append(Dictionary(key_to_row[remaining_key]))
	table["rows"] = merged_rows

func _build_event_csv_row(event_definition: Dictionary, existing_row: Dictionary = {}) -> Dictionary:
	var event_id: String = _build_draft_event_id(event_definition)
	var participants: Array[String] = Array(event_definition.get("participants", []), TYPE_STRING, "", null)
	var title_key: String = "evt.%s.title" % event_id
	var desc_key: String = "evt.%s.desc" % event_id
	var row: Dictionary = existing_row.duplicate(true)
	row["event_id"] = event_id
	if not row.has("story_id") or str(row.get("story_id", "")).strip_edges().is_empty():
		row["story_id"] = DEFAULT_STORY_ID
	row["event_class"] = str(event_definition.get("event_class", row.get("event_class", "conditional_story")))
	row["content_category"] = str(event_definition.get("content_category", row.get("content_category", "npc_state")))
	row["time_slot"] = _normalize_time_slot(str(event_definition.get("time_slot", row.get("time_slot", "day"))))
	row["participants"] = "|".join(participants)
	row["presentation_type"] = str(event_definition.get("presentation_type", row.get("presentation_type", "standard_event")))
	row["speaker_npc_id"] = participants[0] if not participants.is_empty() else str(row.get("speaker_npc_id", ""))
	row["slot"] = str(event_definition.get("slot", row.get("slot", "phase_entry")))
	row["location_id"] = str(event_definition.get("location_id", row.get("location_id", "")))
	row["title_key"] = title_key
	row["desc_key"] = desc_key
	if not row.has("notes") or str(row.get("notes", "")).strip_edges().is_empty():
		row["notes"] = "generated_from_markdown"
	for key: String in [
		"next_hooks", "portrait_key", "dialogue_resource_path", "dialogue_start_cue",
		"pool_id", "allowed_locations", "schedule_priority", "random_weight", "repeatable",
		"req_flags", "block_flags", "combat_enemy_id", "combat_name_key", "combat_guard",
		"combat_damage", "combat_hp", "combat_escape_target"
	]:
		if not row.has(key):
			row[key] = ""
	return row

func _build_trigger_csv_rows(event_definition: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var event_id: String = _build_draft_event_id(event_definition)
	var order: int = 1
	var time_slot: String = _normalize_time_slot(str(event_definition.get("time_slot", "")))
	var has_phase_condition: bool = false
	for condition: Dictionary in Array(event_definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null):
		if str(condition.get("type", "")) == "phase_is":
			has_phase_condition = true
			break
	if not time_slot.is_empty() and not has_phase_condition:
		rows.append({
			"event_id": event_id,
			"group_id": "main",
			"order": str(order),
			"condition_type": "phase_is",
			"scope": "",
			"key": "",
			"op_value": time_slot,
			"target_id": "",
			"field": "",
			"extra_json": ""
		})
		order += 1
	for condition: Dictionary in Array(event_definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null):
		rows.append(_build_trigger_condition_row(event_id, order, condition))
		order += 1
	return rows

func _build_trigger_condition_row(event_id: String, order: int, condition: Dictionary) -> Dictionary:
	var row := {
		"event_id": event_id,
		"group_id": "main",
		"order": str(order),
		"condition_type": str(condition.get("type", "")),
		"scope": "",
		"key": "",
		"op_value": "",
		"target_id": "",
		"field": "",
		"extra_json": ""
	}
	match str(condition.get("type", "")):
		"day_range":
			row["op_value"] = "%s-%s" % [str(condition.get("min", "")), str(condition.get("max", ""))]
		"day_gte":
			row["op_value"] = str(condition.get("value", ""))
		"flag_present", "flag_not_present":
			row["key"] = str(condition.get("key", ""))
		"current_location_is", "phase_is":
			row["op_value"] = str(condition.get("value", ""))
		"npc_tag_present":
			row["key"] = str(condition.get("key", ""))
			row["target_id"] = str(condition.get("npc_id", ""))
		_:
			row["extra_json"] = JSON.stringify(condition)
	return row

func _build_option_csv_rows(event_definition: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var option_index: int = 1
	for option_definition: Dictionary in Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null):
		var option_id: String = _resolved_option_id(event_definition, option_definition, option_index)
		rows.append({
			"option_id": option_id,
			"event_id": _build_draft_event_id(event_definition),
			"order": str(option_index),
			"text_key": "opt.%s.text" % option_id,
			"result_key": "opt.%s.result" % option_id,
			"success_result_key": "opt.%s.success" % option_id if not str(option_definition.get("success_result_text", "")).strip_edges().is_empty() else "",
			"failure_result_key": "opt.%s.failure" % option_id if not str(option_definition.get("failure_result_text", "")).strip_edges().is_empty() else "",
			"check_system": str(Dictionary(option_definition.get("check", {})).get("system", "")),
			"check_source": str(Dictionary(option_definition.get("check", {})).get("source", "")),
			"check_key": str(Dictionary(option_definition.get("check", {})).get("key", "")),
			"check_target": str(Dictionary(option_definition.get("check", {})).get("target", "")),
			"check_bonus": str(Dictionary(option_definition.get("check", {})).get("bonus", "")),
			"check_npc_id": str(Dictionary(option_definition.get("check", {})).get("npc_id", "")),
			"check_field": str(Dictionary(option_definition.get("check", {})).get("field", "")),
			"notes": "generated_from_markdown"
		})
		option_index += 1
	return rows

func _build_option_condition_csv_rows(event_definition: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var event_id: String = _build_draft_event_id(event_definition)
	var option_index: int = 1
	for option_definition: Dictionary in Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null):
		var option_id: String = _resolved_option_id(event_definition, option_definition, option_index)
		var order: int = 1
		for condition: Dictionary in Array(option_definition.get("conditions", []), TYPE_DICTIONARY, "", null):
			rows.append(_build_option_condition_row(option_id, order, condition))
			order += 1
		option_index += 1
	return rows

func _build_option_condition_row(option_id: String, order: int, condition: Dictionary) -> Dictionary:
	var row := {
		"option_id": option_id,
		"group_id": "main",
		"order": str(order),
		"condition_type": str(condition.get("type", "")),
		"scope": "",
		"key": "",
		"op_value": "",
		"target_id": "",
		"field": "",
		"extra_json": ""
	}
	match str(condition.get("type", "")):
		"resource_gte":
			row["scope"] = "player"
			row["key"] = str(condition.get("key", ""))
			row["op_value"] = str(condition.get("value", ""))
		"flag_present", "flag_not_present":
			row["key"] = str(condition.get("key", ""))
		_:
			row["extra_json"] = JSON.stringify(condition)
	return row

func _build_option_effect_csv_rows(event_definition: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var event_id: String = _build_draft_event_id(event_definition)
	var option_index: int = 1
	for option_definition: Dictionary in Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null):
		var option_id: String = _resolved_option_id(event_definition, option_definition, option_index)
		var order: int = 1
		for effect_definition: Dictionary in Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null):
			rows.append({
				"option_id": option_id,
				"order": str(order),
				"effect_type": str(effect_definition.get("type", "")),
				"scope": str(effect_definition.get("scope", "")),
				"key": str(effect_definition.get("key", "")),
				"delta": str(effect_definition.get("delta", "")),
				"target_id": str(effect_definition.get("target_id", effect_definition.get("npc_id", ""))),
				"field": str(effect_definition.get("field", "")),
				"outcome": str(effect_definition.get("outcome", "")),
				"extra_json": ""
			})
			order += 1
		option_index += 1
	return rows

func _build_localization_csv_rows(event_definition: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var event_id: String = _build_draft_event_id(event_definition)
	rows.append({"text_key": "evt.%s.title" % event_id, "zh_cn": str(event_definition.get("title", event_id))})
	rows.append({"text_key": "evt.%s.desc" % event_id, "zh_cn": str(event_definition.get("description", "")).strip_edges()})
	var option_index: int = 1
	for option_definition: Dictionary in Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null):
		var option_id: String = _resolved_option_id(event_definition, option_definition, option_index)
		rows.append({"text_key": "opt.%s.text" % option_id, "zh_cn": str(option_definition.get("text", "")).strip_edges()})
		rows.append({"text_key": "opt.%s.result" % option_id, "zh_cn": str(option_definition.get("result_text", "")).strip_edges()})
		var success_text: String = str(option_definition.get("success_result_text", "")).strip_edges()
		var failure_text: String = str(option_definition.get("failure_result_text", "")).strip_edges()
		if not success_text.is_empty():
			rows.append({"text_key": "opt.%s.success" % option_id, "zh_cn": success_text})
		if not failure_text.is_empty():
			rows.append({"text_key": "opt.%s.failure" % option_id, "zh_cn": failure_text})
		option_index += 1
	return rows

func _generated_option_ids_for_event(event_definition: Dictionary) -> Array[String]:
	var option_ids: Array[String] = []
	var option_definitions: Array[Dictionary] = Array(event_definition.get("options", []), TYPE_DICTIONARY, "", null)
	for index: int in range(option_definitions.size()):
		option_ids.append(_resolved_option_id(event_definition, option_definitions[index], index + 1))
	return option_ids

func _generated_option_id(event_id: String, order: int) -> String:
	return "%s_opt_%02d" % [event_id, order]


func _single_line_for_doc(text: String) -> String:
	var value: String = text.strip_edges()
	if value.is_empty():
		return "TODO"
	return value.replace("\r", " ").replace("\n", "\\n")

func _apply_option_metadata(option: Dictionary, metadata_text: String) -> void:
	for raw_part: String in metadata_text.split(",", false):
		var part: String = raw_part.strip_edges()
		if part.is_empty():
			continue
		if ":" not in part:
			_warn("未识别选项括号参数: %s" % part)
			continue
		var key: String = part.get_slice(":", 0).strip_edges()
		var raw_value: String = part.get_slice(":", 1).strip_edges()
		match key:
			"ID", "内部ID":
				option["id"] = raw_value
			"MP", "神识", "消耗神识":
				_apply_resource_cost(option, "spirit_sense", raw_value.to_int())
			"气血", "消耗气血":
				_apply_resource_cost(option, "blood_qi", raw_value.to_int())
			"灵石", "消耗灵石":
				_apply_resource_cost(option, "spirit_stone", raw_value.to_int())
			"判定", "判定属性":
				_set_check_stat(option, raw_value)
			"难度", "目标":
				_ensure_option_check(option)
				option["check"]["target"] = raw_value.to_int()
			"系统", "骰型":
				_ensure_option_check(option)
				option["check"]["system"] = raw_value.to_lower()
			"判定人物", "对象":
				_ensure_option_check(option)
				option["check"]["npc_id"] = _resolve_npc_id(raw_value)
			"关系":
				_ensure_option_check(option)
				option["check"]["source"] = "npc_relation"
				option["check"]["field"] = _parse_relation_field(raw_value)
			"加值":
				_ensure_option_check(option)
				option["check"]["bonus"] = raw_value.to_int()
			_:
				_warn("未识别选项元数据: %s" % key)

func _apply_mode_defaults(option: Dictionary) -> void:
	var mode_label: String = str(option.get("mode_label", ""))
	if mode_label == "魔念":
		option["check"] = {
			"system": "d100",
			"source": "stat",
			"key": "occult",
			"target": 35,
			"bonus": 0
		}
	elif mode_label == "话术":
		option["check"] = {
			"system": "d20",
			"source": "stat",
			"key": "tact",
			"target": 12,
			"bonus": 0
		}

func _finalize_option(option: Dictionary) -> void:
	var has_branch_text: bool = not str(option.get("success_result_text", "")).is_empty() or not str(option.get("failure_result_text", "")).is_empty()
	if has_branch_text and Dictionary(option.get("check", {})).is_empty():
		_warn("选项《%s》存在成功/失败分支，但尚未配置可执行判定，已回退为普通结果。" % str(option.get("text", "")))
		if str(option.get("result_text", "")).is_empty():
			if not str(option.get("success_result_text", "")).is_empty():
				option["result_text"] = option["success_result_text"]
			elif not str(option.get("failure_result_text", "")).is_empty():
				option["result_text"] = option["failure_result_text"]

func _apply_branch_metadata(option: Dictionary, branch: String, metadata_text: String, event: Dictionary) -> void:
	for raw_part: String in metadata_text.split(",", false):
		var part: String = raw_part.strip_edges()
		if part.is_empty() or ":" not in part:
			continue
		var key: String = part.get_slice(":", 0).strip_edges()
		var raw_value: String = part.get_slice(":", 1).strip_edges()
		match key:
			"破绽":
				if branch == "success":
					_ensure_option_check(option)
					var participants: Array = event.get("participants", [])
					if participants.is_empty():
						_warn("成功分支声明破绽时缺少参与 NPC：%s" % raw_value)
						continue
					option["check"]["required_npc_id"] = str(participants[0])
					option["check"]["required_npc_label"] = _find_npc_label(str(participants[0]))
					option["check"]["required_npc_tag"] = _parse_status_key(raw_value, "npc_tag")
					option["check"]["required_npc_tag_label"] = raw_value
			"难度":
				_ensure_option_check(option)
				option["check"]["target"] = raw_value.to_int()
			"加值":
				_ensure_option_check(option)
				option["check"]["bonus"] = raw_value.to_int()
			_:
				_warn("未识别分支元数据: %s" % key)

func _apply_resource_cost(option: Dictionary, resource_key: String, amount: int) -> void:
	option["conditions"].append({"type": "resource_gte", "key": resource_key, "value": amount})
	option["effects"].append({"type": "modify_resource", "scope": "player", "key": resource_key, "delta": -amount})

func _set_check_stat(option: Dictionary, label: String) -> void:
	var stat_key: String = _parse_stat_key(label)
	_ensure_option_check(option)
	option["check"]["source"] = "stat"
	option["check"]["key"] = stat_key

func _ensure_option_check(option: Dictionary) -> void:
	if Dictionary(option.get("check", {})).is_empty():
		option["check"] = {
			"system": "d100",
			"source": "stat",
			"key": "occult",
			"target": 35,
			"bonus": 0
		}

func _parse_stat_key(label: String) -> String:
	if STAT_LABELS.has(label):
		return str(STAT_LABELS[label])
	_warn("未识别判定属性: %s" % label)
	return "occult"

func _parse_relation_field(label: String) -> String:
	if RELATION_FIELD_LABELS.has(label):
		return str(RELATION_FIELD_LABELS[label])
	_warn("未识别关系字段: %s" % label)
	return "favor"

func _find_npc_label(npc_id: String) -> String:
	for label: Variant in _npc_name_map.keys():
		if str(_npc_name_map[label]) == npc_id:
			return str(label)
	return npc_id

func _with_outcome(effect: Dictionary, outcome: String) -> Dictionary:
	if outcome.is_empty() or outcome == "main":
		return effect
	var result := effect.duplicate(true)
	result["outcome"] = outcome
	return result

func _csv_escape(text: String) -> String:
	var value: String = text
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		value = value.replace("\"", "\"\"")
		return "\"%s\"" % value
	return value

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var text: String = String(value).strip_edges().to_lower()
			return text == "true" or text == "1" or text == "yes"
		_:
			return value != null

func _is_numeric_id(value: String) -> bool:
	if value.is_empty():
		return false
	var regex := RegEx.new()
	regex.compile("^[0-9]+$")
	return regex.search(value) != null
