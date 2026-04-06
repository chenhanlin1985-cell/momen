class_name RouteMapPanel
extends Control

signal node_selected(node_id: String)
signal node_focused(node_view: Dictionary)

const NODE_SIZE := Vector2(188, 88)
const START_NODE_SIZE := Vector2(150, 76)
const GRAPH_PADDING := Vector2(28, 24)
const SECTION_HEADER_HEIGHT := 42.0
const SECTION_GAP_WIDTH := 52.0
const COLUMN_GUIDE_COLOR := Color(0.72, 0.78, 0.86, 0.08)
const ROW_GUIDE_COLOR := Color(0.72, 0.78, 0.86, 0.05)
const VISITED_LINE_COLOR := Color("f3d88a")
const VISITED_NODE_GLOW := Color("fff4bd")
const FUTURE_SECTION_OVERLAY := Color(0.05, 0.06, 0.09, 0.34)
const FUTURE_SECTION_STRIPE := Color(0.85, 0.88, 0.92, 0.05)
const CURRENT_SECTION_BORDER := Color("f2e3ad")

const TERMINAL_THEME := {
	"fill": Color("2f3448"),
	"border": Color("f0d98a"),
	"glow": Color("fff1b8")
}

const NODE_THEME := {
	"story": {"fill": Color("4a342b"), "border": Color("c89a74")},
	"dialogue": {"fill": Color("31404d"), "border": Color("7fa7c7")},
	"reward": {"fill": Color("274435"), "border": Color("7cc19d")},
	"shop": {"fill": Color("4c3728"), "border": Color("d6ab76")},
	"review": {"fill": Color("31364f"), "border": Color("8c92d3")},
	"battle": {"fill": Color("4a2631"), "border": Color("d07a98")},
	"risk": {"fill": Color("4b4731"), "border": Color("d0ba73")}
}

const ROUTE_THEME := {
	"route_records": {"accent": Color("d7b16d"), "line": Color("d6b273"), "tag": "账册线"},
	"route_seek_senior": {"accent": Color("c88386"), "line": Color("d7898a"), "tag": "长老线"},
	"route_well": {"accent": Color("7ea8cf"), "line": Color("8cb7dc"), "tag": "化骨池线"},
	"route_lie_low": {"accent": Color("8ea18a"), "line": Color("9fb095"), "tag": "避锋芒"}
}

const TYPE_ICONS := {
	"story": "线",
	"dialogue": "谈",
	"reward": "利",
	"shop": "市",
	"review": "整",
	"battle": "战",
	"risk": "险"
}

const DAY_SECTION_COLORS := [
	Color(0.18, 0.21, 0.28, 0.34),
	Color(0.16, 0.23, 0.20, 0.34),
	Color(0.24, 0.19, 0.17, 0.34),
	Color(0.17, 0.18, 0.26, 0.34),
	Color(0.22, 0.18, 0.24, 0.34)
]
const DRAG_THRESHOLD := 8.0

var _view_data: Dictionary = {}
var _node_views_by_id: Dictionary = {}
var _node_buttons_by_id: Dictionary = {}
var _base_centers: Dictionary = {}
var _column_centers: Dictionary = {}
var _row_centers: Array[float] = []
var _section_rects: Array[Dictionary] = []
var _content_width: float = 0.0
var _pan_x: float = 0.0
var _dragging: bool = false
var _drag_button_index: int = -1
var _drag_start_mouse_x: float = 0.0
var _drag_start_pan_x: float = 0.0
var _drag_distance: float = 0.0
var _suppress_next_left_click: bool = false
var _pan_tween: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(0, 230)
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_rebuild)

func configure(view_data: Dictionary) -> void:
	var previous_day: int = int(_view_data.get("current_day", -1))
	_view_data = view_data.duplicate(true)
	_reset_drag_state()
	var next_day: int = int(_view_data.get("current_day", -1))
	_rebuild()
	if next_day != previous_day:
		_auto_focus_current_day()

func clear_panel() -> void:
	if _pan_tween != null:
		_pan_tween.kill()
		_pan_tween = null
	_view_data = {}
	_pan_x = 0.0
	_reset_drag_state()
	_rebuild()

func _gui_input(event: InputEvent) -> void:
	if _view_data.is_empty():
		return
	if _handle_pan_input(event, true):
		accept_event()

func _handle_pan_input(event: InputEvent, allow_left_drag: bool) -> bool:
	if event is InputEventMouseButton:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_UP and mouse_button.pressed:
			if _pan_tween != null:
				_pan_tween.kill()
				_pan_tween = null
			_set_pan_x(_pan_x - 120.0)
			return true
		if mouse_button.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse_button.pressed:
			if _pan_tween != null:
				_pan_tween.kill()
				_pan_tween = null
			_set_pan_x(_pan_x + 120.0)
			return true
		var drag_enabled: bool = mouse_button.button_index == MOUSE_BUTTON_RIGHT or mouse_button.button_index == MOUSE_BUTTON_MIDDLE
		if allow_left_drag and mouse_button.button_index == MOUSE_BUTTON_LEFT and _can_start_left_drag():
			drag_enabled = true
		if drag_enabled:
			if mouse_button.pressed:
				if _pan_tween != null:
					_pan_tween.kill()
					_pan_tween = null
				_dragging = true
				_drag_button_index = mouse_button.button_index
				_drag_start_mouse_x = mouse_button.position.x
				_drag_start_pan_x = _pan_x
				_drag_distance = 0.0
				_suppress_next_left_click = false
			elif _dragging and _drag_button_index == mouse_button.button_index:
				if mouse_button.button_index == MOUSE_BUTTON_LEFT and _drag_distance >= DRAG_THRESHOLD:
					_suppress_next_left_click = true
				_dragging = false
				_drag_button_index = -1
			return true
	elif event is InputEventMouseMotion and _dragging:
		var motion: InputEventMouseMotion = event as InputEventMouseMotion
		_drag_distance = max(_drag_distance, absf(motion.position.x - _drag_start_mouse_x))
		if _drag_button_index == MOUSE_BUTTON_LEFT and _drag_distance >= DRAG_THRESHOLD:
			_suppress_next_left_click = true
		_set_pan_x(_drag_start_pan_x - (motion.position.x - _drag_start_mouse_x))
		return true
	return false

func _can_start_left_drag() -> bool:
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	return hovered_control == self

func _reset_drag_state() -> void:
	_dragging = false
	_drag_button_index = -1
	_drag_start_mouse_x = 0.0
	_drag_start_pan_x = _pan_x
	_drag_distance = 0.0
	_suppress_next_left_click = false

func focus_first_selectable_node() -> void:
	for node_view: Dictionary in Array(_view_data.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node_view.get("is_locked", false)):
			continue
		node_focused.emit(node_view.duplicate(true))
		return
	if not Array(_view_data.get("nodes", []), TYPE_DICTIONARY, "", null).is_empty():
		var first_node: Dictionary = Array(_view_data.get("nodes", []), TYPE_DICTIONARY, "", null)[0]
		node_focused.emit(Dictionary(first_node).duplicate(true))

func _rebuild() -> void:
	for child: Node in get_children():
		child.queue_free()
	_reset_drag_state()
	_node_views_by_id.clear()
	_node_buttons_by_id.clear()
	_base_centers.clear()
	_column_centers.clear()
	_row_centers.clear()
	_section_rects.clear()
	_content_width = 0.0

	if _view_data.is_empty():
		visible = false
		queue_redraw()
		return
	visible = true

	var positions: Dictionary = _compute_node_positions()
	_build_section_rects()
	_add_section_headers()

	var start_node: Dictionary = Dictionary(_view_data.get("start_node", {}))
	if not start_node.is_empty() and positions.has("start"):
		_add_node_button(start_node, Rect2(positions["start"], START_NODE_SIZE), false)

	for node_view: Dictionary in Array(_view_data.get("nodes", []), TYPE_DICTIONARY, "", null):
		var node_id: String = str(node_view.get("id", ""))
		if not positions.has(node_id):
			continue
		_add_node_button(node_view, Rect2(positions[node_id], NODE_SIZE), true)

	_apply_pan_x(_pan_x)
	queue_redraw()

func _compute_node_positions() -> Dictionary:
	var positions: Dictionary = {}
	var nodes: Array[Dictionary] = Array(_view_data.get("nodes", []), TYPE_DICTIONARY, "", null)
	var column_ids: Array[int] = []
	var max_lane: int = 0
	for node_view: Dictionary in nodes:
		var column: int = max(int(node_view.get("column", 1)), 1)
		var lane: int = max(int(node_view.get("lane", 0)), 0)
		if not column_ids.has(column):
			column_ids.append(column)
		max_lane = max(max_lane, lane)
	column_ids.sort()

	var graph_height: float = max(size.y - GRAPH_PADDING.y * 2.0 - SECTION_HEADER_HEIGHT, 220.0)
	var row_count: int = max(max_lane + 1, 1)
	var step_y: float = graph_height / float(row_count + 1)
	for row_index: int in row_count:
		_row_centers.append(GRAPH_PADDING.y + SECTION_HEADER_HEIGHT + step_y * float(row_index + 1))

	var start_position: Vector2 = Vector2(
		GRAPH_PADDING.x,
		GRAPH_PADDING.y + SECTION_HEADER_HEIGHT + graph_height * 0.5 - START_NODE_SIZE.y * 0.5
	)
	positions["start"] = start_position
	_column_centers[0] = start_position.x + START_NODE_SIZE.x * 0.5
	_base_centers["start"] = start_position + START_NODE_SIZE * 0.5

	var column_x: float = GRAPH_PADDING.x + START_NODE_SIZE.x + 56.0
	for column: int in column_ids:
		_column_centers[column] = column_x + NODE_SIZE.x * 0.5
		for node_view: Dictionary in nodes:
			if int(node_view.get("column", 1)) != column:
				continue
			var node_id: String = str(node_view.get("id", ""))
			var lane: int = clamp(int(node_view.get("lane", 0)), 0, _row_centers.size() - 1)
			var top_left: Vector2 = Vector2(column_x, _row_centers[lane] - NODE_SIZE.y * 0.5)
			positions[node_id] = top_left
			_base_centers[node_id] = top_left + NODE_SIZE * 0.5
		column_x += NODE_SIZE.x + SECTION_GAP_WIDTH

	_content_width = max(column_x + GRAPH_PADDING.x, size.x)
	return positions

func _build_section_rects() -> void:
	for section: Dictionary in Array(_view_data.get("day_sections", []), TYPE_DICTIONARY, "", null):
		var start_column: int = int(section.get("start_column", 1))
		var end_column: int = int(section.get("end_column", start_column))
		if not _column_centers.has(start_column) or not _column_centers.has(end_column):
			continue
		var left: float = float(_column_centers[start_column]) - NODE_SIZE.x * 0.5 - 20.0
		var right: float = float(_column_centers[end_column]) + NODE_SIZE.x * 0.5 + 20.0
		_section_rects.append({
			"day": int(section.get("day", 0)),
			"title": str(section.get("title", "")),
			"is_current": bool(section.get("is_current", false)),
			"is_future": int(section.get("day", 0)) > int(_view_data.get("current_day", 0)),
			"rect": Rect2(
				Vector2(left, GRAPH_PADDING.y),
				Vector2(max(right - left, 120.0), size.y - GRAPH_PADDING.y * 2.0)
			)
		})

func _add_section_headers() -> void:
	for section: Dictionary in _section_rects:
		var rect: Rect2 = Rect2(section.get("rect", Rect2()))
		var day: int = int(section.get("day", 0))
		var title: String = str(section.get("title", ""))
		var label: Label = Label.new()
		label.set_meta("base_position", rect.position + Vector2(14.0, 10.0))
		label.size = Vector2(max(rect.size.x - 28.0, 120.0), 28.0)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14 if bool(section.get("is_current", false)) else 12)
		label.add_theme_color_override("font_color", Color("eef2f6") if bool(section.get("is_current", false)) else Color("c9d1d8"))
		var header_text: String = "第%d天" % day
		if not title.is_empty():
			header_text += "  %s" % title
		if bool(section.get("is_current", false)):
			header_text += "  [当前]"
		elif bool(section.get("is_future", false)):
			header_text += "  [预览]"
		else:
			header_text += "  [已过]"
		label.text = header_text
		add_child(label)

func _add_node_button(node_view: Dictionary, rect: Rect2, is_selectable: bool) -> void:
	var button: Button = Button.new()
	button.size = rect.size
	button.set_meta("base_position", rect.position)
	button.set_meta("focus_state", str(node_view.get("focus_state", "neutral")))
	button.set_meta("is_locked", bool(node_view.get("is_locked", false)))
	button.set_meta("route_key", str(node_view.get("route_key", "")))
	button.set_meta("target_kind", str(node_view.get("target_kind", "action")))
	button.set_meta("is_terminal", bool(node_view.get("is_terminal", false)))
	button.set_meta("is_past_day", bool(node_view.get("is_past_day", false)))
	button.set_meta("is_future_day", bool(node_view.get("is_future_day", false)))
	button.set_meta("is_completed", bool(node_view.get("is_completed", false)))
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.text = _build_node_text(node_view)
	var node_type: String = str(node_view.get("node_type", "story"))
	var is_locked: bool = bool(node_view.get("is_locked", false))
	_apply_button_theme(button, node_type, not is_selectable or is_locked, bool(node_view.get("is_route_active", false)))
	button.gui_input.connect(_on_node_button_gui_input.bind(str(node_view.get("id", ""))))
	button.mouse_entered.connect(_on_node_button_focused.bind(node_view.duplicate(true)))
	button.focus_entered.connect(_on_node_button_focused.bind(node_view.duplicate(true)))
	if is_selectable and not is_locked:
		button.pressed.connect(_on_node_button_pressed.bind(str(node_view.get("id", ""))))
	else:
		button.disabled = true
	add_child(button)
	var node_id: String = str(node_view.get("id", "start"))
	_node_buttons_by_id[node_id] = button
	_node_views_by_id[node_id] = node_view.duplicate(true)

func _build_node_text(node_view: Dictionary) -> String:
	var lines: Array[String] = []
	var node_type: String = str(node_view.get("node_type", "story"))
	var type_label: String = str(node_view.get("type_label", "节点"))
	var type_icon: String = str(TYPE_ICONS.get(node_type, "点"))
	var route_key: String = str(node_view.get("route_key", ""))
	var route_tag: String = str(ROUTE_THEME.get(route_key, {}).get("tag", ""))
	var header: String = "[%s %s]" % [type_icon, type_label]
	if not route_tag.is_empty():
		header += " [%s]" % route_tag
	lines.append(header)

	if bool(node_view.get("is_terminal", false)):
		lines.append("路线终点")
	elif bool(node_view.get("is_completed", false)):
		lines.append("已走过")
	elif bool(node_view.get("is_future_day", false)):
		lines.append("后续天数")
	elif bool(node_view.get("is_past_day", false)):
		lines.append("已过去")

	var route_label: String = str(node_view.get("route_label", ""))
	if not route_label.is_empty():
		lines.append("路线：%s" % route_label)
	lines.append(str(node_view.get("title", "")))

	var hint: String = str(node_view.get("hint", ""))
	if not hint.is_empty():
		lines.append(hint)

	var lock_reason_text: String = str(node_view.get("lock_reason_text", ""))
	if not lock_reason_text.is_empty():
		lines.append(lock_reason_text)
	return "\n".join(lines)

func _apply_button_theme(button: Button, node_type: String, muted: bool, is_route_active: bool) -> void:
	var theme: Dictionary = Dictionary(NODE_THEME.get(node_type, NODE_THEME["story"]))
	var fill_color: Color = Color(theme.get("fill", Color("4a342b")))
	var border_color: Color = Color(theme.get("border", Color("c89a74")))
	var focus_state: String = str(button.get_meta("focus_state", "neutral"))
	var is_locked: bool = bool(button.get_meta("is_locked", false))
	var is_terminal: bool = bool(button.get_meta("is_terminal", false))
	var is_past_day: bool = bool(button.get_meta("is_past_day", false))
	var is_future_day: bool = bool(button.get_meta("is_future_day", false))
	var is_completed: bool = bool(button.get_meta("is_completed", false))
	var route_key: String = str(button.get_meta("route_key", ""))
	var route_theme: Dictionary = Dictionary(ROUTE_THEME.get(route_key, {}))

	if is_terminal:
		fill_color = Color(TERMINAL_THEME.get("fill", fill_color))
		border_color = Color(TERMINAL_THEME.get("border", border_color))
	elif not route_theme.is_empty():
		border_color = border_color.lerp(Color(route_theme.get("accent", border_color)), 0.45)
		fill_color = fill_color.lerp(Color(route_theme.get("accent", fill_color)).darkened(0.6), 0.12)

	if is_route_active:
		fill_color = fill_color.lightened(0.12)
		border_color = Color("f3d88a")
	elif focus_state == "off_route":
		fill_color = fill_color.darkened(0.12)
		border_color = border_color.darkened(0.28)

	if is_past_day or is_completed:
		fill_color = fill_color.darkened(0.10)
		border_color = border_color.darkened(0.12)
	if is_future_day:
		fill_color = fill_color.darkened(0.18)
		border_color = border_color.darkened(0.20)
	if is_locked:
		fill_color = fill_color.darkened(0.24)
		border_color = Color("9f98a8")
	if muted:
		fill_color = fill_color.darkened(0.18)
		border_color = border_color.darkened(0.18)

	var normal: StyleBoxFlat = StyleBoxFlat.new()
	normal.bg_color = fill_color
	normal.border_color = border_color
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 16
	normal.corner_radius_top_right = 16
	normal.corner_radius_bottom_left = 16
	normal.corner_radius_bottom_right = 16
	normal.content_margin_left = 12
	normal.content_margin_top = 10
	normal.content_margin_right = 12
	normal.content_margin_bottom = 10
	if is_terminal:
		normal.shadow_size = 8
		normal.shadow_color = Color(TERMINAL_THEME.get("glow", Color("fff1b8")), 0.18)
	elif is_completed:
		normal.shadow_size = 6
		normal.shadow_color = Color(VISITED_NODE_GLOW, 0.16)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = fill_color.lightened(0.08)
	if is_terminal:
		hover.shadow_color = Color(TERMINAL_THEME.get("glow", Color("fff1b8")), 0.28)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_color_override("font_color", Color("f3eee2"))
	button.add_theme_color_override("font_disabled_color", Color("d9d3c7"))
	button.add_theme_font_size_override("font_size", 14)

func _set_pan_x(value: float) -> void:
	_apply_pan_x(value)
	queue_redraw()

func _animate_pan_to(value: float) -> void:
	var max_pan: float = max(_content_width - size.x, 0.0)
	var target_pan: float = clamp(value, 0.0, max_pan)
	if is_equal_approx(target_pan, _pan_x):
		_set_pan_x(target_pan)
		return
	if _pan_tween != null:
		_pan_tween.kill()
	_pan_tween = create_tween()
	_pan_tween.set_trans(Tween.TRANS_SINE)
	_pan_tween.set_ease(Tween.EASE_OUT)
	_pan_tween.tween_method(_set_pan_x, _pan_x, target_pan, 0.24)
	_pan_tween.finished.connect(func() -> void:
		_pan_tween = null
	)

func _apply_pan_x(value: float) -> void:
	var max_pan: float = max(_content_width - size.x, 0.0)
	_pan_x = clamp(value, 0.0, max_pan)
	for child: Node in get_children():
		if not (child is Control):
			continue
		var control: Control = child as Control
		var base_position: Variant = control.get_meta("base_position", null)
		if base_position == null:
			continue
		control.position = Vector2(base_position) - Vector2(_pan_x, 0.0)

func _auto_focus_current_day() -> void:
	var current_day: int = int(_view_data.get("current_day", -1))
	if current_day < 0:
		return
	for section: Dictionary in _section_rects:
		if int(section.get("day", -1)) != current_day:
			continue
		var rect: Rect2 = Rect2(section.get("rect", Rect2()))
		var desired_pan: float = rect.position.x + rect.size.x * 0.5 - size.x * 0.5
		_animate_pan_to(desired_pan)
		return

func _is_edge_visited(from_id: String, to_id: String) -> bool:
	var visited_node_ids: Array[String] = Array(_view_data.get("visited_node_ids", []), TYPE_STRING, "", null)
	if visited_node_ids.is_empty():
		return false
	var to_index: int = visited_node_ids.find(to_id)
	if to_index < 0:
		return false
	if to_index == 0:
		return from_id == "start"
	return visited_node_ids[to_index - 1] == from_id

func _on_node_button_pressed(node_id: String) -> void:
	if _suppress_next_left_click:
		_suppress_next_left_click = false
		return
	node_selected.emit(node_id)

func _on_node_button_focused(node_view: Dictionary) -> void:
	node_focused.emit(node_view.duplicate(true))

func _on_node_button_gui_input(event: InputEvent, _node_id: String) -> void:
	if _handle_pan_input(event, false):
		accept_event()

func _draw() -> void:
	if _view_data.is_empty():
		return

	for section: Dictionary in _section_rects:
		var rect: Rect2 = Rect2(section.get("rect", Rect2()))
		var color_index: int = max(int(section.get("day", 1)) - 1, 0) % DAY_SECTION_COLORS.size()
		var fill_color: Color = DAY_SECTION_COLORS[color_index]
		if bool(section.get("is_current", false)):
			fill_color = fill_color.lightened(0.08)
		var draw_rect_data := Rect2(Vector2(rect.position.x - _pan_x, rect.position.y), rect.size)
		draw_rect(draw_rect_data, fill_color, true)
		if bool(section.get("is_future", false)):
			draw_rect(draw_rect_data, FUTURE_SECTION_OVERLAY, true)
			var stripe_x: float = draw_rect_data.position.x - draw_rect_data.size.y
			while stripe_x < draw_rect_data.position.x + draw_rect_data.size.x:
				draw_line(
					Vector2(stripe_x, draw_rect_data.position.y + draw_rect_data.size.y),
					Vector2(stripe_x + draw_rect_data.size.y * 0.6, draw_rect_data.position.y),
					FUTURE_SECTION_STRIPE,
					2.0,
					true
				)
				stripe_x += 26.0
		var border_color: Color = fill_color.lightened(0.18)
		var border_width: float = 2.0
		if bool(section.get("is_current", false)):
			border_color = CURRENT_SECTION_BORDER
			border_width = 3.0
		draw_rect(draw_rect_data, border_color, false, border_width, true)
		draw_line(
			Vector2(draw_rect_data.position.x, draw_rect_data.position.y + SECTION_HEADER_HEIGHT),
			Vector2(draw_rect_data.position.x + draw_rect_data.size.x, draw_rect_data.position.y + SECTION_HEADER_HEIGHT),
			border_color.lightened(0.08),
			2.0,
			true
		)

	for row_center: float in _row_centers:
		draw_line(
			Vector2(GRAPH_PADDING.x, row_center),
			Vector2(size.x - GRAPH_PADDING.x, row_center),
			ROW_GUIDE_COLOR,
			1.0,
			true
		)

	for column: int in _column_centers.keys():
		if column <= 0:
			continue
		var x: float = float(_column_centers[column]) - _pan_x
		draw_line(
			Vector2(x, GRAPH_PADDING.y + SECTION_HEADER_HEIGHT * 0.8),
			Vector2(x, size.y - GRAPH_PADDING.y),
			COLUMN_GUIDE_COLOR,
			1.0,
			true
		)

	for edge: Dictionary in Array(_view_data.get("edges", []), TYPE_DICTIONARY, "", null):
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))
		if not _base_centers.has(from_id) or not _base_centers.has(to_id):
			continue
		var from_point: Vector2 = Vector2(_base_centers[from_id]) - Vector2(_pan_x, 0.0)
		var to_point: Vector2 = Vector2(_base_centers[to_id]) - Vector2(_pan_x, 0.0)
		var to_node_view: Dictionary = Dictionary(_node_views_by_id.get(to_id, {}))
		var route_key: String = str(to_node_view.get("route_key", ""))
		var line_color: Color = Color("89a3b7")
		if ROUTE_THEME.has(route_key):
			line_color = Color(ROUTE_THEME.get(route_key, {}).get("line", line_color))
		if bool(to_node_view.get("is_terminal", false)):
			line_color = Color(TERMINAL_THEME.get("border", line_color))
		if bool(to_node_view.get("is_future_day", false)):
			line_color = line_color.darkened(0.18)
		if bool(to_node_view.get("is_locked", false)):
			line_color = line_color.darkened(0.24)
		var is_visited_edge: bool = _is_edge_visited(from_id, to_id)
		if is_visited_edge:
			line_color = VISITED_LINE_COLOR
		var mid_x: float = lerp(from_point.x, to_point.x, 0.5)
		draw_polyline_colors(
			PackedVector2Array([from_point, Vector2(mid_x, from_point.y), Vector2(mid_x, to_point.y), to_point]),
			PackedColorArray([line_color, line_color, line_color, line_color]),
			4.0 if is_visited_edge else 3.0,
			true
		)
		draw_circle(to_point, 4.0, line_color.lightened(0.18))
