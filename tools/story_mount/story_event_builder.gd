@tool
extends Control

const RUNS_PATH: String = "res://content/runs/run_definitions.json"

@onready var _run_selector: OptionButton = %RunSelector
@onready var _reload_button: Button = %ReloadButton
@onready var _event_id_edit: LineEdit = %EventIdEdit
@onready var _title_edit: LineEdit = %TitleEdit
@onready var _description_edit: TextEdit = %DescriptionEdit
@onready var _event_class_selector: OptionButton = %EventClassSelector
@onready var _content_category_selector: OptionButton = %ContentCategorySelector
@onready var _time_slot_selector: OptionButton = %TimeSlotSelector
@onready var _presentation_selector: OptionButton = %PresentationSelector
@onready var _location_selector: OptionButton = %LocationSelector
@onready var _participants_edit: LineEdit = %ParticipantsEdit
@onready var _next_hooks_edit: LineEdit = %NextHooksEdit
@onready var _req_flags_edit: LineEdit = %ReqFlagsEdit
@onready var _priority_spin: SpinBox = %PrioritySpin
@onready var _random_weight_spin: SpinBox = %RandomWeightSpin
@onready var _repeatable_check: CheckBox = %RepeatableCheck
@onready var _day_min_spin: SpinBox = %DayMinSpin
@onready var _day_max_spin: SpinBox = %DayMaxSpin
@onready var _speaker_selector: OptionButton = %SpeakerSelector
@onready var _flow_node_selector: OptionButton = %FlowNodeSelector
@onready var _prefill_flow_button: Button = %PrefillFlowButton
@onready var _flow_gate_hint_label: Label = %FlowGateHintLabel
@onready var _block_type_selector: OptionButton = %BlockTypeSelector
@onready var _block_tag_edit: LineEdit = %BlockTagEdit
@onready var _block_npc_selector: OptionButton = %BlockNpcSelector
@onready var _block_relation_field_selector: OptionButton = %BlockRelationFieldSelector
@onready var _block_relation_value_spin: SpinBox = %BlockRelationValueSpin
@onready var _option_id_edit: LineEdit = %OptionIdEdit
@onready var _option_text_edit: LineEdit = %OptionTextEdit
@onready var _result_text_edit: TextEdit = %ResultTextEdit
@onready var _clue_gain_spin: SpinBox = %ClueGainSpin
@onready var _tag_gain_edit: LineEdit = %TagGainEdit
@onready var _set_flag_edit: LineEdit = %SetFlagEdit
@onready var _clear_flag_edit: LineEdit = %ClearFlagEdit
@onready var _relation_npc_selector: OptionButton = %RelationNpcSelector
@onready var _relation_field_selector: OptionButton = %RelationFieldSelector
@onready var _relation_delta_spin: SpinBox = %RelationDeltaSpin
@onready var _option2_enabled_check: CheckBox = %Option2EnabledCheck
@onready var _option2_id_edit: LineEdit = %Option2IdEdit
@onready var _option2_text_edit: LineEdit = %Option2TextEdit
@onready var _option2_result_text_edit: TextEdit = %Option2ResultTextEdit
@onready var _option2_clue_gain_spin: SpinBox = %Option2ClueGainSpin
@onready var _option2_tag_gain_edit: LineEdit = %Option2TagGainEdit
@onready var _option2_set_flag_edit: LineEdit = %Option2SetFlagEdit
@onready var _option2_clear_flag_edit: LineEdit = %Option2ClearFlagEdit
@onready var _option2_relation_npc_selector: OptionButton = %Option2RelationNpcSelector
@onready var _option2_relation_field_selector: OptionButton = %Option2RelationFieldSelector
@onready var _option2_relation_delta_spin: SpinBox = %Option2RelationDeltaSpin
@onready var _generate_button: Button = %GenerateButton
@onready var _copy_button: Button = %CopyButton
@onready var _output_edit: TextEdit = %OutputEdit

var _content_repository: ContentRepository
var _runs: Array[Dictionary] = []
var _selected_run_id: String = ""
var _selected_story_id: String = ""


func _ready() -> void:
	_content_repository = ContentRepository.new()
	_reload_button.pressed.connect(_reload_all)
	_run_selector.item_selected.connect(_on_run_selected)
	_flow_node_selector.item_selected.connect(_on_flow_node_selected)
	_prefill_flow_button.pressed.connect(_prefill_from_flow_node)
	_generate_button.pressed.connect(_generate_output)
	_copy_button.pressed.connect(_copy_output)
	_setup_static_selectors()
	_reload_all()


func _reload_all() -> void:
	_content_repository = ContentRepository.new()
	_runs = _load_runs()
	_rebuild_run_selector()
	_rebuild_story_sources()
	_generate_output()


func _setup_static_selectors() -> void:
	_fill_selector(_event_class_selector, [
		["fixed_story", "固定事件"],
		["conditional_story", "条件固定事件"],
		["random_filler", "随机事件"],
		["ending_check", "结局验证"]
	])
	_fill_selector(_content_category_selector, [
		["main_story", "主线骨架"],
		["npc_state", "人物状态"],
		["location_content", "地点内容"],
		["random_disturbance", "随机扰动"],
		["black_market_trade", "灰市交易"]
	])
	_fill_selector(_time_slot_selector, [
		["morning", "晨间"],
		["afternoon", "午后"],
		["night", "夜间"],
		["any", "任意"]
	])
	_fill_selector(_presentation_selector, [
		["standard_event", "普通事件"],
		["dialogue_event", "对话事件"],
		["ending_event", "结局事件"]
	])
	_fill_selector(_block_type_selector, [
		["none", "无阻断条件"],
		["tag_present", "玩家标签存在"],
		["npc_relation_gte", "NPC 关系达到阈值"]
	])
	_fill_selector(_block_relation_field_selector, [
		["favor", "好感"],
		["alert", "警惕"]
	])
	_fill_selector(_relation_field_selector, [
		["favor", "好感"],
		["alert", "警惕"]
	])
	_fill_selector(_option2_relation_field_selector, [
		["favor", "好感"],
		["alert", "警惕"]
	])


func _fill_selector(selector: OptionButton, items: Array) -> void:
	selector.clear()
	for item in items:
		selector.add_item(str(item[1]))
		selector.set_item_metadata(selector.item_count - 1, str(item[0]))
	if selector.item_count > 0:
		selector.select(0)


func _load_runs() -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(RUNS_PATH, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []
	var result: Array[Dictionary] = []
	for item in parsed:
		if item is Dictionary:
			result.append(item.duplicate(true))
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

	var selected_index: int = 0
	for i: int in range(_runs.size()):
		if str(_runs[i].get("id", "")) == _selected_run_id:
			selected_index = i
			break
	_run_selector.select(selected_index)
	_selected_story_id = str(_runs[selected_index].get("story_id", ""))


func _on_run_selected(index: int) -> void:
	if index < 0 or index >= _run_selector.item_count:
		return
	_selected_run_id = str(_run_selector.get_item_metadata(index))
	for run_definition: Dictionary in _runs:
		if str(run_definition.get("id", "")) == _selected_run_id:
			_selected_story_id = str(run_definition.get("story_id", ""))
			break
	_rebuild_story_sources()
	_generate_output()


func _on_flow_node_selected(_index: int) -> void:
	_refresh_flow_gate_hint()
	_generate_output()


func _rebuild_story_sources() -> void:
	_location_selector.clear()
	_location_selector.add_item("未绑定地点")
	_location_selector.set_item_metadata(0, "")
	var locations: Array[Dictionary] = _content_repository.get_location_definitions(_selected_story_id)
	locations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	for location_definition: Dictionary in locations:
		var location_id: String = str(location_definition.get("id", ""))
		_location_selector.add_item(str(location_definition.get("display_name", location_id)))
		_location_selector.set_item_metadata(_location_selector.item_count - 1, location_id)
	_location_selector.select(0)

	_rebuild_npc_selectors()
	_rebuild_flow_node_selector()
	_refresh_flow_gate_hint()


func _rebuild_flow_node_selector() -> void:
	_flow_node_selector.clear()
	_flow_node_selector.add_item("不挂主线节点")
	_flow_node_selector.set_item_metadata(0, "")

	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(_selected_run_id)
	var nodes: Array[Dictionary] = Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null)
	for node_definition: Dictionary in nodes:
		var node_id: String = str(node_definition.get("id", ""))
		var node_title: String = str(node_definition.get("title", node_id))
		_flow_node_selector.add_item("Day %d / %s" % [int(node_definition.get("day", 0)), node_title])
		_flow_node_selector.set_item_metadata(_flow_node_selector.item_count - 1, node_id)
	_flow_node_selector.select(0)


func _refresh_flow_gate_hint() -> void:
	var node_definition: Dictionary = _get_selected_flow_node_definition()
	if node_definition.is_empty():
		_flow_gate_hint_label.text = "褰撳墠鏈€夋嫨涓荤嚎鑺傜偣锛屽彲鐢ㄤ簬鎻愮ず杩欐潯鏂板唴瀹逛富瑕佹敮鎸佸摢涓€鍏炽€?"
		return

	var gate_check: Dictionary = Dictionary(node_definition.get("gate_check", {}))
	var day_value: int = int(node_definition.get("day", 0))
	var title: String = str(node_definition.get("title", node_definition.get("id", "")))
	var time_slot: String = _describe_time_slot(str(node_definition.get("time_slot", "")))
	if gate_check.is_empty():
		_flow_gate_hint_label.text = "涓荤嚎鑺傜偣锛?Day %d / %s / %s" % [day_value, time_slot, title]
		return

	_flow_gate_hint_label.text = "涓荤嚎鑺傜偣锛?Day %d / %s / %s | 闂ㄦ锛?s >= %d" % [
		day_value,
		time_slot,
		title,
		str(gate_check.get("label", "鏉′欢")),
		int(gate_check.get("value", 0))
	]


func _prefill_from_flow_node() -> void:
	var node_definition: Dictionary = _get_selected_flow_node_definition()
	if node_definition.is_empty():
		return

	_select_by_metadata(_time_slot_selector, str(node_definition.get("time_slot", "any")))
	_select_by_metadata(_location_selector, str(node_definition.get("location_id", "")))
	_select_by_metadata(_event_class_selector, "conditional_story")
	_select_by_metadata(_content_category_selector, "location_content")
	_select_by_metadata(_presentation_selector, "standard_event")

	var day_value: int = int(node_definition.get("day", 1))
	_day_min_spin.value = day_value
	_day_max_spin.value = day_value

	if _participants_edit.text.strip_edges().is_empty():
		_participants_edit.text = "player"
	if _next_hooks_edit.text.strip_edges().is_empty():
		_next_hooks_edit.text = "support_%s" % str(node_definition.get("id", ""))
	if _req_flags_edit.text.strip_edges().is_empty():
		_req_flags_edit.text = "|".join(Array(node_definition.get("required_flags", []), TYPE_STRING, "", null))
	if _title_edit.text.strip_edges().is_empty():
		_title_edit.text = "补充%s" % str(node_definition.get("title", node_definition.get("id", "")))
	if _description_edit.text.strip_edges().is_empty():
		_description_edit.text = "这条内容用于支持主线节点「%s」。" % str(node_definition.get("title", node_definition.get("id", "")))

	_generate_output()


func _get_selected_flow_node_definition() -> Dictionary:
	var node_id: String = _selected_metadata(_flow_node_selector)
	if node_id.is_empty():
		return {}
	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(_selected_run_id)
	for node_definition: Dictionary in Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(node_definition.get("id", "")) == node_id:
			return node_definition
	return {}


func _rebuild_npc_selectors() -> void:
	_speaker_selector.clear()
	_speaker_selector.add_item("无说话人")
	_speaker_selector.set_item_metadata(0, "")
	_block_npc_selector.clear()
	_block_npc_selector.add_item("未选择 NPC")
	_block_npc_selector.set_item_metadata(0, "")
	_relation_npc_selector.clear()
	_relation_npc_selector.add_item("未选择 NPC")
	_relation_npc_selector.set_item_metadata(0, "")
	_option2_relation_npc_selector.clear()
	_option2_relation_npc_selector.add_item("未选择 NPC")
	_option2_relation_npc_selector.set_item_metadata(0, "")

	var npcs: Array[Dictionary] = _content_repository.get_npc_definitions(_selected_story_id)
	npcs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", a.get("id", ""))) < str(b.get("display_name", b.get("id", "")))
	)
	for npc_definition: Dictionary in npcs:
		var npc_id: String = str(npc_definition.get("id", ""))
		var npc_name: String = str(npc_definition.get("display_name", npc_id))
		_speaker_selector.add_item(npc_name)
		_speaker_selector.set_item_metadata(_speaker_selector.item_count - 1, npc_id)
		_block_npc_selector.add_item(npc_name)
		_block_npc_selector.set_item_metadata(_block_npc_selector.item_count - 1, npc_id)
		_relation_npc_selector.add_item(npc_name)
		_relation_npc_selector.set_item_metadata(_relation_npc_selector.item_count - 1, npc_id)
		_option2_relation_npc_selector.add_item(npc_name)
		_option2_relation_npc_selector.set_item_metadata(_option2_relation_npc_selector.item_count - 1, npc_id)

	_speaker_selector.select(0)
	_block_npc_selector.select(0)
	_relation_npc_selector.select(0)
	_option2_relation_npc_selector.select(0)


func _generate_output() -> void:
	var event_id: String = _event_id_edit.text.strip_edges()
	if event_id.is_empty():
		_output_edit.text = "请先填写事件 ID。"
		return

	var title_key: String = "evt.%s.title" % event_id
	var desc_key: String = "evt.%s.desc" % event_id
	var option_id: String = _option_id_edit.text.strip_edges()
	if option_id.is_empty():
		option_id = "%s_option_1" % event_id
	var option_text_key: String = "opt.%s.text" % option_id
	var result_key: String = "opt.%s.result" % option_id
	var option2_enabled: bool = _option2_enabled_check.button_pressed
	var option2_id: String = _option2_id_edit.text.strip_edges()
	if option2_enabled and option2_id.is_empty():
		option2_id = "%s_option_2" % event_id
	var option2_text_key: String = "opt.%s.text" % option2_id if option2_enabled else ""
	var option2_result_key: String = "opt.%s.result" % option2_id if option2_enabled else ""

	var event_row: String = _build_event_row(event_id, title_key, desc_key)
	var trigger_rows: Array[String] = _build_trigger_rows(event_id)
	var block_rows: Array[String] = _build_block_rows(event_id)
	var option_rows: Array[String] = [_build_option_row(event_id, option_id, option_text_key, result_key, 1)]
	if option2_enabled:
		option_rows.append(_build_option_row(event_id, option2_id, option2_text_key, option2_result_key, 2))
	var effect_rows: Array[String] = _build_effect_rows(option_id, false)
	if option2_enabled:
		effect_rows.append_array(_build_effect_rows(option2_id, true))
	var localization_rows: Array[String] = _build_localization_rows(
		title_key,
		desc_key,
		option_text_key,
		result_key,
		option2_enabled,
		option2_text_key,
		option2_result_key
	)
	var flag_summary_rows: Array[String] = _build_flag_summary_rows()

	var sections: Array[String] = [
		"# events.csv",
		event_row,
		"",
		"# event_triggers.csv"
	]
	if trigger_rows.is_empty():
		sections.append("(无新增触发条件行)")
	else:
		sections.append_array(trigger_rows)
	sections.append("")
	sections.append("# event_blocks.csv")
	if block_rows.is_empty():
		sections.append("(无新增阻断条件行)")
	else:
		sections.append_array(block_rows)
	sections.append("")
	sections.append("# event_options.csv")
	sections.append_array(option_rows)
	sections.append("")
	sections.append("# option_effects.csv")
	if effect_rows.is_empty():
		sections.append("(无新增效果行)")
	else:
		sections.append_array(effect_rows)
	sections.append("")
	sections.append("# main_story_flow.json")
	sections.append_array(_build_flow_support_hint(event_id))
	sections.append("")
	sections.append("# flag_summary")
	sections.append_array(flag_summary_rows)
	sections.append("")
	sections.append("# localization.csv")
	sections.append_array(localization_rows)

	_output_edit.text = "\n".join(sections)


func _build_event_row(event_id: String, title_key: String, desc_key: String) -> String:
	var event_class: String = _selected_metadata(_event_class_selector)
	var content_category: String = _selected_metadata(_content_category_selector)
	var time_slot: String = _selected_metadata(_time_slot_selector)
	var presentation_type: String = _selected_metadata(_presentation_selector)
	var speaker_npc_id: String = _selected_metadata(_speaker_selector)
	var portrait_key: String = "%s_half" % speaker_npc_id if not speaker_npc_id.is_empty() else ""
	var location_id: String = _selected_metadata(_location_selector)
	var schedule_priority: int = int(_priority_spin.value)
	var random_weight: int = int(_random_weight_spin.value)
	var repeatable: String = "true" if _repeatable_check.button_pressed else "false"
	var participants: String = _participants_edit.text.strip_edges()
	var next_hooks: String = _next_hooks_edit.text.strip_edges()
	var req_flags: String = _req_flags_edit.text.strip_edges()

	return ",".join([
		event_id,
		_selected_story_id,
		event_class,
		content_category,
		time_slot,
		_csv_escape(participants),
		_csv_escape(next_hooks),
		presentation_type,
		speaker_npc_id,
		portrait_key,
		"phase_entry",
		"",
		location_id,
		"",
		str(schedule_priority),
		str(random_weight),
		repeatable,
		title_key,
		desc_key,
		"generated_by_story_event_builder",
		_csv_escape(req_flags),
		""
	])


func _build_trigger_rows(event_id: String) -> Array[String]:
	var rows: Array[String] = []
	var day_min: int = int(_day_min_spin.value)
	var day_max: int = int(_day_max_spin.value)
	if day_min > 0 and day_max > 0:
		rows.append(",".join([
			event_id,
			"main",
			"1",
			"day_range",
			"",
			"",
			"%d-%d" % [day_min, day_max],
			"",
			"",
			""
		]))
	return rows


func _build_block_rows(event_id: String) -> Array[String]:
	var block_type: String = _selected_metadata(_block_type_selector)
	if block_type == "none":
		return []

	match block_type:
		"tag_present":
			var tag_key: String = _block_tag_edit.text.strip_edges()
			if tag_key.is_empty():
				return []
			return [",".join([
				event_id,
				"main",
				"1",
				"tag_present",
				"player",
				tag_key,
				"",
				"",
				"",
				""
			])]
		"npc_relation_gte":
			var npc_id: String = _selected_metadata(_block_npc_selector)
			if npc_id.is_empty():
				return []
			var field: String = _selected_metadata(_block_relation_field_selector)
			return [",".join([
				event_id,
				"main",
				"1",
				"npc_relation_gte",
				"",
				"",
				str(int(_block_relation_value_spin.value)),
				npc_id,
				field,
				""
			])]
		_:
			return []


func _build_option_row(event_id: String, option_id: String, text_key: String, result_key: String, order_index: int) -> String:
	return ",".join([
		option_id,
		event_id,
		str(order_index),
		text_key,
		result_key,
		"generated_by_story_event_builder"
	])


func _build_effect_rows(option_id: String, use_second_option: bool) -> Array[String]:
	var rows: Array[String] = []
	var clue_gain: int = int(_option2_clue_gain_spin.value) if use_second_option else int(_clue_gain_spin.value)
	var tag_gain: String = _option2_tag_gain_edit.text.strip_edges() if use_second_option else _tag_gain_edit.text.strip_edges()
	var set_flags: Array[String] = _split_values(_option2_set_flag_edit.text if use_second_option else _set_flag_edit.text)
	var clear_flags: Array[String] = _split_values(_option2_clear_flag_edit.text if use_second_option else _clear_flag_edit.text)
	var relation_npc_id: String = _selected_metadata(_option2_relation_npc_selector) if use_second_option else _selected_metadata(_relation_npc_selector)
	var relation_field: String = _selected_metadata(_option2_relation_field_selector) if use_second_option else _selected_metadata(_relation_field_selector)
	var relation_delta: int = int(_option2_relation_delta_spin.value) if use_second_option else int(_relation_delta_spin.value)
	var order_index: int = 1

	if clue_gain != 0:
		rows.append(",".join([
			option_id,
			str(order_index),
			"modify_resource",
			"player",
			"clue_fragments",
			str(clue_gain),
			"",
			"",
			""
		]))
		order_index += 1

	if not tag_gain.is_empty():
		rows.append(",".join([
			option_id,
			str(order_index),
			"add_tag",
			"player",
			tag_gain,
			"",
			"",
			"",
			""
		]))
		order_index += 1

	for flag_key: String in set_flags:
		rows.append(",".join([
			option_id,
			str(order_index),
			"set_flag",
			"",
			flag_key,
			"",
			"",
			"",
			""
		]))
		order_index += 1

	for flag_key: String in clear_flags:
		rows.append(",".join([
			option_id,
			str(order_index),
			"clear_flag",
			"",
			flag_key,
			"",
			"",
			"",
			""
		]))
		order_index += 1

	if not relation_npc_id.is_empty() and relation_delta != 0:
		rows.append(",".join([
			option_id,
			str(order_index),
			"modify_npc_relation",
			"",
			"",
			str(relation_delta),
			relation_npc_id,
			relation_field,
			""
		]))

	return rows


func _build_localization_rows(
	title_key: String,
	desc_key: String,
	option_text_key: String,
	result_key: String,
	option2_enabled: bool,
	option2_text_key: String,
	option2_result_key: String
) -> Array[String]:
	var rows: Array[String] = [
		"%s,%s" % [title_key, _csv_escape(_title_edit.text.strip_edges())],
		"%s,%s" % [desc_key, _csv_escape(_single_line(_description_edit.text))],
		"%s,%s" % [option_text_key, _csv_escape(_option_text_edit.text.strip_edges())],
		"%s,%s" % [result_key, _csv_escape(_single_line(_result_text_edit.text))]
	]
	if option2_enabled:
		rows.append("%s,%s" % [option2_text_key, _csv_escape(_option2_text_edit.text.strip_edges())])
		rows.append("%s,%s" % [option2_result_key, _csv_escape(_single_line(_option2_result_text_edit.text))])
	return rows


func _build_flow_support_hint(event_id: String) -> Array[String]:
	var node_id: String = _selected_metadata(_flow_node_selector)
	if node_id.is_empty():
		return ["(当前未指定主线节点挂载)"]

	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(_selected_run_id)
	var node_title: String = node_id
	for node_definition: Dictionary in Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(node_definition.get("id", "")) != node_id:
			continue
		node_title = str(node_definition.get("title", node_id))
		break

	return [
		"在主线节点 `%s`（%s）的 `supports_from` 中追加：" % [node_id, node_title],
		"\"%s\"" % event_id
	]


func _build_flag_summary_rows() -> Array[String]:
	var rows: Array[String] = []
	var req_flags: Array[String] = _split_values(_req_flags_edit.text)
	var option1_set_flags: Array[String] = _split_values(_set_flag_edit.text)
	var option1_clear_flags: Array[String] = _split_values(_clear_flag_edit.text)
	var option2_enabled: bool = _option2_enabled_check.button_pressed
	var option2_set_flags: Array[String] = _split_values(_option2_set_flag_edit.text) if option2_enabled else []
	var option2_clear_flags: Array[String] = _split_values(_option2_clear_flag_edit.text) if option2_enabled else []

	if req_flags.is_empty() and option1_set_flags.is_empty() and option1_clear_flags.is_empty() and option2_set_flags.is_empty() and option2_clear_flags.is_empty():
		return ["(褰撳墠浜嬩欢鏈鍐?flag)"]

	if not req_flags.is_empty():
		rows.append("闇€瑕?Flags锛? %s" % " | ".join(req_flags))
	if not option1_set_flags.is_empty():
		rows.append("閫夐」 1 璁剧疆锛? %s" % " | ".join(option1_set_flags))
	if not option1_clear_flags.is_empty():
		rows.append("閫夐」 1 娓呴櫎锛? %s" % " | ".join(option1_clear_flags))
	if not option2_set_flags.is_empty():
		rows.append("閫夐」 2 璁剧疆锛? %s" % " | ".join(option2_set_flags))
	if not option2_clear_flags.is_empty():
		rows.append("閫夐」 2 娓呴櫎锛? %s" % " | ".join(option2_clear_flags))
	return rows


func _copy_output() -> void:
	DisplayServer.clipboard_set(_output_edit.text)


func _selected_metadata(selector: OptionButton) -> String:
	if selector.item_count == 0 or selector.selected < 0:
		return ""
	return str(selector.get_item_metadata(selector.selected))


func _select_by_metadata(selector: OptionButton, expected: String) -> void:
	if expected.is_empty():
		return
	for index: int in range(selector.item_count):
		if str(selector.get_item_metadata(index)) != expected:
			continue
		selector.select(index)
		return


func _single_line(text: String) -> String:
	return text.replace("\r", " ").replace("\n", "\\n").strip_edges()


func _csv_escape(text: String) -> String:
	var value: String = text
	if value.contains(",") or value.contains("\"") or value.contains("\n"):
		value = value.replace("\"", "\"\"")
		return "\"%s\"" % value
	return value


func _split_values(text: String) -> Array[String]:
	var values: Array[String] = []
	for item: String in text.split("|", false):
		var normalized: String = item.strip_edges()
		if not normalized.is_empty():
			values.append(normalized)
	return values


func _describe_time_slot(time_slot: String) -> String:
	match time_slot:
		"morning":
			return "鏅ㄩ棿"
		"afternoon":
			return "鍗堝悗"
		"night":
			return "澶滈棿"
		"any":
			return "浠绘剰"
		_:
			return time_slot
