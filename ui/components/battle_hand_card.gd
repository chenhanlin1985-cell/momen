extends PanelContainer

signal activated(card_ref: String)

var card_ref: String = ""
var card_id: String = ""
var card_group: String = ""

var _name_label: Label
var _meta_label: Label
var _description_label: Label

func _ready() -> void:
	_ensure_ui()

func _ensure_ui() -> void:
	if _name_label != null and _meta_label != null and _description_label != null:
		return
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	custom_minimum_size = Vector2(170, 220)
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var padding: MarginContainer = MarginContainer.new()
	padding.set_anchors_preset(Control.PRESET_FULL_RECT)
	padding.add_theme_constant_override("margin_left", 12)
	padding.add_theme_constant_override("margin_top", 12)
	padding.add_theme_constant_override("margin_right", 12)
	padding.add_theme_constant_override("margin_bottom", 12)
	add_child(padding)

	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	padding.add_child(content)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_name_label)

	_meta_label = Label.new()
	_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_meta_label)

	_description_label = Label.new()
	_description_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_description_label)

func configure(card_view: Dictionary) -> void:
	_ensure_ui()
	card_ref = str(card_view.get("card_ref", card_view.get("card_id", "")))
	card_id = str(card_view.get("card_id", ""))
	card_group = str(card_view.get("card_group", ""))
	_name_label.text = str(card_view.get("text", card_id))
	var meta_parts: Array[String] = []
	var role_text: String = str(card_view.get("role_text", ""))
	if not role_text.is_empty():
		meta_parts.append(role_text)
	var cost_text: String = str(card_view.get("cost_text", ""))
	if not cost_text.is_empty():
		meta_parts.append(cost_text)
	_meta_label.text = "  ".join(meta_parts)
	_description_label.text = str(card_view.get("description", ""))
	tooltip_text = str(card_view.get("detail_text", ""))
	_apply_card_style()

func _apply_card_style() -> void:
	var background: Color = Color("2a2231")
	var border: Color = Color("7a6076")
	if card_group == "02":
		background = Color("3a1f22")
		border = Color("d06767")
	elif card_group == "01":
		background = Color("1d2b38")
		border = Color("66a8d9")
	add_theme_stylebox_override("panel", _make_panel_style(background, border))

func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
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
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 4)
	return style

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			activated.emit(card_ref)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if card_ref.is_empty():
		return null
	var preview_panel: PanelContainer = PanelContainer.new()
	preview_panel.custom_minimum_size = Vector2(160, 96)
	var preview_padding: MarginContainer = MarginContainer.new()
	preview_padding.add_theme_constant_override("margin_left", 10)
	preview_padding.add_theme_constant_override("margin_top", 10)
	preview_padding.add_theme_constant_override("margin_right", 10)
	preview_padding.add_theme_constant_override("margin_bottom", 10)
	preview_panel.add_child(preview_padding)
	var preview_label: Label = Label.new()
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.text = _name_label.text
	preview_padding.add_child(preview_label)
	set_drag_preview(preview_panel)
	return {
		"type": "battle_card",
		"card_ref": card_ref,
		"card_id": card_id,
		"card_group": card_group
	}
