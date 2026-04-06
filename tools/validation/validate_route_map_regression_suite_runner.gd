extends SceneTree

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

	_validate_day1_opening_chain(run_controller, app_state)
	_validate_day2_lie_low_chain(run_controller, app_state)
	_validate_day3_lie_low_chain(run_controller, app_state)
	_validate_day5_gray_market_records_branch(run_controller, app_state)
	_validate_day5_gray_market_liu_branch(run_controller, app_state)
	_validate_day6_gray_market_records_branch(run_controller, app_state)

	print("validate_route_map_regression_suite_runner: OK")
	quit()

func _validate_day1_opening_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 1 opening chain validation.")
		quit(1)
		return

	var opening_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if opening_options.is_empty():
		push_error("Expected opening event options at run start.")
		quit(1)
		return
	run_controller.choose_event_option(str(opening_options[0].get("id", "")))
	if run_state.current_event_id == "1001":
		run_controller.choose_event_option("__continue__")

	var opening_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if opening_frontier != ["day1_liu_battle"]:
		push_error("Expected only day1_liu_battle at Day 1 opening frontier, got %s" % str(opening_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day1_liu_battle")
	_expect_event(run_controller, run_state, "2001", "day1_liu_battle")
	run_controller.choose_event_option("__intrude__")
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_liu_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_liu_frontier != ["day1_wang_event"]:
		push_error("Expected only day1_wang_event after day1_liu_battle, got %s" % str(post_liu_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day1_wang_event")
	_expect_event(run_controller, run_state, "2004", "day1_wang_event")
	run_controller.choose_event_option("__intrude__")
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_wang_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_wang_frontier != ["day1_close"]:
		push_error("Expected only day1_close after day1_wang_event, got %s" % str(post_wang_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day1_close")
	var next_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if run_state.current_event_id != "1002" and run_state.current_event_id != "2002" and not next_frontier.has("day2_liu_entry"):
		push_error("Expected 1002, 2002 or day2_liu_entry after day1_close, got event=%s frontier=%s" % [
			run_state.current_event_id,
			str(next_frontier)
		])
		quit(1)
		return
	if run_state.current_event_id == "1002":
		_complete_current_event_with_first_option(run_controller, run_state)
		next_frontier = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if next_frontier.has("day2_liu_entry"):
		run_controller.select_route_map_node("day2_liu_entry")
		_expect_event(run_controller, run_state, "2002", "day2_liu_entry")
	if run_state.current_event_id == "2002":
		_complete_current_event_with_first_option(run_controller, run_state)
		next_frontier = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not next_frontier.has("day2_rest"):
		push_error("Expected Day 2 route frontier after day1_close, got %s" % str(next_frontier))
		quit(1)
		return

func _validate_day2_lie_low_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 2 lie-low chain validation.")
		quit(1)
		return

	_advance_to_day2_route_choices(run_controller, run_state)

	var frontier_ids: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not frontier_ids.has("day2_rest"):
		push_error("Expected day2_rest to be selectable on Day 2, got %s" % str(frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day2_rest")
	_expect_action_feedback(run_controller, run_state, "day2_rest")

	var post_rest_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_rest_frontier != ["day2_lie_low_reflection", "day2_close"]:
		push_error("Expected day2_rest to advance to day2_lie_low_reflection/day2_close, got %s" % str(post_rest_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day2_lie_low_reflection")
	_expect_action_feedback(run_controller, run_state, "day2_lie_low_reflection")

	var post_reflection_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_reflection_frontier != ["day2_lie_low_blend"]:
		push_error("Expected day2_lie_low_reflection to continue to day2_lie_low_blend, got %s" % str(post_reflection_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day2_lie_low_blend")
	_expect_action_feedback(run_controller, run_state, "day2_lie_low_blend")

	var post_blend_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_blend_frontier != ["day2_pharmacy_work"]:
		push_error("Expected day2_lie_low_blend to continue to day2_pharmacy_work, got %s" % str(post_blend_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day2_pharmacy_work")
	_expect_action_feedback(run_controller, run_state, "day2_pharmacy_work")

	var post_work_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_work_frontier != ["day2_close"]:
		push_error("Expected day2_pharmacy_work to continue to day2_close, got %s" % str(post_work_frontier))
		quit(1)
		return

func _validate_day3_lie_low_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 3 lie-low chain validation.")
		quit(1)
		return

	_prepare_progressed_state(
		run_controller,
		app_state,
		run_state,
		3,
		"morning",
		[
			"1001",
			"2001",
			"9102",
			"2004",
			"9202",
			"1002",
			"2002"
		],
		{
			"route_lie_low": true
		},
		{
			"id": "transition_day_3",
			"transition_kind": "advance_then_phase_entry",
			"target_event_id": "1102"
		}
	)

	run_controller.select_route_map_node("day3_morning_entry")
	_expect_event(run_controller, run_state, "1102", "day3_morning_entry")
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_entry_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_entry_frontier.has("day3_rest"):
		push_error("Expected day3_rest after day3_morning_entry, got %s" % str(post_entry_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day3_rest")
	_expect_action_feedback(run_controller, run_state, "day3_rest")

	var post_rest_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_rest_frontier != ["day3_lie_low_reflection"]:
		push_error("Expected day3_lie_low_reflection after day3_rest, got %s" % str(post_rest_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day3_lie_low_reflection")
	_expect_action_feedback(run_controller, run_state, "day3_lie_low_reflection")

	var post_reflection_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_reflection_frontier != ["day3_lie_low_blend"]:
		push_error("Expected day3_lie_low_blend after day3_lie_low_reflection, got %s" % str(post_reflection_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day3_lie_low_blend")
	_expect_action_feedback(run_controller, run_state, "day3_lie_low_blend")

	var post_blend_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if post_blend_frontier != ["day3_close"]:
		push_error("Expected day3_close after day3_lie_low_blend, got %s" % str(post_blend_frontier))
		quit(1)
		return

func _validate_day5_gray_market_records_branch(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 5 records branch validation.")
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
	_expect_event(run_controller, run_state, "1103", "day5_morning_entry")
	_complete_current_event_with_first_option(run_controller, run_state)

	run_controller.select_route_map_node("day5_records_push")
	_expect_action_feedback(run_controller, run_state, "day5_records_push")

	var post_push_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_push_frontier.has("day5_records_event"):
		push_error("Expected day5_records_event after day5_records_push, got %s" % str(post_push_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_records_event")
	_expect_event(run_controller, run_state, "2403", "day5_records_event")
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_records_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_records_frontier.has("day5_gray_market"):
		push_error("Expected day5_gray_market after day5_records_event, got %s" % str(post_records_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_gray_market")
	_expect_event(run_controller, run_state, "3401", "day5_gray_market")
	if run_state.current_battle_state != null:
		push_error("day5_gray_market should not open battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return

func _validate_day5_gray_market_liu_branch(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 5 Liu branch validation.")
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
	_expect_event(run_controller, run_state, "1103", "day5_morning_entry (liu)")
	_complete_current_event_with_first_option(run_controller, run_state)

	run_controller.select_route_map_node("day5_peer_talk")
	_expect_action_feedback(run_controller, run_state, "day5_peer_talk")

	var post_peer_talk_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_peer_talk_frontier.has("day5_liu_false_rumor"):
		push_error("Expected day5_liu_false_rumor after day5_peer_talk, got %s" % str(post_peer_talk_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_liu_false_rumor")
	_expect_event(run_controller, run_state, "2203", "day5_liu_false_rumor")
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_false_rumor_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_false_rumor_frontier.has("day5_liu_readback"):
		push_error("Expected day5_liu_readback after day5_liu_false_rumor, got %s" % str(post_false_rumor_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_liu_readback")
	_expect_action_feedback(run_controller, run_state, "day5_liu_readback")

	var post_readback_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_readback_frontier.has("day5_gray_market"):
		push_error("Expected day5_gray_market after day5_liu_readback, got %s" % str(post_readback_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_gray_market")
	_expect_event(run_controller, run_state, "3401", "day5_gray_market from liu branch")
	if run_state.current_battle_state != null:
		push_error("day5_gray_market from liu branch should not open battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return

func _validate_day6_gray_market_records_branch(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 6 records branch validation.")
		quit(1)
		return

	_prepare_progressed_state(
		run_controller,
		app_state,
		run_state,
		6,
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
			"1003",
			"1004"
		],
		{
			"liu_contact_established": true,
			"route_records": true
		},
		{
			"id": "transition_day_6",
			"transition_kind": "advance_then_phase_entry",
			"target_event_id": "1104"
		}
	)

	run_controller.select_route_map_node("day6_morning_entry")
	_expect_event(run_controller, run_state, "1104", "day6_morning_entry")
	_complete_current_event_with_first_option(run_controller, run_state)

	run_controller.select_route_map_node("day6_records_push")
	_expect_action_feedback(run_controller, run_state, "day6_records_push")

	var post_push_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_push_frontier.has("day6_records_event"):
		push_error("Expected day6_records_event after day6_records_push, got %s" % str(post_push_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day6_records_event")
	_expect_event(run_controller, run_state, "2403", "day6_records_event")
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_records_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_records_frontier.has("day6_gray_market"):
		push_error("Expected day6_gray_market after day6_records_event, got %s" % str(post_records_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day6_gray_market")
	_expect_event(run_controller, run_state, "3402", "day6_gray_market")
	if run_state.current_battle_state != null:
		push_error("day6_gray_market should not open battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return

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
	if run_state.current_battle_state != null:
		push_error("Selecting %s should not open battle, got %s" % [node_id, run_state.current_battle_state.battle_id])
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

func _expect_event(run_controller: Node, run_state: RunState, expected_event_id: String, context: String) -> void:
	if run_state.current_event_id != expected_event_id:
		push_error("Expected %s after %s, got %s" % [expected_event_id, context, run_state.current_event_id])
		quit(1)
		return

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids
