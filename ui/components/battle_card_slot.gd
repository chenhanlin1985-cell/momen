extends PanelContainer

signal selected(slot_index: int)
signal card_dropped(slot_index: int, card_id: String)

var slot_index: int = -1
var accepted_group: String = ""
var is_selected: bool = false

var _title_label: Label

func _ready() -> void:
	_ensure_ui()

func _ensure_ui() -> void:
	if _title_label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(0, 120)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var padding: MarginContainer = MarginContainer.new()
	padding.set_anchors_preset(Control.PRESET_FULL_RECT)
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	add_child(padding)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	padding.add_child(_title_label)

func configure(slot_view: Dictionary) -> void:
	_ensure_ui()
	slot_index = int(slot_view.get("slot_index", -1))
	accepted_group = str(slot_view.get("accepted_group", ""))
	is_selected = bool(slot_view.get("is_selected", false))
	_title_label.text = str(slot_view.get("text", ""))
	_apply_slot_style(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			selected.emit(slot_index)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var can_drop: bool = (
		data is Dictionary
		and str(data.get("type", "")) == "battle_card"
		and not str(data.get("card_id", "")).is_empty()
		and str(data.get("card_group", "")) == accepted_group
	)
	_apply_slot_style(can_drop)
	return can_drop

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	_apply_slot_style(false)
	card_dropped.emit(slot_index, str(data.get("card_id", "")))

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_apply_slot_style(false)

func _apply_slot_style(is_drag_hover: bool) -> void:
	var background: Color = Color("211c28")
	var border: Color = Color("67606e")
	if accepted_group == "02":
		border = Color("d06767")
	elif accepted_group == "01":
		border = Color("66a8d9")
	if is_selected:
		background = background.lightened(0.14)
	if is_drag_hover:
		background = border.darkened(0.65)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.shadow_color = Color(0, 0, 0, 0.3)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("panel", style)
