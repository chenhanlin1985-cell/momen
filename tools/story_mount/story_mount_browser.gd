@tool
extends Control

const RUNS_PATH: String = "res://content/runs/run_definitions.json"
const RUN_INITIALIZER_SCRIPT := preload("res://systems/run/run_initializer.gd")
const META_PROGRESS_SCRIPT := preload("res://core/models/meta_progress.gd")

const CATEGORY_LABELS := {
	"main_story": "主线骨架",
	"npc_state": "人物状态",
	"location_content": "地点内容",
	"random_disturbance": "随机扰动"
	,
	"black_market_trade": "灰市交易"
}

const STATUS_LABELS := {
	"ready": "可触发",
	"blocked": "已阻断",
	"resolved": "已触发",
	"pending": "待满足"
}

@onready var _run_selector: OptionButton = %RunSelector
@onready var _reload_button: Button = %ReloadButton
@onready var _category_filter: OptionButton = %CategoryFilter
@onready var _location_list: ItemList = %LocationList
@onready var _npc_list: ItemList = %NpcList
@onready var _flow_list: ItemList = %FlowList
@onready var _experience_list: ItemList = %ExperienceList
@onready var _flag_list: ItemList = %FlagList
@onready var _mount_list: ItemList = %MountList
@onready var _detail_label: RichTextLabel = %DetailLabel

var _content_repository: ContentRepository
var _run_initializer: RunInitializer
var _condition_evaluator: ConditionEvaluator
var _runs: Array[Dictionary] = []
var _selected_run_id: String = ""
var _selected_story_id: String = ""
var _selected_category_filter: String = "all"


func _ready() -> void:
	_content_repository = ContentRepository.new()
	_run_initializer = RUN_INITIALIZER_SCRIPT.new()
	_condition_evaluator = ConditionEvaluator.new()
	_reload_button.pressed.connect(_reload_all)
	_run_selector.item_selected.connect(_on_run_selected)
	_category_filter.item_selected.connect(_on_category_filter_selected)
	_location_list.item_selected.connect(_on_location_selected)
	_npc_list.item_selected.connect(_on_npc_selected)
	_flow_list.item_selected.connect(_on_flow_selected)
	_experience_list.item_selected.connect(_on_experience_selected)
	_flag_list.item_selected.connect(_on_flag_selected)
	_mount_list.item_selected.connect(_on_mount_selected)
	_reload_all()


func _reload_all() -> void:
	_content_repository = ContentRepository.new()
	_run_initializer = RUN_INITIALIZER_SCRIPT.new()
	_condition_evaluator = ConditionEvaluator.new()
	_runs = _load_runs()
	_rebuild_run_selector()
	_rebuild_sources()


func _on_run_selected(index: int) -> void:
	if index < 0 or index >= _run_selector.item_count:
		return
	_selected_run_id = str(_run_selector.get_item_metadata(index))
	var run_definition: Dictionary = _find_run_definition(_selected_run_id)
	_selected_story_id = str(run_definition.get("story_id", ""))
	_rebuild_sources()


func _on_category_filter_selected(index: int) -> void:
	if index < 0 or index >= _category_filter.item_count:
		return
	_selected_category_filter = str(_category_filter.get_item_metadata(index))
	_rebuild_sources()


func _on_location_selected(index: int) -> void:
	if index < 0 or index >= _location_list.item_count:
		return
	_rebuild_mount_list_for_location(str(_location_list.get_item_metadata(index)))


func _on_npc_selected(index: int) -> void:
	if index < 0 or index >= _npc_list.item_count:
		return
	_rebuild_mount_list_for_npc(str(_npc_list.get_item_metadata(index)))


func _on_flow_selected(index: int) -> void:
	if index < 0 or index >= _flow_list.item_count:
		return
	var metadata: Variant = _flow_list.get_item_metadata(index)
	if metadata is Dictionary:
		_detail_label.text = _build_flow_node_detail_text(metadata)


func _on_experience_selected(index: int) -> void:
	if index < 0 or index >= _experience_list.item_count:
		return
	var metadata: Variant = _experience_list.get_item_metadata(index)
	if metadata is Dictionary:
		_detail_label.text = _build_event_detail_text(metadata)


func _on_mount_selected(index: int) -> void:
	if index < 0 or index >= _mount_list.item_count:
		return
	var metadata: Variant = _mount_list.get_item_metadata(index)
	if metadata is Dictionary:
		_detail_label.text = _build_event_detail_text(metadata)


func _on_flag_selected(index: int) -> void:
	if index < 0 or index >= _flag_list.item_count:
		return
	var metadata: Variant = _flag_list.get_item_metadata(index)
	if metadata is Dictionary:
		_detail_label.text = _build_flag_detail_text(metadata)


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


func _rebuild_category_filter() -> void:
	_category_filter.clear()
	var items: Array[Dictionary] = [
		{"id": "all", "label": "全部内容"},
		{"id": "main_story", "label": "主线骨架"},
		{"id": "npc_state", "label": "人物状态"},
		{"id": "location_content", "label": "地点内容"},
		{"id": "random_disturbance", "label": "随机扰动"},
		{"id": "black_market_trade", "label": "灰市交易"}
	]
	for item: Dictionary in items:
		_category_filter.add_item(str(item.get("label", "")))
		_category_filter.set_item_metadata(_category_filter.item_count - 1, str(item.get("id", "")))

	var selected_index: int = 0
	for i: int in range(_category_filter.item_count):
		if str(_category_filter.get_item_metadata(i)) == _selected_category_filter:
			selected_index = i
			break
	_category_filter.select(selected_index)


func _rebuild_sources() -> void:
	_rebuild_category_filter()
	_location_list.clear()
	_npc_list.clear()
	_flow_list.clear()
	_experience_list.clear()
	_flag_list.clear()
	_mount_list.clear()
	_detail_label.text = ""

	var locations: Array[Dictionary] = _content_repository.get_location_definitions(_selected_story_id)
	locations.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	for location_definition: Dictionary in locations:
		var location_id: String = str(location_definition.get("id", ""))
		var counts: Dictionary = _count_filtered_location_slots(Dictionary(location_definition.get("content_slots", {})))
		var summary: String = "%s | 固定 %d / 调查 %d / 随机 %d" % [
			str(location_definition.get("display_name", location_id)),
			int(counts.get("fixed_events", 0)),
			int(counts.get("investigation_events", 0)),
			int(counts.get("random_events", 0))
		]
		_location_list.add_item(summary)
		_location_list.set_item_metadata(_location_list.item_count - 1, location_id)

	var npcs: Array[Dictionary] = _content_repository.get_npc_definitions(_selected_story_id)
	npcs.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("display_name", a.get("id", ""))) < str(b.get("display_name", b.get("id", "")))
	)
	for npc_definition: Dictionary in npcs:
		var npc_id: String = str(npc_definition.get("id", ""))
		var count: int = _count_filtered_event_ids(_content_repository.get_npc_state_event_ids(npc_id))
		var summary: String = "%s | 态度：%s | 状态事件 %d" % [
			str(npc_definition.get("display_name", npc_id)),
			str(npc_definition.get("default_attitude", "未标注")),
			count
		]
		_npc_list.add_item(summary)
		_npc_list.set_item_metadata(_npc_list.item_count - 1, npc_id)

	_rebuild_flow_list()
	_rebuild_experience_list()
	_rebuild_flag_list()

	if _location_list.item_count > 0:
		_location_list.select(0)
		_on_location_selected(0)
	elif _flow_list.item_count > 0:
		_flow_list.select(0)
		_on_flow_selected(0)
	else:
		_detail_label.text = "[b]没有可显示的剧情内容[/b]"


func _rebuild_flow_list() -> void:
	_flow_list.clear()
	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(_selected_run_id)
	var nodes: Array[Dictionary] = Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null)
	for node_definition: Dictionary in nodes:
		var event_id: String = str(node_definition.get("event_id", ""))
		var event_definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
		if event_definition.is_empty():
			continue
		if not _matches_category_filter(event_definition):
			continue
		var state_view: Dictionary = _evaluate_event_state(event_definition)
		var gate_view: Dictionary = _evaluate_gate_check(node_definition)
		var enriched_node: Dictionary = node_definition.duplicate(true)
		enriched_node["_event_definition"] = event_definition
		enriched_node["_debug_state"] = state_view
		enriched_node["_gate_view"] = gate_view
		var gate_summary: String = ""
		if not gate_view.is_empty():
			gate_summary = " / %s %d/%d" % [
				str(gate_view.get("label", "条件")),
				int(gate_view.get("current_value", 0)),
				int(gate_view.get("target_value", 0))
			]
		_flow_list.add_item("Day %d / %s / %s%s" % [
			int(node_definition.get("day", 0)),
			_describe_status(str(state_view.get("status", "pending"))),
			str(node_definition.get("title", node_definition.get("id", ""))),
			gate_summary
		])
		_flow_list.set_item_metadata(_flow_list.item_count - 1, enriched_node)


func _rebuild_experience_list() -> void:
	_experience_list.clear()
	var all_events: Array[Dictionary] = _content_repository.get_story_event_definitions(_selected_run_id)
	all_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_day: int = _extract_day_order(a)
		var b_day: int = _extract_day_order(b)
		if a_day != b_day:
			return a_day < b_day
		var a_time: int = _time_slot_order(str(a.get("time_slot", "")))
		var b_time: int = _time_slot_order(str(b.get("time_slot", "")))
		if a_time != b_time:
			return a_time < b_time
		var a_category: int = _content_category_order(str(a.get("content_category", "")))
		var b_category: int = _content_category_order(str(b.get("content_category", "")))
		if a_category != b_category:
			return a_category < b_category
		return int(a.get("schedule_priority", 0)) > int(b.get("schedule_priority", 0))
	)

	for definition: Dictionary in all_events:
		if not _matches_category_filter(definition):
			continue
		var state_view: Dictionary = _evaluate_event_state(definition)
		var enriched_definition: Dictionary = definition.duplicate(true)
		enriched_definition["_debug_state"] = state_view
		var label: String = "Day %d / %s / %s / %s / %s" % [
			_extract_day_order(definition),
			_describe_time_slot(str(definition.get("time_slot", ""))),
			_describe_category(str(definition.get("content_category", ""))),
			_describe_event_location(definition),
			str(definition.get("title", definition.get("id", "")))
		]
		_experience_list.add_item("%s %s" % [
			_describe_status(str(state_view.get("status", "pending"))),
			label
		])
		_experience_list.set_item_metadata(_experience_list.item_count - 1, enriched_definition)


func _rebuild_flag_list() -> void:
	_flag_list.clear()
	var registry: Dictionary = _collect_flag_registry()
	var flag_keys: Array[String] = []
	for flag_key_variant: Variant in registry.keys():
		flag_keys.append(str(flag_key_variant))
	flag_keys.sort()
	for flag_key: String in flag_keys:
		var record: Dictionary = Dictionary(registry.get(flag_key, {}))
		var summary: String = "%s | 设置 %d / 需求 %d / 阻断 %d / 清除 %d" % [
			_describe_flag(flag_key),
			Array(record.get("setters", []), TYPE_STRING, "", null).size(),
			Array(record.get("required_by", []), TYPE_STRING, "", null).size(),
			Array(record.get("blocked_by", []), TYPE_STRING, "", null).size(),
			Array(record.get("clearers", []), TYPE_STRING, "", null).size()
		]
		var enriched: Dictionary = record.duplicate(true)
		enriched["flag_key"] = flag_key
		_flag_list.add_item(summary)
		_flag_list.set_item_metadata(_flag_list.item_count - 1, enriched)


func _rebuild_mount_list_for_location(location_id: String) -> void:
	_mount_list.clear()
	var location_definition: Dictionary = _content_repository.get_location_definition(location_id)
	var content_slots: Dictionary = Dictionary(location_definition.get("content_slots", {}))
	for slot_name: String in ["fixed_events", "investigation_events", "random_events"]:
		var event_ids: Array[String] = Array(content_slots.get(slot_name, []), TYPE_STRING, "", null)
		for event_id: String in event_ids:
			var definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
			if definition.is_empty() or not _matches_category_filter(definition):
				continue
			var state_view: Dictionary = _evaluate_event_state(definition)
			var enriched_definition: Dictionary = definition.duplicate(true)
			enriched_definition["_debug_state"] = state_view
			_mount_list.add_item("[%s] %s %s" % [
				_describe_slot(slot_name),
				_describe_status(str(state_view.get("status", "pending"))),
				str(definition.get("title", event_id))
			])
			_mount_list.set_item_metadata(_mount_list.item_count - 1, enriched_definition)

	var counts: Dictionary = _count_filtered_location_slots(content_slots)
	_detail_label.text = "\n".join([
		"[b]%s[/b]" % str(location_definition.get("display_name", location_id)),
		str(location_definition.get("description", "")),
		"",
		"[b]挂载槽摘要[/b]",
		"当前筛选：%s" % _describe_filter_label(_selected_category_filter),
		"常驻人物：%d" % Array(content_slots.get("resident_npcs", []), TYPE_STRING, "", null).size(),
		"固定事件：%d" % int(counts.get("fixed_events", 0)),
		"调查事件：%d" % int(counts.get("investigation_events", 0)),
		"随机事件：%d" % int(counts.get("random_events", 0))
	])

	if _mount_list.item_count > 0:
		_mount_list.select(0)
		_on_mount_selected(0)


func _rebuild_mount_list_for_npc(npc_id: String) -> void:
	_mount_list.clear()
	var npc_definition: Dictionary = _content_repository.get_npc_definition(npc_id)
	var event_ids: Array[String] = _content_repository.get_npc_state_event_ids(npc_id)
	for event_id: String in event_ids:
		var definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
		if definition.is_empty() or not _matches_category_filter(definition):
			continue
		var state_view: Dictionary = _evaluate_event_state(definition)
		var enriched_definition: Dictionary = definition.duplicate(true)
		enriched_definition["_debug_state"] = state_view
		_mount_list.add_item("[状态事件] %s %s" % [
			_describe_status(str(state_view.get("status", "pending"))),
			str(definition.get("title", event_id))
		])
		_mount_list.set_item_metadata(_mount_list.item_count - 1, enriched_definition)

	_detail_label.text = "\n".join([
		"[b]%s[/b]" % str(npc_definition.get("display_name", npc_id)),
		"身份：%s" % str(npc_definition.get("role", "")),
		"默认态度：%s" % str(npc_definition.get("default_attitude", "未标注")),
		"默认状态：%s" % str(npc_definition.get("default_state", "未标注")),
		"默认地点：%s" % _describe_location_name(str(npc_definition.get("default_location_id", ""))),
		"",
		"[b]状态事件[/b]",
		"当前筛选：%s" % _describe_filter_label(_selected_category_filter),
		"共 %d 条" % _count_filtered_event_ids(event_ids)
	])

	if _mount_list.item_count > 0:
		_mount_list.select(0)
		_on_mount_selected(0)


func _build_flow_node_detail_text(node_definition: Dictionary) -> String:
	var event_definition: Dictionary = Dictionary(node_definition.get("_event_definition", {}))
	var debug_state: Dictionary = Dictionary(node_definition.get("_debug_state", {}))
	var gate_view: Dictionary = Dictionary(node_definition.get("_gate_view", {}))
	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(_selected_run_id)
	var edges: Array[Dictionary] = Array(flow_definition.get("edges", []), TYPE_DICTIONARY, "", null)
	var fallback_endings: Array[Dictionary] = Array(flow_definition.get("fallback_endings", []), TYPE_DICTIONARY, "", null)
	var outgoing_edges: Array[Dictionary] = []
	for edge_definition: Dictionary in edges:
		if str(edge_definition.get("from_node_id", "")) == str(node_definition.get("id", "")):
			outgoing_edges.append(edge_definition)

	var lines: Array[String] = [
		"[b]%s[/b]" % str(node_definition.get("title", node_definition.get("id", ""))),
		"主线节点：%s" % str(node_definition.get("id", "")),
		"阶段类型：%s" % _describe_hub_type(str(node_definition.get("hub_type", ""))),
		"对应事件：%s" % str(node_definition.get("event_id", "")),
		"时间：Day %d / %s" % [int(node_definition.get("day", 0)), _describe_time_slot(str(node_definition.get("time_slot", "")))],
		"地点：%s" % _describe_location_name(str(node_definition.get("location_id", ""))),
		"当前状态：%s" % _describe_status(str(debug_state.get("status", "pending"))),
		"状态说明：%s" % str(debug_state.get("reason_text", "")),
		"",
		"[b]节点说明[/b]",
		str(node_definition.get("description", "")),
		"",
		"[b]主线节点数据检查[/b]"
	]

	if gate_view.is_empty():
		lines.append("- 未配置")
	else:
		lines.append("- %s：当前 %d / 需要 %d" % [
			str(gate_view.get("label", "条件")),
			int(gate_view.get("current_value", 0)),
			int(gate_view.get("target_value", 0))
		])
		lines.append("- 结果：%s" % ("通过" if bool(gate_view.get("passed", false)) else "未通过"))
		lines.append("- 说明：%s" % str(gate_view.get("description", "")))

	lines.append("")
	lines.append("[b]通过这个主线节点主要要看什么[/b]")
	var gate_requirements: Array[String] = Array(node_definition.get("gate_requirements", []), TYPE_STRING, "", null)
	if gate_requirements.is_empty():
		lines.append("- 无额外摘要")
	else:
		for requirement: String in gate_requirements:
			lines.append("- %s" % requirement)

	var structured_requirements: Dictionary = Dictionary(node_definition.get("structured_requirements", {}))
	if not structured_requirements.is_empty():
		lines.append("")
		lines.append("[b]结构化判定摘要[/b]")
		_append_requirement_group(lines, "需要的线索", Array(structured_requirements.get("clues", []), TYPE_STRING, "", null))
		_append_requirement_group(lines, "需要的标签", Array(structured_requirements.get("tags", []), TYPE_STRING, "", null))
		_append_requirement_group(lines, "需要的人物关系", Array(structured_requirements.get("relations", []), TYPE_STRING, "", null))
		_append_requirement_group(lines, "需要承受的风险", Array(structured_requirements.get("risks", []), TYPE_STRING, "", null))

	var required_flags: Array[String] = Array(node_definition.get("required_flags", []), TYPE_STRING, "", null)
	if not required_flags.is_empty():
		lines.append("")
		lines.append("[b]进入这个主线节点需要的全局标记[/b]")
		for flag_key: String in required_flags:
			lines.append("- %s" % _describe_flag(flag_key))

	lines.append("")
	lines.append("[b]支持这个主线节点的内容[/b]")
	lines.append("[i]括号内会标注该事件最多可提供的线索数量，帮助判断这关主要靠什么喂线索。[/i]")
	var support_grouped: Dictionary = {
		"npc_state": [],
		"location_content": [],
		"random_disturbance": [],
		"black_market_trade": [],
		"main_story": []
	}
	var support_unknown: Array[String] = []
	var supports_from: Array[String] = Array(node_definition.get("supports_from", []), TYPE_STRING, "", null)
	var support_clue_total: int = 0
	if supports_from.is_empty():
		lines.append("- 无")
	else:
		for event_id: String in supports_from:
			var support_definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
			if support_definition.is_empty():
				support_unknown.append(event_id)
				continue
			var support_category: String = str(support_definition.get("content_category", ""))
			var support_line: String = _build_support_line(support_definition, event_id)
			support_clue_total += _calculate_max_resource_gain(support_definition, "clue_fragments")
			if support_grouped.has(support_category):
				var grouped_lines: Array = support_grouped[support_category]
				grouped_lines.append(support_line)
				support_grouped[support_category] = grouped_lines
			else:
				support_unknown.append(support_line)

	for category_key: String in ["npc_state", "location_content", "black_market_trade", "random_disturbance", "main_story"]:
		var category_lines: Array = support_grouped.get(category_key, [])
		if category_lines.is_empty():
			continue
		lines.append("- %s：" % _describe_category(category_key))
		for category_line: String in category_lines:
			lines.append("  - %s" % category_line)
	if not support_unknown.is_empty():
		lines.append("- 其他：")
		for support_line: String in support_unknown:
			lines.append("  - %s" % support_line)

	if not gate_view.is_empty():
		lines.append("")
		lines.append("[b]这关理论上线索供给总量[/b]")
		lines.append("- 支持内容最高总供给：%d" % support_clue_total)
		lines.append("- 当前主线门槛：%d" % int(gate_view.get("target_value", 0)))
		if support_clue_total >= int(gate_view.get("target_value", 0)):
			lines.append("- 结果：理论上够喂到这关")
		else:
			lines.append("- 结果：理论上供给不足，建议补地点/NPC/随机内容，或下调门槛")

	lines.append("")
	lines.append("[b]前往下一个主线节点的条件[/b]")
	if outgoing_edges.is_empty():
		lines.append("- 无后续连接")
	else:
		for edge_definition: Dictionary in outgoing_edges:
			lines.append("- %s -> %s" % [
				str(edge_definition.get("label", "继续推进")),
				_describe_flow_target(flow_definition, str(edge_definition.get("to_node_id", "")))
			])
			var summaries: Array[String] = Array(edge_definition.get("conditions_summary", []), TYPE_STRING, "", null)
			for summary: String in summaries:
				lines.append("  - %s" % summary)
			var failure_to: String = str(edge_definition.get("failure_to", ""))
			if not failure_to.is_empty():
				lines.append("  - 不满足时导向：%s" % _describe_fallback(fallback_endings, failure_to))

	var resolution_checks: Array[Dictionary] = Array(node_definition.get("resolution_checks", []), TYPE_DICTIONARY, "", null)
	if not resolution_checks.is_empty():
		lines.append("")
		lines.append("[b]收束判定[/b]")
		for check_definition: Dictionary in resolution_checks:
			lines.append("- %s" % str(check_definition.get("label", "未命名判定")))
			for flag_key: String in Array(check_definition.get("requires_flags", []), TYPE_STRING, "", null):
				lines.append("  - 需要: %s" % _describe_flag(flag_key))

	if not event_definition.is_empty():
		lines.append("")
		lines.append("[b]关联事件信息[/b]")
		lines.append("内容分类：%s" % _describe_category(str(event_definition.get("content_category", ""))))
		lines.append("参与者：%s" % _join_strings(Array(event_definition.get("participants", []), TYPE_STRING, "", null)))

	return "\n".join(lines)


func _build_event_detail_text(definition: Dictionary) -> String:
	var lines: Array[String] = [
		"[b]%s[/b]" % str(definition.get("title", definition.get("id", ""))),
		"事件 ID：%s" % str(definition.get("id", "")),
		"运行时分类：%s" % str(definition.get("event_class", "")),
		"内容分类：%s" % _describe_category(str(definition.get("content_category", ""))),
		"时间槽：%s" % _describe_time_slot(str(definition.get("time_slot", ""))),
		"地点：%s" % _describe_event_location(definition),
		"参与者：%s" % _join_strings(Array(definition.get("participants", []), TYPE_STRING, "", null)),
		"需求 Flags：%s" % _join_strings(_describe_flag_list(Array(definition.get("req_flags", []), TYPE_STRING, "", null))),
		"阻断 Flags：%s" % _join_strings(_describe_flag_list(Array(definition.get("block_flags", []), TYPE_STRING, "", null))),
		"挂载点：%s" % _join_strings(Array(definition.get("next_hooks", []), TYPE_STRING, "", null)),
		""
	]

	var debug_state: Dictionary = Dictionary(definition.get("_debug_state", {}))
	if not debug_state.is_empty():
		lines.append("[b]当前初始局面状态[/b]")
		lines.append("状态：%s" % _describe_status(str(debug_state.get("status", "pending"))))
		lines.append("说明：%s" % str(debug_state.get("reason_text", "")))
		lines.append("")

	var trigger_conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
	var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
	lines.append("[b]触发条件[/b]")
	if trigger_conditions.is_empty():
		lines.append("- 无")
	else:
		for condition: Dictionary in trigger_conditions:
			lines.append("- %s" % JSON.stringify(condition))

	lines.append("")
	lines.append("[b]阻断条件[/b]")
	if block_conditions.is_empty():
		lines.append("- 无")
	else:
		for condition: Dictionary in block_conditions:
			lines.append("- %s" % JSON.stringify(condition))

	lines.append("")
	lines.append("[b]事件文本[/b]")
	lines.append(str(definition.get("description", "")))

	var options: Array[Dictionary] = Array(definition.get("options", []), TYPE_DICTIONARY, "", null)
	lines.append("")
	lines.append("[b]选项[/b]")
	if options.is_empty():
		lines.append("- 无选项")
	else:
		for option_definition: Dictionary in options:
			lines.append("- %s" % str(option_definition.get("text", option_definition.get("id", ""))))
	return "\n".join(lines)


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


func _find_run_definition(run_id: String) -> Dictionary:
	for run_definition: Dictionary in _runs:
		if str(run_definition.get("id", "")) == run_id:
			return run_definition
	return {}


func _describe_slot(slot_name: String) -> String:
	match slot_name:
		"fixed_events":
			return "固定"
		"investigation_events":
			return "调查"
		"random_events":
			return "随机"
		_:
			return slot_name


func _describe_category(category: String) -> String:
	return str(CATEGORY_LABELS.get(category, category))


func _describe_filter_label(filter_id: String) -> String:
	if filter_id == "all":
		return "全部内容"
	return _describe_category(filter_id)


func _join_strings(values: Array[String]) -> String:
	return "无" if values.is_empty() else ", ".join(values)


func _describe_flag_list(values: Array[String]) -> Array[String]:
	var result: Array[String] = []
	for value: String in values:
		result.append(_describe_flag(value))
	return result


func _describe_flag(flag_key: String) -> String:
	var labels: Dictionary = {
		"heard_well_warning": "已听闻化骨池警告",
		"missing_rumor_confirmed": "已确认失踪传闻",
		"met_outer_senior": "已接触疯长老",
		"met_herb_steward": "已接触药房执事",
		"entered_records_room": "已进入记录间",
		"records_tampered_confirmed": "已确认账册被篡改",
		"approached_inner_well": "已靠近井边禁区",
		"marked_by_well": "已被化骨池标记",
		"reported_to_patrol": "已向夜巡上报",
		"trusted_outer_senior": "已信任疯长老",
		"prepared_report": "已准备上报",
		"prepared_descent": "已准备深入",
		"accepted_whisper": "已接受池底异声"
	}
	return str(labels.get(flag_key, flag_key))


func _describe_status(status: String) -> String:
	return str(STATUS_LABELS.get(status, status))


func _describe_hub_type(hub_type: String) -> String:
	match hub_type:
		"exploration":
			return "探索段"
		"branching":
			return "分化段"
		"resolution":
			return "收束段"
		_:
			return hub_type if not hub_type.is_empty() else "未标注"


func _evaluate_event_state(definition: Dictionary) -> Dictionary:
	var run_state: RunState = _create_preview_run_state()
	var event_id: String = str(definition.get("id", ""))
	var trigger_conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
	var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
	var repeatable: bool = bool(definition.get("repeatable", false))

	if not repeatable and run_state.triggered_event_ids.has(event_id):
		return {"status": "resolved", "reason_text": "当前预览局面里已触发"}
	if not block_conditions.is_empty() and _condition_evaluator.evaluate_all(run_state, block_conditions):
		return {"status": "blocked", "reason_text": "阻断条件已生效"}
	if _condition_evaluator.evaluate_all(run_state, trigger_conditions):
		return {"status": "ready", "reason_text": "当前初始局面已满足"}
	return {
		"status": "pending",
		"reason_text": " / ".join(_condition_evaluator.get_unmet_descriptions(run_state, trigger_conditions))
	}


func _evaluate_gate_check(node_definition: Dictionary) -> Dictionary:
	var gate_check: Dictionary = Dictionary(node_definition.get("gate_check", {}))
	if gate_check.is_empty():
		return {}
	var run_state: RunState = _create_preview_run_state()
	var check_type: String = str(gate_check.get("type", ""))
	var label: String = str(gate_check.get("label", "条件"))
	var target_value: int = int(gate_check.get("value", 0))
	var current_value: int = 0

	match check_type:
		"resource_gte":
			if str(gate_check.get("scope", "player")) == "player":
				current_value = int(run_state.player_state.resources.get(str(gate_check.get("key", "")), 0))
		"world_value_gte":
			current_value = int(run_state.world_state.values.get(str(gate_check.get("key", "")), 0))
		_:
			current_value = 0

	return {
		"label": label,
		"current_value": current_value,
		"target_value": target_value,
		"passed": current_value >= target_value,
		"description": "%s：当前 %d / 需要 %d" % [label, current_value, target_value]
	}


func _create_preview_run_state() -> RunState:
	return _run_initializer.create_run(
		_selected_run_id,
		META_PROGRESS_SCRIPT.new(),
		_content_repository
	)


func _extract_day_order(definition: Dictionary) -> int:
	var trigger_conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
	for condition: Dictionary in trigger_conditions:
		var condition_type: String = str(condition.get("type", ""))
		if condition_type == "day_range":
			var min_day: int = int(condition.get("min", condition.get("min_day", 0)))
			if min_day > 0:
				return min_day
		elif condition_type == "day_gte":
			var day_value: int = int(condition.get("value", 0))
			if day_value > 0:
				return day_value
	return 99


func _time_slot_order(time_slot: String) -> int:
	match time_slot:
		"morning":
			return 0
		"afternoon":
			return 1
		"night":
			return 2
		"any":
			return 3
		_:
			return 4


func _describe_time_slot(time_slot: String) -> String:
	match time_slot:
		"morning":
			return "晨间"
		"afternoon":
			return "午后"
		"night":
			return "夜间"
		"any":
			return "任意"
		_:
			return time_slot


func _content_category_order(category: String) -> int:
	match category:
		"main_story":
			return 0
		"npc_state":
			return 1
		"location_content":
			return 2
		"random_disturbance":
			return 3
		_:
			return 9


func _describe_event_location(definition: Dictionary) -> String:
	var location_id: String = str(definition.get("location_id", ""))
	if not location_id.is_empty():
		return _describe_location_name(location_id)
	var allowed_locations: Array[String] = Array(definition.get("allowed_locations", []), TYPE_STRING, "", null)
	if allowed_locations.is_empty():
		return "未绑定"
	var display_names: Array[String] = []
	for allowed_location: String in allowed_locations:
		display_names.append(_describe_location_name(allowed_location))
	return " / ".join(display_names)


func _describe_location_name(location_id: String) -> String:
	if location_id.is_empty():
		return "未绑定"
	var location_definition: Dictionary = _content_repository.get_location_definition(location_id)
	if location_definition.is_empty():
		return location_id
	return str(location_definition.get("display_name", location_id))


func _matches_category_filter(definition: Dictionary) -> bool:
	if _selected_category_filter == "all":
		return true
	return str(definition.get("content_category", "")) == _selected_category_filter


func _count_filtered_event_ids(event_ids: Array[String]) -> int:
	var count: int = 0
	for event_id: String in event_ids:
		var definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
		if definition.is_empty():
			continue
		if _matches_category_filter(definition):
			count += 1
	return count


func _count_filtered_location_slots(content_slots: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"fixed_events": 0,
		"investigation_events": 0,
		"random_events": 0
	}
	for slot_name: String in result.keys():
		var event_ids: Array[String] = Array(content_slots.get(slot_name, []), TYPE_STRING, "", null)
		for event_id: String in event_ids:
			var definition: Dictionary = _content_repository.get_story_event_definition(_selected_run_id, event_id)
			if definition.is_empty():
				continue
			if _matches_category_filter(definition):
				result[slot_name] = int(result.get(slot_name, 0)) + 1
	return result


func _describe_flow_target(flow_definition: Dictionary, node_id: String) -> String:
	var nodes: Array[Dictionary] = Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null)
	for node_definition: Dictionary in nodes:
		if str(node_definition.get("id", "")) == node_id:
			return str(node_definition.get("title", node_id))
	return node_id


func _describe_fallback(fallback_endings: Array[Dictionary], fallback_id: String) -> String:
	for fallback_definition: Dictionary in fallback_endings:
		if str(fallback_definition.get("id", "")) == fallback_id:
			return str(fallback_definition.get("label", fallback_id))
	return fallback_id


func _append_requirement_group(lines: Array[String], title: String, values: Array[String]) -> void:
	lines.append("- %s：" % title)
	if values.is_empty():
		lines.append("  - 无")
		return
	for value: String in values:
		lines.append("  - %s" % value)


func _build_support_line(definition: Dictionary, fallback_event_id: String) -> String:
	var title: String = str(definition.get("title", fallback_event_id))
	var location_text: String = _describe_event_location(definition)
	var max_clue_gain: int = _calculate_max_resource_gain(definition, "clue_fragments")
	if max_clue_gain > 0:
		return "%s（%s，最高线索 +%d）" % [title, location_text, max_clue_gain]
	return "%s（%s）" % [title, location_text]


func _build_flag_detail_text(record: Dictionary) -> String:
	var flag_key: String = str(record.get("flag_key", ""))
	var lines: Array[String] = [
		"[b]%s[/b]" % _describe_flag(flag_key),
		"Flag Key：%s" % flag_key,
		"当前初始局面：%s" % ("已成立" if bool(_create_preview_run_state().world_state.global_flags.get(flag_key, false)) else "未成立"),
		""
	]

	_append_flag_event_group(lines, "设置这个标记的内容", Array(record.get("setters", []), TYPE_STRING, "", null))
	_append_flag_event_group(lines, "清除这个标记的内容", Array(record.get("clearers", []), TYPE_STRING, "", null))
	_append_flag_event_group(lines, "需要这个标记的内容", Array(record.get("required_by", []), TYPE_STRING, "", null))
	_append_flag_event_group(lines, "会被这个标记阻断的内容", Array(record.get("blocked_by", []), TYPE_STRING, "", null))

	return "\n".join(lines)


func _append_flag_event_group(lines: Array[String], title: String, values: Array[String]) -> void:
	lines.append("[b]%s[/b]" % title)
	if values.is_empty():
		lines.append("- 无")
		lines.append("")
		return
	for value: String in values:
		lines.append("- %s" % value)
	lines.append("")


func _collect_flag_registry() -> Dictionary:
	var registry: Dictionary = {}
	var all_events: Array[Dictionary] = _content_repository.get_story_event_definitions(_selected_run_id)
	for definition: Dictionary in all_events:
		var title: String = str(definition.get("title", definition.get("id", "")))
		for flag_key: String in Array(definition.get("req_flags", []), TYPE_STRING, "", null):
			_ensure_flag_record(registry, flag_key)["required_by"].append(title)
		for flag_key: String in Array(definition.get("block_flags", []), TYPE_STRING, "", null):
			_ensure_flag_record(registry, flag_key)["blocked_by"].append(title)

		for option_definition: Dictionary in Array(definition.get("options", []), TYPE_DICTIONARY, "", null):
			for effect_definition: Dictionary in Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null):
				var effect_type: String = str(effect_definition.get("type", ""))
				var flag_key_from_effect: String = str(effect_definition.get("key", ""))
				if flag_key_from_effect.is_empty():
					continue
				if effect_type == "set_flag":
					_ensure_flag_record(registry, flag_key_from_effect)["setters"].append(title)
				elif effect_type == "clear_flag":
					_ensure_flag_record(registry, flag_key_from_effect)["clearers"].append(title)

	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(_selected_run_id)
	for node_definition: Dictionary in Array(flow_definition.get("nodes", []), TYPE_DICTIONARY, "", null):
		var node_title: String = "主线节点: %s" % str(node_definition.get("title", node_definition.get("id", "")))
		for flag_key: String in Array(node_definition.get("required_flags", []), TYPE_STRING, "", null):
			_ensure_flag_record(registry, flag_key)["required_by"].append(node_title)
		for resolution_definition: Dictionary in Array(node_definition.get("resolution_checks", []), TYPE_DICTIONARY, "", null):
			var resolution_title: String = "%s / %s" % [node_title, str(resolution_definition.get("label", "收束判定"))]
			for flag_key: String in Array(resolution_definition.get("requires_flags", []), TYPE_STRING, "", null):
				_ensure_flag_record(registry, flag_key)["required_by"].append(resolution_title)

	return registry


func _ensure_flag_record(registry: Dictionary, flag_key: String) -> Dictionary:
	if not registry.has(flag_key):
		registry[flag_key] = {
			"setters": [],
			"clearers": [],
			"required_by": [],
			"blocked_by": []
		}
	return registry[flag_key]


func _calculate_max_resource_gain(definition: Dictionary, resource_key: String) -> int:
	var options: Array[Dictionary] = Array(definition.get("options", []), TYPE_DICTIONARY, "", null)
	var best_gain: int = 0
	for option_definition: Dictionary in options:
		var option_gain: int = 0
		var effects: Array[Dictionary] = Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null)
		for effect_definition: Dictionary in effects:
			if str(effect_definition.get("type", "")) != "modify_resource":
				continue
			if str(effect_definition.get("scope", "")) != "player":
				continue
			if str(effect_definition.get("key", "")) != resource_key:
				continue
			option_gain += int(effect_definition.get("delta", 0))
		best_gain = maxi(best_gain, option_gain)
	return best_gain
