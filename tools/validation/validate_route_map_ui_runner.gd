extends SceneTree

const VIEW_MODEL_SCRIPT := preload("res://ui/view_models/main_game_view_model.gd")
const ACTION_FEEDBACK_EVENT_ID := "__route_map_action_feedback__"

func _initialize() -> void:
	var root: Window = get_root()
	var run_controller: Node = root.get_node_or_null("RunController")
	var app_state: Node = root.get_node_or_null("AppState")
	if run_controller == null or app_state == null:
		push_error("Missing autoload singletons RunController/AppState.")
		quit(1)
		return
	if run_controller._content_repository == null:
		run_controller._ready()

	_validate_day2_feedback_type(run_controller, app_state)
	_validate_day5_dialogue_feedback_type(run_controller, app_state)
	_validate_day5_gray_market_ui_type(run_controller, app_state)

	print("validate_route_map_ui_runner: OK")
	quit()

func _validate_day2_feedback_type(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 2 UI validation.")
		quit(1)
		return

	_advance_to_day2_route_choices(run_controller, run_state)
	run_controller.select_route_map_node("day2_rest")
	_expect_action_feedback(run_controller, run_state, "day2_rest")
	run_controller.select_route_map_node("day2_lie_low_reflection")
	_expect_actionFeedback_and_continue(run_controller, run_state, "day2_lie_low_reflection")
	run_controller.select_route_map_node("day2_lie_low_blend")
	_expect_actionFeedback_and_continue(run_controller, run_state, "day2_lie_low_blend")
	run_controller.select_route_map_node("day2_pharmacy_work")
	if run_state.current_event_id != ACTION_FEEDBACK_EVENT_ID:
		push_error("Expected action feedback after day2_pharmacy_work, got %s" % run_state.current_event_id)
		quit(1)
		return

	var view_model: Dictionary = _build_view_model(run_controller, run_state)
	if str(view_model.get("event_type_key", "")) != "reward":
		push_error("Expected day2_pharmacy_work feedback to render as reward, got %s" % str(view_model.get("event_type_key", "")))
		quit(1)
		return
	if str(view_model.get("scene_mode", "")) != "event":
		push_error("Expected day2_pharmacy_work feedback to render in event scene mode, got %s" % str(view_model.get("scene_mode", "")))
		quit(1)
		return
	var current_event: Dictionary = Dictionary(run_controller._event_service.get_current_event_definition(run_state, run_controller._content_repository))
	var description: String = str(current_event.get("description", ""))
	if not description.contains("本次变化："):
		push_error("Expected day2_pharmacy_work feedback copy to include reward summary, got %s" % description)
		quit(1)
		return

func _validate_day5_dialogue_feedback_type(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 5 dialogue UI validation.")
		quit(1)
		return

	_prepare_progressed_state(
		run_controller,
		app_state,
		run_state,
		5,
		"morning",
		[
			"1001",
			"2001",
			"9102",
			"2004",
			"9202",
			"1002",
			"2002",
			"1102",
			"2202"
		],
		{
			"liu_contact_established": true,
			"liu_informant_active": true,
			"liu_shared_drop_established": true,
			"wang_schedule_exposed": true
		},
		{
			"id": "transition_day_5",
			"transition_kind": "advance_then_phase_entry",
			"target_event_id": "1103"
		}
	)

	run_controller.select_route_map_node("day5_morning_entry")
	_complete_current_event_with_first_option(run_controller, run_state)
	run_controller.select_route_map_node("day5_peer_talk")
	if run_state.current_event_id != ACTION_FEEDBACK_EVENT_ID:
		push_error("Expected action feedback after day5_peer_talk, got %s" % run_state.current_event_id)
		quit(1)
		return

	var view_model: Dictionary = _build_view_model(run_controller, run_state)
	if str(view_model.get("event_type_key", "")) != "dialogue":
		push_error("Expected day5_peer_talk feedback to render as dialogue, got %s" % str(view_model.get("event_type_key", "")))
		quit(1)
		return
	if str(view_model.get("scene_mode", "")) != "event":
		push_error("Expected day5_peer_talk feedback to stay in event scene mode, got %s" % str(view_model.get("scene_mode", "")))
		quit(1)
		return
	var current_event: Dictionary = Dictionary(run_controller._event_service.get_current_event_definition(run_state, run_controller._content_repository))
	var description: String = str(current_event.get("description", ""))
	if not description.contains("试探") and not description.contains("气口"):
		push_error("Expected day5_peer_talk feedback copy to read like dialogue framing, got %s" % description)
		quit(1)
		return

func _validate_day5_gray_market_ui_type(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 5 gray market UI validation.")
		quit(1)
		return

	_prepare_progressed_state(
		run_controller,
		app_state,
		run_state,
		5,
		"morning",
		[
			"1001",
			"2001",
			"9102",
			"2004",
			"9202",
			"1002",
			"2002",
			"1102"
		],
		{
			"liu_contact_established": true,
			"route_records": true
		},
		{
			"id": "transition_day_5",
			"transition_kind": "advance_then_phase_entry",
			"target_event_id": "1103"
		}
	)

	run_controller.select_route_map_node("day5_morning_entry")
	_complete_current_event_with_first_option(run_controller, run_state)
	run_controller.select_route_map_node("day5_records_push")
	_expect_action_feedback(run_controller, run_state, "day5_records_push")
	run_controller.select_route_map_node("day5_records_event")
	_complete_current_event_with_first_option(run_controller, run_state)
	run_controller.select_route_map_node("day5_gray_market")

	if run_state.current_event_id != "3401":
		push_error("Expected 3401 after selecting day5_gray_market, got %s" % run_state.current_event_id)
		quit(1)
		return
	if run_state.current_battle_state != null:
		push_error("Expected day5_gray_market to open shop event, not battle %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return

	var view_model: Dictionary = _build_view_model(run_controller, run_state)
	if str(view_model.get("event_type_key", "")) != "shop":
		push_error("Expected day5_gray_market to render as shop, got %s" % str(view_model.get("event_type_key", "")))
		quit(1)
		return
	if str(view_model.get("scene_mode", "")) != "event":
		push_error("Expected day5_gray_market to render in event scene mode, got %s" % str(view_model.get("scene_mode", "")))
		quit(1)
		return

func _build_view_model(run_controller: Node, run_state: RunState) -> Dictionary:
	var repository = run_controller._content_repository
	var current_location: Dictionary = repository.get_location_definition(run_state.world_state.current_location_id)
	var route_map_view: Dictionary = run_controller.get_current_route_map_view()
	var current_event: Dictionary = run_controller._event_service.get_current_event_definition(run_state, repository)
	var option_views: Array[Dictionary] = run_controller.get_current_event_option_views()
	return VIEW_MODEL_SCRIPT.build(
		run_state,
		current_location,
		[],
		[],
		route_map_view,
		current_event,
		[],
		option_views,
		[],
		[],
		{}
	)

func _advance_to_day2_route_choices(run_controller: Node, run_state: RunState) -> void:
	var opening_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	run_controller.choose_event_option(str(opening_options[0].get("id", "")))
	if run_state.current_event_id == "1001":
		run_controller.choose_event_option("__continue__")

	run_controller.select_route_map_node("day1_liu_battle")
	run_controller.choose_event_option("__intrude__")
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_complete_current_event_with_first_option(run_controller, run_state)

	run_controller.select_route_map_node("day1_wang_event")
	run_controller.choose_event_option("__intrude__")
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_complete_current_event_with_first_option(run_controller, run_state)

	run_controller.select_route_map_node("day1_close")
	_complete_current_event_with_first_option(run_controller, run_state)
	run_controller.select_route_map_node("day2_liu_entry")
	_complete_current_event_with_first_option(run_controller, run_state)

func _prepare_progressed_state(
	run_controller: Node,
	app_state: Node,
	run_state: RunState,
	day: int,
	phase: String,
	triggered_ids: Array,
	flags: Dictionary,
	transition_preview: Dictionary = {}
) -> void:
	run_state.world_state.day = day
	run_state.world_state.current_phase = phase
	run_state.triggered_event_ids = Array(triggered_ids, TYPE_STRING, "", null)
	for flag_key: String in flags.keys():
		run_state.world_state.global_flags[flag_key] = flags.get(flag_key)
	run_controller._run_state_mutator.clear_current_event(run_state)
	run_controller._run_state_mutator.clear_current_action_candidates(run_state)
	run_controller._route_map_service.clear_route_map_progress(run_state)
	run_controller._route_map_service.clear_transition_preview(run_state)
	if not transition_preview.is_empty():
		run_controller._route_map_service.set_transition_preview(run_state, transition_preview)
	app_state.set_run_state(run_state)

func _complete_current_event_with_first_option(run_controller: Node, run_state: RunState) -> void:
	var options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if options.is_empty():
		push_error("Event %s has no options." % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option(str(options[0].get("id", "")))
	if not run_state.current_event_id.is_empty():
		run_controller.choose_event_option("__continue__")

func _expect_action_feedback(run_controller: Node, run_state: RunState, node_id: String) -> void:
	if run_state.current_event_id != ACTION_FEEDBACK_EVENT_ID:
		push_error("Selecting %s should open action feedback event, got %s" % [node_id, run_state.current_event_id])
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

func _expect_actionFeedback_and_continue(run_controller: Node, run_state: RunState, node_id: String) -> void:
	if run_state.current_event_id != ACTION_FEEDBACK_EVENT_ID:
		push_error("Selecting %s should open action feedback event, got %s" % [node_id, run_state.current_event_id])
		quit(1)
		return
	run_controller.choose_event_option("__continue__")
