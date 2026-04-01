@tool
extends Control

const RUNS_PATH: String = "res://content/runs/run_definitions.json"
const MANIFEST_PATH: String = "res://content/dialogue/encounters/_manifest.json"

@onready var _run_selector: OptionButton = %RunSelector
@onready var _npc_selector: OptionButton = %NpcSelector
@onready var _reload_button: Button = %ReloadButton
@onready var _event_list: ItemList = %EventList
@onready var _state_flow: VBoxContainer = %StateFlow
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _detail_label: RichTextLabel = %DetailLabel
@onready var _scaffold_event_id_edit: LineEdit = %ScaffoldEventIdEdit
@onready var _scaffold_day_spin: SpinBox = %ScaffoldDaySpin
@onready var _scaffold_title_edit: LineEdit = %ScaffoldTitleEdit
@onready var _scaffold_required_flags_edit: LineEdit = %ScaffoldRequiredFlagsEdit
@onready var _scaffold_set_flags_edit: LineEdit = %ScaffoldSetFlagsEdit
@onready var _scaffold_clear_flags_edit: LineEdit = %ScaffoldClearFlagsEdit
@onready var _scaffold_notes_edit: LineEdit = %ScaffoldNotesEdit
@onready var _generate_scaffold_button: Button = %GenerateScaffoldButton
@onready var _copy_scaffold_button: Button = %CopyScaffoldButton
@onready var _scaffold_output: TextEdit = %ScaffoldOutput
@onready var _draft_opening_edit: TextEdit = %DraftOpeningEdit
@onready var _draft_observe_edit: TextEdit = %DraftObserveEdit
@onready var _draft_option_a_text_edit: LineEdit = %DraftOptionATextEdit
@onready var _draft_option_a_result_edit: TextEdit = %DraftOptionAResultEdit
@onready var _draft_option_b_text_edit: LineEdit = %DraftOptionBTextEdit
@onready var _draft_option_b_result_edit: TextEdit = %DraftOptionBResultEdit
@onready var _draft_intrusion_greed_edit: LineEdit = %DraftIntrusionGreedEdit
@onready var _draft_intrusion_wrath_edit: LineEdit = %DraftIntrusionWrathEdit
@onready var _draft_intrusion_delusion_edit: LineEdit = %DraftIntrusionDelusionEdit

var _content_repository: ContentRepository
var _runs: Array[Dictionary] = []
var _selected_run_id: String = ""
var _selected_story_id: String = ""
var _selected_npc_id: String = ""
var _event_records: Array[Dictionary] = []


func _ready() -> void:
	_reload_button.pressed.connect(_reload_all)
	_run_selector.item_selected.connect(_on_run_selected)
	_npc_selector.item_selected.connect(_on_npc_selected)
	_event_list.item_selected.connect(_on_event_selected)
	_generate_scaffold_button.pressed.connect(_generate_scaffold_output)
	_copy_scaffold_button.pressed.connect(_copy_scaffold_output)
	_bind_draft_refresh_signals()
	_reload_all()


func _reload_all() -> void:
	_content_repository = ContentRepository.new()
	_runs = _load_runs()
	_rebuild_run_selector()
	_rebuild_npc_selector()
	_rebuild_view()


func _load_runs() -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(RUNS_PATH, FileAccess.READ)
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


func _rebuild_run_selector() -> void:
	_run_selector.clear()
	for run_definition: Dictionary in _runs:
		var run_id: String = str(run_definition.get("id", ""))
		var display_name: String = str(run_definition.get("display_name", run_id))
		_run_selector.add_item(display_name)
		_run_selector.set_item_metadata(_run_selector.item_count - 1, run_id)

	if _runs.is_empty():
		_selected_run_id = ""
		_selected_story_id = ""
		return

	if _selected_run_id.is_empty():
		_selected_run_id = str(_runs[0].get("id", ""))

	for index: int in range(_run_selector.item_count):
		if str(_run_selector.get_item_metadata(index)) != _selected_run_id:
			continue
		_run_selector.select(index)
		break

	var selected_run: Dictionary = _find_run_definition(_selected_run_id)
	_selected_story_id = str(selected_run.get("story_id", ""))


func _rebuild_npc_selector() -> void:
	_npc_selector.clear()
	var npcs: Array[Dictionary] = _content_repository.get_npc_definitions(_selected_story_id)
	npcs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", a.get("id", ""))) < str(b.get("display_name", b.get("id", "")))
	)
	for npc_definition: Dictionary in npcs:
		var npc_id: String = str(npc_definition.get("id", ""))
		_npc_selector.add_item(str(npc_definition.get("display_name", npc_id)))
		_npc_selector.set_item_metadata(_npc_selector.item_count - 1, npc_id)

	if _npc_selector.item_count == 0:
		_selected_npc_id = ""
		return

	if _selected_npc_id.is_empty():
		_selected_npc_id = str(_npc_selector.get_item_metadata(0))

	for index: int in range(_npc_selector.item_count):
		if str(_npc_selector.get_item_metadata(index)) != _selected_npc_id:
			continue
		_npc_selector.select(index)
		return

	_npc_selector.select(0)
	_selected_npc_id = str(_npc_selector.get_item_metadata(0))


func _on_run_selected(index: int) -> void:
	if index < 0 or index >= _run_selector.item_count:
		return
	_selected_run_id = str(_run_selector.get_item_metadata(index))
	var selected_run: Dictionary = _find_run_definition(_selected_run_id)
	_selected_story_id = str(selected_run.get("story_id", ""))
	_selected_npc_id = ""
	_rebuild_npc_selector()
	_rebuild_view()


func _on_npc_selected(index: int) -> void:
	if index < 0 or index >= _npc_selector.item_count:
		return
	_selected_npc_id = str(_npc_selector.get_item_metadata(index))
	_rebuild_view()


func _rebuild_view() -> void:
	_event_records = _build_event_records()
	_rebuild_event_list()
	_rebuild_state_flow()
	_rebuild_summary()
	_generate_scaffold_output()
	if _event_records.is_empty():
		_detail_label.text = "[b]No dialogue events found.[/b]"
		return
	_event_list.select(0)
	_show_event_detail(0)


func _build_event_records() -> Array[Dictionary]:
	var event_ids: Array[String] = _collect_dialogue_event_ids_for_selected_npc()
	var records: Array[Dictionary] = []
	for event_id: String in event_ids:
		var story_event: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
		if story_event.is_empty():
			continue
		var encounter: Dictionary = _content_repository.get_dialogue_encounter_definition(event_id)
		var required_flags: Array[String] = _extract_required_flags(story_event)
		var set_flags: Array[String] = []
		var clear_flags: Array[String] = []
		var option_summaries: Array[String] = []

		for option_definition: Dictionary in Array(story_event.get("options", []), TYPE_DICTIONARY, "", null):
			var option_id: String = str(option_definition.get("id", ""))
			option_summaries.append("base :: %s" % option_id)
			_collect_flag_effects(Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null), set_flags, clear_flags)

		for intrusion_definition: Dictionary in Array(encounter.get("intrusions", []), TYPE_DICTIONARY, "", null):
			var intrusion_id: String = str(intrusion_definition.get("id", ""))
			var option_overrides: Dictionary = Dictionary(intrusion_definition.get("option_overrides", {}))
			for option_id: Variant in option_overrides.keys():
				option_summaries.append("%s :: %s" % [intrusion_id, str(option_id)])
				var override_definition: Dictionary = Dictionary(option_overrides[option_id])
				_collect_flag_effects(Array(override_definition.get("effects", []), TYPE_DICTIONARY, "", null), set_flags, clear_flags)
			var fallback_definition: Dictionary = Dictionary(intrusion_definition.get("fallback_option_override", {}))
			if not fallback_definition.is_empty():
				option_summaries.append("%s :: fallback" % intrusion_id)
				_collect_flag_effects(Array(fallback_definition.get("effects", []), TYPE_DICTIONARY, "", null), set_flags, clear_flags)

		records.append({
			"event_id": event_id,
			"title": str(story_event.get("title", event_id)),
			"time_slot": str(story_event.get("time_slot", "")),
			"required_flags": _unique_sorted(required_flags),
			"set_flags": _unique_sorted(set_flags),
			"clear_flags": _unique_sorted(clear_flags),
			"option_summaries": option_summaries,
			"story_event": story_event,
			"encounter": encounter
		})

	records.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_day: int = _extract_day_hint(Dictionary(a.get("story_event", {})))
		var b_day: int = _extract_day_hint(Dictionary(b.get("story_event", {})))
		if a_day != b_day:
			return a_day < b_day
		return str(a.get("event_id", "")) < str(b.get("event_id", ""))
	)
	return records


func _collect_dialogue_event_ids_for_selected_npc() -> Array[String]:
	if _selected_npc_id.is_empty():
		return []
	var result: Array[String] = []
	for event_id: String in _content_repository.get_npc_state_event_ids(_selected_npc_id):
		var definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
		if str(definition.get("presentation_type", "")) != "dialogue_event":
			continue
		if not result.has(event_id):
			result.append(event_id)

	for interaction_definition: Dictionary in _content_repository.get_npc_interaction_definitions(_selected_story_id):
		if str(interaction_definition.get("npc_id", "")) != _selected_npc_id:
			continue
		var dialogue_event_id: String = str(interaction_definition.get("dialogue_event_id", ""))
		if dialogue_event_id.is_empty():
			continue
		if not result.has(dialogue_event_id):
			result.append(dialogue_event_id)

	for definition: Dictionary in _content_repository.get_story_event_definitions(_selected_run_id):
		if str(definition.get("presentation_type", "")) != "dialogue_event":
			continue
		if str(definition.get("speaker_npc_id", "")) != _selected_npc_id:
			continue
		var event_id: String = str(definition.get("id", ""))
		if not result.has(event_id):
			result.append(event_id)
	return result


func _extract_required_flags(story_event: Dictionary) -> Array[String]:
	var flags: Array[String] = Array(story_event.get("req_flags", []), TYPE_STRING, "", null)
	_extract_required_flags_from_conditions(Array(story_event.get("trigger_conditions", []), TYPE_DICTIONARY, "", null), flags)
	return flags


func _extract_required_flags_from_conditions(conditions: Array[Dictionary], output: Array[String]) -> void:
	for condition: Dictionary in conditions:
		var condition_type: String = str(condition.get("type", ""))
		if condition_type == "flag_present":
			var flag_key: String = str(condition.get("key", ""))
			if not flag_key.is_empty() and not output.has(flag_key):
				output.append(flag_key)
			continue
		if condition_type == "all_of" or condition_type == "any_of":
			_extract_required_flags_from_conditions(Array(condition.get("conditions", []), TYPE_DICTIONARY, "", null), output)


func _collect_flag_effects(effects: Array[Dictionary], set_flags: Array[String], clear_flags: Array[String]) -> void:
	for effect_definition: Dictionary in effects:
		var effect_type: String = str(effect_definition.get("type", ""))
		var flag_key: String = str(effect_definition.get("key", ""))
		if flag_key.is_empty():
			continue
		if effect_type == "set_flag" and not set_flags.has(flag_key):
			set_flags.append(flag_key)
		elif effect_type == "clear_flag" and not clear_flags.has(flag_key):
			clear_flags.append(flag_key)


func _rebuild_event_list() -> void:
	_event_list.clear()
	for record: Dictionary in _event_records:
		var day_hint: int = _extract_day_hint(Dictionary(record.get("story_event", {})))
		_event_list.add_item("Day %d / %s" % [day_hint, str(record.get("title", record.get("event_id", "")))])


func _rebuild_state_flow() -> void:
	for child: Node in _state_flow.get_children():
		child.queue_free()

	if _event_records.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No dialogue state records."
		_state_flow.add_child(empty_label)
		return

	for record: Dictionary in _event_records:
		_state_flow.add_child(_build_event_card(record))


func _build_event_card(record: Dictionary) -> Control:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style())

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 6)
	margin.add_child(content)

	var header: Label = Label.new()
	header.text = "Day %d / %s" % [_extract_day_hint(Dictionary(record.get("story_event", {}))), str(record.get("title", record.get("event_id", "")))]
	header.add_theme_font_size_override("font_size", 18)
	content.add_child(header)

	var meta: Label = Label.new()
	meta.text = "event_id=%s | phase=%s" % [str(record.get("event_id", "")), str(record.get("time_slot", ""))]
	meta.add_theme_font_size_override("font_size", 12)
	content.add_child(meta)

	var required_flags: Array[String] = Array(record.get("required_flags", []), TYPE_STRING, "", null)
	var set_flags: Array[String] = Array(record.get("set_flags", []), TYPE_STRING, "", null)
	var clear_flags: Array[String] = Array(record.get("clear_flags", []), TYPE_STRING, "", null)

	content.add_child(_build_tag_row("Requires", required_flags))
	content.add_child(_build_tag_row("Sets", set_flags))
	content.add_child(_build_tag_row("Clears", clear_flags))

	var options_label: Label = Label.new()
	options_label.text = "Overrides: %s" % ", ".join(Array(record.get("option_summaries", []), TYPE_STRING, "", null))
	options_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(options_label)
	return panel


func _build_tag_row(title: String, values: Array[String]) -> Control:
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)

	var title_label: Label = Label.new()
	title_label.text = "%s:" % title
	title_label.add_theme_font_size_override("font_size", 12)
	box.add_child(title_label)

	var value_label: Label = Label.new()
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.text = "-" if values.is_empty() else ", ".join(values)
	box.add_child(value_label)
	return box


func _rebuild_summary() -> void:
	if _selected_npc_id.is_empty():
		_summary_label.text = "[b]No NPC selected.[/b]"
		return
	var npc_definition: Dictionary = _content_repository.get_npc_definition(_selected_npc_id)
	var logic_path: String = _resolve_manifest_path("%s_logic.json" % _selected_npc_id)
	var text_path: String = _resolve_manifest_path("%s_texts.json" % _selected_npc_id)
	var lines: Array[String] = [
		"[b]%s[/b]" % str(npc_definition.get("display_name", _selected_npc_id)),
		"dialogue events: %d" % _event_records.size(),
		"",
		"[b]Core files[/b]",
		"- story events: [code]content/story/act1/csv/events.csv[/code]",
		"- event triggers: [code]content/story/act1/csv/event_triggers.csv[/code]",
		"- event options: [code]content/story/act1/csv/event_options.csv[/code]",
		"- option effects: [code]content/story/act1/csv/option_effects.csv[/code]",
		"- localization: [code]content/story/act1/csv/localization.csv[/code]",
		"- logic: [code]%s[/code]" % logic_path,
		"- texts: [code]%s[/code]" % text_path,
		"- npc interactions: [code]content/npcs/npc_interactions.json[/code]",
		"- npc state ids: [code]content/npcs/npc_definitions.json[/code]",
		"",
		"[b]What this view shows[/b]",
		"- which flags unlock each dialogue event",
		"- which flags each event sets or clears",
		"- which intrusion overrides are already consuming option ids",
		"- how one writer draft fans out into csv rows, logic ids, and text ids"
	]
	_summary_label.text = "\n".join(lines)


func _on_event_selected(index: int) -> void:
	_show_event_detail(index)


func _show_event_detail(index: int) -> void:
	if index < 0 or index >= _event_records.size():
		return
	var record: Dictionary = _event_records[index]
	var story_event: Dictionary = Dictionary(record.get("story_event", {}))
	var encounter: Dictionary = Dictionary(record.get("encounter", {}))
	var detail_lines: Array[String] = [
		"[b]%s[/b]" % str(record.get("title", record.get("event_id", ""))),
		"event_id: [code]%s[/code]" % str(record.get("event_id", "")),
		"time_slot: [code]%s[/code]" % str(story_event.get("time_slot", "")),
		"phase conditions: [code]%s[/code]" % _summarize_condition_types(Array(story_event.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)),
		"",
		"[b]Required flags[/b]",
		"- %s" % _join_or_dash(Array(record.get("required_flags", []), TYPE_STRING, "", null)),
		"",
		"[b]Set flags[/b]",
		"- %s" % _join_or_dash(Array(record.get("set_flags", []), TYPE_STRING, "", null)),
		"",
		"[b]Clear flags[/b]",
		"- %s" % _join_or_dash(Array(record.get("clear_flags", []), TYPE_STRING, "", null)),
		"",
		"[b]Encounter structure[/b]",
		"- opening text: %s" % _bool_text(not str(encounter.get("opening_text", "")).is_empty()),
		"- observation text: %s" % _bool_text(not str(encounter.get("observation_text", "")).is_empty()),
		"- intrusions: %s" % _join_intrusion_ids(Array(encounter.get("intrusions", []), TYPE_DICTIONARY, "", null)),
		"",
		"[b]Writer-first workflow[/b]",
		"1. write opening / observe / two base talk choices",
		"2. jot the greed / wrath / delusion hook in plain language",
		"3. let the editor generate text ids, logic stub, and csv draft",
		"4. replace generated TODO effects with the real state changes",
		"5. wire the event into [code]npc_interactions.json[/code] and usually [code]npc_definitions.json[/code]"
	]
	_detail_label.text = "\n".join(detail_lines)
	_prefill_scaffold_from_record(record)


func _resolve_manifest_path(file_name: String) -> String:
	var file: FileAccess = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return _default_manifest_fallback(file_name)
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return _default_manifest_fallback(file_name)
	for entry: Variant in parsed:
		if not (entry is Dictionary):
			continue
		var dictionary_entry: Dictionary = entry
		for key: String in ["logic_path", "text_path"]:
			var path: String = str(dictionary_entry.get(key, ""))
			if path.ends_with(file_name):
				return path.trim_prefix("res://")
	return _default_manifest_fallback(file_name)


func _default_manifest_fallback(file_name: String) -> String:
	if file_name.ends_with("_texts.json"):
		return "content/dialogue/texts/%s" % file_name
	return "content/dialogue/encounters/%s" % file_name


func _find_run_definition(run_id: String) -> Dictionary:
	for run_definition: Dictionary in _runs:
		if str(run_definition.get("id", "")) == run_id:
			return run_definition
	return {}


func _extract_day_hint(story_event: Dictionary) -> int:
	for condition: Dictionary in Array(story_event.get("trigger_conditions", []), TYPE_DICTIONARY, "", null):
		var condition_type: String = str(condition.get("type", ""))
		if condition_type == "day_range":
			return int(condition.get("min", 1))
		if condition_type == "day_gte":
			return int(condition.get("value", 1))
	return 1


func _summarize_condition_types(conditions: Array[Dictionary]) -> String:
	var labels: Array[String] = []
	for condition: Dictionary in conditions:
		var condition_type: String = str(condition.get("type", ""))
		if condition_type == "all_of" or condition_type == "any_of":
			labels.append("%s(%s)" % [condition_type, _summarize_condition_types(Array(condition.get("conditions", []), TYPE_DICTIONARY, "", null))])
		else:
			labels.append(condition_type)
	return ", ".join(labels)


func _join_intrusion_ids(intrusions: Array[Dictionary]) -> String:
	var ids: Array[String] = []
	for intrusion: Dictionary in intrusions:
		ids.append(str(intrusion.get("id", "")))
	return _join_or_dash(ids)


func _join_or_dash(values: Array[String]) -> String:
	return "-" if values.is_empty() else ", ".join(values)


func _bool_text(value: bool) -> String:
	return "yes" if value else "no"


func _prefill_scaffold_from_record(record: Dictionary) -> void:
	var event_id: String = str(record.get("event_id", ""))
	if _scaffold_event_id_edit.text.strip_edges().is_empty() or _scaffold_event_id_edit.text.begins_with("dlg_"):
		_scaffold_event_id_edit.text = "%s_followup" % event_id
	var next_day: int = _extract_day_hint(Dictionary(record.get("story_event", {}))) + 1
	if int(_scaffold_day_spin.value) <= 1:
		_scaffold_day_spin.value = next_day
	var current_title: String = str(record.get("title", event_id))
	if _scaffold_title_edit.text.strip_edges().is_empty():
		_scaffold_title_edit.text = "%s 后续" % current_title
	if _scaffold_required_flags_edit.text.strip_edges().is_empty():
		_scaffold_required_flags_edit.text = "|".join(Array(record.get("set_flags", []), TYPE_STRING, "", null))
	if _draft_opening_edit.text.strip_edges().is_empty():
		_draft_opening_edit.text = "在这里写下一段剧情的开场。先按写作直觉描述人物、时机和氛围。"
	if _draft_observe_edit.text.strip_edges().is_empty():
		_draft_observe_edit.text = "在这里写观察阶段看到的情绪、细节和漏洞。"
	if _draft_option_a_text_edit.text.strip_edges().is_empty():
		_draft_option_a_text_edit.text = "先稳住她，继续听下去"
	if _draft_option_a_result_edit.text.strip_edges().is_empty():
		_draft_option_a_result_edit.text = "这条路线的基础结果写在这里。"
	if _draft_option_b_text_edit.text.strip_edges().is_empty():
		_draft_option_b_text_edit.text = "逼她现在就表态"
	if _draft_option_b_result_edit.text.strip_edges().is_empty():
		_draft_option_b_result_edit.text = "另一条路线的基础结果写在这里。"
	_generate_scaffold_output()


func _generate_scaffold_output() -> void:
	var event_id: String = _scaffold_event_id_edit.text.strip_edges()
	if event_id.is_empty():
		_scaffold_output.text = "Fill New Event ID first."
		return
	if _content_repository != null:
		_scaffold_output.text = "\n".join(_build_writer_draft_lines(event_id))
		return

	var title_key: String = "evt.%s.title" % event_id
	var desc_key: String = "evt.%s.desc" % event_id
	var option_a_id: String = "%s_option_a" % event_id
	var option_b_id: String = "%s_option_b" % event_id
	var option_a_text_key: String = "opt.%s.text" % option_a_id
	var option_a_result_key: String = "opt.%s.result" % option_a_id
	var option_b_text_key: String = "opt.%s.text" % option_b_id
	var option_b_result_key: String = "opt.%s.result" % option_b_id

	var required_flags: Array[String] = _split_pipe_values(_scaffold_required_flags_edit.text)
	var set_flags: Array[String] = _split_pipe_values(_scaffold_set_flags_edit.text)
	var clear_flags: Array[String] = _split_pipe_values(_scaffold_clear_flags_edit.text)
	var note_text: String = _scaffold_notes_edit.text.strip_edges()
	var opening_text: String = _single_line(_draft_opening_edit.text)
	var observe_text: String = _single_line(_draft_observe_edit.text)
	var option_a_text: String = _draft_option_a_text_edit.text.strip_edges()
	var option_a_result: String = _single_line(_draft_option_a_result_edit.text)
	var option_b_text: String = _draft_option_b_text_edit.text.strip_edges()
	var option_b_result: String = _single_line(_draft_option_b_result_edit.text)
	var greed_note: String = _draft_intrusion_greed_edit.text.strip_edges()
	var wrath_note: String = _draft_intrusion_wrath_edit.text.strip_edges()
	var delusion_note: String = _draft_intrusion_delusion_edit.text.strip_edges()
	var scene_key: String = event_id.trim_prefix("dlg_")

	var event_row: String = ",".join([
		event_id,
		_selected_story_id,
		"conditional_story",
		"npc_state",
		"afternoon",
		"player|%s" % _selected_npc_id,
		"",
		"dialogue_event",
		_selected_npc_id,
		"%s_half" % _selected_npc_id,
		"res://content/dialogue/act1/%s.dialogue" % _selected_npc_id,
		"",
		"phase_entry",
		"",
		str(_content_repository.get_npc_definition(_selected_npc_id).get("default_location_id", "")),
		"",
		"300",
		"1",
		"false",
		title_key,
		desc_key,
		"generated_by_dialogue_state_editor",
		"|".join(required_flags),
		"",
		"",
		"",
		"",
		"",
		"",
		""
	])

	var trigger_rows: Array[String] = [
		"%s,main,1,phase_is,,,day,,," % event_id,
		"%s,main,2,day_gte,,,%d,,," % [event_id, int(_scaffold_day_spin.value)]
	]

	var option_rows: Array[String] = [
		"%s,%s,1,%s,%s," % [option_a_id, event_id, option_a_text_key, option_a_result_key],
		"%s,%s,2,%s,%s," % [option_b_id, event_id, option_b_text_key, option_b_result_key]
	]

	var effect_rows: Array[String] = []
	var effect_order: int = 1
	for flag_key: String in clear_flags:
		effect_rows.append("%s,%d,clear_flag,,%s,,,," % [option_a_id, effect_order, flag_key])
		effect_order += 1
	for flag_key: String in set_flags:
		effect_rows.append("%s,%d,set_flag,,%s,,,," % [option_a_id, effect_order, flag_key])
		effect_order += 1
	if effect_rows.is_empty():
		effect_rows.append("%s,1,modify_resource,player,clue_fragments,1,,," % option_a_id)
	effect_rows.append("%s,1,modify_npc_relation,,,1,%s,favor," % [option_b_id, _selected_npc_id])

	var logic_path: String = _resolve_manifest_path("%s_logic.json" % _selected_npc_id)
	var text_path: String = _resolve_manifest_path("%s_texts.json" % _selected_npc_id)

	var lines: Array[String] = [
		"# events.csv",
		event_row,
		"",
		"# event_triggers.csv",
	]
	lines.append_array(trigger_rows)
	lines.append("")
	lines.append("# event_options.csv")
	lines.append_array(option_rows)
	lines.append("")
	lines.append("# option_effects.csv")
	lines.append_array(effect_rows)
	lines.append("")
	lines.append("# localization.csv")
	lines.append("%s,%s" % [title_key, _csv_escape(_scaffold_title_edit.text.strip_edges())])
	lines.append("%s,%s" % [desc_key, _csv_escape(note_text if not note_text.is_empty() else "Add follow-up dialogue body here.")])
	lines.append("%s,%s" % [option_a_text_key, _csv_escape(option_a_text if not option_a_text.is_empty() else "先稳住她")])
	lines.append("%s,%s" % [option_a_result_key, _csv_escape(option_a_result if not option_a_result.is_empty() else "她继续压低声音，把下一层真相慢慢递给你。")])
	lines.append("%s,%s" % [option_b_text_key, _csv_escape(option_b_text if not option_b_text.is_empty() else "逼她马上表态")])
	lines.append("%s,%s" % [option_b_result_key, _csv_escape(option_b_result if not option_b_result.is_empty() else "她被你逼得不得不选边，但这份站队未必牢靠。")])
	lines.append("")
	lines.append("# %s" % text_path)
	lines.append("%s.opening = %s" % [scene_key, opening_text])
	lines.append("%s.observe = %s" % [scene_key, observe_text])
	lines.append("%s.greed.note = %s" % [scene_key, greed_note if not greed_note.is_empty() else "TODO: write greed route note"])
	lines.append("%s.wrath.note = %s" % [scene_key, wrath_note if not wrath_note.is_empty() else "TODO: write wrath route note"])
	lines.append("%s.delusion.note = %s" % [scene_key, delusion_note if not delusion_note.is_empty() else "TODO: write delusion route note"])
	lines.append("")
	lines.append("# %s" % logic_path)
	lines.append("{")
	lines.append("  \"event_id\": \"%s\"," % event_id)
	lines.append("  \"opening_text_id\": \"%s.opening\"," % scene_key)
	lines.append("  \"observation_text_id\": \"%s.observe\"," % scene_key)
	lines.append("  \"intrusions\": [")
	lines.append("    { \"id\": \"greed\", \"label_id\": \"%s.greed.label\", \"description_id\": \"%s.greed.desc\" }," % [scene_key, scene_key])
	lines.append("    { \"id\": \"wrath\", \"label_id\": \"%s.wrath.label\", \"description_id\": \"%s.wrath.desc\" }," % [scene_key, scene_key])
	lines.append("    { \"id\": \"delusion\", \"label_id\": \"%s.delusion.label\", \"description_id\": \"%s.delusion.desc\" }" % [scene_key, scene_key])
	lines.append("  ]")
	lines.append("}")
	lines.append("")
	lines.append("# wiring reminder")
	lines.append("- link event in content/npcs/npc_interactions.json")
	lines.append("- usually append event id into content/npcs/npc_definitions.json -> state_event_ids")
	lines.append("- then replace the TODO intrusion stubs with real option_overrides / effects")

	_scaffold_output.text = "\n".join(lines)


func _copy_scaffold_output() -> void:
	DisplayServer.clipboard_set(_scaffold_output.text)


func _bind_draft_refresh_signals() -> void:
	var line_edits: Array[LineEdit] = [
		_scaffold_event_id_edit,
		_scaffold_title_edit,
		_scaffold_required_flags_edit,
		_scaffold_set_flags_edit,
		_scaffold_clear_flags_edit,
		_scaffold_notes_edit,
		_draft_option_a_text_edit,
		_draft_option_b_text_edit,
		_draft_intrusion_greed_edit,
		_draft_intrusion_wrath_edit,
		_draft_intrusion_delusion_edit
	]
	for edit: LineEdit in line_edits:
		edit.text_changed.connect(_on_draft_field_changed)

	var text_edits: Array[TextEdit] = [
		_draft_opening_edit,
		_draft_observe_edit,
		_draft_option_a_result_edit,
		_draft_option_b_result_edit
	]
	for edit: TextEdit in text_edits:
		edit.text_changed.connect(_on_draft_field_changed)

	_scaffold_day_spin.value_changed.connect(_on_draft_value_changed)


func _on_draft_field_changed(_value: Variant = null) -> void:
	_generate_scaffold_output()


func _on_draft_value_changed(_value: float) -> void:
	_generate_scaffold_output()


func _build_writer_draft_lines(event_id: String) -> Array[String]:
	var title_key: String = "evt.%s.title" % event_id
	var desc_key: String = "evt.%s.desc" % event_id
	var option_a_id: String = "%s_option_a" % event_id
	var option_b_id: String = "%s_option_b" % event_id
	var option_a_text_key: String = "opt.%s.text" % option_a_id
	var option_a_result_key: String = "opt.%s.result" % option_a_id
	var option_b_text_key: String = "opt.%s.text" % option_b_id
	var option_b_result_key: String = "opt.%s.result" % option_b_id
	var required_flags: Array[String] = _split_pipe_values(_scaffold_required_flags_edit.text)
	var set_flags: Array[String] = _split_pipe_values(_scaffold_set_flags_edit.text)
	var clear_flags: Array[String] = _split_pipe_values(_scaffold_clear_flags_edit.text)
	var note_text: String = _scaffold_notes_edit.text.strip_edges()
	var opening_text: String = _single_line(_draft_opening_edit.text)
	var observe_text: String = _single_line(_draft_observe_edit.text)
	var option_a_text: String = _draft_option_a_text_edit.text.strip_edges()
	var option_a_result: String = _single_line(_draft_option_a_result_edit.text)
	var option_b_text: String = _draft_option_b_text_edit.text.strip_edges()
	var option_b_result: String = _single_line(_draft_option_b_result_edit.text)
	var greed_note: String = _draft_intrusion_greed_edit.text.strip_edges()
	var wrath_note: String = _draft_intrusion_wrath_edit.text.strip_edges()
	var delusion_note: String = _draft_intrusion_delusion_edit.text.strip_edges()
	var scene_key: String = event_id.trim_prefix("dlg_")
	var npc_definition: Dictionary = _content_repository.get_npc_definition(_selected_npc_id)
	var npc_display_name: String = str(npc_definition.get("display_name", _selected_npc_id))
	var logic_path: String = _resolve_manifest_path("%s_logic.json" % _selected_npc_id)
	var text_path: String = _resolve_manifest_path("%s_texts.json" % _selected_npc_id)
	var draft_title: String = _scaffold_title_edit.text.strip_edges()

	var event_row: String = ",".join([
		event_id,
		_selected_story_id,
		"conditional_story",
		"npc_state",
		"afternoon",
		"player|%s" % _selected_npc_id,
		"",
		"dialogue_event",
		_selected_npc_id,
		"%s_half" % _selected_npc_id,
		"res://content/dialogue/act1/%s.dialogue" % _selected_npc_id,
		"",
		"phase_entry",
		"",
		str(npc_definition.get("default_location_id", "")),
		"",
		"300",
		"1",
		"false",
		title_key,
		desc_key,
		"generated_by_dialogue_state_editor",
		"|".join(required_flags),
		"",
		"",
		"",
		"",
		"",
		"",
		""
	])

	var trigger_rows: Array[String] = [
		"%s,main,1,phase_is,,,day,,," % event_id,
		"%s,main,2,day_gte,,,%d,,," % [event_id, int(_scaffold_day_spin.value)]
	]
	var option_rows: Array[String] = [
		"%s,%s,1,%s,%s," % [option_a_id, event_id, option_a_text_key, option_a_result_key],
		"%s,%s,2,%s,%s," % [option_b_id, event_id, option_b_text_key, option_b_result_key]
	]

	var effect_rows: Array[String] = []
	var effect_order: int = 1
	for flag_key: String in clear_flags:
		effect_rows.append("%s,%d,clear_flag,,%s,,,," % [option_a_id, effect_order, flag_key])
		effect_order += 1
	for flag_key: String in set_flags:
		effect_rows.append("%s,%d,set_flag,,%s,,,," % [option_a_id, effect_order, flag_key])
		effect_order += 1
	if effect_rows.is_empty():
		effect_rows.append("%s,1,modify_resource,player,clue_fragments,1,,," % option_a_id)
	effect_rows.append("%s,1,modify_npc_relation,,,1,%s,favor," % [option_b_id, _selected_npc_id])

	var lines: Array[String] = [
		"# Writer Draft",
		"NPC: %s" % npc_display_name,
		"Event ID: %s" % event_id,
		"Unlock Day: %d" % int(_scaffold_day_spin.value),
		"Required Flags: %s" % _join_or_dash(required_flags),
		"Set Flags: %s" % _join_or_dash(set_flags),
		"Clear Flags: %s" % _join_or_dash(clear_flags),
		"Design Note: %s" % (note_text if not note_text.is_empty() else "-"),
		"",
		"# Author Scene",
		"title = %s" % draft_title,
		"opening = %s" % opening_text,
		"observe = %s" % observe_text,
		"talk.option_a.text = %s" % option_a_text,
		"talk.option_a.result = %s" % option_a_result,
		"talk.option_b.text = %s" % option_b_text,
		"talk.option_b.result = %s" % option_b_result,
		"intrusion.greed = %s" % (greed_note if not greed_note.is_empty() else "TODO"),
		"intrusion.wrath = %s" % (wrath_note if not wrath_note.is_empty() else "TODO"),
		"intrusion.delusion = %s" % (delusion_note if not delusion_note.is_empty() else "TODO"),
		"",
		"# Text File Draft",
		"# %s" % text_path,
		"{",
		"  \"%s.opening\": \"%s\"," % [scene_key, _json_escape_multiline(_draft_opening_edit.text)],
		"  \"%s.observe\": \"%s\"," % [scene_key, _json_escape_multiline(_draft_observe_edit.text)],
		"  \"%s.greed.desc\": \"%s\"," % [scene_key, _json_escape_multiline(greed_note if not greed_note.is_empty() else "TODO: write greed route note")],
		"  \"%s.wrath.desc\": \"%s\"," % [scene_key, _json_escape_multiline(wrath_note if not wrath_note.is_empty() else "TODO: write wrath route note")],
		"  \"%s.delusion.desc\": \"%s\"," % [scene_key, _json_escape_multiline(delusion_note if not delusion_note.is_empty() else "TODO: write delusion route note")],
		"  \"%s.base.option_a.text\": \"%s\"," % [scene_key, _json_escape_multiline(option_a_text)],
		"  \"%s.base.option_a.result\": \"%s\"," % [scene_key, _json_escape_multiline(_draft_option_a_result_edit.text)],
		"  \"%s.base.option_b.text\": \"%s\"," % [scene_key, _json_escape_multiline(option_b_text)],
		"  \"%s.base.option_b.result\": \"%s\"" % [scene_key, _json_escape_multiline(_draft_option_b_result_edit.text)],
		"}",
		"",
		"# Logic File Draft",
		"# %s" % logic_path,
		"{",
		"  \"event_id\": \"%s\"," % event_id,
		"  \"opening_text_id\": \"%s.opening\"," % scene_key,
		"  \"observation_text_id\": \"%s.observe\"," % scene_key,
		"  \"intrusions\": [",
		"    { \"id\": \"greed\", \"label_id\": \"%s.greed.label\", \"description_id\": \"%s.greed.desc\" }," % [scene_key, scene_key],
		"    { \"id\": \"wrath\", \"label_id\": \"%s.wrath.label\", \"description_id\": \"%s.wrath.desc\" }," % [scene_key, scene_key],
		"    { \"id\": \"delusion\", \"label_id\": \"%s.delusion.label\", \"description_id\": \"%s.delusion.desc\" }" % [scene_key, scene_key],
		"  ],",
		"  \"notes\": \"replace base option text/result ids and add real option_overrides/effects for the intrusions that should branch\"",
		"}",
		"",
		"# CSV Draft",
		"# events.csv",
		event_row,
		"",
		"# event_triggers.csv",
	]
	lines.append_array(trigger_rows)
	lines.append("")
	lines.append("# event_options.csv")
	lines.append_array(option_rows)
	lines.append("")
	lines.append("# option_effects.csv")
	lines.append_array(effect_rows)
	lines.append("")
	lines.append("# localization.csv")
	lines.append("%s,%s" % [title_key, _csv_escape(draft_title)])
	lines.append("%s,%s" % [desc_key, _csv_escape(note_text if not note_text.is_empty() else "Add follow-up dialogue body here.")])
	lines.append("%s,%s" % [option_a_text_key, _csv_escape(option_a_text if not option_a_text.is_empty() else "TODO")])
	lines.append("%s,%s" % [option_a_result_key, _csv_escape(option_a_result if not option_a_result.is_empty() else "TODO")])
	lines.append("%s,%s" % [option_b_text_key, _csv_escape(option_b_text if not option_b_text.is_empty() else "TODO")])
	lines.append("%s,%s" % [option_b_result_key, _csv_escape(option_b_result if not option_b_result.is_empty() else "TODO")])
	lines.append("")
	lines.append("# Wiring Reminder")
	lines.append("- link event in content/npcs/npc_interactions.json")
	lines.append("- usually append event id into content/npcs/npc_definitions.json -> state_event_ids")
	lines.append("- then replace the TODO intrusion stubs with real option_overrides / effects")
	return lines


func _unique_sorted(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		if value.is_empty() or result.has(value):
			continue
		result.append(value)
	result.sort()
	return result


func _split_pipe_values(text: String) -> Array[String]:
	var result: Array[String] = []
	for raw_value: String in text.split("|", false):
		var value: String = raw_value.strip_edges()
		if value.is_empty() or result.has(value):
			continue
		result.append(value)
	return result


func _csv_escape(text: String) -> String:
	var value: String = text
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		value = value.replace("\"", "\"\"")
		return "\"%s\"" % value
	return value


func _json_escape_multiline(text: String) -> String:
	return text.replace("\\", "\\\\").replace("\"", "\\\"").replace("\r", "").replace("\n", "\\n").strip_edges()


func _single_line(text: String) -> String:
	return text.replace("\r", " ").replace("\n", "\\n").strip_edges()


func _make_panel_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("1f252c")
	style.border_color = Color("51606f")
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style
