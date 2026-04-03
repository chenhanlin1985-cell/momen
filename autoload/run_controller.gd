extends Node

const DEFAULT_RUN_ID: String = "default_run"
const GAME_TEXT := preload("res://systems/content/game_text.gd")
const ENDING_SERVICE_SCRIPT := preload("res://systems/ending/ending_service.gd")
const DIALOGUE_STATE_BRIDGE_SCRIPT := preload("res://systems/dialogue/dialogue_state_bridge.gd")
const LOCATION_SERVICE_SCRIPT := preload("res://systems/location/location_service.gd")

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

func start_new_run(run_id: String = DEFAULT_RUN_ID) -> void:
	var run_state: RunState = _run_initializer.create_run(
		run_id,
		AppState.meta_progress,
		_content_repository
	)
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
	return battle_view

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

func assign_battle_hand_card(card_id: String) -> void:
	if AppState.current_run_state == null:
		return
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return
	if battle_state.selected_slot_index < 0:
		AppState.raise_error(_battle_error_text("battle.slot_required"))
		return
	var card_definition: Dictionary = _content_repository.get_battle_card_definition(card_id)
	if card_definition.is_empty():
		AppState.raise_error(_battle_error_text("battle.cards_missing"))
		return
	var result: Dictionary = _battle_service.assign_card_to_slot(
		battle_state,
		battle_state.selected_slot_index,
		card_id,
		card_definition
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(_battle_error_text(str(result.get("message", ""))))
		return
	AppState.set_run_state(AppState.current_run_state)

func assign_battle_hand_card_to_slot(slot_index: int, card_id: String) -> void:
	if AppState.current_run_state == null:
		return
	var battle_state: BattleState = AppState.current_run_state.current_battle_state
	if battle_state == null:
		return
	battle_state.selected_slot_index = slot_index
	var card_definition: Dictionary = _content_repository.get_battle_card_definition(card_id)
	if card_definition.is_empty():
		AppState.raise_error(_battle_error_text("battle.cards_missing"))
		return
	var result: Dictionary = _battle_service.assign_card_to_slot(
		battle_state,
		slot_index,
		card_id,
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
	var result: Dictionary = _battle_service.redraw_hand(
		battle_state,
		battle_state.hand_cards.size()
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(_battle_error_text(str(result.get("message", ""))))
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
	if run_state.world_state.current_phase == "day":
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "day_tail")
		if not run_state.current_event_id.is_empty() or run_state.current_battle_state != null:
			return
	if run_state.world_state.current_phase == "night":
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "night_tail")
		if not run_state.current_event_id.is_empty() or run_state.current_battle_state != null:
			return
	_day_flow_service.advance_after_event(run_state)
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

	var shuffled_ids: Array[String] = []
	for action_definition: Dictionary in available_actions:
		var action_id: String = str(action_definition.get("id", ""))
		if action_id.is_empty():
			continue
		shuffled_ids.append(action_id)
	_shuffle_string_array(shuffled_ids)

	var selected_ids: Array[String] = []
	for action_id: String in shuffled_ids:
		selected_ids.append(action_id)
		if selected_ids.size() >= 3:
			break
	_run_state_mutator.set_current_action_candidates(run_state, selected_ids)
	return selected_ids

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
