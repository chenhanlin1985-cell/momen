@tool
extends Control

const BUILDER_SCRIPT := preload("res://tools/story_graph/story_graph_builder.gd")
const VALIDATOR_SCRIPT := preload("res://tools/story_graph/story_graph_validator.gd")

@onready var _event_list: ItemList = $MarginContainer/RootSplit/LeftPanel/EventList
@onready var _warning_list: ItemList = $MarginContainer/RootSplit/LeftPanel/WarningList
@onready var _graph_edit: GraphEdit = $MarginContainer/RootSplit/CenterPanel
@onready var _detail_label: RichTextLabel = $MarginContainer/RootSplit/RightPanel/DetailLabel

var _graph_data: Dictionary = {}
var _node_lookup: Dictionary = {}
var _ordered_ids: Array[String] = []

func _ready() -> void:
	_reload_graph()

func _on_reload_button_pressed() -> void:
	_reload_graph()

func _on_event_list_item_selected(index: int) -> void:
	if index < 0 or index >= _ordered_ids.size():
		return
	_focus_event(_ordered_ids[index])

func _on_warning_list_item_selected(index: int) -> void:
	if index < 0 or index >= _warning_list.item_count:
		return
	var metadata: Variant = _warning_list.get_item_metadata(index)
	if metadata is String and _graph_data.get("nodes", {}).has(metadata):
		_focus_event(str(metadata))

func _reload_graph() -> void:
	var builder = BUILDER_SCRIPT.new()
	var validator = VALIDATOR_SCRIPT.new()
	_graph_data = builder.build_graph()
	_node_lookup.clear()
	_ordered_ids.clear()

	var ordered_variants: Array = _graph_data.get("ordered_ids", [])
	for item: Variant in ordered_variants:
		_ordered_ids.append(str(item))

	_rebuild_event_list()
	_rebuild_warnings(validator.validate(_graph_data))
	_rebuild_graph()

	if not _ordered_ids.is_empty():
		_focus_event(_ordered_ids[0])
	else:
		_detail_label.text = "[b]未找到事件。[/b]"

func _rebuild_event_list() -> void:
	_event_list.clear()
	for event_id: String in _ordered_ids:
		var node_data: Dictionary = _graph_data.get("nodes", {}).get(event_id, {})
		var label: String = "Day %d | %s | %s" % [
			int(node_data.get("day_min", 0)),
			_describe_phase(str(node_data.get("phase", "unknown"))),
			event_id
		]
		_event_list.add_item(label)
		_event_list.set_item_metadata(_event_list.item_count - 1, event_id)

func _rebuild_warnings(warnings: Array[String]) -> void:
	_warning_list.clear()
	for warning: String in warnings:
		_warning_list.add_item(warning)
		_warning_list.set_item_metadata(_warning_list.item_count - 1, _extract_event_id_from_warning(warning))

func _rebuild_graph() -> void:
	for child: Node in _graph_edit.get_children():
		if child is GraphElement:
			child.queue_free()

	for connection: Dictionary in _graph_edit.get_connection_list():
		_graph_edit.disconnect_node(
			str(connection.get("from_node", "")),
			int(connection.get("from_port", 0)),
			str(connection.get("to_node", "")),
			int(connection.get("to_port", 0))
		)

	for event_id: String in _ordered_ids:
		var node_data: Dictionary = _graph_data.get("nodes", {}).get(event_id, {})
		var graph_node: GraphNode = _build_graph_node(node_data)
		_graph_edit.add_child(graph_node)
		_node_lookup[event_id] = graph_node

	for event_id: String in _ordered_ids:
		var node_data: Dictionary = _graph_data.get("nodes", {}).get(event_id, {})
		for edge: Dictionary in node_data.get("edges", []):
			var target_id: String = str(edge.get("to_id", ""))
			if not _node_lookup.has(target_id):
				continue
			_graph_edit.connect_node(event_id, 0, target_id, 0)

func _build_graph_node(node_data: Dictionary) -> GraphNode:
	var graph_node: GraphNode = GraphNode.new()
	graph_node.name = str(node_data.get("id", ""))
	graph_node.title = "%s | Day %d | %s" % [
		str(node_data.get("title", "")),
		int(node_data.get("day_min", 0)),
		_describe_phase(str(node_data.get("phase", "unknown")))
	]
	graph_node.position_offset = node_data.get("position", Vector2.ZERO)
	graph_node.resizable = true
	graph_node.custom_minimum_size = Vector2(260, 150)

	var container: VBoxContainer = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var id_label: Label = Label.new()
	id_label.text = str(node_data.get("id", ""))
	id_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(id_label)

	var desc_label: Label = Label.new()
	desc_label.text = str(node_data.get("description", ""))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.clip_text = true
	container.add_child(desc_label)

	var effect_label: Label = Label.new()
	effect_label.text = _build_node_summary_text(node_data)
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(effect_label)

	graph_node.add_child(container)
	graph_node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	return graph_node

func _focus_event(event_id: String) -> void:
	var node_data: Dictionary = _graph_data.get("nodes", {}).get(event_id, {})
	if node_data.is_empty():
		_detail_label.text = ""
		return

	_select_list_item(event_id)
	_select_graph_node(event_id)
	_detail_label.text = _build_detail_text(node_data)

func _build_detail_text(node_data: Dictionary) -> String:
	var lines: Array[String] = [
		"[b]%s[/b]" % str(node_data.get("title", "")),
		"事件ID：%s" % str(node_data.get("id", "")),
		"天数：%d-%d" % [int(node_data.get("day_min", 0)), int(node_data.get("day_max", 0))],
		"阶段：%s" % _describe_phase(str(node_data.get("phase", "unknown"))),
		"优先级：%d | 可重复：%s" % [
			int(node_data.get("priority", 0)),
			"是" if bool(node_data.get("repeatable", false)) else "否"
		],
		"",
		"[b]说明[/b]",
		str(node_data.get("description", "")),
		"",
		"[b]触发条件[/b]"
	]

	for condition: Dictionary in node_data.get("trigger_conditions", []):
		lines.append("- " + JSON.stringify(condition))

	lines.append("")
	lines.append("[b]选项与效果[/b]")
	for summary: String in node_data.get("effect_summary", []):
		lines.append("- " + summary)

	lines.append("")
	lines.append("[b]后续连接[/b]")
	var edges: Array[Dictionary] = node_data.get("edges", [])
	if edges.is_empty():
		lines.append("- 没有显式 add_followup_event 连接")
	else:
		for edge: Dictionary in edges:
			lines.append("- %s -> %s" % [str(edge.get("label", "")), str(edge.get("to_id", ""))])

	return "\n".join(lines)

func _build_node_summary_text(node_data: Dictionary) -> String:
	var edges: Array[Dictionary] = node_data.get("edges", [])
	if not edges.is_empty():
		return "后续：%s" % ", ".join(_extract_edge_targets(edges))
	return "没有显式后续事件"

func _extract_edge_targets(edges: Array[Dictionary]) -> Array[String]:
	var targets: Array[String] = []
	for edge: Dictionary in edges:
		targets.append(str(edge.get("to_id", "")))
	return targets

func _select_list_item(event_id: String) -> void:
	for i: int in range(_event_list.item_count):
		if str(_event_list.get_item_metadata(i)) != event_id:
			continue
		_event_list.select(i)
		_event_list.ensure_current_is_visible()
		return

func _select_graph_node(event_id: String) -> void:
	for node_name: String in _node_lookup.keys():
		var graph_node: GraphNode = _node_lookup[node_name]
		graph_node.selected = node_name == event_id

func _describe_phase(phase: String) -> String:
	var labels: Dictionary = {
		"morning": "晨间",
		"day": "白天行动",
		"night": "夜间异常",
		"closing": "收束",
		"unknown": "未知"
	}
	return str(labels.get(phase, phase))

func _extract_event_id_from_warning(warning: String) -> String:
	var parts: PackedStringArray = warning.split(" ")
	if parts.size() < 2:
		return ""
	return parts[1]
