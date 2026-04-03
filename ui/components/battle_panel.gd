class_name BattlePanel
extends Control

const BATTLE_CARD_SLOT_SCRIPT := preload("res://ui/components/battle_card_slot.gd")
const BATTLE_HAND_CARD_SCRIPT := preload("res://ui/components/battle_hand_card.gd")

signal slot_selected(slot_index: int)
signal hand_card_selected(card_id: String)
signal card_dropped_to_slot(slot_index: int, card_id: String)
signal redraw_requested
signal resolve_requested

@onready var _battle_title_label: Label = %BattleTitleLabel
@onready var _battle_status_label: Label = %BattleStatusLabel
@onready var _content_title_label: Label = %ContentTitleLabel
@onready var _calc_title_label: Label = %CalcTitleLabel
@onready var _calc_formula_label: Label = %CalcFormulaLabel
@onready var _enemy_stage_name_label: Label = %EnemyStageNameLabel
@onready var _enemy_portrait_rect: TextureRect = %EnemyPortraitRect
@onready var _enemy_portrait_placeholder: Label = %EnemyPortraitPlaceholder
@onready var _hint_title_label: Label = %HintTitleLabel
@onready var _enemy_stage_hint_label: Label = %EnemyStageHintLabel
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
@onready var _hand_container: Control = %HandContainer
@onready var _log_title_label: Label = %LogTitleLabel
@onready var _battle_log_label: Label = %BattleLogLabel
@onready var _action_title_label: Label = %ActionTitleLabel
@onready var _redraw_button: Button = %RedrawButton
@onready var _resolve_button: Button = %ResolveButton

func _ready() -> void:
	_redraw_button.pressed.connect(_on_redraw_pressed)
	_resolve_button.pressed.connect(_on_resolve_pressed)
	_hand_container.resized.connect(_layout_hand_cards)

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
	_rebuild_hand(Array(battle_view.get("hand_views", []), TYPE_DICTIONARY, "", null))
	_layout_hand_cards()
	_redraw_button.disabled = not _to_bool(battle_view.get("can_redraw", true))
	_resolve_button.disabled = not _to_bool(battle_view.get("can_resolve", true))
	_redraw_button.text = str(battle_view.get("redraw_text", ""))
	_resolve_button.text = str(battle_view.get("resolve_text", ""))
	_apply_panel_style()

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
	for child: Node in _slot_container.get_children():
		child.queue_free()
	for child: Node in _hand_container.get_children():
		child.queue_free()

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
	var card_width: float = 170.0
	var spacing: float = 112.0
	var total_width: float = card_width + max(cards.size() - 1, 0) * spacing
	var start_x: float = max((_hand_container.size.x - total_width) * 0.5, 0.0)
	var mid_index: float = (cards.size() - 1) * 0.5
	for index: int in range(cards.size()):
		var card: Control = cards[index]
		var offset: float = float(index) - mid_index
		card.custom_minimum_size = Vector2(card_width, 204)
		card.position = Vector2(start_x + index * spacing, 4 + abs(offset) * 8.0)
		card.rotation_degrees = offset * 4.0
		card.pivot_offset = Vector2(card_width * 0.5, 204)
		card.z_index = 10 + index

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
