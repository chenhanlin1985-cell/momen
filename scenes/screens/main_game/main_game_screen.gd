class_name MainGameScreen
extends Control

const GAME_TEXT := preload("res://systems/content/game_text.gd")

const LOCATION_BACKDROP_THEME: Dictionary = {
	"01": {
		"color": Color("24303c"),
		"accent": Color("6f98bf"),
		"background_path": "res://assets/art/backgrounds/scenes/01/01_01.png"
	},
	"02": {"color": Color("2e2f3c"), "accent": Color("b3a36f"), "background_path": "res://assets/art/backgrounds/scenes/02/02_01.png"},
	"03": {"color": Color("26352d"), "accent": Color("81b783"), "background_path": "res://assets/art/backgrounds/scenes/03/03_01.png"},
	"04": {"color": Color("342e26"), "accent": Color("d0b27a"), "background_path": "res://assets/art/backgrounds/scenes/04/04_01.png"},
	"05": {"color": Color("1f2838"), "accent": Color("86a7d1"), "background_path": "res://assets/art/backgrounds/scenes/05/05_01.png"},
	"06": {"color": Color("261f33"), "accent": Color("c79cf0"), "background_path": "res://assets/art/backgrounds/scenes/06/06_01.png"}
}

const ENDING_ART_PATHS: Dictionary = {
	"ending_battle_deviation": "res://assets/art/backgrounds/scenes/endings/ending_battle_deviation.png.png"
}

const NPC_AVATAR_THEME: Dictionary = {
	"01": {"color": Color("7a8fb8")},
	"04": {"color": Color("b7936d")},
	"03": {"color": Color("8d7aa8")},
	"02": {"color": Color("7ba16d")}
}

const EVENT_TYPE_THEME: Dictionary = {
	"story": {
		"panel_fill": Color("33231d"),
		"panel_border": Color("ab7c5f"),
		"title": Color("f3e3d3"),
		"body": Color("ddd1c4"),
		"tag": Color("d8b697"),
		"button_kind": "event_story"
	},
	"dialogue": {
		"panel_fill": Color("26303a"),
		"panel_border": Color("6c8aa4"),
		"title": Color("e2edf7"),
		"body": Color("d5dde4"),
		"tag": Color("a8c3d9"),
		"button_kind": "event_dialogue"
	},
	"random": {
		"panel_fill": Color("312f24"),
		"panel_border": Color("b39a54"),
		"title": Color("f5ebc8"),
		"body": Color("e0d8bf"),
		"tag": Color("d9c36d"),
		"button_kind": "event_random"
	},
	"reward": {
		"panel_fill": Color("1f3128"),
		"panel_border": Color("76b08d"),
		"title": Color("ddf6e7"),
		"body": Color("cfe4d7"),
		"tag": Color("93d0aa"),
		"button_kind": "event_reward"
	},
	"review": {
		"panel_fill": Color("24273a"),
		"panel_border": Color("7c83ba"),
		"title": Color("e3e7ff"),
		"body": Color("d4d8eb"),
		"tag": Color("a7afe7"),
		"button_kind": "event_review"
	},
	"shop": {
		"panel_fill": Color("34281f"),
		"panel_border": Color("d1a262"),
		"title": Color("fee7c8"),
		"body": Color("ead9c4"),
		"tag": Color("efbe7d"),
		"button_kind": "event_shop"
	},
	"normal_battle": {
		"panel_fill": Color("341f27"),
		"panel_border": Color("b15f78"),
		"title": Color("ffe1e9"),
		"body": Color("e7d0d7"),
		"tag": Color("d78aa2"),
		"button_kind": "event_battle"
	},
	"elite_battle": {
		"panel_fill": Color("381d2f"),
		"panel_border": Color("cb5da7"),
		"title": Color("ffe0f4"),
		"body": Color("ead1e3"),
		"tag": Color("eb86c3"),
		"button_kind": "event_elite_battle"
	},
	"boss_battle": {
		"panel_fill": Color("3b171d"),
		"panel_border": Color("da5b68"),
		"title": Color("ffe0e4"),
		"body": Color("efd0d3"),
		"tag": Color("f08b96"),
		"button_kind": "event_boss_battle"
	}
}

const ROUTE_THEME: Dictionary = {
	"route_records": {"tag": "账册线", "color": Color("d7b16d")},
	"route_seek_senior": {"tag": "疯长老线", "color": Color("c88386")},
	"route_well": {"tag": "化骨池线", "color": Color("7ea8cf")},
	"route_lie_low": {"tag": "暂避锋芒", "color": Color("8ea18a")}
}


@onready var _day_label: Label = %DayLabel
@onready var _phase_label: Label = %PhaseLabel
@onready var _remaining_action_label: Label = %RemainingActionLabel
@onready var _resource_label: Label = %ResourceLabel
@onready var _track_label: Label = %TrackLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _status_label: Label = %StatusLabel
@onready var _stage_title_label: Label = %StageTitleLabel
@onready var _stage_body_label: Label = %StageBodyLabel
@onready var _event_title_label: Label = %EventTitleLabel
@onready var _event_body_label: Label = %EventBodyLabel
@onready var _dialogue_event_panel: Node = %DialogueEventPanel
@onready var _battle_panel: Node = %BattlePanel
@onready var _event_panel_title: Label = $"MarginContainer/Root/MainRow/StageColumn/EventPanel/EventPadding/EventScroll/EventContent/EventPanelTitle"
@onready var _event_type_hint_label: Label = %EventTypeHintLabel
@onready var _event_content_title_label: Label = %EventContentTitleLabel
@onready var _event_hint_title_label: Label = %EventHintTitleLabel
@onready var _event_hint_label: Label = %EventHintLabel
@onready var _event_decision_title_label: Label = %EventDecisionTitleLabel
@onready var _event_options_container: VBoxContainer = %EventOptionsContainer
@onready var _ending_title_label: Label = %EndingTitleLabel
@onready var _ending_body_label: Label = %EndingBodyLabel
@onready var _ending_hint_label: Label = %EndingHintLabel
@onready var _ending_restart_button: Button = %EndingRestartButton
@onready var _goal_label: Label = %GoalLabel
@onready var _attribute_role_label: Label = %AttributeRoleLabel
@onready var _hint_label: Label = %HintLabel
@onready var _location_mount_label: Label = %LocationMountLabel
@onready var _npc_state_event_label: Label = %NpcStateEventLabel
@onready var _log_label: RichTextLabel = %LogLabel
@onready var _location_panel: PanelContainer = %LocationPanel
@onready var _event_panel: PanelContainer = %EventPanel
@onready var _ending_panel: PanelContainer = %EndingPanel
@onready var _ending_art_rect: TextureRect = %EndingArtRect
@onready var _scene_background: ColorRect = %SceneBackground
@onready var _scene_background_texture: TextureRect = %SceneBackgroundTexture
@onready var _scene_backdrop: MarginContainer = $"MarginContainer/Root/MainRow/StageColumn/LocationPanel/LocationPadding/LocationContent/SceneViewport/SceneBackdrop"
@onready var _scene_overlay: MarginContainer = $"MarginContainer/Root/MainRow/StageColumn/LocationPanel/LocationPadding/LocationContent/SceneViewport/SceneOverlay"
@onready var _backdrop_title_label: Label = %BackdropTitleLabel
@onready var _backdrop_subtitle_label: Label = %BackdropSubtitleLabel
@onready var _backdrop_note_label: Label = %BackdropNoteLabel
@onready var _scene_actor_layer: Control = %SceneActorLayer
@onready var _scene_interaction_panel: PanelContainer = %SceneInteractionPanel
@onready var _node_summary_label: Label = %NodeSummaryLabel
@onready var _route_map_panel: Node = %RouteMapPanel
@onready var _top_bar: PanelContainer = $"MarginContainer/Root/TopBar"
@onready var _top_bar_content: GridContainer = $"MarginContainer/Root/TopBar/TopBarPadding/TopBarContent"
@onready var _status_bar: PanelContainer = $"MarginContainer/Root/StatusBar"
@onready var _sidebar: PanelContainer = $"MarginContainer/Root/MainRow/Sidebar"
@onready var _popup_overlay: ColorRect = %PopupOverlay
@onready var _popup_dismiss_layer: Control = %PopupDismissLayer
@onready var _popup_panel: PanelContainer = %PopupPanel
@onready var _popup_title: Label = %PopupTitle
@onready var _popup_close_button: Button = %PopupCloseButton
@onready var _card_menu_button: Button = %CardMenuButton
@onready var _card_column: VBoxContainer = %CardColumn
@onready var _actions_container: VBoxContainer = %ActionsContainer
@onready var _action_scroll: ScrollContainer = $"MarginContainer/Root/MainRow/StageColumn/SceneInteractionPanel/SceneInteractionPadding/SceneInteractionContent/ActionScroll"
@onready var _action_title: Label = %ActionTitle
@onready var _card_title: Label = %CardTitle
@onready var _card_summary_label: Label = %CardSummaryLabel
@onready var _backdrop_tag: Label = $"MarginContainer/Root/MainRow/StageColumn/LocationPanel/LocationPadding/LocationContent/SceneViewport/SceneBackdrop/SceneBackdropContent/BackdropTag"
@onready var _opening_overlay: Control = %OpeningOverlay
@onready var _opening_overlay_color: ColorRect = %OpeningOverlay
@onready var _opening_pulse: ColorRect = %OpeningPulse
@onready var _opening_accent_bar: ColorRect = %OpeningAccentBar
@onready var _opening_title_label: Label = %OpeningTitleLabel
@onready var _opening_body_label: Label = %OpeningBodyLabel
@onready var _opening_goal_title: Label = $"OpeningOverlay/CenterContainer/OpeningPanel/OpeningPadding/OpeningContent/OpeningGoalTitle"
@onready var _opening_goal_label: Label = %OpeningGoalLabel
@onready var _opening_buttons: HBoxContainer = $"OpeningOverlay/CenterContainer/OpeningPanel/OpeningPadding/OpeningContent/OpeningButtons"
@onready var _opening_start_button: Button = %OpeningStartButton
@onready var _opening_panel: PanelContainer = $"OpeningOverlay/CenterContainer/OpeningPanel"

var _active_scene_menu: String = ""
var _last_present_npcs: Array[Dictionary] = []
var _current_event_type_key: String = ""
var _opening_steps: Array[Dictionary] = []
var _opening_step_index_by_id: Dictionary = {}
var _current_opening_run_id: String = RunController.DEFAULT_RUN_ID
var _current_opening_button_kind: String = "event"
var _opening_visual_tween: Tween
var _top_card_button: Button

func _ready() -> void:
	_apply_visual_theme()
	_build_persistent_card_button()
	_scene_actor_layer.resized.connect(_layout_scene_hotspots)
	_dialogue_event_panel.option_selected.connect(_on_event_option_pressed)
	_dialogue_event_panel.dialogue_finished.connect(_on_dialogue_event_finished)
	_battle_panel.slot_selected.connect(_on_battle_slot_selected)
	_battle_panel.hand_card_selected.connect(_on_battle_hand_card_selected)
	_battle_panel.card_dropped_to_slot.connect(_on_battle_card_dropped_to_slot)
	_battle_panel.redraw_requested.connect(_on_battle_redraw_requested)
	_battle_panel.resolve_requested.connect(_on_battle_resolve_requested)
	_route_map_panel.node_selected.connect(_on_route_map_node_selected)
	_route_map_panel.node_focused.connect(_on_route_map_node_focused)
	_card_menu_button.pressed.connect(_on_scene_menu_pressed.bind("cards"))
	_popup_close_button.pressed.connect(_close_scene_popup)
	_popup_dismiss_layer.gui_input.connect(_on_popup_overlay_input)
	_opening_start_button.pressed.connect(_on_opening_start_pressed)
	_ending_restart_button.pressed.connect(_on_restart_pressed)
	_card_menu_button.text = _main_text("menu_buttons.cards")
	_ending_restart_button.text = _main_text("buttons.restart")
	_card_title.text = _main_text("popup_titles.cards")
	AppState.run_state_changed.connect(_refresh)
	AppState.error_raised.connect(_show_error)
	if AppState.current_run_state == null:
		_show_opening()
	else:
		_refresh(AppState.current_run_state)

func _refresh(run_state: RunState) -> void:
	_opening_overlay.visible = false
	RunController.sync_current_battle_state()
	run_state = AppState.current_run_state
	if run_state == null:
		return
	var current_location: Dictionary = RunController.get_current_location()
	var present_npcs: Array[Dictionary] = RunController.get_present_npcs()
	var visible_actions: Array[Dictionary] = RunController.get_visible_actions()
	var route_map_view: Dictionary = RunController.get_current_route_map_view()
	var current_event: Dictionary = RunController.get_current_event()
	var event_hints: Array[String] = RunController.get_event_hints()
	var current_event_option_views: Array[Dictionary] = RunController.get_current_event_option_views()
	var location_mount_traces: Array[Dictionary] = RunController.get_current_location_mount_trace()
	var npc_state_event_traces: Array[Dictionary] = RunController.get_present_npc_state_event_trace()
	var attribute_roles: Dictionary = RunController.get_attribute_roles()
	var view_model: Dictionary = MainGameViewModel.build(
		run_state,
		current_location,
		present_npcs,
		visible_actions,
		route_map_view,
		current_event,
		event_hints,
		current_event_option_views,
		location_mount_traces,
		npc_state_event_traces,
		attribute_roles
	)

	_last_present_npcs = present_npcs.duplicate(true)

	_day_label.text = str(view_model.get("day_text", ""))
	_phase_label.text = str(view_model.get("phase_text", ""))
	_remaining_action_label.text = str(view_model.get("remaining_action_text", ""))
	_resource_label.text = str(view_model.get("resource_text", ""))
	_track_label.text = str(view_model.get("track_text", ""))
	_stats_label.text = str(view_model.get("stats_text", ""))
	_status_label.text = str(view_model.get("status_text", ""))
	_node_summary_label.text = str(view_model.get("summary_text", view_model.get("story_text", "")))
	_stage_title_label.text = str(view_model.get("stage_title_text", ""))
	_stage_body_label.text = str(view_model.get("stage_body_text", ""))
	_event_title_label.text = str(view_model.get("event_title_text", ""))
	_event_body_label.text = str(view_model.get("event_body_text", ""))
	_event_panel_title.text = str(view_model.get("event_type_text", _main_text("event_titles.default")))
	_event_type_hint_label.text = ""
	_event_content_title_label.text = _main_text("section_titles.content", "褰撳墠涓讳綋")
	_event_hint_title_label.text = _main_text("section_titles.hint", "褰撳墠鎻愮ず")
	_event_hint_label.text = str(view_model.get("hint_text", ""))
	_event_decision_title_label.text = _main_text("section_titles.decision", "褰撳墠鍐崇瓥")
	_ending_title_label.text = str(view_model.get("ending_title_text", ""))
	_ending_body_label.text = str(view_model.get("ending_body_text", ""))
	_apply_ending_art(run_state)
	var ending_outcome_type: String = str(view_model.get("ending_outcome_type", ""))
	_ending_hint_label.text = _main_text("ending.restart_hint") if ending_outcome_type == "death" else _main_text("ending.continue_hint")
	_apply_ending_theme(ending_outcome_type)
	_goal_label.text = str(view_model.get("goal_text", ""))
	_attribute_role_label.text = str(view_model.get("attribute_roles_text", ""))
	_hint_label.text = str(view_model.get("hint_text", ""))
	_location_mount_label.text = str(view_model.get("location_mount_text", ""))
	_npc_state_event_label.text = str(view_model.get("npc_state_event_text", ""))
	_log_label.text = str(view_model.get("log_text", ""))
	_card_summary_label.text = RunController.get_card_library_summary()
	_backdrop_tag.text = str(view_model.get("event_type_short_text", ""))
	_current_event_type_key = str(view_model.get("event_type_key", ""))
	_apply_event_type_theme(_current_event_type_key)

	var scene_mode: String = str(view_model.get("scene_mode", "location"))
	_update_stage_panels(scene_mode)
	_update_scene_backdrop(scene_mode, current_location, run_state.is_run_over)
	_apply_route_map_scene_theme(scene_mode, route_map_view)
	_update_event_presentation(scene_mode, view_model, current_event)
	_update_battle_presentation()
	_update_route_map_presentation(scene_mode, route_map_view)
	_rebuild_event_options(scene_mode, current_event, run_state.is_run_over)
	_rebuild_scene_hotspots(scene_mode, present_npcs, run_state.is_run_over)
	_rebuild_action_buttons(scene_mode, visible_actions, run_state.is_run_over)
	_sync_popup_state(scene_mode, run_state.is_run_over)

func _show_error(message: String) -> void:
	_status_label.text = message


func _show_opening(run_id: String = RunController.DEFAULT_RUN_ID) -> void:
	var opening_data: Dictionary = RunController.get_opening_data(run_id)
	_current_opening_run_id = run_id
	_opening_steps = Array(opening_data.get("sequence", []), TYPE_DICTIONARY, "", null)
	_opening_step_index_by_id = {}
	for index: int in _opening_steps.size():
		var step_definition: Dictionary = _opening_steps[index]
		var step_id: String = str(step_definition.get("id", ""))
		if step_id.is_empty():
			continue
		_opening_step_index_by_id[step_id] = index
	_opening_overlay.visible = true
	_close_scene_popup()
	if _opening_steps.is_empty():
		_render_opening_fallback(opening_data)
		return
	_show_opening_step(str(_opening_steps[0].get("id", "")))


func _on_opening_start_pressed() -> void:
	RunController.start_new_run(_current_opening_run_id)

func _show_opening_step(step_id: String) -> void:
	if not _opening_step_index_by_id.has(step_id):
		_render_opening_fallback(RunController.get_opening_data(_current_opening_run_id))
		return
	var step_definition: Dictionary = _opening_steps[int(_opening_step_index_by_id[step_id])]
	_apply_opening_step_visual_style(str(step_definition.get("style", "opening")))
	_opening_title_label.text = str(step_definition.get("title", ""))
	var step_lines: Array[String] = Array(step_definition.get("lines", []), TYPE_STRING, "", null)
	_opening_body_label.text = "\n\n".join(step_lines)
	var goal_summary: String = str(step_definition.get("goal_summary", ""))
	_opening_goal_title.text = _main_text("opening.goal_title")
	_opening_goal_title.visible = not goal_summary.is_empty()
	_opening_goal_label.text = goal_summary
	_opening_goal_label.visible = not goal_summary.is_empty()
	var buttons: Array[Dictionary] = Array(step_definition.get("buttons", []), TYPE_DICTIONARY, "", null)
	_rebuild_opening_buttons(buttons)

func _render_opening_fallback(opening_data: Dictionary) -> void:
	_apply_opening_step_visual_style("opening")
	_opening_title_label.text = str(opening_data.get("title", ""))
	var opening_lines: Array[String] = Array(opening_data.get("lines", []), TYPE_STRING, "", null)
	_opening_body_label.text = "\n\n".join(opening_lines)
	var goal_summary: String = str(opening_data.get("goal_summary", ""))
	_opening_goal_title.text = _main_text("opening.goal_title")
	_opening_goal_title.visible = not goal_summary.is_empty()
	_opening_goal_label.text = goal_summary
	_opening_goal_label.visible = not goal_summary.is_empty()
	_rebuild_opening_buttons([
		{
			"text": str(opening_data.get("start_button_text", _main_text("opening.button_start"))),
			"action": "start_run"
		}
	])

func _rebuild_opening_buttons(buttons: Array[Dictionary]) -> void:
	for child: Node in _opening_buttons.get_children():
		child.queue_free()
	for button_definition: Dictionary in buttons:
		var button: Button = Button.new()
		_style_button(button, 48, _current_opening_button_kind)
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = Vector2(220, 48)
		button.text = str(button_definition.get("text", _main_text("opening.button_continue")))
		var action_id: String = str(button_definition.get("action", ""))
		var target_step_id: String = str(button_definition.get("target_step_id", ""))
		button.pressed.connect(_on_opening_sequence_button_pressed.bind(action_id, target_step_id))
		_opening_buttons.add_child(button)

func _on_opening_sequence_button_pressed(action_id: String, target_step_id: String) -> void:
	match action_id:
		"goto":
			if not target_step_id.is_empty():
				_show_opening_step(target_step_id)
		"start_run":
			RunController.start_new_run(_current_opening_run_id)
		_:
			if not target_step_id.is_empty():
				_show_opening_step(target_step_id)

func _apply_opening_step_visual_style(style_id: String) -> void:
	var overlay_color: Color = Color(0, 0, 0, 0.72)
	var pulse_color: Color = Color(0.23, 0.05, 0.09, 0.0)
	var accent_color: Color = Color(0.42, 0.58, 0.75, 0.0)
	var panel_fill: Color = Color("182124")
	var panel_border: Color = Color("46606b")
	var title_color: Color = Color("f4f0e5")
	var body_color: Color = Color("ddd8cb")
	var goal_color: Color = Color("d7ddd5")
	var button_kind: String = "event"
	var pulse_alpha: float = 0.0
	var accent_alpha: float = 0.0
	var title_scale: Vector2 = Vector2.ONE

	match style_id:
		"intro":
			overlay_color = Color(0.02, 0.02, 0.03, 0.78)
			accent_color = Color(0.33, 0.45, 0.60, 0.16)
			panel_fill = Color("1d2028")
			panel_border = Color("55667d")
			accent_alpha = 0.16
		"choice":
			overlay_color = Color(0.03, 0.03, 0.04, 0.82)
			accent_color = Color(0.48, 0.42, 0.34, 0.18)
			panel_fill = Color("222127")
			panel_border = Color("7a6b57")
			accent_alpha = 0.18
		"death":
			overlay_color = Color(0.16, 0.01, 0.03, 0.86)
			pulse_color = Color(0.38, 0.04, 0.08, 0.18)
			accent_color = Color(0.70, 0.23, 0.29, 0.38)
			panel_fill = Color("29161a")
			panel_border = Color("b4545d")
			title_color = Color("ffe4e6")
			body_color = Color("f0d5d9")
			goal_color = Color("f0d5d9")
			button_kind = "npc"
			pulse_alpha = 0.18
			accent_alpha = 0.38
			title_scale = Vector2(1.02, 1.02)
		"awakening":
			overlay_color = Color(0.07, 0.01, 0.12, 0.88)
			pulse_color = Color(0.30, 0.10, 0.45, 0.24)
			accent_color = Color(0.56, 0.34, 0.78, 0.44)
			panel_fill = Color("1f1628")
			panel_border = Color("8f63b0")
			title_color = Color("efe2ff")
			body_color = Color("dfd0ee")
			goal_color = Color("dfd0ee")
			button_kind = "action"
			pulse_alpha = 0.24
			accent_alpha = 0.44
			title_scale = Vector2(1.03, 1.03)
		"opening":
			overlay_color = Color(0, 0, 0, 0.72)
			accent_color = Color(0.30, 0.44, 0.56, 0.18)
			panel_fill = Color("182124")
			panel_border = Color("46606b")
			accent_alpha = 0.18

	_current_opening_button_kind = button_kind
	_opening_overlay_color.color = overlay_color
	_opening_pulse.color = pulse_color
	_opening_accent_bar.color = accent_color
	_opening_panel.add_theme_stylebox_override("panel", _make_panel_style(panel_fill, panel_border, 24))
	_opening_title_label.add_theme_color_override("font_color", title_color)
	_opening_body_label.add_theme_color_override("font_color", body_color)
	_opening_goal_title.add_theme_color_override("font_color", title_color)
	_opening_goal_label.add_theme_color_override("font_color", goal_color)
	_play_opening_style_animation(pulse_alpha, accent_alpha, title_scale)

	for child: Node in _opening_buttons.get_children():
		if child is Button:
			_style_button(child as Button, 48, button_kind)

func _play_opening_style_animation(pulse_alpha: float, accent_alpha: float, title_scale: Vector2) -> void:
	if _opening_visual_tween != null:
		_opening_visual_tween.kill()
	_opening_pulse.modulate = Color(1, 1, 1, 0)
	_opening_accent_bar.modulate = Color(1, 1, 1, accent_alpha)
	_opening_title_label.scale = Vector2.ONE
	_opening_visual_tween = create_tween()
	_opening_visual_tween.set_parallel(true)
	_opening_visual_tween.tween_property(_opening_pulse, "modulate:a", pulse_alpha, 0.45).from(0.0)
	_opening_visual_tween.tween_property(_opening_title_label, "scale", title_scale, 0.35).from(Vector2.ONE)
	if pulse_alpha > 0.0:
		_opening_visual_tween.chain().tween_property(_opening_pulse, "modulate:a", max(pulse_alpha * 0.45, 0.08), 1.2)

func _update_stage_panels(scene_mode: String) -> void:
	_location_panel.visible = scene_mode == "location"
	_event_panel.visible = scene_mode == "event"
	_ending_panel.visible = scene_mode == "ending"
	_battle_panel.visible = scene_mode == "battle"
	_scene_backdrop.visible = scene_mode != "dialogue"
	_scene_interaction_panel.visible = scene_mode == "location" or scene_mode == "route_map"
	_action_scroll.visible = scene_mode != "route_map"
	_scene_overlay.visible = scene_mode != "dialogue"
	_top_bar.visible = scene_mode != "dialogue" and scene_mode != "ending"
	_sidebar.visible = scene_mode != "dialogue" and scene_mode != "ending" and scene_mode != "route_map"
	_status_bar.visible = scene_mode != "dialogue" and scene_mode != "ending" and scene_mode != "route_map"
	_scene_interaction_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL if scene_mode == "route_map" else 0
	_route_map_panel.custom_minimum_size = Vector2(0, 560) if scene_mode == "route_map" else Vector2(0, 230)
	_node_summary_label.visible = scene_mode == "route_map"
	_card_menu_button.visible = scene_mode != "route_map"

	match scene_mode:
		"dialogue":
			_action_title.text = _main_text("action_titles.dialogue")
			_action_title.visible = true
			_close_scene_popup()
		"event":
			_action_title.text = _main_text("action_titles.event")
			_action_title.visible = true
			if _active_scene_menu != "cards":
				_close_scene_popup()
		"ending":
			_action_title.text = _main_text("action_titles.ending")
			_action_title.visible = true
			if _active_scene_menu != "cards":
				_close_scene_popup()
		"battle":
			_action_title.text = _main_text("action_titles.combat")
			_action_title.visible = true
			if _active_scene_menu != "cards":
				_close_scene_popup()
		"route_map":
			_action_title.visible = false
			_action_title.text = "璺嚎閫夋嫨"
			if _active_scene_menu != "cards":
				_close_scene_popup()
		_:
			_action_title.text = _main_text("action_titles.scene")
			_action_title.visible = true

func _build_persistent_card_button() -> void:
	_top_card_button = Button.new()
	_top_card_button.text = _main_text("menu_buttons.cards")
	_top_card_button.custom_minimum_size = Vector2(0, 44)
	_style_button(_top_card_button, 44, "event")
	_top_card_button.pressed.connect(_on_scene_menu_pressed.bind("cards"))
	_top_bar_content.add_child(_top_card_button)

func _update_event_presentation(scene_mode: String, view_model: Dictionary, current_event: Dictionary) -> void:
	var is_dialogue: bool = scene_mode == "dialogue" and not current_event.is_empty()
	var is_event_scene: bool = scene_mode == "event" and not current_event.is_empty()
	_event_panel_title.visible = not is_dialogue
	_event_title_label.visible = false if is_event_scene else not is_dialogue
	_event_body_label.visible = false if is_event_scene else not is_dialogue

	if not is_dialogue:
		_event_body_label.add_theme_font_size_override("font_size", 13)
		_event_body_label.add_theme_color_override("font_color", Color("ddd8cb"))
		_event_type_hint_label.visible = false
		if is_event_scene:
			_event_title_label.text = ""
			_event_body_label.text = ""
		_dialogue_event_panel.clear_panel()
		return


	var speaker_npc_id: String = str(current_event.get("speaker_npc_id", ""))
	var npc_theme: Dictionary = _npc_theme(speaker_npc_id)
	_dialogue_event_panel.configure(
		current_event,
		RunController.get_current_event_option_views(),
		npc_theme,
		str(view_model.get("event_type_text", "")),
		"",
		RunController.get_dialogue_extra_game_states(),
		_scene_background_texture.texture,
		_scene_background.color
	)

func _update_battle_presentation() -> void:
	var battle_view: Dictionary = RunController.get_current_battle_view()
	if battle_view.is_empty():
		_battle_panel.clear_panel()
		return
	_battle_panel.configure(battle_view)

func _update_route_map_presentation(scene_mode: String, route_map_view: Dictionary) -> void:
	if scene_mode != "route_map":
		_route_map_panel.clear_panel()
		return
	_action_title.visible = true
	_action_title.text = str(route_map_view.get("title", "路线选择"))
	_route_map_panel.configure(route_map_view)
	var current_day_text: String = str(route_map_view.get("current_day_text", ""))
	var current_day_title: String = str(route_map_view.get("current_day_title", ""))
	var current_day_description: String = str(route_map_view.get("current_day_description", ""))
	var summary_lines: Array[String] = []
	if not current_day_text.is_empty() or not current_day_title.is_empty():
		summary_lines.append("%s %s" % [current_day_text, current_day_title])
	if not current_day_description.is_empty():
		summary_lines.append(current_day_description)
	var visited_path_text: String = str(route_map_view.get("visited_path_text", ""))
	if not visited_path_text.is_empty():
		summary_lines.append(visited_path_text)
	if not summary_lines.is_empty():
		_node_summary_label.text = "\n\n".join(summary_lines)
	_route_map_panel.focus_first_selectable_node()

func _apply_route_map_scene_theme(scene_mode: String, route_map_view: Dictionary) -> void:
	if scene_mode != "route_map":
		return
	var current_route_key: String = str(route_map_view.get("current_route_key", ""))
	if current_route_key.is_empty():
		_backdrop_tag.visible = true
		_backdrop_tag.text = "路线图"
		_backdrop_tag.add_theme_color_override("font_color", Color("b9d4df"))
		_stage_title_label.add_theme_color_override("font_color", Color("dbe6ef"))
		return
	var route_theme: Dictionary = Dictionary(ROUTE_THEME.get(current_route_key, {}))
	var route_tag: String = str(route_theme.get("tag", route_map_view.get("current_route_text", "路线图")))
	var route_color: Color = Color(route_theme.get("color", Color("b9d4df")))
	_backdrop_tag.visible = true
	_backdrop_tag.text = route_tag
	_backdrop_tag.add_theme_color_override("font_color", route_color.lightened(0.08))
	_stage_title_label.add_theme_color_override("font_color", route_color.lightened(0.2))

func _rebuild_event_options(scene_mode: String, current_event: Dictionary, is_run_over: bool) -> void:
	for child: Node in _event_options_container.get_children():
		child.queue_free()

	if is_run_over or current_event.is_empty() or scene_mode != "event":
		_event_content_title_label.visible = false
		_event_hint_title_label.visible = false
		_event_hint_label.visible = false
		_event_decision_title_label.visible = false
		return

	_event_content_title_label.visible = false
	_event_hint_title_label.visible = not _event_hint_label.text.strip_edges().is_empty()
	_event_hint_label.visible = not _event_hint_label.text.strip_edges().is_empty()
	_event_decision_title_label.visible = true
	var button_kind: String = _event_button_kind(_current_event_type_key)
	for option_view: Dictionary in RunController.get_current_event_option_views():
		var button: Button = Button.new()
		_style_button(button, 68 if _is_compact_event(current_event) else 92, button_kind)
		button.text = _format_event_option_button_text(option_view, str(current_event.get("presentation_type", "standard_event")))
		button.disabled = not bool(option_view.get("is_available", false))
		button.pressed.connect(_on_event_option_pressed.bind(str(option_view.get("id", ""))))
		_event_options_container.add_child(button)

func _update_scene_backdrop(scene_mode: String, current_location: Dictionary, is_run_over: bool) -> void:
	if is_run_over:
		_scene_background.color = Color("2a1216")
		_scene_background_texture.texture = null
		_backdrop_title_label.text = ""
		_backdrop_subtitle_label.text = ""
		_backdrop_note_label.text = ""
		_backdrop_tag.visible = false
		return

	if scene_mode != "location" and scene_mode != "route_map":
		_scene_background_texture.texture = null
		if scene_mode == "dialogue":
			_scene_background.color = Color("242230")
		elif scene_mode == "battle":
			_scene_background.color = Color("251722")
		else:
			_scene_background.color = Color("2e241e")
		_backdrop_title_label.text = ""
		_backdrop_subtitle_label.text = ""
		_backdrop_note_label.text = ""
		_backdrop_tag.visible = scene_mode == "dialogue" or scene_mode == "event"
		return

	var location_id: String = str(current_location.get("id", ""))
	var backdrop_theme: Dictionary = LOCATION_BACKDROP_THEME.get(location_id, {
		"color": Color("24303c"),
		"accent": Color("6f98bf"),
		"title": str(current_location.get("display_name", location_id)),
		"subtitle": str(current_location.get("description", "")),
		"note": _main_text("backdrop.generic_note")
	})
	var accent: Color = backdrop_theme.get("accent", Color("6f98bf"))
	var background_path: String = str(backdrop_theme.get("background_path", ""))
	_scene_background.color = backdrop_theme.get("color", Color("24303c"))
	_scene_background_texture.texture = _load_scene_background_texture(background_path)
	_backdrop_title_label.text = ""
	_backdrop_subtitle_label.text = ""
	_backdrop_note_label.text = ""
	_backdrop_tag.visible = false
	_stage_title_label.add_theme_color_override("font_color", accent.lightened(0.28))

func _load_scene_background_texture(background_path: String) -> Texture2D:
	if background_path.is_empty():
		return null
	if not ResourceLoader.exists(background_path):
		return null
	var resource: Resource = load(background_path)
	if resource is Texture2D:
		return resource as Texture2D
	return null

func _apply_ending_art(run_state: RunState) -> void:
	if run_state == null or run_state.ending_result == null:
		_ending_art_rect.texture = null
		_ending_art_rect.visible = false
		return
	var ending_id: String = str(run_state.ending_result.id)
	var art_path: String = str(ENDING_ART_PATHS.get(ending_id, ""))
	_ending_art_rect.texture = _load_scene_background_texture(art_path)
	_ending_art_rect.visible = _ending_art_rect.texture != null

func _rebuild_scene_hotspots(
	scene_mode: String,
	present_npcs: Array[Dictionary],
	is_run_over: bool
) -> void:
	for child: Node in _scene_actor_layer.get_children():
		child.queue_free()

	if is_run_over:
		return
	if scene_mode != "location" and scene_mode != "route_map":
		return

	for actor_index: int in present_npcs.size():
		var npc_definition: Dictionary = present_npcs[actor_index]
		_scene_actor_layer.add_child(_build_npc_hotspot_button(npc_definition, actor_index))
	call_deferred("_layout_scene_hotspots")

func _rebuild_action_buttons(
	scene_mode: String,
	visible_actions: Array[Dictionary],
	is_run_over: bool
) -> void:
	for child: Node in _actions_container.get_children():
		child.queue_free()

	if is_run_over:
		var restart_button: Button = Button.new()
		_style_button(restart_button, 56, "event")
		restart_button.text = _main_text("buttons.restart")
		restart_button.pressed.connect(_on_restart_pressed)
		_actions_container.add_child(restart_button)
		return

	if scene_mode != "location" and scene_mode != "dialogue" and scene_mode != "route_map":
		return
	if scene_mode == "route_map":
		return

	for action_definition: Dictionary in visible_actions:
		var button: Button = Button.new()
		_style_button(button, 94, "action")
		button.text = _format_action_button_text(action_definition)
		button.pressed.connect(_on_action_pressed.bind(str(action_definition.get("id", ""))))
		_actions_container.add_child(button)

	if _actions_container.get_child_count() == 0:
		var empty_label: Label = Label.new()
		empty_label.text = _main_text("buttons.no_options")
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_color_override("font_color", Color("b7b1a3"))
		_actions_container.add_child(empty_label)

func _sync_popup_state(scene_mode: String, is_run_over: bool) -> void:
	if is_run_over and _active_scene_menu != "cards":
		_close_scene_popup()
		return
	if scene_mode == "battle" and _active_scene_menu != "cards":
		_close_scene_popup()
		return
	if _active_scene_menu.is_empty():
		_hide_popup_content()
		_popup_overlay.visible = false
		return

	match _active_scene_menu:
		"cards":
			_popup_title.text = _main_text("popup_titles.cards")
			_card_column.visible = true
		_:
			_hide_popup_content()
			_popup_overlay.visible = false
			return

	_popup_overlay.visible = true

func _on_action_pressed(action_id: String) -> void:
	RunController.perform_action(action_id)
	_close_scene_popup()

func _on_route_map_node_selected(target_action_id: String) -> void:
	RunController.select_route_map_node(target_action_id)
	_close_scene_popup()

func _on_route_map_node_focused(node_view: Dictionary) -> void:
	_node_summary_label.text = _build_route_map_preview_text(node_view)

func _build_route_map_preview_text(node_view: Dictionary) -> String:
	var lines: Array[String] = []
	var route_map_view: Dictionary = RunController.get_current_route_map_view()
	var current_day_text: String = str(route_map_view.get("current_day_text", ""))
	var current_day_title: String = str(route_map_view.get("current_day_title", ""))
	if not current_day_text.is_empty() or not current_day_title.is_empty():
		lines.append("%s %s" % [current_day_text, current_day_title])
		lines.append("")
	var visited_path_text: String = str(route_map_view.get("visited_path_text", ""))
	if not visited_path_text.is_empty():
		lines.append(visited_path_text)
		lines.append("")
	var route_label: String = str(node_view.get("route_label", ""))
	var type_label: String = str(node_view.get("type_label", "节点"))
	var title_text: String = str(node_view.get("title", ""))
	if not route_label.is_empty():
		lines.append("%s 路 · %s" % [route_label, type_label])
	else:
		lines.append(type_label)
	if not title_text.is_empty():
		lines.append(title_text)

	if bool(node_view.get("is_terminal", false)):
		lines.append("这是当前路线的收束点。点下去后，会进入下一阶段。")
	else:
		var focus_state: String = str(node_view.get("focus_state", "neutral"))
		match focus_state:
			"active":
				lines.append("这一步会继续压深你当前主押的路线。")
			"off_route":
				lines.append("这一步会把推进偏向另一条线。")
			_:
				lines.append("这一步更像是在补信息、调站位，或为后续分支做准备。")

	var hint_text: String = str(node_view.get("hint", ""))
	if not hint_text.is_empty():
		lines.append(hint_text)

	var node_type: String = str(node_view.get("node_type", "story"))
	lines.append(_route_map_node_outlook_text(node_type, bool(node_view.get("is_terminal", false))))

	var lock_reason_text: String = str(node_view.get("lock_reason_text", ""))
	if bool(node_view.get("is_locked", false)):
		lines.append("")
		lines.append("当前还不能进入：")
		lines.append(lock_reason_text if not lock_reason_text.is_empty() else "这个节点还没有解锁。")
	return "\n".join(lines)

func _route_map_node_outlook_text(node_type: String, is_terminal: bool = false) -> String:
	if is_terminal:
		return "预期：确认后将结束当前这段路线，并把流程推进到下一阶段。"
	match node_type:
		"story":
			return "预期：更接近关键剧情推进。"
		"dialogue":
			return "预期：更偏向试探、谈判或经营关系。"
		"reward":
			return "预期：资源、线索或站位收益更稳。"
		"shop":
			return "预期：会接触灰市、交换或临时买路。"
		"review":
			return "预期：更适合收口、整理和稳住状态。"
		"battle":
			return "预期：更容易直接推进到冲突或心战。"
		"risk":
			return "预期：收益更高，但更容易把自己送进危险。"
		_:
			return "预期：这一步会把今天的推进继续向前压一格。"


func _on_event_option_pressed(option_id: String) -> void:
	RunController.choose_event_option(option_id)
	if RunController.get_current_event().is_empty():
		_close_scene_popup()

func _on_dialogue_event_finished() -> void:
	RunController.complete_current_dialogue_event()

func _on_restart_pressed() -> void:
	RunController.start_new_run()

func _on_scene_menu_pressed(menu_id: String) -> void:
	_active_scene_menu = menu_id
	_sync_popup_state("location", false)

func _close_scene_popup() -> void:
	_active_scene_menu = ""
	_popup_overlay.visible = false
	_hide_popup_content()

func _hide_popup_content() -> void:
	_card_column.visible = false

func _on_popup_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and not _popup_panel.get_global_rect().has_point(mouse_event.global_position):
			_close_scene_popup()

func _style_button(button: Button, min_height: float, button_kind: String) -> void:
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.custom_minimum_size = Vector2(0, min_height)
	button.add_theme_stylebox_override("normal", _make_button_style(button_kind, false, false))
	button.add_theme_stylebox_override("hover", _make_button_style(button_kind, true, false))
	button.add_theme_stylebox_override("pressed", _make_button_style(button_kind, true, true))
	button.add_theme_stylebox_override("disabled", _make_button_style(button_kind, false, true))
	button.add_theme_color_override("font_color", Color("f2eee3"))
	button.add_theme_color_override("font_disabled_color", Color("8f9087"))
	var font_size: int = 15
	if button_kind == "location":
		font_size = 16
	elif button_kind.begins_with("event"):
		font_size = 17
	button.add_theme_font_size_override("font_size", font_size)

func _apply_visual_theme() -> void:
	_top_bar.add_theme_stylebox_override("panel", _make_panel_style(Color("243334"), Color("4d6b64"), 18))
	_status_bar.add_theme_stylebox_override("panel", _make_panel_style(Color("312824"), Color("7e6656"), 16))
	_location_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("1d2832"), Color("56718c"), 22))
	_event_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("33231d"), Color("ab7c5f"), 22))
	_ending_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("2f2620"), Color("c4a26f"), 22))
	_scene_interaction_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("182124"), Color("46606b"), 18))
	_popup_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("182124"), Color("46606b"), 20))
	_sidebar.add_theme_stylebox_override("panel", _make_panel_style(Color("222127"), Color("595462"), 18))
	_opening_overlay.get_node("CenterContainer/OpeningPanel").add_theme_stylebox_override("panel", _make_panel_style(Color("182124"), Color("46606b"), 24))
	_scene_actor_layer.mouse_filter = Control.MOUSE_FILTER_PASS

	for menu_button: Button in [_card_menu_button]:
		_style_button(menu_button, 46, "location")
		menu_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		menu_button.custom_minimum_size = Vector2(0, 42)
		menu_button.toggle_mode = false

	_style_button(_popup_close_button, 40, "event")
	_popup_close_button.custom_minimum_size = Vector2(92, 38)
	_style_button(_opening_start_button, 48, "event")
	_opening_start_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_button(_ending_restart_button, 52, "event_boss_battle")
	_ending_restart_button.alignment = HORIZONTAL_ALIGNMENT_CENTER

	for title: Label in [
		_day_label, _phase_label, _remaining_action_label, _track_label, _action_title,
		_stage_title_label, _event_title_label, _ending_title_label, _event_content_title_label, _event_hint_title_label, _event_decision_title_label
	]:
		title.add_theme_font_size_override("font_size", 15)
		title.add_theme_color_override("font_color", Color("f7f1df"))

	for label: Label in [
		_resource_label, _status_label, _stage_body_label, _event_body_label,
		_ending_body_label, _ending_hint_label, _goal_label, _attribute_role_label, _hint_label, _stats_label,
		_backdrop_subtitle_label, _backdrop_note_label, _card_summary_label, _node_summary_label
	]:
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color("ddd8cb"))

	_backdrop_title_label.add_theme_font_size_override("font_size", 24)
	_backdrop_title_label.add_theme_color_override("font_color", Color("f4f0e5"))
	_backdrop_subtitle_label.add_theme_color_override("font_color", Color("d7ddd5"))
	_backdrop_note_label.add_theme_color_override("font_color", Color("aeb4ac"))
	_backdrop_tag.add_theme_font_size_override("font_size", 11)
	_backdrop_tag.add_theme_color_override("font_color", Color("b9d4df"))
	_backdrop_tag.visible = false
	_event_type_hint_label.add_theme_font_size_override("font_size", 13)
	_event_type_hint_label.add_theme_color_override("font_color", Color("d8cfbf"))
	_event_hint_label.add_theme_font_size_override("font_size", 13)
	_event_hint_label.add_theme_color_override("font_color", Color("cfc8bb"))
	_opening_title_label.add_theme_font_size_override("font_size", 26)
	_opening_title_label.add_theme_color_override("font_color", Color("f4f0e5"))
	_opening_body_label.add_theme_font_size_override("font_size", 15)
	_opening_body_label.add_theme_color_override("font_color", Color("ddd8cb"))
	_opening_goal_label.add_theme_font_size_override("font_size", 15)
	_opening_goal_label.add_theme_color_override("font_color", Color("d7ddd5"))
	_opening_goal_title.add_theme_font_size_override("font_size", 15)
	_opening_goal_title.add_theme_color_override("font_color", Color("f4f0e5"))

	_log_label.add_theme_color_override("default_color", Color("d7d2c7"))
	_log_label.add_theme_font_size_override("normal_font_size", 13)
	_apply_event_type_theme("")

func _apply_ending_theme(outcome_type: String) -> void:
	if outcome_type == "death":
		_ending_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("35171b"), Color("d35f6c"), 22))
		_ending_title_label.add_theme_color_override("font_color", Color("ffe3e6"))
		_ending_body_label.add_theme_color_override("font_color", Color("f2d2d7"))
		_ending_hint_label.add_theme_color_override("font_color", Color("f0b7c0"))
		_style_button(_ending_restart_button, 52, "event_boss_battle")
		return
	_ending_panel.add_theme_stylebox_override("panel", _make_panel_style(Color("2f2620"), Color("c4a26f"), 22))
	_ending_title_label.add_theme_color_override("font_color", Color("f7f1df"))
	_ending_body_label.add_theme_color_override("font_color", Color("ddd8cb"))
	_ending_hint_label.add_theme_color_override("font_color", Color("ddd8cb"))
	_style_button(_ending_restart_button, 52, "event")

func _make_panel_style(fill_color: Color, border_color: Color, corner_radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = 6
	style.content_margin_top = 6
	style.content_margin_right = 6
	style.content_margin_bottom = 6
	return style

func _make_button_style(button_kind: String, hovered: bool, muted: bool) -> StyleBoxFlat:
	var base_color: Color = Color("32424a")
	var border_color: Color = Color("5f7b86")
	match button_kind:
		"location":
			base_color = Color("30403a")
			border_color = Color("88a48b")
		"npc":
			base_color = Color("45373d")
			border_color = Color("b08b90")
		"event":
			base_color = Color("4a342b")
			border_color = Color("c89a74")
		"event_story":
			base_color = Color("4a342b")
			border_color = Color("c89a74")
		"event_dialogue":
			base_color = Color("31404d")
			border_color = Color("7fa7c7")
		"event_random":
			base_color = Color("4b4731")
			border_color = Color("d0ba73")
		"event_reward":
			base_color = Color("274435")
			border_color = Color("7cc19d")
		"event_review":
			base_color = Color("31364f")
			border_color = Color("8c92d3")
		"event_shop":
			base_color = Color("4c3728")
			border_color = Color("d6ab76")
		"event_battle":
			base_color = Color("4a2631")
			border_color = Color("d07a98")
		"event_elite_battle":
			base_color = Color("51263f")
			border_color = Color("dd73bf")
		"event_boss_battle":
			base_color = Color("571f27")
			border_color = Color("ef707f")
		"action":
			base_color = Color("243645")
			border_color = Color("77a7cc")

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

func _apply_event_type_theme(event_type_key: String) -> void:
	var theme_key: String = event_type_key if EVENT_TYPE_THEME.has(event_type_key) else "story"
	var theme: Dictionary = EVENT_TYPE_THEME.get(theme_key, EVENT_TYPE_THEME["story"])
	_event_panel.add_theme_stylebox_override(
		"panel",
		_make_panel_style(
			theme.get("panel_fill", Color("33231d")),
			theme.get("panel_border", Color("ab7c5f")),
			22
		)
	)
	_event_panel_title.add_theme_color_override("font_color", theme.get("title", Color("f3e3d3")))
	_event_title_label.add_theme_color_override("font_color", theme.get("title", Color("f3e3d3")))
	_event_body_label.add_theme_color_override("font_color", theme.get("body", Color("ddd1c4")))
	_event_type_hint_label.add_theme_color_override("font_color", theme.get("body", Color("ddd1c4")).lightened(0.08))
	_backdrop_tag.add_theme_color_override("font_color", theme.get("tag", Color("d8b697")))
	_status_label.add_theme_color_override("font_color", theme.get("body", Color("ddd8cb")))

func _event_button_kind(event_type_key: String) -> String:
	var theme: Dictionary = EVENT_TYPE_THEME.get(event_type_key, EVENT_TYPE_THEME.get("story", {}))
	return str(theme.get("button_kind", "event_story"))

func _build_npc_hotspot_button(npc_definition: Dictionary, actor_index: int) -> Button:
	var npc_id: String = str(npc_definition.get("id", ""))
	var npc_theme_data: Dictionary = _npc_theme(npc_id)
	var portrait_path: String = str(npc_definition.get("portrait_path", ""))
	var portrait_texture: Texture2D = _load_scene_background_texture(portrait_path)
	var hotspot: Button = Button.new()
	hotspot.flat = true
	hotspot.text = ""
	hotspot.focus_mode = Control.FOCUS_NONE
	hotspot.mouse_default_cursor_shape = Control.CURSOR_ARROW
	hotspot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hotspot.set_meta("npc_id", npc_id)
	hotspot.set_meta("actor_index", actor_index)
	hotspot.set_meta("base_position", Vector2.ZERO)
	hotspot.anchor_left = 0.0
	hotspot.anchor_top = 0.0
	hotspot.anchor_right = 0.0
	hotspot.anchor_bottom = 0.0
	hotspot.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	hotspot.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	hotspot.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	hotspot.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	if portrait_texture != null:
		hotspot.custom_minimum_size = Vector2(220, 360)
	else:
		hotspot.custom_minimum_size = Vector2(132, 220)
	hotspot.size = hotspot.custom_minimum_size
	var shadow: ColorRect = ColorRect.new()
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.set_anchors_preset(Control.PRESET_FULL_RECT)
	shadow.offset_left = 14
	shadow.offset_top = 28
	shadow.offset_right = -14
	shadow.offset_bottom = -4
	shadow.color = Color(0, 0, 0, 0.18)
	hotspot.add_child(shadow)

	if portrait_texture != null:
		var portrait: TextureRect = TextureRect.new()
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait.name = "Portrait"
		portrait.texture = portrait_texture
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.offset_left = -12
		portrait.offset_top = -10
		portrait.offset_right = 12
		portrait.offset_bottom = 0
		hotspot.add_child(portrait)
	else:
		var avatar_panel: PanelContainer = PanelContainer.new()
		avatar_panel.name = "PlaceholderPanel"
		avatar_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		avatar_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
		avatar_panel.offset_left = 6
		avatar_panel.offset_top = 16
		avatar_panel.offset_right = -6
		avatar_panel.offset_bottom = -16
		avatar_panel.add_theme_stylebox_override("panel", _make_avatar_style(npc_theme_data.get("color", Color("72808c"))))
		hotspot.add_child(avatar_panel)

		var silhouette: ColorRect = ColorRect.new()
		silhouette.mouse_filter = Control.MOUSE_FILTER_IGNORE
		silhouette.set_anchors_preset(Control.PRESET_FULL_RECT)
		silhouette.offset_left = 24
		silhouette.offset_top = 18
		silhouette.offset_right = -24
		silhouette.offset_bottom = -18
		silhouette.color = Color(0.08, 0.09, 0.11, 0.36)
		avatar_panel.add_child(silhouette)

		var name_plate: Label = Label.new()
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_plate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_plate.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		name_plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_plate.size_flags_vertical = Control.SIZE_EXPAND_FILL
		name_plate.text = str(npc_definition.get("display_name", npc_id))
		name_plate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_plate.add_theme_font_size_override("font_size", 14)
		name_plate.add_theme_color_override("font_color", Color("f5f1e6"))
		avatar_panel.add_child(name_plate)

	return hotspot

func _make_avatar_style(fill_color: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = fill_color.lightened(0.24)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	return style

func _build_avatar_glyph(display_name: String) -> String:
	if display_name.is_empty():
		return "?"
	return display_name.left(1)

func _format_event_option_button_text(option_view: Dictionary, presentation_type: String = "standard_event") -> String:
	if bool(option_view.get("is_continue", false)):
		return str(option_view.get("text", _main_text("buttons.event_option_continue_dialogue")))

	if presentation_type == "compact_choice_event" or presentation_type == "summary_event":
		var compact_lines: Array[String] = []
		compact_lines.append(str(option_view.get("text", option_view.get("id", ""))))
		var compact_meta_parts: Array[String] = []
		var compact_check_tag_text: String = str(option_view.get("check_tag_text", ""))
		if not compact_check_tag_text.is_empty():
			compact_meta_parts.append(compact_check_tag_text)
		var compact_difficulty_text: String = str(option_view.get("difficulty_text", ""))
		if not compact_difficulty_text.is_empty():
			compact_meta_parts.append(compact_difficulty_text)
		var compact_check_text: String = str(option_view.get("check_text", ""))
		if not compact_check_text.is_empty():
			compact_meta_parts.append(compact_check_text)
		if not compact_meta_parts.is_empty():
			compact_lines.append(" 路 ".join(compact_meta_parts))
		if not bool(option_view.get("is_available", false)):
			compact_lines.append(str(option_view.get("unmet_text", _main_text("buttons.event_option_unmet_default"))))
		return "\n".join(compact_lines)

	var lines: Array[String] = []
	var check_tag_text: String = str(option_view.get("check_tag_text", ""))
	if not check_tag_text.is_empty():
		lines.append(check_tag_text)
	var difficulty_text: String = str(option_view.get("difficulty_text", ""))
	if not difficulty_text.is_empty():
		lines.append(difficulty_text)
	lines.append(str(option_view.get("text", option_view.get("id", ""))))
	var check_text: String = str(option_view.get("check_text", ""))
	if not check_text.is_empty():
		lines.append(check_text)
	var reward_text: String = str(option_view.get("reward_text", ""))
	if not reward_text.is_empty():
		lines.append(reward_text)
	if bool(option_view.get("is_available", false)):
		lines.append(_main_text("buttons.event_option_continue_dialogue") if presentation_type == "dialogue_event" else _main_text("buttons.event_option_execute"))
	else:
		lines.append(str(option_view.get("unmet_text", _main_text("buttons.event_option_unmet_dialogue") if presentation_type == "dialogue_event" else _main_text("buttons.event_option_unmet_default"))))
	return "\n".join(lines)

func _format_action_button_text(action_definition: Dictionary) -> String:
	var category_labels: Dictionary = {
		"investigate": _main_text("action_category_tags.investigate"),
		"talk": _main_text("action_category_tags.talk"),
		"work": _main_text("action_category_tags.work"),
		"rest": _main_text("action_category_tags.rest"),
		"combat": _main_text("action_category_tags.combat")
	}
	var lines: Array[String] = []
	var category_text: String = str(category_labels.get(str(action_definition.get("action_category", "")), ""))
	if not category_text.is_empty():
		lines.append(category_text)
	lines.append(str(action_definition.get("display_name", action_definition.get("id", ""))))
	var description_text: String = str(action_definition.get("description", ""))
	if not description_text.is_empty():
		lines.append(description_text)
	return "\n".join(lines)

func _is_compact_event(current_event: Dictionary) -> bool:
	var presentation_type: String = str(current_event.get("presentation_type", "standard_event"))
	return presentation_type == "compact_choice_event" or presentation_type == "summary_event"

func _compact_event_body_text(full_text: String) -> String:
	var trimmed_text: String = full_text.strip_edges()
	if trimmed_text.is_empty():
		return ""
	var paragraphs: PackedStringArray = trimmed_text.split("\n\n", false)
	if paragraphs.is_empty():
		return trimmed_text
	return String(paragraphs[0]).strip_edges()

func _contains_npc(npc_id: String, npc_list: Array[Dictionary]) -> bool:
	for npc_definition: Dictionary in npc_list:
		if str(npc_definition.get("id", "")) == npc_id:
			return true
	return false

func _get_npc_display_name(npc_id: String) -> String:
	for npc_definition: Dictionary in _last_present_npcs:
		if str(npc_definition.get("id", "")) == npc_id:
			return str(npc_definition.get("display_name", npc_id))
	return npc_id

func _layout_scene_hotspots() -> void:
	var left_margin: float = 28.0
	var bottom_margin: float = 0.0
	var spacing: float = 18.0
	var cursor_x: float = left_margin
	for child: Node in _scene_actor_layer.get_children():
		if child is Button:
			var hotspot: Button = child as Button
			var hotspot_size: Vector2 = hotspot.get_combined_minimum_size()
			if hotspot_size == Vector2.ZERO:
				hotspot_size = hotspot.custom_minimum_size
			if hotspot_size == Vector2.ZERO:
				hotspot_size = Vector2(220, 360)
			hotspot.size = hotspot_size
			var base_position: Vector2 = Vector2(cursor_x, _scene_actor_layer.size.y - hotspot_size.y - bottom_margin)
			hotspot.position = base_position
			hotspot.set_meta("base_position", base_position)
			cursor_x += hotspot_size.x + spacing

func _main_text(path: String, fallback: String = "") -> String:
	return GAME_TEXT.text("main_screen.%s" % path, fallback)

func _on_battle_slot_selected(slot_index: int) -> void:
	RunController.select_battle_slot(slot_index)

func _on_battle_hand_card_selected(card_id: String) -> void:
	RunController.assign_battle_hand_card(card_id)

func _on_battle_card_dropped_to_slot(slot_index: int, card_id: String) -> void:
	RunController.assign_battle_hand_card_to_slot(slot_index, card_id)

func _on_battle_redraw_requested() -> void:
	RunController.redraw_current_battle_hand()

func _on_battle_resolve_requested() -> void:
	RunController.resolve_current_battle_turn()


func _main_dict(path: String, fallback: Dictionary = {}) -> Dictionary:
	return GAME_TEXT.dict("main_screen.%s" % path, fallback)


func _npc_role_text(npc_id: String) -> String:
	return str(_main_dict("npc_roles").get(npc_id, _main_text("npc_roles.default")))


func _npc_theme(npc_id: String) -> Dictionary:
	var npc_theme_data: Dictionary = NPC_AVATAR_THEME.get(npc_id, {"color": Color("72808c")}).duplicate(true)
	npc_theme_data["role"] = _npc_role_text(npc_id)
	return npc_theme_data
