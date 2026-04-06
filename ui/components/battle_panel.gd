class_name BattlePanel
extends Control

const BATTLE_CARD_SLOT_SCRIPT := preload("res://ui/components/battle_card_slot.gd")
const BATTLE_HAND_CARD_SCRIPT := preload("res://ui/components/battle_hand_card.gd")

signal slot_selected(slot_index: int)
signal hand_card_selected(card_id: String)
signal card_dropped_to_slot(slot_index: int, card_id: String)
signal redraw_requested
signal resolve_requested

var _layout_finalize_queued: bool = false
var _content_scroll: ScrollContainer = null
var _scroll_host: Control = null
var _hand_layout_slot_count: int = 0

@onready var _battle_title_label: Label = %BattleTitleLabel
@onready var _battle_status_label: Label = %BattleStatusLabel
@onready var _root_container: MarginContainer = $Root
@onready var _content_container: VBoxContainer = $Root/Content
@onready var _content_title_label: Label = %ContentTitleLabel
@onready var _calc_title_label: Label = %CalcTitleLabel
@onready var _calc_formula_label: Label = %CalcFormulaLabel
@onready var _stage_row: HBoxContainer = $Root/Content/StageRow
@onready var _enemy_stage_panel: PanelContainer = $Root/Content/StageRow/EnemyStagePanel
@onready var _battle_info_column: VBoxContainer = $Root/Content/StageRow/BattleInfoColumn
@onready var _enemy_stage_name_label: Label = %EnemyStageNameLabel
@onready var _enemy_portrait_frame: AspectRatioContainer = $Root/Content/StageRow/EnemyStagePanel/EnemyStagePadding/EnemyStageContent/EnemyPortraitFrame
@onready var _enemy_portrait_stack: Control = $Root/Content/StageRow/EnemyStagePanel/EnemyStagePadding/EnemyStageContent/EnemyPortraitFrame/EnemyPortraitPanel/EnemyPortraitContent/EnemyPortraitStack
@onready var _enemy_portrait_rect: TextureRect = %EnemyPortraitRect
@onready var _enemy_portrait_placeholder: Label = %EnemyPortraitPlaceholder
@onready var _hint_title_label: Label = %HintTitleLabel
@onready var _enemy_stage_hint_label: Label = %EnemyStageHintLabel
@onready var _guide_title_label: Label = %GuideTitleLabel
@onready var _guide_label: Label = %GuideLabel
@onready var _player_status_label: Label = %PlayerStatusLabel
@onready var _enemy_status_label: Label = %EnemyStatusLabel
@onready var _draw_pile_label: Label = %DrawPileLabel
@onready var _discard_pile_label: Label = %DiscardPileLabel
@onready var _slot_title_label: Label = %SlotTitleLabel
@onready var _slot_container: HBoxContainer = %SlotContainer
@onready var _weakness_title_label: Label = %WeaknessTitleLabel
@onready var _weakness_label: Label = %WeaknessLabel
@onready var _resistance_title_label: Label = %ResistanceTitleLabel
@onready var _resistance_label: Label = %ResistanceLabel
@onready var _hand_title_label: Label = %HandTitleLabel
@onready var _hand_scroll: ScrollContainer = $Root/Content/StageRow/BattleInfoColumn/HandPanel/HandPadding/HandContent/HandScroll
@onready var _hand_container: Control = %HandContainer
@onready var _log_title_label: Label = %LogTitleLabel
@onready var _log_scroll: ScrollContainer = $Root/Content/LogPanel/LogPadding/LogContent/LogScroll
@onready var _battle_log_label: Label = %BattleLogLabel
@onready var _action_title_label: Label = %ActionTitleLabel
@onready var _redraw_button: Button = %RedrawButton
@onready var _resolve_button: Button = %ResolveButton

func _ready() -> void:
	_ensure_scroll_host()
	_redraw_button.pressed.connect(_on_redraw_pressed)
	_resolve_button.pressed.connect(_on_resolve_pressed)
	_hand_container.resized.connect(_layout_hand_cards)
	resized.connect(_apply_responsive_layout)
	_apply_responsive_layout()

func _ensure_scroll_host() -> void:
	if _content_scroll != null and is_instance_valid(_content_scroll):
		return
	if has_node("ContentScroll"):
		_content_scroll = get_node("ContentScroll") as ScrollContainer
	else:
		_content_scroll = ScrollContainer.new()
		_content_scroll.name = "ContentScroll"
		_content_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
		_content_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
		_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
		add_child(_content_scroll)
		move_child(_content_scroll, get_child_count() - 1)
	if _scroll_host == null or not is_instance_valid(_scroll_host):
		if _content_scroll.has_node("ScrollHost"):
			_scroll_host = _content_scroll.get_node("ScrollHost") as Control
		else:
			_scroll_host = Control.new()
			_scroll_host.name = "ScrollHost"
			_scroll_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_content_scroll.add_child(_scroll_host)
	if _root_container.get_parent() != _scroll_host:
		var previous_position: Vector2 = _root_container.position
		remove_child(_root_container)
		_scroll_host.add_child(_root_container)
		_root_container.anchor_left = 0.0
		_root_container.anchor_top = 0.0
		_root_container.anchor_right = 0.0
		_root_container.anchor_bottom = 0.0
		_root_container.position = previous_position

func configure(battle_view: Dictionary) -> void:
	visible = true
	_battle_title_label.text = str(battle_view.get("title_text", ""))
	_battle_status_label.text = str(battle_view.get("status_text", ""))
	_content_title_label.text = str(battle_view.get("content_title_text", ""))
	_calc_title_label.text = str(battle_view.get("calc_title_text", ""))
	_calc_formula_label.text = str(battle_view.get("calc_formula_text", ""))
	_enemy_stage_name_label.text = str(battle_view.get("enemy_stage_name_text", battle_view.get("enemy_name_text", "")))
	_hint_title_label.text = str(battle_view.get("hint_title_text", ""))
	_enemy_stage_hint_label.text = str(battle_view.get("hint_text", battle_view.get("drag_hint_text", "")))
	_guide_title_label.text = str(battle_view.get("guide_title_text", ""))
	_guide_label.text = str(battle_view.get("guide_text", ""))
	_player_status_label.text = str(battle_view.get("player_text", ""))
	_enemy_status_label.text = str(battle_view.get("enemy_text", ""))
	_draw_pile_label.text = str(battle_view.get("draw_pile_text", ""))
	_discard_pile_label.text = str(battle_view.get("discard_pile_text", ""))
	_slot_title_label.text = str(battle_view.get("slot_title_text", ""))
	_weakness_title_label.text = str(battle_view.get("weakness_title_text", ""))
	_weakness_label.text = str(battle_view.get("weakness_text", ""))
	_resistance_title_label.text = str(battle_view.get("resistance_title_text", ""))
	_resistance_label.text = str(battle_view.get("resistance_text", ""))
	_hand_title_label.text = str(battle_view.get("hand_title_text", ""))
	_log_title_label.text = str(battle_view.get("log_title_text", ""))
	_battle_log_label.text = str(battle_view.get("log_text", ""))
	_action_title_label.text = str(battle_view.get("action_title_text", ""))
	_apply_enemy_portrait(
		str(battle_view.get("enemy_portrait_path", "")),
		str(battle_view.get("enemy_portrait_placeholder", "")),
		str(battle_view.get("enemy_name_text", ""))
	)
	_rebuild_slots(Array(battle_view.get("slot_views", []), TYPE_DICTIONARY, "", null))
	_hand_layout_slot_count = maxi(
		int(battle_view.get("hand_layout_slot_count", 0)),
		Array(battle_view.get("hand_views", []), TYPE_DICTIONARY, "", null).size()
	)
	_rebuild_hand(Array(battle_view.get("hand_views", []), TYPE_DICTIONARY, "", null))
	_layout_hand_cards()
	_redraw_button.disabled = not _to_bool(battle_view.get("can_redraw", true))
	_resolve_button.disabled = not _to_bool(battle_view.get("can_resolve", true))
	_redraw_button.text = str(battle_view.get("redraw_text", ""))
	_resolve_button.text = str(battle_view.get("resolve_text", ""))
	_apply_panel_style()
	call_deferred("_apply_responsive_layout")

func clear_panel() -> void:
	visible = false
	_battle_title_label.text = ""
	_battle_status_label.text = ""
	_content_title_label.text = ""
	_calc_title_label.text = ""
	_calc_formula_label.text = ""
	_enemy_stage_name_label.text = ""
	_hint_title_label.text = ""
	_enemy_stage_hint_label.text = ""
	_guide_title_label.text = ""
	_guide_label.text = ""
	_enemy_portrait_rect.texture = null
	_enemy_portrait_placeholder.text = ""
	_enemy_portrait_placeholder.visible = false
	_player_status_label.text = ""
	_enemy_status_label.text = ""
	_draw_pile_label.text = ""
	_discard_pile_label.text = ""
	_slot_title_label.text = ""
	_weakness_title_label.text = ""
	_weakness_label.text = ""
	_resistance_title_label.text = ""
	_resistance_label.text = ""
	_hand_title_label.text = ""
	_log_title_label.text = ""
	_battle_log_label.text = ""
	_action_title_label.text = ""
	_hand_layout_slot_count = 0
	for child: Node in _slot_container.get_children():
		child.queue_free()
	for child: Node in _hand_container.get_children():
		child.queue_free()
	_apply_responsive_layout()

func _rebuild_slots(slot_views: Array[Dictionary]) -> void:
	for child: Node in _slot_container.get_children():
		child.queue_free()
	for slot_view: Dictionary in slot_views:
		var slot_control = PanelContainer.new()
		slot_control.set_script(BATTLE_CARD_SLOT_SCRIPT)
		slot_control.configure(slot_view)
		slot_control.selected.connect(_emit_slot_selected)
		slot_control.card_dropped.connect(_emit_card_dropped_to_slot)
		_slot_container.add_child(slot_control)

func _rebuild_hand(hand_views: Array[Dictionary]) -> void:
	for child: Node in _hand_container.get_children():
		child.queue_free()
	for hand_view: Dictionary in hand_views:
		var card_control = PanelContainer.new()
		card_control.set_script(BATTLE_HAND_CARD_SCRIPT)
		card_control.configure(hand_view)
		card_control.set_meta("layout_index", int(hand_view.get("layout_index", _hand_container.get_child_count())))
		card_control.activated.connect(_emit_hand_card_selected)
		_hand_container.add_child(card_control)
	_layout_hand_cards()

func _apply_enemy_portrait(portrait_path: String, placeholder_text: String, enemy_name_text: String) -> void:
	var portrait_texture: Texture2D = _load_portrait_texture(portrait_path)
	_enemy_portrait_rect.texture = portrait_texture
	_enemy_portrait_placeholder.text = placeholder_text if not placeholder_text.is_empty() else enemy_name_text
	_enemy_portrait_placeholder.visible = portrait_texture == null

func _layout_hand_cards() -> void:
	var cards: Array[Control] = []
	for child: Node in _hand_container.get_children():
		if child is Control:
			cards.append(child as Control)
	if cards.is_empty():
		return
	var available_width: float = max(_hand_container.size.x, 320.0)
	var layout_slot_count: int = maxi(_hand_layout_slot_count, cards.size())
	var card_width: float = clampf((available_width - 40.0) / max(layout_slot_count + 0.45, 1.0), 132.0, 170.0)
	var spacing: float = clampf(card_width * 0.66, 88.0, 112.0)
	var total_width: float = card_width + max(layout_slot_count - 1, 0) * spacing
	var start_x: float = max((_hand_container.size.x - total_width) * 0.5, 0.0)
	for index: int in range(cards.size()):
		var card: Control = cards[index]
		var layout_index: int = int(card.get_meta("layout_index", index))
		var offset: float = float(layout_index) - (layout_slot_count - 1) * 0.5
		card.custom_minimum_size = Vector2(card_width, 204)
		card.position = Vector2(start_x + layout_index * spacing, 4 + abs(offset) * 8.0)
		card.rotation_degrees = offset * 4.0
		card.pivot_offset = Vector2(card_width * 0.5, 204)
		card.z_index = 10 + layout_index

func _apply_panel_style() -> void:
	_battle_title_label.add_theme_font_size_override("font_size", 26)
	_battle_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_content_title_label.add_theme_font_size_override("font_size", 15)
	_content_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_calc_title_label.add_theme_color_override("font_color", Color("c8c0ad"))
	_calc_formula_label.add_theme_font_size_override("font_size", 22)
	_calc_formula_label.add_theme_color_override("font_color", Color("f3d06f"))
	_enemy_stage_name_label.add_theme_font_size_override("font_size", 24)
	_enemy_stage_name_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_hint_title_label.add_theme_font_size_override("font_size", 15)
	_hint_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_enemy_stage_hint_label.add_theme_color_override("font_color", Color("bfb6c8"))
	_guide_title_label.add_theme_font_size_override("font_size", 15)
	_guide_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_guide_label.add_theme_color_override("font_color", Color("ddd8cb"))
	_action_title_label.add_theme_font_size_override("font_size", 15)
	_action_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_weakness_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_resistance_title_label.add_theme_color_override("font_color", Color("f0ddb2"))
	_weakness_label.add_theme_color_override("font_color", Color("ddd8cb"))
	_resistance_label.add_theme_color_override("font_color", Color("c6bfd0"))
	_redraw_button.custom_minimum_size = Vector2(170, 52)
	_resolve_button.custom_minimum_size = Vector2(240, 58)
	_redraw_button.add_theme_font_size_override("font_size", 18)
	_resolve_button.add_theme_font_size_override("font_size", 20)
	_redraw_button.add_theme_color_override("font_color", Color("e9dfc8"))
	_resolve_button.add_theme_color_override("font_color", Color("fff1d0"))
	_redraw_button.add_theme_stylebox_override("normal", _make_button_style(Color("33404a"), Color("8899ab")))
	_redraw_button.add_theme_stylebox_override("hover", _make_button_style(Color("3d4a55"), Color("b3c0d0")))
	_redraw_button.add_theme_stylebox_override("pressed", _make_button_style(Color("2d3941"), Color("6e7b89")))
	_resolve_button.add_theme_stylebox_override("normal", _make_button_style(Color("7a2329"), Color("f08d75")))
	_resolve_button.add_theme_stylebox_override("hover", _make_button_style(Color("8f2a31"), Color("ffb08f")))
	_resolve_button.add_theme_stylebox_override("pressed", _make_button_style(Color("681d23"), Color("d77769")))
	_apply_responsive_layout()

func _apply_responsive_layout() -> void:
	if not is_node_ready():
		return
	_ensure_scroll_host()
	_root_container.scale = Vector2.ONE
	_root_container.pivot_offset = Vector2.ZERO
	var panel_width: float = _resolve_panel_width()
	_apply_stage_layout(panel_width)
	_root_container.custom_minimum_size = Vector2(panel_width, 0.0)
	_root_container.size = Vector2(panel_width, _root_container.size.y)
	if _hand_scroll == null or _log_scroll == null:
		return
	var compact_ratio: float = clampf((panel_width - 760.0) / 360.0, 0.0, 1.0)
	_hand_scroll.custom_minimum_size = Vector2(0, lerpf(152.0, 184.0, compact_ratio))
	_log_scroll.custom_minimum_size = Vector2(0, lerpf(96.0, 120.0, compact_ratio))
	_redraw_button.custom_minimum_size = Vector2(lerpf(148.0, 170.0, compact_ratio), lerpf(44.0, 52.0, compact_ratio))
	_resolve_button.custom_minimum_size = Vector2(lerpf(200.0, 240.0, compact_ratio), lerpf(48.0, 58.0, compact_ratio))
	_battle_title_label.add_theme_font_size_override("font_size", int(round(lerpf(22.0, 26.0, compact_ratio))))
	_calc_formula_label.add_theme_font_size_override("font_size", int(round(lerpf(18.0, 22.0, compact_ratio))))
	if _layout_finalize_queued:
		return
	_layout_finalize_queued = true
	call_deferred("_finalize_responsive_layout")

func _resolve_panel_width() -> float:
	var viewport_width: float = max(size.x, 320.0)
	return clampf(viewport_width - 56.0, 720.0, 1180.0)

func _apply_stage_layout(panel_width: float) -> void:
	if _enemy_stage_panel == null or _battle_info_column == null or _enemy_portrait_frame == null or _enemy_portrait_stack == null:
		return
	var portrait_width: float = clampf(panel_width * 0.24, 220.0, 320.0)
	var portrait_height: float = roundf(portrait_width / max(_enemy_portrait_frame.ratio, 0.1))
	_enemy_stage_panel.size_flags_horizontal = 0
	_battle_info_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_battle_info_column.size_flags_stretch_ratio = 1.0
	_enemy_portrait_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_enemy_portrait_frame.custom_minimum_size = Vector2(portrait_width, portrait_height)
	_enemy_portrait_stack.custom_minimum_size = Vector2(0.0, portrait_height - 24.0)
	_stage_row.alignment = BoxContainer.ALIGNMENT_BEGIN

func _finalize_responsive_layout() -> void:
	_layout_finalize_queued = false
	if not is_node_ready():
		return
	var panel_width: float = _resolve_panel_width()
	_apply_stage_layout(panel_width)
	var required_height: float = _root_container.get_combined_minimum_size().y
	_root_container.custom_minimum_size = Vector2(panel_width, required_height)
	_root_container.size = Vector2(panel_width, required_height)
	if _scroll_host != null:
		var host_width: float = max(size.x, panel_width + 24.0)
		var host_height: float = max(size.y, required_height + 24.0)
		_scroll_host.custom_minimum_size = Vector2(host_width, host_height)
		_scroll_host.size = Vector2(host_width, host_height)
		_root_container.position = Vector2(max((host_width - panel_width) * 0.5, 0.0), 12.0)
	if _content_scroll != null:
		_content_scroll.custom_minimum_size = size
	_layout_hand_cards()

func _load_portrait_texture(portrait_path: String) -> Texture2D:
	if portrait_path.is_empty():
		return null
	var loaded_resource: Resource = load(portrait_path)
	if loaded_resource is Texture2D:
		return loaded_resource as Texture2D
	return null

func _make_button_style(background: Color, border: Color) -> StyleBoxFlat:
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
	return style

func _emit_slot_selected(slot_index: int) -> void:
	slot_selected.emit(slot_index)

func _emit_hand_card_selected(card_id: String) -> void:
	hand_card_selected.emit(card_id)

func _emit_card_dropped_to_slot(slot_index: int, card_id: String) -> void:
	card_dropped_to_slot.emit(slot_index, card_id)

func _on_redraw_pressed() -> void:
	redraw_requested.emit()

func _on_resolve_pressed() -> void:
	resolve_requested.emit()

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
