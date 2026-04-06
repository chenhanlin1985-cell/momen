extends Node

const DEFAULT_RUN_ID: String = "default_run"
const GAME_TEXT := preload("res://systems/content/game_text.gd")
const ENDING_SERVICE_SCRIPT := preload("res://systems/ending/ending_service.gd")
const DIALOGUE_STATE_BRIDGE_SCRIPT := preload("res://systems/dialogue/dialogue_state_bridge.gd")
const LOCATION_SERVICE_SCRIPT := preload("res://systems/location/location_service.gd")
const ROUTE_MAP_SERVICE_SCRIPT := preload("res://systems/route/route_map_service.gd")
const ROUTE_MAP_ACTION_FEEDBACK_EVENT_ID: String = "__route_map_action_feedback__"
const ROUTE_MAP_ACTION_FEEDBACK_KEY: String = "_route_map_action_feedback"
const BATTLE_ENEMY_PORTRAITS: Dictionary = {
	"9501": "res://assets/art/portraits/npcs/00/9501_default.png"
}

var _content_repository: ContentRepository
var _run_initializer: RunInitializer
var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator
var _action_service: ActionService
var _day_flow_service: DayFlowService
var _goal_service: GoalService
var _event_service: EventService
var _dialogue_state_bridge
var _location_service
var _ending_service
var _inheritance_service: InheritanceService
var _battle_service: BattleService
var _route_map_service

func _ready() -> void:
	_content_repository = ContentRepository.new()
	_run_initializer = RunInitializer.new()
	_condition_evaluator = ConditionEvaluator.new()
	_run_state_mutator = RunStateMutator.new()
	_action_service = ActionService.new(_condition_evaluator, _run_state_mutator)
	_day_flow_service = DayFlowService.new(_run_state_mutator)
	_goal_service = GoalService.new(_condition_evaluator, _run_state_mutator)
	_event_service = EventService.new(_condition_evaluator, _run_state_mutator)
	_dialogue_state_bridge = DIALOGUE_STATE_BRIDGE_SCRIPT.new(_run_state_mutator)
	_location_service = LOCATION_SERVICE_SCRIPT.new(_condition_evaluator, _run_state_mutator)
	_ending_service = ENDING_SERVICE_SCRIPT.new(_condition_evaluator)
	_inheritance_service = InheritanceService.new()
	_battle_service = preload("res://systems/battle/battle_service.gd").new()
	_route_map_service = ROUTE_MAP_SERVICE_SCRIPT.new()

func start_new_run(run_id: String = DEFAULT_RUN_ID) -> void:
	var run_state: RunState = _run_initializer.create_run(
		run_id,
		AppState.meta_progress,
		_content_repository
	)
	_route_map_service.clear_route_map_progress(run_state)
	_route_map_service.clear_transition_preview(run_state)
	_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
	_advance_through_empty_non_day_phases(run_state)
	AppState.set_run_state(run_state)
	AppState.emit_run_started(run_state)

func perform_action(action_id: String) -> void:
	if not _ensure_run_for_action():
		return

	var candidate_ids: Array[String] = _get_or_create_current_action_candidates(AppState.current_run_state)
	if not candidate_ids.has(action_id):
		AppState.raise_error(GAME_TEXT.text("action_service.errors.unavailable"))
		return

	if _location_service.is_story_event_action_id(action_id):
		_open_story_event_action(action_id)
		return

	var action_definition: Dictionary = _content_repository.get_action_definition(action_id)
	if action_definition.is_empty():
		AppState.raise_error(GAME_TEXT.format_text("run_controller.errors.action_not_found", [action_id], action_id))
		return

	_run_state_mutator.clear_current_action_candidates(AppState.current_run_state)
	var result: Dictionary = _action_service.execute_action(
		AppState.current_run_state,
		action_definition
	)
	if not result.get("success", false):
		AppState.raise_error(str(result.get("message", GAME_TEXT.text("run_controller.errors.action_failed"))))
		return

	_event_service.collect_action_followups(
		AppState.current_run_state,
		_content_repository,
		action_definition,
		result
	)
	_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "post_action")
	_finalize_progression(AppState.current_run_state, true, true)

func get_visible_actions() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	if not AppState.current_run_state.current_event_id.is_empty():
		return []
	if AppState.current_run_state.world_state.current_phase != "day":
		return []
	var candidate_ids: Array[String] = _get_or_create_current_action_candidates(AppState.current_run_state)
	var visible_actions: Array[Dictionary] = []
	for action_id: String in candidate_ids:
		var definition: Dictionary = _content_repository.get_action_definition(action_id)
		if definition.is_empty():
			continue
		visible_actions.append(definition)
	return visible_actions

func get_current_route_map_view() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	if not AppState.current_run_state.current_event_id.is_empty():
		return {}
	if AppState.current_run_state.current_battle_state != null:
		return {}
	var pending_transition: Dictionary = _route_map_service.get_transition_preview(AppState.current_run_state)
	var candidate_ids: Array[String] = []
	var should_use_campaign_map: bool = _should_use_campaign_route_map(AppState.current_run_state, pending_transition)
	if should_use_campaign_map:
		candidate_ids = _get_available_day_action_ids(AppState.current_run_state)
	elif AppState.current_run_state.world_state.current_phase == "day":
		candidate_ids = _get_or_create_current_action_candidates(AppState.current_run_state)
	var forced_frontier_event_id: String = ""
	if should_use_campaign_map:
		forced_frontier_event_id = str(pending_transition.get("target_event_id", ""))
	if not pending_transition.is_empty() and not should_use_campaign_map:
		return _route_map_service.build_transition_view(AppState.current_run_state, pending_transition)
	if not should_use_campaign_map and AppState.current_run_state.world_state.current_phase != "day":
		return {}
	if candidate_ids.is_empty() and not _route_map_service.has_template_for_day(AppState.current_run_state.world_state.day):
		return {}
	return _route_map_service.build_route_map_view(
		AppState.current_run_state,
		_content_repository,
		_condition_evaluator,
		candidate_ids,
		forced_frontier_event_id
	)

func select_route_map_node(node_id: String) -> void:
	if AppState.current_run_state == null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.no_run"))
		return
	var pending_transition: Dictionary = _route_map_service.get_transition_preview(AppState.current_run_state)
	var should_use_campaign_map: bool = _should_use_campaign_route_map(AppState.current_run_state, pending_transition)
	if not pending_transition.is_empty() and not should_use_campaign_map:
		if str(pending_transition.get("id", "transition_continue")) != node_id:
			AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_failed"))
			return
		_route_map_service.clear_transition_preview(AppState.current_run_state)
		_execute_pending_transition(AppState.current_run_state, pending_transition)
		if AppState.current_run_state.current_event_id.is_empty() and AppState.current_run_state.current_battle_state == null:
			_finalize_progression(AppState.current_run_state, true, true)
		else:
			AppState.set_run_state(AppState.current_run_state)
		return
	var route_map_view: Dictionary = get_current_route_map_view()
	var nodes: Array[Dictionary] = Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null)
	for node_view: Dictionary in nodes:
		if str(node_view.get("id", "")) != node_id:
			continue
		if bool(node_view.get("is_locked", false)):
			var lock_reason_text: String = str(node_view.get("lock_reason_text", "当前节点尚未解锁"))
			AppState.raise_error(lock_reason_text)
			return
		_route_map_service.clear_transition_preview(AppState.current_run_state)
		_route_map_service.set_route_map_cursor(AppState.current_run_state, node_id)
		var target_kind: String = str(node_view.get("target_kind", "action"))
		if should_use_campaign_map and _node_matches_pending_transition(node_view, pending_transition):
			_execute_pending_transition(AppState.current_run_state, pending_transition, true)
			if AppState.current_run_state.current_event_id.is_empty() and AppState.current_run_state.current_battle_state == null:
				_finalize_progression(AppState.current_run_state, true, true)
			else:
				AppState.set_run_state(AppState.current_run_state)
			return
		if should_use_campaign_map:
			_bridge_campaign_route_phase_if_needed(AppState.current_run_state, node_view)
		if target_kind == "event":
			_open_route_map_event(str(node_view.get("target_event_id", "")))
			return
		if target_kind == "transition":
			var transition_preview: Dictionary = {}
			if should_use_campaign_map:
				if not pending_transition.is_empty():
					transition_preview = pending_transition.duplicate(true)
				var immediate_target_event_id: String = _route_map_service.get_immediate_transition_target_event_id(
					AppState.current_run_state.world_state.day,
					node_id
				)
				if not immediate_target_event_id.is_empty():
					transition_preview["target_event_id"] = immediate_target_event_id
			if transition_preview.is_empty():
				transition_preview = {
					"transition_kind": str(node_view.get("target_transition_kind", "advance_then_phase_entry"))
				}
			else:
				transition_preview["transition_kind"] = str(
					node_view.get("target_transition_kind", transition_preview.get("transition_kind", "advance_then_phase_entry"))
				)
			_execute_pending_transition(AppState.current_run_state, transition_preview)
			if AppState.current_run_state.current_event_id.is_empty() and AppState.current_run_state.current_battle_state == null:
				_finalize_progression(AppState.current_run_state, true, true)
			else:
				AppState.set_run_state(AppState.current_run_state)
			return
		if should_use_campaign_map:
			_perform_route_map_action_node(node_view)
			return
		if not _ensure_run_for_action():
			return
		perform_action(str(node_view.get("target_action_id", "")))
		return
	AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_failed"))

func _should_use_campaign_route_map(run_state: RunState, pending_transition: Dictionary) -> bool:
	if run_state == null:
		return false
	if not _route_map_service.has_template_for_day(run_state.world_state.day):
		return false
	if _route_map_service.has_route_map_cursor_for_current_day(run_state):
		return true
	if run_state.world_state.current_phase == "morning":
		return true
	if pending_transition.is_empty():
		return run_state.world_state.current_phase == "day"
	var target_event_id: String = str(pending_transition.get("target_event_id", ""))
	if target_event_id.is_empty():
		return run_state.world_state.current_phase == "day"
	return _route_map_service.has_event_target_for_day(run_state.world_state.day, target_event_id)

func _node_matches_pending_transition(node_view: Dictionary, pending_transition: Dictionary) -> bool:
	if pending_transition.is_empty():
		return false
	if str(node_view.get("target_kind", "")) != "event":
		return false
	return str(node_view.get("target_event_id", "")) == str(pending_transition.get("target_event_id", ""))

func get_current_location() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	return _location_service.get_current_location_definition(
		AppState.current_run_state,
		_content_repository
	)

func get_present_npcs() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	return _location_service.get_present_npcs_for_current_location(
		AppState.current_run_state,
		_content_repository
	)

func get_current_location_mount_trace() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	var location_id: String = AppState.current_run_state.world_state.current_location_id
	var content_slots: Dictionary = _content_repository.get_location_content_slots(location_id)
	var traced_ids: Array[String] = []
	var traces: Array[Dictionary] = []
	for slot_key: String in ["fixed_events", "investigation_events", "random_events"]:
		var event_ids: Array[String] = Array(content_slots.get(slot_key, []), TYPE_STRING, "", null)
		for event_id: String in event_ids:
			if traced_ids.has(event_id):
				continue
			traced_ids.append(event_id)
			var definition: Dictionary = _content_repository.get_story_event_definition(AppState.current_run_state.run_id, event_id)
			if definition.is_empty():
				continue
			var trace: Dictionary = _build_story_event_trace(definition)
			trace["mount_slot"] = slot_key
			traces.append(trace)
	return traces

func get_present_npc_state_event_trace() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	var traces: Array[Dictionary] = []
	var traced_ids: Array[String] = []
	for npc_definition: Dictionary in get_present_npcs():
		var npc_id: String = str(npc_definition.get("id", ""))
		var npc_name: String = str(npc_definition.get("display_name", npc_id))
		for event_id: String in _content_repository.get_npc_state_event_ids(npc_id):
			var trace_key: String = "%s::%s" % [npc_id, event_id]
			if traced_ids.has(trace_key):
				continue
			traced_ids.append(trace_key)
			var definition: Dictionary = _content_repository.get_story_event_definition(AppState.current_run_state.run_id, event_id)
			if definition.is_empty():
				continue
			var trace: Dictionary = _build_story_event_trace(definition)
			trace["npc_id"] = npc_id
			trace["npc_name"] = npc_name
			traces.append(trace)
	return traces

func get_current_event() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	return _event_service.get_current_event_definition(
		AppState.current_run_state,
		_content_repository
	)

func get_current_battle_view() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return {}
	var card_definitions_by_id: Dictionary = {}
	for card_definition: Dictionary in _content_repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		card_definitions_by_id[card_id] = card_definition
	var battle_view: Dictionary = _battle_service.build_battle_view(
		battle_state,
		card_definitions_by_id,
		_content_repository.get_battle_texts()
	)
	var current_event: Dictionary = get_current_event()
	var speaker_npc_id: String = str(current_event.get("speaker_npc_id", ""))
	var battle_type_data: Dictionary = _resolve_battle_type_ui_data(str(current_event.get("id", "")), battle_state.battle_id)
	if not battle_type_data.is_empty():
		battle_view["title_text"] = str(battle_type_data.get("title", battle_view.get("title_text", "")))
		battle_view["status_text"] = str(battle_type_data.get("description", battle_view.get("status_text", "")))
	if not speaker_npc_id.is_empty():
		var npc_definition: Dictionary = _content_repository.get_npc_definition(speaker_npc_id)
		if not npc_definition.is_empty():
			battle_view["enemy_stage_name_text"] = str(npc_definition.get("display_name", battle_state.enemy_display_name))
			battle_view["enemy_portrait_path"] = str(current_event.get("speaker_portrait_path", npc_definition.get("portrait_path", "")))
			battle_view["enemy_portrait_placeholder"] = str(
				npc_definition.get("portrait_placeholder", battle_state.enemy_display_name)
			)
	elif BATTLE_ENEMY_PORTRAITS.has(battle_state.battle_id):
		battle_view["enemy_portrait_path"] = str(BATTLE_ENEMY_PORTRAITS.get(battle_state.battle_id, ""))
		battle_view["enemy_portrait_placeholder"] = str(battle_state.enemy_display_name)
	return battle_view

func sync_current_battle_state() -> bool:
	if AppState.current_run_state == null:
		return false
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return false
	var card_definitions_by_id: Dictionary = {}
	for card_definition: Dictionary in _content_repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		card_definitions_by_id[card_id] = card_definition
	var did_finish: bool = _battle_service.sync_terminal_state(
		battle_state,
		card_definitions_by_id,
		_content_repository.get_battle_texts()
	)
	if did_finish:
		_complete_current_battle()
	return did_finish

func _resolve_battle_type_ui_data(event_id: String, battle_id: String) -> Dictionary:
	var battle_key: String = "normal_battle"
	if battle_id == "9101" or event_id == "2001":
		battle_key = "boss_battle"
	elif battle_id in ["9201", "9301", "9401"] or event_id in ["2004", "2005", "2003"]:
		battle_key = "elite_battle"
	return {
		"title": GAME_TEXT.text("view_model.event_types.%s" % battle_key),
		"description": GAME_TEXT.text("view_model.event_type_descriptions.%s" % battle_key)
	}

func get_card_library_summary() -> String:
	if AppState.current_run_state == null:
		return ""
	var story_id: String = AppState.current_run_state.story_id
	var owned_card_ids: Array[String] = []
	for battle_definition: Dictionary in _content_repository.get_battle_definitions():
		if str(battle_definition.get("story_id", "")) != story_id:
			continue
		for card_id: String in Array(battle_definition.get("starter_deck", []), TYPE_STRING, "", null):
			if AppState.current_run_state.player_state.removed_battle_card_ids.has(card_id):
				continue
			if not owned_card_ids.has(card_id):
				owned_card_ids.append(card_id)
	for card_id: String in AppState.current_run_state.player_state.battle_card_ids:
		if AppState.current_run_state.player_state.removed_battle_card_ids.has(card_id):
			continue
		if not owned_card_ids.has(card_id):
			owned_card_ids.append(card_id)

	var clue_lines: Array[String] = []
	var emotion_lines: Array[String] = []
	var battle_texts: Dictionary = _content_repository.get_battle_texts()
	var multi_role_label: String = str(battle_texts.get("battle.ui.card_role.01", "MULTI"))
	var base_role_label: String = str(battle_texts.get("battle.ui.card_role.02", "BASE"))
	owned_card_ids.sort()
	for card_id: String in owned_card_ids:
		var card_definition: Dictionary = _content_repository.get_battle_card_definition(card_id)
		if card_definition.is_empty():
			continue
		var display_name: String = str(card_definition.get("display_name", card_id))
		var description_text: String = str(battle_texts.get(str(card_definition.get("text_key", "")), ""))
		var line: String = "%s\n%s" % [display_name, description_text] if not description_text.is_empty() else display_name
		if str(card_definition.get("card_group", "")) == "01":
			clue_lines.append(line)
		else:
			emotion_lines.append(line)

	var lines: Array[String] = []
	lines.append(
		GAME_TEXT.format_text(
			"main_screen.card_popup.summary",
			[owned_card_ids.size()],
			str(owned_card_ids.size())
		)
	)
	if not clue_lines.is_empty():
		lines.append("")
		lines.append("%s 牌" % multi_role_label)
		for line: String in clue_lines:
			lines.append(GAME_TEXT.format_text("main_screen.card_popup.entry", [line], line))
	if not emotion_lines.is_empty():
		lines.append("")
		lines.append("%s 牌" % base_role_label)
		for line: String in emotion_lines:
			lines.append(GAME_TEXT.format_text("main_screen.card_popup.entry", [line], line))
	if owned_card_ids.is_empty():
		lines.append("")
		lines.append(GAME_TEXT.text("main_screen.card_popup.empty"))
	return "\n".join(lines)

func select_battle_slot(slot_index: int) -> void:
	if AppState.current_run_state == null or AppState.current_run_state.current_battle_state == null:
		return
	AppState.current_run_state.current_battle_state.selected_slot_index = slot_index
	AppState.set_run_state(AppState.current_run_state)

func assign_battle_hand_card(card_ref: String) -> void:
	if AppState.current_run_state == null:
		return
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return
	if battle_state.selected_slot_index < 0:
		AppState.raise_error(_battle_error_text("battle.slot_required"))
		return
	var card_definition: Dictionary = _content_repository.get_battle_card_definition(
		_battle_service.resolve_card_definition_id(card_ref)
	)
	if card_definition.is_empty():
		AppState.raise_error(_battle_error_text("battle.cards_missing"))
		return
	var result: Dictionary = _battle_service.assign_card_to_slot(
		battle_state,
		battle_state.selected_slot_index,
		card_ref,
		card_definition
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(_battle_error_text(str(result.get("message", ""))))
		return
	AppState.set_run_state(AppState.current_run_state)

func assign_battle_hand_card_to_slot(slot_index: int, card_ref: String) -> void:
	if AppState.current_run_state == null:
		return
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return
	battle_state.selected_slot_index = slot_index
	var card_definition: Dictionary = _content_repository.get_battle_card_definition(
		_battle_service.resolve_card_definition_id(card_ref)
	)
	if card_definition.is_empty():
		AppState.raise_error(_battle_error_text("battle.cards_missing"))
		return
	var result: Dictionary = _battle_service.assign_card_to_slot(
		battle_state,
		slot_index,
		card_ref,
		card_definition
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(_battle_error_text(str(result.get("message", ""))))
		return
	AppState.set_run_state(AppState.current_run_state)

func redraw_current_battle_hand() -> void:
	if AppState.current_run_state == null:
		return
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return
	var card_definitions_by_id: Dictionary = {}
	for card_definition: Dictionary in _content_repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		card_definitions_by_id[card_id] = card_definition
	var result: Dictionary = _battle_service.redraw_hand(
		battle_state,
		battle_state.hand_cards.size(),
		card_definitions_by_id,
		_content_repository.get_battle_texts()
	)
	if not _to_bool(result.get("success", false)):
		if battle_state.is_battle_over:
			_complete_current_battle()
			return
		AppState.raise_error(_battle_error_text(str(result.get("message", ""))))
		return
	if battle_state.is_battle_over:
		_complete_current_battle()
		return
	AppState.set_run_state(AppState.current_run_state)

func resolve_current_battle_turn() -> void:
	if AppState.current_run_state == null:
		return
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return
	var card_definitions_by_id: Dictionary = {}
	for card_definition: Dictionary in _content_repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		card_definitions_by_id[card_id] = card_definition
	var result: Dictionary = _battle_service.resolve_turn(
		battle_state,
		card_definitions_by_id,
		_content_repository.get_battle_texts()
	)
	if not _to_bool(result.get("success", false)):
		if battle_state.is_battle_over:
			_complete_current_battle()
			return
		AppState.raise_error(_battle_error_text(str(result.get("message", ""))))
		return
	if _to_bool(result.get("battle_over", false)):
		_complete_current_battle()
		return
	AppState.set_run_state(AppState.current_run_state)

func get_event_hints() -> Array[String]:
	if AppState.current_run_state == null:
		return []
	return _event_service.get_event_hints(
		AppState.current_run_state,
		_content_repository
	)

func choose_event_option(option_id: String) -> void:
	if AppState.current_run_state == null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.no_run"))
		return

	var result: Dictionary = _event_service.choose_option(
		AppState.current_run_state,
		_content_repository,
		option_id
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(str(result.get("message", GAME_TEXT.text("run_controller.errors.event_resolution_failed"))))
		return

	_finalize_progression(AppState.current_run_state, true, true)

func get_current_event_option_views() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	return _event_service.get_current_event_option_views(
		AppState.current_run_state,
		_content_repository
	)

func get_dialogue_extra_game_states() -> Array:
	if AppState.current_run_state == null:
		return []
	_dialogue_state_bridge.bind_run(AppState.current_run_state)
	return [{"bridge": _dialogue_state_bridge}]

func complete_current_dialogue_event() -> void:
	if AppState.current_run_state == null:
		return
	if AppState.current_run_state.current_event_id.is_empty():
		return

	var finished_event_id: String = AppState.current_run_state.current_event_id
	_run_state_mutator.mark_event_triggered(AppState.current_run_state, finished_event_id)
	_run_state_mutator.clear_current_event(AppState.current_run_state)
	_finalize_progression(AppState.current_run_state, true, true)

func get_attribute_roles() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	var run_definition: Dictionary = _content_repository.get_run_definition(AppState.current_run_state.run_id)
	var player_init: Dictionary = Dictionary(run_definition.get("player_init", {}))
	return Dictionary(player_init.get("attribute_roles", {}))


func get_opening_data(run_id: String = DEFAULT_RUN_ID) -> Dictionary:
	var run_definition: Dictionary = _content_repository.get_run_definition(run_id)
	if run_definition.is_empty():
		return {}
	return {
		"run_id": run_id,
		"title": str(run_definition.get("opening_title", run_definition.get("display_name", run_id))),
		"lines": Array(run_definition.get("opening_lines", []), TYPE_STRING, "", null),
		"sequence": Array(run_definition.get("opening_sequence", []), TYPE_DICTIONARY, "", null),
		"goal_summary": str(run_definition.get("opening_goal_summary", "")),
		"start_button_text": str(run_definition.get("opening_start_button_text", GAME_TEXT.text("main_screen.opening.button_start")))
	}

func _build_story_event_trace(definition: Dictionary) -> Dictionary:
	var run_state: RunState = AppState.current_run_state
	var event_id: String = str(definition.get("id", ""))
	var trigger_conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
	var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
	var repeatable: bool = _to_bool(definition.get("repeatable", false))
	var trace: Dictionary = {
		"id": event_id,
		"title": str(definition.get("title", event_id)),
		"content_category": str(definition.get("content_category", "")),
		"time_slot": str(definition.get("time_slot", "")),
		"status": "pending",
		"reason_text": ""
	}

	if not repeatable and run_state.triggered_event_ids.has(event_id):
		trace["status"] = "resolved"
		trace["reason_text"] = GAME_TEXT.text("run_controller.trace_reasons.resolved")
		return trace

	if not block_conditions.is_empty() and _condition_evaluator.evaluate_all(run_state, block_conditions):
		trace["status"] = "blocked"
		trace["reason_text"] = GAME_TEXT.text("run_controller.trace_reasons.blocked")
		return trace

	if _condition_evaluator.evaluate_all(run_state, trigger_conditions):
		trace["status"] = "ready"
		trace["reason_text"] = GAME_TEXT.text("run_controller.trace_reasons.ready")
		return trace

	var unmet: Array[String] = _condition_evaluator.get_unmet_descriptions(run_state, trigger_conditions)
	trace["status"] = "pending"
	trace["reason_text"] = " / ".join(unmet)
	return trace

func _advance_through_empty_non_day_phases(run_state: RunState) -> void:
	var guard: int = 0
	while (
		guard < 8
		and not run_state.is_run_over
		and run_state.current_event_id.is_empty()
		and run_state.current_battle_state == null
		and run_state.world_state.current_phase != "day"
	):
		guard += 1
		if run_state.world_state.current_phase == "night":
			_event_service.resolve_current_or_next_event(run_state, _content_repository, "night_tail")
			if not run_state.current_event_id.is_empty() or run_state.current_battle_state != null:
				return
		_day_flow_service.advance_after_event(run_state)
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")

func _resolve_after_completed_step(run_state: RunState) -> void:
	if run_state.is_run_over or not run_state.current_event_id.is_empty() or run_state.current_battle_state != null:
		return
	_run_state_mutator.clear_current_action_candidates(run_state)
	_route_map_service.clear_transition_preview(run_state)
	if _route_map_service.has_template_for_day(run_state.world_state.day) and _route_map_service.has_route_map_cursor_for_current_day(run_state):
		if _route_map_service.has_remaining_route_map_choices(
			run_state,
			_content_repository,
			_condition_evaluator,
			_get_available_day_action_ids(run_state)
		):
			return
	var pending_transition: Dictionary = _build_transition_preview(run_state)
	if run_state.world_state.current_phase == "morning" and _route_map_service.has_template_for_day(run_state.world_state.day):
		var has_cursor: bool = _route_map_service.has_route_map_cursor_for_current_day(run_state)
		var pending_target_event_id: String = str(pending_transition.get("target_event_id", ""))
		if not has_cursor and not pending_target_event_id.is_empty() and _route_map_service.has_event_target_for_day(
			run_state.world_state.day,
			pending_target_event_id
		):
			_route_map_service.set_transition_preview(run_state, pending_transition)
			return
		if _route_map_service.has_remaining_route_map_choices(
			run_state,
			_content_repository,
			_condition_evaluator,
			_get_available_day_action_ids(run_state)
		):
			return
	if not pending_transition.is_empty():
		_route_map_service.set_transition_preview(run_state, pending_transition)
		return
	if run_state.world_state.current_phase == "day":
		if _route_map_service.has_remaining_route_map_choices(
			run_state,
			_content_repository,
			_condition_evaluator,
			_get_available_day_action_ids(run_state)
		):
			return
		_route_map_service.clear_route_map_progress(run_state)
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "day_tail")
		if not run_state.current_event_id.is_empty() or run_state.current_battle_state != null:
			return
	if run_state.world_state.current_phase == "night":
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "night_tail")
		if not run_state.current_event_id.is_empty() or run_state.current_battle_state != null:
			return
	_day_flow_service.advance_after_event(run_state)
	if run_state.world_state.current_phase == "day":
		_route_map_service.clear_route_map_progress(run_state)
	_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
	_advance_through_empty_non_day_phases(run_state)

func _finalize_progression(run_state: RunState, refresh_goals: bool = true, advance_if_idle: bool = true) -> void:
	if refresh_goals:
		_goal_service.refresh_goal_progress(run_state, _content_repository)
	if advance_if_idle and run_state.current_event_id.is_empty():
		_resolve_after_completed_step(run_state)
	if run_state.is_run_over and run_state.ending_result == null:
		_log_resolved_ending(run_state)
		var inheritance_options: Array[Dictionary] = _inheritance_service.generate_options(run_state)
		_run_state_mutator.append_log(
			run_state,
			GAME_TEXT.format_text(
				"run_controller.logs.inheritance_count",
				[inheritance_options.size()],
				str(inheritance_options.size())
			)
		)
	AppState.set_run_state(run_state)

func _resolve_run_ending(run_state: RunState) -> RefCounted:
	var ending_definitions: Array[Dictionary] = _content_repository.get_ending_definitions()
	var flow_definition: Dictionary = _content_repository.get_main_story_flow_definition(run_state.run_id)
	var flow_result: RefCounted = _ending_service.resolve_story_flow_ending(
		run_state,
		flow_definition,
		ending_definitions
	)
	if not String(flow_result.id).is_empty():
		return flow_result
	return _ending_service.resolve_ending(run_state, ending_definitions)

func _ensure_run_for_action() -> bool:
	if AppState.current_run_state == null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.no_run"))
		return false
	if not AppState.current_run_state.current_event_id.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.handle_event_first"))
		return false
	if AppState.current_run_state.world_state.current_phase != "day":
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.not_day_phase"))
		return false
	return true

func _log_resolved_ending(run_state: RunState) -> void:
	var ending_result = _resolve_run_ending(run_state)
	_run_state_mutator.set_ending_result(run_state, ending_result)
	_run_state_mutator.append_log(
		run_state,
		GAME_TEXT.format_text("run_controller.logs.ending_reached", [ending_result.title], str(ending_result.title))
	)


func _open_story_event_action(action_id: String) -> void:
	var event_id: String = _location_service.resolve_story_event_action_id(action_id)
	if event_id.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_not_found"))
		return

	for action_definition: Dictionary in get_visible_actions():
		if str(action_definition.get("id", "")) != action_id:
			continue
		_run_state_mutator.set_last_action_id(AppState.current_run_state, event_id)
		_run_state_mutator.set_last_action_category(AppState.current_run_state, "story_followup")
		_set_current_event_and_start_battle(AppState.current_run_state, event_id)
		AppState.set_run_state(AppState.current_run_state)
		return

	AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_failed"))

func _open_route_map_event(event_id: String) -> void:
	if event_id.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_not_found"))
		return
	var definition: Dictionary = _content_repository.get_story_event_definition(AppState.current_run_state.run_id, event_id)
	if definition.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_not_found"))
		return
	_run_state_mutator.clear_current_action_candidates(AppState.current_run_state)
	_run_state_mutator.set_last_action_id(AppState.current_run_state, event_id)
	_run_state_mutator.set_last_action_category(AppState.current_run_state, "route_map_event")
	_set_current_event_and_start_battle(AppState.current_run_state, event_id)
	AppState.set_run_state(AppState.current_run_state)

func _perform_route_map_action_node(node_view: Dictionary) -> void:
	if AppState.current_run_state == null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.no_run"))
		return
	if not AppState.current_run_state.current_event_id.is_empty() or AppState.current_run_state.current_battle_state != null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.handle_event_first"))
		return
	if AppState.current_run_state.world_state.current_phase != "day":
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.not_day_phase"))
		return
	var action_id: String = str(node_view.get("target_action_id", ""))
	var action_definition: Dictionary = _content_repository.get_action_definition(action_id)
	if action_definition.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.action_not_found"))
		return
	_run_state_mutator.clear_current_action_candidates(AppState.current_run_state)
	var result: Dictionary = _action_service.execute_action(
		AppState.current_run_state,
		action_definition
	)
	if not result.get("success", false):
		AppState.raise_error(str(result.get("message", GAME_TEXT.text("run_controller.errors.action_failed"))))
		return
	# Route-map actions are deterministic route steps; they should apply action effects
	# without being overwritten by the legacy post_action random scheduler.
	_event_service.collect_action_followups(
		AppState.current_run_state,
		_content_repository,
		action_definition,
		result
	)
	AppState.current_run_state.world_state.values[ROUTE_MAP_ACTION_FEEDBACK_KEY] = _build_route_map_action_feedback_event(
		node_view,
		action_definition
	)
	_run_state_mutator.set_current_event(AppState.current_run_state, ROUTE_MAP_ACTION_FEEDBACK_EVENT_ID)
	AppState.set_run_state(AppState.current_run_state)

func _build_route_map_action_feedback_event(node_view: Dictionary, action_definition: Dictionary) -> Dictionary:
	var node_type: String = str(node_view.get("node_type", _resolve_fallback_route_action_type(action_definition)))
	var title: String = str(node_view.get("title", action_definition.get("display_name", action_definition.get("id", ""))))
	var summary_lines: Array[String] = []
	var framing_text: String = _build_route_action_feedback_framing(node_type, title)
	if not framing_text.is_empty():
		summary_lines.append(framing_text)
	var node_hint: String = str(node_view.get("hint", "")).strip_edges()
	var action_description: String = str(action_definition.get("description", "")).strip_edges()
	if not node_hint.is_empty():
		summary_lines.append(node_hint)
	elif not action_description.is_empty():
		summary_lines.append(action_description)
	var reward_text: String = _build_route_action_reward_summary(action_definition)
	if not reward_text.is_empty():
		summary_lines.append(reward_text)
	var body_text: String = "\n\n".join(summary_lines)
	if body_text.is_empty():
		body_text = GAME_TEXT.text("run_controller.logs.action_completed", "这一步已经完成。")
	return {
		"id": ROUTE_MAP_ACTION_FEEDBACK_EVENT_ID,
		"title": title,
		"description": body_text,
		"presentation_type": "summary_event" if node_type == "review" else "standard_event",
		"content_category": "route_map_action",
		"event_type_key": node_type,
		"awaiting_continue": true
	}

func _build_route_action_feedback_framing(node_type: String, title: String) -> String:
	match node_type:
		"reward":
			if title.is_empty():
				return "这一手先替你换回了立刻能落袋的收获，也让眼前局面多了一点可用余地。"
			return "你先把「%s」这一步做实了，手里也因此多出一份立刻能派上用场的收获。" % title
		"review":
			if title.is_empty():
				return "你先把脚步压住，借这一手重新整理心绪和盘算，再决定接下来往哪一侧发力。"
			return "你先借「%s」把脚步压住，给自己腾出一口重新盘算和稳住局面的气。" % title
		"dialogue":
			if title.is_empty():
				return "这一步更像一次试探性的接触。话说得不重，但场中的气口已经悄悄起了变化。"
			return "「%s」更像一次带着分寸的试探。话说得不重，但场中的气口已经开始往另一边偏。 " % title
		"risk":
			if title.is_empty():
				return "你沿着这一步碰到了更紧的风声。事情没立刻失控，但周围已经开始起波澜。"
			return "你顺着「%s」往前试了一步，周围的风声也立刻紧了起来，局势已经不再平稳。" % title
		"battle":
			if title.is_empty():
				return "这一步已经把局势压到了正面冲突的边缘，再往前走就会是真正的硬碰。"
			return "「%s」已经把局势压到了正面冲突的边缘，再往前半步就会是真正的硬碰。" % title
		"shop":
			if title.is_empty():
				return "你顺着这一步摸到了能换来实利的门路，场上能动用的余地也稍微宽了一些。"
			return "你先沿着「%s」摸到一条能换来实利的门路，手里能周转的余地也跟着宽了一点。" % title
		_:
			if title.is_empty():
				return "这一步已经落地，场中的线头也跟着往前推了一截。"
			return "你先把「%s」这一步落稳，眼下局势也随之往前推进了一截。" % title

func _build_route_action_reward_summary(action_definition: Dictionary) -> String:
	var parts: Array[String] = []
	var resource_labels: Dictionary = {
		"blood_qi": "血气",
		"spirit_stone": "灵石",
		"spirit_sense": "灵识",
		"clue_fragments": "线索碎片",
		"pollution": "污染",
		"exposure": "暴露"
	}
	var stat_labels: Dictionary = {
		"physique": "体魄",
		"mind": "心神",
		"insight": "洞察",
		"occult": "玄感",
		"tact": "机变"
	}
	var costs: Dictionary = Dictionary(Dictionary(action_definition.get("base_costs", {})).get("resources", {}))
	var rewards: Dictionary = Dictionary(Dictionary(action_definition.get("base_rewards", {})).get("resources", {}))
	var stats: Dictionary = Dictionary(Dictionary(action_definition.get("base_rewards", {})).get("stats", {}))
	for key: String in costs.keys():
		parts.append("%s -%d" % [str(resource_labels.get(key, key)), int(costs[key])])
	for key: String in rewards.keys():
		parts.append("%s +%d" % [str(resource_labels.get(key, key)), int(rewards[key])])
	for key: String in stats.keys():
		parts.append("%s +%d" % [str(stat_labels.get(key, key)), int(stats[key])])
	if parts.is_empty():
		return ""
	return "本次变化：\n- %s" % "\n- ".join(parts)

func _resolve_fallback_route_action_type(action_definition: Dictionary) -> String:
	var action_category: String = str(action_definition.get("action_category", ""))
	match action_category:
		"rest":
			return "review"
		"work":
			return "reward"
		"talk":
			return "dialogue"
		"investigate":
			return "story"
		_:
			return "story"

func _bridge_campaign_route_phase_if_needed(run_state: RunState, node_view: Dictionary) -> void:
	if run_state == null:
		return
	if run_state.world_state.current_phase != "morning":
		return
	if not _route_map_service.has_template_for_day(run_state.world_state.day):
		return
	if str(node_view.get("target_kind", "")) == "transition":
		return
	_day_flow_service.advance_after_event(run_state)
	_run_state_mutator.clear_current_action_candidates(run_state)

func _execute_pending_transition(run_state: RunState, preview: Dictionary, preserve_route_map_progress: bool = false) -> void:
	var transition_kind: String = str(preview.get("transition_kind", "advance_then_phase_entry"))
	var target_event_id: String = str(preview.get("target_event_id", ""))
	match transition_kind:
		"phase_entry":
			if not target_event_id.is_empty():
				_route_map_service.advance_cursor_to_matching_successor_event(run_state, target_event_id)
				_set_current_event_and_start_battle(run_state, target_event_id)
			else:
				_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
		"day_tail":
			_event_service.resolve_current_or_next_event(run_state, _content_repository, "day_tail")
		"night_tail":
			_event_service.resolve_current_or_next_event(run_state, _content_repository, "night_tail")
		"advance_then_phase_entry":
			_day_flow_service.advance_after_event(run_state)
			if run_state.world_state.current_phase == "day" and not preserve_route_map_progress:
				_route_map_service.clear_route_map_progress(run_state)
			if not target_event_id.is_empty():
				_route_map_service.advance_cursor_to_matching_successor_event(run_state, target_event_id)
				_set_current_event_and_start_battle(run_state, target_event_id)
			else:
				_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
				_advance_through_empty_non_day_phases(run_state)
		_:
			_day_flow_service.advance_after_event(run_state)
			if run_state.world_state.current_phase == "day" and not preserve_route_map_progress:
				_route_map_service.clear_route_map_progress(run_state)
			if not target_event_id.is_empty():
				_route_map_service.advance_cursor_to_matching_successor_event(run_state, target_event_id)
				_set_current_event_and_start_battle(run_state, target_event_id)
			else:
				_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
				_advance_through_empty_non_day_phases(run_state)

func _build_transition_preview(run_state: RunState) -> Dictionary:
	var phase_entry_definition: Dictionary = _event_service.preview_next_event_definition(
		run_state,
		_content_repository,
		"phase_entry"
	)
	if not phase_entry_definition.is_empty():
		return _make_transition_preview(run_state, phase_entry_definition, "phase_entry")
	if run_state.world_state.current_phase == "day" and _route_map_service.has_remaining_route_map_choices(
		run_state,
		_content_repository,
		_condition_evaluator,
		_get_available_day_action_ids(run_state)
	):
		return {}
	var tail_slot: String = ""
	if run_state.world_state.current_phase == "day":
		tail_slot = "day_tail"
	elif run_state.world_state.current_phase == "night":
		tail_slot = "night_tail"
	if not tail_slot.is_empty():
		var tail_definition: Dictionary = _event_service.preview_next_event_definition(
			run_state,
			_content_repository,
			tail_slot
		)
		if not tail_definition.is_empty():
			return _make_transition_preview(run_state, tail_definition, tail_slot)
	return _build_phase_advance_preview(run_state)

func _build_phase_advance_preview(run_state: RunState) -> Dictionary:
	var next_state: Dictionary = _describe_next_phase_state(run_state)
	if _to_bool(next_state.get("ends_run", false)):
		return {}
	var next_phase: String = str(next_state.get("phase", ""))
	var next_day: int = int(next_state.get("day", run_state.world_state.day))
	var preview_event: Dictionary = _preview_phase_entry_after_advance(run_state, next_day, next_phase)
	var title: String = str(next_state.get("title", "继续推进"))
	var hint: String = str(next_state.get("hint", "确认后进入下一段流程。"))
	if not preview_event.is_empty():
		title = str(preview_event.get("title", title))
		var description_text: String = str(preview_event.get("description", ""))
		if not description_text.is_empty():
			hint = description_text
	return {
		"id": "transition_%s_%d" % [next_phase, next_day],
		"transition_kind": "advance_then_phase_entry",
		"target_event_id": str(preview_event.get("id", "")),
		"node_type": str(next_state.get("node_type", "story")),
		"type_label": str(next_state.get("type_label", "后续")),
		"title": title,
		"hint": hint,
		"summary": str(next_state.get("summary", hint)),
		"view_title": str(next_state.get("view_title", "后续选择")),
		"view_description": str(next_state.get("view_description", "当前事件已结束，请确认下一步推进。")),
		"start_title": str(next_state.get("start_title", "当前阶段")),
		"start_hint": str(next_state.get("start_hint", "这一段流程即将继续推进。")),
		"phase_text": str(next_state.get("phase_text", ""))
	}

func _make_transition_preview(run_state: RunState, event_definition: Dictionary, transition_kind: String) -> Dictionary:
	var phase_name: String = _phase_preview_label(run_state.world_state.current_phase, run_state.world_state.day)
	return {
		"id": "transition_%s_%s" % [transition_kind, str(event_definition.get("id", ""))],
		"transition_kind": transition_kind,
		"target_event_id": str(event_definition.get("id", "")),
		"node_type": _event_node_type_for_transition(event_definition),
		"type_label": _transition_type_label(_event_node_type_for_transition(event_definition)),
		"title": str(event_definition.get("title", event_definition.get("id", "继续推进"))),
		"hint": str(event_definition.get("description", "确认后进入下一事件。")),
		"summary": str(event_definition.get("description", "")),
		"view_title": "后续选择",
		"view_description": "%s 已结束，请明确确认下一步。" % phase_name,
		"start_title": "当前阶段",
		"start_hint": "%s 已结束，下一步会进入固定后续。" % phase_name,
		"phase_text": phase_name
	}

func _describe_next_phase_state(run_state: RunState) -> Dictionary:
	var current_phase: String = str(run_state.world_state.current_phase)
	var current_day: int = int(run_state.world_state.day)
	match current_phase:
		"morning":
			return {
				"phase": "day",
				"day": current_day,
				"title": "进入白天",
				"hint": "确认后进入当天白天流程。",
				"summary": "当前晨间事件已经结束，接下来进入白天推进。",
				"view_title": "白天路线",
				"view_description": "当前晨间事件已结束，请确认进入白天。",
				"start_title": "晨间收束",
				"start_hint": "这一拍已经说完，下一步会进入白天。",
				"phase_text": "白天",
				"node_type": "story",
				"type_label": "推进"
			}
		"day":
			return {
				"phase": "night",
				"day": current_day,
				"title": "进入夜晚",
				"hint": "确认后进入当天夜晚流程。",
				"summary": "当前白天事件已经结束，接下来进入夜晚。",
				"view_title": "夜晚后续",
				"view_description": "当前白天节点已结束，请确认进入夜晚。",
				"start_title": "白天收束",
				"start_hint": "这一段白天推进已经完成。",
				"phase_text": "夜晚",
				"node_type": "review",
				"type_label": "收束"
			}
		"night":
			return {
				"phase": "closing",
				"day": current_day,
				"title": "进入收束",
				"hint": "确认后进入当天收束阶段。",
				"summary": "当前夜晚事件已经结束，接下来进入收束。",
				"view_title": "夜晚收束",
				"view_description": "当前夜晚节点已结束，请确认进入收束。",
				"start_title": "夜晚收束",
				"start_hint": "这一拍夜晚流程已经完成。",
				"phase_text": "收束",
				"node_type": "review",
				"type_label": "收束"
			}
		"closing":
			if current_day >= int(run_state.world_state.max_day):
				return {"ends_run": true}
			return {
				"phase": "morning",
				"day": current_day + 1,
				"title": "进入下一天",
				"hint": "确认后迎来新的一天。",
				"summary": "当前收束已结束，接下来进入下一天。",
				"view_title": "新一天开始",
				"view_description": "当前阶段已收束，请确认进入下一天。",
				"start_title": "今日收束",
				"start_hint": "这一轮已经落下，下一步会进入新的一天。",
				"phase_text": "第 %d 天" % (current_day + 1),
				"node_type": "story",
				"type_label": "继续"
			}
		_:
			return {"ends_run": true}

func _preview_phase_entry_after_advance(run_state: RunState, next_day: int, next_phase: String) -> Dictionary:
	var previous_day: int = int(run_state.world_state.day)
	var previous_phase: String = str(run_state.world_state.current_phase)
	var previous_candidates: Array[String] = Array(run_state.world_state.current_action_candidates, TYPE_STRING, "", null)
	run_state.world_state.day = next_day
	run_state.world_state.current_phase = next_phase
	if next_phase != "day":
		run_state.world_state.current_action_candidates.clear()
	var definition: Dictionary = _event_service.preview_next_event_definition(
		run_state,
		_content_repository,
		"phase_entry"
	)
	run_state.world_state.day = previous_day
	run_state.world_state.current_phase = previous_phase
	run_state.world_state.current_action_candidates = previous_candidates
	return definition

func _phase_preview_label(phase: String, day: int) -> String:
	match phase:
		"morning":
			return "第 %d 天清晨" % day
		"day":
			return "第 %d 天白天" % day
		"night":
			return "第 %d 天夜晚" % day
		"closing":
			return "第 %d 天收束" % day
		_:
			return "当前阶段"

func _event_node_type_for_transition(event_definition: Dictionary) -> String:
	var presentation_type: String = str(event_definition.get("presentation_type", "standard_event"))
	match presentation_type:
		"battle_event":
			return "battle"
		"dialogue_event":
			return "dialogue"
		"summary_event":
			return "review"
		"compact_choice_event":
			return "reward"
		"ending_event":
			return "risk"
		_:
			return "story"

func _transition_type_label(node_type: String) -> String:
	match node_type:
		"dialogue":
			return "对话"
		"reward":
			return "奖励"
		"shop":
			return "商店"
		"review":
			return "收束"
		"battle":
			return "战斗"
		"risk":
			return "风险"
		_:
			return "剧情"

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


func _get_or_create_current_action_candidates(run_state: RunState) -> Array[String]:
	var cached_ids: Array[String] = Array(run_state.world_state.current_action_candidates, TYPE_STRING, "", null)
	if not cached_ids.is_empty():
		return cached_ids

	var available_actions: Array[Dictionary] = _content_repository.get_visible_day_node_actions(
		run_state,
		_condition_evaluator
	)
	if available_actions.is_empty():
		return []

	var available_by_id: Dictionary = {}
	var shuffled_ids: Array[String] = []
	for action_definition: Dictionary in available_actions:
		var action_id: String = str(action_definition.get("id", ""))
		if action_id.is_empty():
			continue
		available_by_id[action_id] = true
		shuffled_ids.append(action_id)

	var selected_ids: Array[String] = []
	if _route_map_service.has_template_for_day(run_state.world_state.day):
		selected_ids = _route_map_service.get_frontier_action_ids(run_state, shuffled_ids)
		_run_state_mutator.set_current_action_candidates(run_state, selected_ids)
		return selected_ids

	_shuffle_string_array(shuffled_ids)

	for action_id: String in shuffled_ids:
		selected_ids.append(action_id)
		if selected_ids.size() >= 3:
			break
	_run_state_mutator.set_current_action_candidates(run_state, selected_ids)
	return selected_ids

func _get_available_day_action_ids(run_state: RunState) -> Array[String]:
	var action_ids: Array[String] = []
	for action_definition: Dictionary in _content_repository.get_visible_day_node_actions(
		run_state,
		_condition_evaluator
	):
		var action_id: String = str(action_definition.get("id", ""))
		if action_id.is_empty():
			continue
		action_ids.append(action_id)
	return action_ids

func _complete_current_battle() -> void:
	var run_state: RunState = AppState.current_run_state
	if run_state == null or run_state.current_battle_state == null:
		return
	var battle_state: BattleState = run_state.current_battle_state
	_run_state_mutator.mark_event_triggered(run_state, battle_state.entry_event_id)
	var resolution_summary_lines: Array[String] = []
	if battle_state.is_player_victory:
		_run_state_mutator.modify_player_resource(run_state, "experience", battle_state.exp_reward)
		resolution_summary_lines.append("心战胜利")
		resolution_summary_lines.append("获得天魔经验 %d" % battle_state.exp_reward)
		_run_state_mutator.append_log(
			run_state,
			GAME_TEXT.format_text(
				"run_controller.logs.battle_victory",
				[battle_state.enemy_display_name],
				battle_state.enemy_display_name
			)
		)
		_run_state_mutator.append_log(
			run_state,
			GAME_TEXT.format_text(
				"run_controller.logs.battle_exp_reward",
				[battle_state.exp_reward],
				str(battle_state.exp_reward)
			)
		)
		for reward_card_id: String in battle_state.reward_card_ids:
			_run_state_mutator.add_battle_card(run_state, reward_card_id)
			var reward_card_definition: Dictionary = _content_repository.get_battle_card_definition(reward_card_id)
			var reward_card_name: String = str(reward_card_definition.get("display_name", reward_card_id))
			resolution_summary_lines.append("获得新卡 %s" % reward_card_name)
			_run_state_mutator.append_log(
				run_state,
				GAME_TEXT.format_text(
					"run_controller.logs.battle_card_reward",
					[reward_card_name],
					reward_card_name
				)
			)
	else:
		resolution_summary_lines.append("心战失败")
		_run_state_mutator.append_log(
			run_state,
			GAME_TEXT.format_text(
				"run_controller.logs.battle_defeat",
				[battle_state.enemy_display_name],
				battle_state.enemy_display_name
			)
		)
	var result_event_id: String = battle_state.result_event_id_success if battle_state.is_player_victory else battle_state.result_event_id_failure
	_run_state_mutator.clear_current_battle_state(run_state)
	if not battle_state.is_player_victory:
		_run_state_mutator.set_global_flag(run_state, "battle_failure_demon_deviation", true)
	if not result_event_id.is_empty():
		_set_current_event_and_start_battle(run_state, result_event_id)
		_run_state_mutator.set_current_battle_resolution_text(run_state, "\n".join(resolution_summary_lines))
	else:
		_run_state_mutator.clear_current_event(run_state)
		if not battle_state.is_player_victory:
			_run_state_mutator.finish_run(run_state, "battle_defeat")
	_finalize_progression(run_state, true, result_event_id.is_empty())

func _set_current_event_and_start_battle(run_state: RunState, event_id: String) -> void:
	_run_state_mutator.set_current_event(run_state, event_id)
	_event_service.start_battle_for_current_event_if_needed(run_state, _content_repository)

func _battle_error_text(message_key: String) -> String:
	match message_key:
		"battle.sanity_not_enough":
			return GAME_TEXT.text("run_controller.errors.battle_sanity_not_enough")
		"battle.slot_out_of_range":
			return GAME_TEXT.text("run_controller.errors.battle_slot_out_of_range")
		"battle.slot_required":
			return GAME_TEXT.text("run_controller.errors.battle_slot_required")
		"battle.card_not_in_hand":
			return GAME_TEXT.text("run_controller.errors.battle_card_not_in_hand")
		"battle.slot_type_mismatch":
			return GAME_TEXT.text("run_controller.errors.battle_slot_type_mismatch")
		"battle.slots_incomplete":
			return GAME_TEXT.text("run_controller.errors.battle_slots_incomplete")
		"battle.cards_missing":
			return GAME_TEXT.text("run_controller.errors.battle_cards_missing")
		_:
			return GAME_TEXT.text("run_controller.errors.battle_action_failed")


func _shuffle_string_array(values: Array[String]) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for index: int in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current_value: String = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value
