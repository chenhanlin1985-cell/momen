class_name DialogueEventPanel
extends Control

const GAME_TEXT := preload("res://systems/content/game_text.gd")

signal option_selected(option_id: String)
signal dialogue_finished

@onready var _dialogue_row: Control = %DialogueRow
@onready var _dialogue_portrait_panel: PanelContainer = %DialoguePortraitPanel
@onready var _dialogue_stage_shade: ColorRect = %DialogueStageShade
@onready var _dialogue_speech_panel: PanelContainer = %DialogueSpeechPanel
@onready var _dialogue_options_panel: PanelContainer = %DialogueOptionsPanel
@onready var _dialogue_portrait_texture: TextureRect = %DialoguePortraitTexture
@onready var _dialogue_portrait_label: Label = %DialoguePortraitLabel
@onready var _dialogue_type_label: Label = %DialogueTypeLabel
@onready var _dialogue_speaker_label: Label = %DialogueSpeakerLabel
@onready var _dialogue_role_label: Label = %DialogueRoleLabel
@onready var _dialogue_body_label: Label = %DialogueBodyLabel
@onready var _dialogue_hint_label: Label = %DialogueHintLabel
@onready var _dialogue_page_label: Label = %DialoguePageLabel
@onready var _dialogue_intrusion_label: Label = %DialogueIntrusionLabel
@onready var _dialogue_options_title: Label = %DialogueOptionsTitle
@onready var _dialogue_options_scroll: ScrollContainer = %DialogueOptionsScroll
@onready var _dialogue_options_container: VBoxContainer = %DialogueOptionsContainer

var _active_event_id: String = ""
var _npc_theme: Dictionary = {}

func _ready() -> void:
	_apply_visual_theme()
	clear_panel()

func configure(
	event_definition: Dictionary,
	option_views: Array[Dictionary],
	npc_theme: Dictionary,
	_dialogue_extra_game_states: Array = []
) -> void:
	visible = true
	_active_event_id = str(event_definition.get("id", ""))
	_npc_theme = npc_theme.duplicate(true)
	_dialogue_page_label.text = ""
	_dialogue_body_label.visible_characters = -1
	_render_dialogue_event(event_definition, option_views)

func clear_panel() -> void:
	visible = false
	_active_event_id = ""
	_dialogue_speaker_label.text = ""
	_dialogue_role_label.text = ""
	_dialogue_body_label.text = ""
	_dialogue_body_label.visible_characters = -1
	_dialogue_hint_label.text = ""
	_dialogue_page_label.text = ""
	_dialogue_intrusion_label.text = ""
	_dialogue_options_title.text = ""
	_dialogue_options_title.visible = false
	_reset_body_scroll()
	_reset_options_scroll()
	_dialogue_portrait_texture.texture = null
	_dialogue_portrait_texture.visible = false
	_dialogue_portrait_label.visible = true
	_dialogue_portrait_label.text = GAME_TEXT.text("dialogue_panel.portrait_placeholder")
	for child: Node in _dialogue_options_container.get_children():
		child.queue_free()

func _render_dialogue_event(event_definition: Dictionary, option_views: Array[Dictionary]) -> void:
	var speaker_name: String = str(
		event_definition.get("speaker_display_name", event_definition.get("title", GAME_TEXT.text("dialogue_panel.default_speaker")))
	)
	var portrait_text: String = str(
		event_definition.get(
			"speaker_portrait_placeholder",
			GAME_TEXT.format_text("dialogue_panel.portrait_placeholder", [speaker_name])
		)
	)
	var portrait_path: String = str(event_definition.get("speaker_portrait_path", ""))
	var body_text: String = str(event_definition.get("description", ""))
	var awaiting_continue: bool = _to_bool(event_definition.get("awaiting_continue", false))
	if awaiting_continue:
		body_text = str(event_definition.get("result_text", body_text))
	elif not Dictionary(event_definition.get("dialogue_encounter", {})).is_empty():
		body_text = _resolve_dialogue_body_text(event_definition, body_text)

	_render_dialogue_header(event_definition, speaker_name, body_text, portrait_text, portrait_path)

	for child: Node in _dialogue_options_container.get_children():
		child.queue_free()

	if awaiting_continue:
		_dialogue_hint_label.text = GAME_TEXT.text("dialogue_panel.continue_hint")
		_dialogue_options_title.text = ""
		_dialogue_options_title.visible = false
		var continue_button: Button = Button.new()
		_style_button(continue_button, 42, "event")
		continue_button.text = GAME_TEXT.text("dialogue_panel.continue_button")
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		continue_button.custom_minimum_size = Vector2(0, 42)
		continue_button.pressed.connect(_emit_dialogue_finished)
		_dialogue_options_container.add_child(continue_button)
		_reset_options_scroll()
		return

	_dialogue_hint_label.text = GAME_TEXT.text("dialogue_panel.responses_hint")
	_dialogue_options_title.text = GAME_TEXT.text("dialogue_panel.responses_title")
	_dialogue_options_title.visible = false
	if not Dictionary(event_definition.get("dialogue_encounter", {})).is_empty():
		var mode: String = str(event_definition.get("dialogue_mode", "hub"))
		match mode:
			"hub":
				_dialogue_hint_label.text = GAME_TEXT.text("dialogue_panel.hub_hint")
				_dialogue_options_title.text = GAME_TEXT.text("dialogue_panel.hub_title")
			"intrude":
				_dialogue_hint_label.text = GAME_TEXT.text("dialogue_panel.intrude_hint")
				_dialogue_options_title.text = GAME_TEXT.text("dialogue_panel.intrude_title")
			"talk":
				_dialogue_hint_label.text = GAME_TEXT.text("dialogue_panel.talk_hint")
				_dialogue_options_title.text = GAME_TEXT.text("dialogue_panel.talk_title")

	for option_view: Dictionary in option_views:
		_dialogue_options_container.add_child(_build_option_card(option_view))
	_reset_options_scroll()

func _emit_dialogue_finished() -> void:
	dialogue_finished.emit()

func _render_dialogue_header(
	event_definition: Dictionary,
	speaker_name: String,
	body_text: String,
	portrait_text: String = "",
	portrait_path: String = ""
) -> void:
	var npc_color: Color = _npc_theme.get("color", Color("72808c"))
	var role_text: String = str(_npc_theme.get("role", GAME_TEXT.text("main_screen.npc_roles.default")))
	var intrusion_label_text: String = _resolve_intrusion_status_label(event_definition)
	var resolved_portrait_text: String = portrait_text if not portrait_text.is_empty() else GAME_TEXT.format_text(
		"dialogue_panel.portrait_placeholder",
		[speaker_name]
	)

	_dialogue_type_label.text = GAME_TEXT.text("dialogue_panel.dialogue_type")
	_dialogue_speaker_label.text = speaker_name
	_dialogue_role_label.text = role_text
	_dialogue_intrusion_label.text = intrusion_label_text
	_dialogue_body_label.text = body_text
	_dialogue_body_label.visible_characters = -1
	_reset_body_scroll()
	_dialogue_portrait_label.text = resolved_portrait_text
	_dialogue_portrait_texture.texture = null
	_dialogue_portrait_texture.visible = false
	_dialogue_portrait_label.visible = true

	if not portrait_path.is_empty() and ResourceLoader.exists(portrait_path):
		var portrait_texture: Texture2D = load(portrait_path)
		if portrait_texture != null:
			_dialogue_portrait_texture.texture = portrait_texture
			_dialogue_portrait_texture.visible = true
			_dialogue_portrait_label.visible = false

	_dialogue_portrait_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0)
	)
	_dialogue_stage_shade.color = npc_color.darkened(0.85)
	_dialogue_stage_shade.color.a = 0.38
	_dialogue_speaker_label.add_theme_color_override("font_color", npc_color.lightened(0.35))
	_dialogue_role_label.add_theme_color_override("font_color", npc_color.lightened(0.18))

func _emit_option(option_id: String) -> void:
	option_selected.emit(option_id)

func _build_option_card(option_view: Dictionary) -> Control:
	if _to_bool(option_view.get("is_continue", false)):
		var continue_button: Button = Button.new()
		_style_button(continue_button, 42, "npc")
		continue_button.custom_minimum_size = Vector2(0, 42)
		continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		continue_button.text = str(option_view.get("text", GAME_TEXT.text("dialogue_panel.continue_button")))
		continue_button.tooltip_text = _compose_option_meta(option_view)
		continue_button.pressed.connect(_emit_option.bind(str(option_view.get("id", ""))))
		return continue_button

	var button: Button = Button.new()
	var button_kind: String = "event" if _to_bool(option_view.get("is_stage_action", false)) else "npc"
	_style_button(button, 42, button_kind)
	button.custom_minimum_size = Vector2(0, 42)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = str(option_view.get("text", option_view.get("id", "")))
	button.disabled = not _to_bool(option_view.get("is_available", false))
	button.tooltip_text = _compose_option_meta(option_view)
	button.pressed.connect(_emit_option.bind(str(option_view.get("id", ""))))
	return button

func _compose_option_meta(option_view: Dictionary) -> String:
	var lines: Array[String] = []
	var header_parts: Array[String] = []
	var check_tag_text: String = str(option_view.get("check_tag_text", "")).strip_edges()
	if not check_tag_text.is_empty():
		header_parts.append(check_tag_text)
	var difficulty_text: String = str(option_view.get("difficulty_text", "")).strip_edges()
	if not difficulty_text.is_empty():
		header_parts.append(difficulty_text)
	if not header_parts.is_empty():
		lines.append(" · ".join(header_parts))

	var check_text: String = str(option_view.get("check_text", "")).strip_edges()
	if not check_text.is_empty():
		lines.append(check_text)
	if _to_bool(option_view.get("is_available", false)):
		var available_text: String = GAME_TEXT.text("dialogue_panel.option_available")
		if not available_text.is_empty():
			lines.append(available_text)
	else:
		var unmet_text: String = str(option_view.get("unmet_text", GAME_TEXT.text("dialogue_panel.option_unmet"))).strip_edges()
		if not unmet_text.is_empty():
			lines.append(unmet_text)
	return "\n".join(lines)

func _resolve_intrusion_status_label(event_definition: Dictionary) -> String:
	var intrusion_id: String = str(event_definition.get("dialogue_intrusion_tag", "")).strip_edges()
	if intrusion_id.is_empty():
		return GAME_TEXT.text("dialogue_panel.intrusion_none")
	match intrusion_id:
		"greed":
			return GAME_TEXT.text("dialogue_panel.intrusion_greed")
		"wrath":
			return GAME_TEXT.text("dialogue_panel.intrusion_wrath")
		"delusion":
			return GAME_TEXT.text("dialogue_panel.intrusion_delusion")
		_:
			return "%s %s" % [GAME_TEXT.text("dialogue_panel.intrusion_none"), intrusion_id]

func _resolve_dialogue_body_text(event_definition: Dictionary, default_text: String) -> String:
	var encounter_definition: Dictionary = Dictionary(event_definition.get("dialogue_encounter", {}))
	var mode: String = str(event_definition.get("dialogue_mode", "hub"))
	var body_override_text: String = str(event_definition.get("dialogue_body_override_text", "")).strip_edges()
	var opening_text: String = str(encounter_definition.get("opening_text", default_text))
	var observation_text: String = str(encounter_definition.get("observation_text", ""))
	var intrusion_id: String = str(event_definition.get("dialogue_intrusion_tag", ""))
	var intrusion_hint: String = ""
	if not intrusion_id.is_empty():
		for intrusion_definition: Dictionary in encounter_definition.get("intrusions", []):
			if str(intrusion_definition.get("id", "")) != intrusion_id:
				continue
			intrusion_hint = str(intrusion_definition.get("selected_hint_text", ""))
			break

	if not body_override_text.is_empty():
		return body_override_text

	match mode:
		"observe":
			if observation_text.is_empty():
				return GAME_TEXT.text("dialogue_panel.observe_header")
			return "%s\n%s" % [GAME_TEXT.text("dialogue_panel.observe_header"), observation_text]
		"intrude":
			if intrusion_hint.is_empty():
				return GAME_TEXT.text("dialogue_panel.intruded_header")
			return "%s\n%s" % [GAME_TEXT.text("dialogue_panel.intruded_header"), intrusion_hint]
		"talk":
			return ""
		_:
			return opening_text

func _apply_visual_theme() -> void:
	_dialogue_portrait_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	_dialogue_speech_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("110f18f1"), Color("9b8cb2"), 18))
	_dialogue_options_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0))
	_dialogue_type_label.add_theme_font_size_override("font_size", 12)
	_dialogue_type_label.add_theme_color_override("font_color", Color("e2d3ae"))
	_dialogue_speaker_label.add_theme_font_size_override("font_size", 22)
	_dialogue_speaker_label.add_theme_color_override("font_color", Color("d8e2f5"))
	_dialogue_role_label.add_theme_font_size_override("font_size", 13)
	_dialogue_role_label.add_theme_color_override("font_color", Color("c7c0d8"))
	_dialogue_body_label.add_theme_font_size_override("font_size", 17)
	_dialogue_body_label.add_theme_color_override("font_color", Color("ece7da"))
	_dialogue_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_portrait_label.add_theme_font_size_override("font_size", 18)
	_dialogue_portrait_label.add_theme_color_override("font_color", Color("f0ece1"))
	_dialogue_portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dialogue_portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_dialogue_portrait_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_dialogue_portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dialogue_portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_dialogue_stage_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dialogue_hint_label.add_theme_font_size_override("font_size", 11)
	_dialogue_hint_label.add_theme_color_override("font_color", Color("c7c0b3"))
	_dialogue_page_label.add_theme_font_size_override("font_size", 10)
	_dialogue_page_label.add_theme_color_override("font_color", Color("9d95a6"))
	_dialogue_intrusion_label.add_theme_font_size_override("font_size", 10)
	_dialogue_intrusion_label.add_theme_color_override("font_color", Color("d9b36c"))
	_dialogue_options_title.add_theme_font_size_override("font_size", 12)
	_dialogue_options_title.add_theme_color_override("font_color", Color("f2ecd8"))

func _style_button(button: Button, min_height: float, button_kind: String) -> void:
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.custom_minimum_size = Vector2(0, min_height)
	button.add_theme_stylebox_override("normal", _make_button_style(button_kind, false, false))
	button.add_theme_stylebox_override("hover", _make_button_style(button_kind, true, false))
	button.add_theme_stylebox_override("pressed", _make_button_style(button_kind, true, true))
	button.add_theme_stylebox_override("disabled", _make_button_style(button_kind, false, true))
	button.add_theme_color_override("font_color", Color("f2eee3"))
	button.add_theme_color_override("font_disabled_color", Color("8f9087"))
	button.add_theme_font_size_override("font_size", 12)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.clip_text = true

func _make_panel_style(fill_color: Color, border_color: Color, corner_radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	return style

func _make_button_style(button_kind: String, hovered: bool, muted: bool) -> StyleBoxFlat:
	var base_color: Color = Color("45373d")
	var border_color: Color = Color("b08b90")
	if button_kind == "event":
		base_color = Color("2c384a")
		border_color = Color("7ea0c8")
	if hovered:
		base_color = base_color.lightened(0.08)
	if muted:
		base_color = base_color.darkened(0.15)
		border_color = border_color.darkened(0.2)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_right = 14
	style.corner_radius_bottom_left = 14
	style.content_margin_left = 12
	style.content_margin_top = 10
	style.content_margin_right = 12
	style.content_margin_bottom = 10
	return style

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized: String = str(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1" or normalized == "yes"
		_:
			return value != null

func _reset_body_scroll() -> void:
	return

func _reset_options_scroll() -> void:
	if _dialogue_options_scroll == null:
		return
	_dialogue_options_scroll.scroll_vertical = 0
