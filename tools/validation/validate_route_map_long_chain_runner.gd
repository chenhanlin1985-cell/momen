extends SceneTree

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

	_validate_day4_elder_chain(run_controller, app_state)
	_validate_day5_records_chain(run_controller, app_state)
	_validate_day5_liu_chain(run_controller, app_state)
	_validate_day6_elder_chain(run_controller, app_state)
	_validate_day6_well_entry_chain(run_controller, app_state)

	print("validate_route_map_long_chain_runner: OK")
	quit()

func _validate_day4_elder_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 4 elder chain validation.")
		quit(1)
		return

	_prepare_progressed_state(
		run_controller,
		app_state,
		run_state,
		4,
		"day",
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
			"route_seek_senior": true,
			"met_mad_elder": true
		}
	)

	var initial_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not initial_frontier.has("day4_peer_talk"):
		push_error("Day 4 elder chain missing day4_peer_talk in initial frontier: %s" % str(initial_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_peer_talk")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day4_peer_talk, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")
	var post_talk_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_talk_frontier.has("day4_elder_event"):
		push_error("Day 4 elder chain did not expose day4_elder_event after day4_peer_talk: %s" % str(post_talk_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_elder_event")
	if run_state.current_event_id != "2301":
		push_error("Expected 2301 after selecting day4_elder_event, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_elder_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_elder_frontier.has("day4_elder_probe"):
		push_error("Day 4 elder chain did not expose day4_elder_probe after 2301: %s" % str(post_elder_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_elder_probe")
	if run_state.current_event_id != "2007":
		push_error("Expected 2007 after selecting day4_elder_probe, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_probe_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_probe_frontier.has("day4_close"):
		push_error("Day 4 elder chain did not expose day4_close after 2007: %s" % str(post_probe_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_close")
	if run_state.current_event_id != "1003":
		push_error("Expected 1003 after selecting day4_close, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_night_visit_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_night_visit_frontier.has("day4_wall_mark"):
		push_error("Day 4 elder chain did not expose day4_wall_mark after 1003: %s" % str(post_night_visit_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_wall_mark")
	if run_state.current_event_id != "act1_ano_mark_on_wall":
		push_error("Expected act1_ano_mark_on_wall after selecting day4_wall_mark, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_wall_mark_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_wall_mark_frontier.has("day4_night_close"):
		push_error("Day 4 elder chain did not expose day4_night_close after act1_ano_mark_on_wall: %s" % str(post_wall_mark_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_night_close")
	if run_state.current_event_id != "1103":
		var day5_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
		if not day5_frontier.has("day5_morning_entry"):
			push_error("Expected 1103 or day5_morning_entry after selecting day4_night_close, got event=%s frontier=%s" % [
				run_state.current_event_id,
				str(day5_frontier)
			])
			quit(1)
			return

func _validate_day5_records_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 5 records chain validation.")
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

	var morning_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if morning_frontier != ["day5_morning_entry"]:
		push_error("Day 5 records chain morning frontier mismatch: %s" % str(morning_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_morning_entry")
	if run_state.current_event_id != "1103":
		push_error("Expected 1103 after selecting day5_morning_entry, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_morning_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_morning_frontier.has("day5_records_push"):
		push_error("Day 5 records chain did not expose day5_records_push after 1103: %s" % str(post_morning_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_records_push")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day5_records_push, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")
	var post_push_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_push_frontier.has("day5_records_event"):
		push_error("Day 5 records chain did not expose day5_records_event after day5_records_push: %s" % str(post_push_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_records_event")
	if run_state.current_event_id != "2403":
		push_error("Expected 2403 after selecting day5_records_event, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_records_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_records_frontier.has("day5_close"):
		push_error("Day 5 records chain did not expose day5_close after 2403: %s" % str(post_records_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_close")
	if run_state.current_event_id != "1004":
		push_error("Expected 1004 after selecting day5_close, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_pill_trial_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_pill_trial_frontier.has("day5_records_cover"):
		push_error("Day 5 records chain did not expose day5_records_cover after 1004: %s" % str(post_pill_trial_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_records_cover")
	if run_state.current_event_id != "2402":
		push_error("Expected 2402 after selecting day5_records_cover, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_records_cover_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_records_cover_frontier.has("day5_night_close"):
		push_error("Day 5 records chain did not expose day5_night_close after 2402: %s" % str(post_records_cover_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_night_close")
	if run_state.current_event_id != "1104":
		var day6_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
		if not day6_frontier.has("day6_morning_entry"):
			push_error("Expected 1104 or day6_morning_entry after selecting day5_night_close, got event=%s frontier=%s" % [
				run_state.current_event_id,
				str(day6_frontier)
			])
			quit(1)
			return

func _validate_day5_liu_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 5 liu chain validation.")
		quit(1)
		return

	_prepare_progressed_state(
		run_controller,
		app_state,
		run_state,
		4,
		"day",
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
			"liu_informant_active": true,
			"liu_shared_drop_established": true
		}
	)

	var day4_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not day4_frontier.has("day4_peer_talk"):
		push_error("Day 4 liu chain missing day4_peer_talk in initial frontier: %s" % str(day4_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_peer_talk")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day4_peer_talk in liu chain, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")
	var post_peer_talk_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_peer_talk_frontier.has("day4_liu_test_event"):
		push_error("Day 4 liu chain did not expose day4_liu_test_event after day4_peer_talk: %s" % str(post_peer_talk_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_liu_test_event")
	if run_state.current_event_id != "2202":
		push_error("Expected 2202 after selecting day4_liu_test_event, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_liu_test_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_liu_test_frontier.has("day4_liu_signal_check"):
		push_error("Day 4 liu chain did not expose day4_liu_signal_check after 2202: %s" % str(post_liu_test_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day4_liu_signal_check")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day4_liu_signal_check, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_signal_check_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_signal_check_frontier.has("day4_close"):
		push_error("Day 4 liu chain did not expose day4_close after day4_liu_signal_check: %s" % str(post_signal_check_frontier))
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
	if run_state.current_event_id != "1103":
		push_error("Expected 1103 after selecting day5_morning_entry in liu chain, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var day5_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not day5_frontier.has("day5_peer_talk"):
		push_error("Day 5 liu chain missing day5_peer_talk after 1103: %s" % str(day5_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_peer_talk")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day5_peer_talk, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")
	var post_day5_peer_talk_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_day5_peer_talk_frontier.has("day5_liu_false_rumor"):
		push_error("Day 5 liu chain did not expose day5_liu_false_rumor after day5_peer_talk: %s" % str(post_day5_peer_talk_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_liu_false_rumor")
	if run_state.current_event_id != "2203":
		push_error("Expected 2203 after selecting day5_liu_false_rumor, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_false_rumor_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_false_rumor_frontier.has("day5_liu_readback"):
		push_error("Day 5 liu chain did not expose day5_liu_readback after 2203: %s" % str(post_false_rumor_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day5_liu_readback")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day5_liu_readback, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_readback_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_readback_frontier.has("day5_gray_market"):
		push_error("Day 5 liu chain did not expose day5_gray_market after day5_liu_readback: %s" % str(post_readback_frontier))
		quit(1)
		return

func _validate_day6_elder_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 6 elder chain validation.")
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
			"1004",
			"2007"
		],
		{
			"route_seek_senior": true,
			"met_mad_elder": true
		},
		{
			"id": "transition_day_6",
			"transition_kind": "advance_then_phase_entry",
			"target_event_id": "1104"
		}
	)

	run_controller.select_route_map_node("day6_morning_entry")
	if run_state.current_event_id != "1104":
		push_error("Expected 1104 after selecting day6_morning_entry in elder chain, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var day6_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not day6_frontier.has("day6_records_push"):
		push_error("Day 6 elder chain missing day6_records_push after 1104: %s" % str(day6_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day6_records_push")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Expected route map action feedback after selecting day6_records_push in elder chain, got %s" % run_state.current_event_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_push_view: Dictionary = run_controller.get_current_route_map_view()
	var post_push_frontier: Array[String] = _collect_selectable_ids(post_push_view)
	if not post_push_frontier.has("day6_records_event"):
		push_error("Day 6 elder pressure chain did not expose day6_records_event after day6_records_push: %s" % str(post_push_frontier))
		quit(1)
		return
	var elder_node: Dictionary = _find_node(post_push_view, "day6_elder_event")
	if elder_node.is_empty():
		push_error("Day 6 elder pressure chain could not find day6_elder_event node in route map view.")
		quit(1)
		return
	if not bool(elder_node.get("is_locked", false)):
		push_error("Expected day6_elder_event to remain as locked preview after day6_records_push, got %s" % str(elder_node))
		quit(1)
		return
	var elder_lock_reason: String = str(elder_node.get("lock_reason_text", ""))
	if not elder_lock_reason.contains("疯长老线"):
		push_error("Expected day6_elder_event lock reason to explain off-route elder pressure, got %s" % elder_lock_reason)
		quit(1)
		return

func _validate_day6_well_entry_chain(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 6 well entry chain validation.")
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
			"1004",
			"1301"
		],
		{
			"route_well": true
		},
		{
			"id": "transition_day_6_well",
			"transition_kind": "advance_then_phase_entry",
			"target_event_id": "1303"
		}
	)

	var morning_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not morning_frontier.has("day6_well_mark_entry"):
		push_error("Day 6 well chain missing day6_well_mark_entry at morning frontier: %s" % str(morning_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day6_well_mark_entry")
	if run_state.current_event_id != "1303":
		push_error("Expected 1303 after selecting day6_well_mark_entry, got %s" % run_state.current_event_id)
		quit(1)
		return
	_complete_current_event_with_first_option(run_controller, run_state)

	var post_well_frontier: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not post_well_frontier.has("day6_rest") or not post_well_frontier.has("day6_records_push"):
		push_error("Day 6 well entry did not unfold shared Day 6 route frontier after 1303: %s" % str(post_well_frontier))
		quit(1)
		return

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

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids

func _find_node(route_map_view: Dictionary, node_id: String) -> Dictionary:
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(node.get("id", "")) == node_id:
			return node
	return {}
