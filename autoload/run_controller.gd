extends Node

const DEFAULT_RUN_ID: String = "default_run"
const GAME_TEXT := preload("res://systems/content/game_text.gd")
const ENDING_SERVICE_SCRIPT := preload("res://systems/ending/ending_service.gd")
const DIALOGUE_STATE_BRIDGE_SCRIPT := preload("res://systems/dialogue/dialogue_state_bridge.gd")
const LOCATION_SERVICE_SCRIPT := preload("res://systems/location/location_service.gd")
const NPC_SERVICE_SCRIPT := preload("res://systems/npc/npc_service.gd")

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
var _npc_service
var _ending_service
var _inheritance_service: InheritanceService

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
	_npc_service = NPC_SERVICE_SCRIPT.new(_condition_evaluator, _run_state_mutator)
	_ending_service = ENDING_SERVICE_SCRIPT.new(_condition_evaluator)
	_inheritance_service = InheritanceService.new()

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

	if _location_service.is_story_event_action_id(action_id):
		_open_story_event_action(action_id)
		return

	var action_definition: Dictionary = _content_repository.get_action_definition(action_id)
	if action_definition.is_empty():
		AppState.raise_error(GAME_TEXT.format_text("run_controller.errors.action_not_found", [action_id], action_id))
		return

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
	_goal_service.refresh_goal_progress(AppState.current_run_state, _content_repository)
	_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "post_action")
	if AppState.current_run_state.current_event_id.is_empty():
		_day_flow_service.advance_after_action(AppState.current_run_state)
		_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
		_advance_through_empty_non_day_phases(AppState.current_run_state)

	if AppState.current_run_state.is_run_over:
		_log_resolved_ending(AppState.current_run_state)
		var inheritance_options: Array[Dictionary] = _inheritance_service.generate_options(
			AppState.current_run_state
		)
		_run_state_mutator.append_log(
			AppState.current_run_state,
			GAME_TEXT.format_text("run_controller.logs.inheritance_count", [inheritance_options.size()], str(inheritance_options.size()))
		)

	AppState.set_run_state(AppState.current_run_state)

func get_visible_actions() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	if AppState.current_run_state.world_state.current_phase != "day":
		return []
	return _location_service.get_available_actions_for_current_location(
		AppState.current_run_state,
		_content_repository
	)

func get_available_locations() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	return _location_service.get_available_locations(
		AppState.current_run_state,
		_content_repository
	)

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

func get_available_npc_interactions() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	if AppState.current_run_state.world_state.current_phase != "day":
		return []
	return _npc_service.get_available_interactions_for_current_location(
		AppState.current_run_state,
		_content_repository
	)

func get_npc_idle_interaction(npc_id: String) -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	if AppState.current_run_state.world_state.current_phase != "day":
		return {}
	return _npc_service.get_idle_interaction_for_npc(
		AppState.current_run_state,
		_content_repository,
		npc_id
	)

func perform_npc_interaction(interaction_id: String) -> void:
	if not _ensure_run_for_action():
		return

	var result: Dictionary = _npc_service.interact(
		AppState.current_run_state,
		_content_repository,
		interaction_id
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(str(result.get("message", GAME_TEXT.text("run_controller.errors.interaction_failed"))))
		return

	var opened_event_id: String = str(result.get("opened_event_id", ""))
	if not opened_event_id.is_empty():
		_run_state_mutator.set_current_event(AppState.current_run_state, opened_event_id)
		AppState.set_run_state(AppState.current_run_state)
		return

	_goal_service.refresh_goal_progress(AppState.current_run_state, _content_repository)
	_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "post_action")
	if AppState.current_run_state.current_event_id.is_empty():
		_day_flow_service.advance_after_action(AppState.current_run_state)
		_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
		_advance_through_empty_non_day_phases(AppState.current_run_state)
	AppState.set_run_state(AppState.current_run_state)

func move_to_location(location_id: String) -> void:
	if AppState.current_run_state == null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.no_run"))
		return
	if not AppState.current_run_state.current_event_id.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.handle_event_first"))
		return
	if AppState.current_run_state.world_state.current_phase != "day":
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.cannot_move_phase"))
		return
	var result: Dictionary = _location_service.move_to_location(
		AppState.current_run_state,
		_content_repository,
		location_id
	)
	if not _to_bool(result.get("success", false)):
		AppState.raise_error(str(result.get("message", GAME_TEXT.text("run_controller.errors.move_failed"))))
		return
	AppState.set_run_state(AppState.current_run_state)

func end_day() -> void:
	if AppState.current_run_state == null:
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.no_run"))
		return
	if not AppState.current_run_state.current_event_id.is_empty():
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.handle_event_first"))
		return
	if AppState.current_run_state.world_state.current_phase != "day":
		AppState.raise_error(GAME_TEXT.text("run_controller.errors.cannot_end_day_phase"))
		return

	_run_state_mutator.set_phase(AppState.current_run_state, "night")
	_run_state_mutator.append_log(AppState.current_run_state, GAME_TEXT.text("run_controller.logs.end_day"))
	_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
	_advance_through_empty_non_day_phases(AppState.current_run_state)
	if AppState.current_run_state.is_run_over:
		_log_resolved_ending(AppState.current_run_state)
	AppState.set_run_state(AppState.current_run_state)

func get_current_event() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	return _event_service.get_current_event_definition(
		AppState.current_run_state,
		_content_repository
	)

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

	_goal_service.refresh_goal_progress(AppState.current_run_state, _content_repository)
	if AppState.current_run_state.current_event_id.is_empty():
		_day_flow_service.advance_after_event(AppState.current_run_state)
		_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
		_advance_through_empty_non_day_phases(AppState.current_run_state)
	if AppState.current_run_state.is_run_over:
		_log_resolved_ending(AppState.current_run_state)
	AppState.set_run_state(AppState.current_run_state)

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
	_goal_service.refresh_goal_progress(AppState.current_run_state, _content_repository)
	_day_flow_service.advance_after_event(AppState.current_run_state)
	_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
	_advance_through_empty_non_day_phases(AppState.current_run_state)
	if AppState.current_run_state.is_run_over:
		_log_resolved_ending(AppState.current_run_state)
	AppState.set_run_state(AppState.current_run_state)

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
		and run_state.world_state.current_phase != "day"
	):
		guard += 1
		_day_flow_service.advance_after_event(run_state)
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")

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
		_run_state_mutator.set_current_event(AppState.current_run_state, event_id)
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
