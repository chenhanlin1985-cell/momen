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

	_validate_day3_entry(run_controller, app_state)
	_validate_day6_well_entry(run_controller, app_state)

	print("validate_route_map_morning_entry_runner: OK")
	quit()

func _validate_day3_entry(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 3 validation.")
		quit(1)
		return

	run_state.world_state.day = 3
	run_state.world_state.current_phase = "morning"
	run_state.triggered_event_ids = Array([
		"1001",
		"2001",
		"9102",
		"2004",
		"9202",
		"1002",
		"2002"
	], TYPE_STRING, "", null)
	run_state.world_state.global_flags["liu_contact_established"] = true
	run_state.world_state.global_flags["route_lie_low"] = true
	run_controller._run_state_mutator.clear_current_event(run_state)
	run_controller._route_map_service.clear_route_map_progress(run_state)
	run_controller._route_map_service.set_transition_preview(run_state, {
		"id": "transition_day_3",
		"transition_kind": "advance_then_phase_entry",
		"target_event_id": "1102"
	})
	app_state.set_run_state(run_state)

	var route_map_view: Dictionary = run_controller.get_current_route_map_view()
	var frontier_ids: Array[String] = _collect_selectable_ids(route_map_view)
	if frontier_ids != ["day3_morning_entry"]:
		push_error("Day 3 morning entry frontier mismatch: %s" % str(frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day3_morning_entry")
	if run_state.current_event_id != "1102":
		push_error("Selecting day3_morning_entry did not open 1102, got %s" % run_state.current_event_id)
		quit(1)
		return
	if not run_controller._route_map_service.get_transition_preview(run_state).is_empty():
		push_error("Day 3 morning entry should clear transition preview once the route node is selected.")
		quit(1)
		return

	var options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if options.is_empty():
		push_error("Event 1102 has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(options[0].get("id", "")))
	if run_state.current_event_id == "1102":
		run_controller.choose_event_option("__continue__")

	var next_view: Dictionary = run_controller.get_current_route_map_view()
	var next_frontier_ids: Array[String] = _collect_selectable_ids(next_view)
	if next_frontier_ids.size() < 3:
		push_error("Day 3 morning entry did not expand into route choices: %s" % str(next_frontier_ids))
		quit(1)
		return
	for expected_node_id: String in ["day3_pharmacy_work", "day3_records_push"]:
		if not next_frontier_ids.has(expected_node_id):
			push_error("Day 3 morning entry did not expose %s after continue: %s" % [expected_node_id, str(next_frontier_ids)])
			quit(1)
			return
	for node: Dictionary in Array(next_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		if str(node.get("target_kind", "")) == "transition":
			push_error("Day 3 morning entry regressed back to a transition node instead of live route choices.")
			quit(1)
			return

func _validate_day6_well_entry(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state for day 6 validation.")
		quit(1)
		return

	run_state.world_state.day = 6
	run_state.world_state.current_phase = "morning"
	run_state.triggered_event_ids = Array([
		"1001",
		"2001",
		"9102",
		"2004",
		"9202",
		"1002",
		"2002",
		"1102",
		"1103"
	], TYPE_STRING, "", null)
	run_state.world_state.global_flags["liu_contact_established"] = true
	run_state.world_state.global_flags["route_well"] = true
	run_controller._run_state_mutator.clear_current_event(run_state)
	run_controller._route_map_service.clear_route_map_progress(run_state)
	run_controller._route_map_service.set_transition_preview(run_state, {
		"id": "transition_day_6_well",
		"transition_kind": "advance_then_phase_entry",
		"target_event_id": "1303"
	})
	app_state.set_run_state(run_state)

	var route_map_view: Dictionary = run_controller.get_current_route_map_view()
	var frontier_ids: Array[String] = _collect_selectable_ids(route_map_view)
	if frontier_ids != ["day6_well_mark_entry"]:
		push_error("Day 6 well morning entry frontier mismatch: %s" % str(frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day6_well_mark_entry")
	if run_state.current_event_id != "1303":
		push_error("Selecting day6_well_mark_entry did not open 1303, got %s" % run_state.current_event_id)
		quit(1)
		return
	if not run_controller._route_map_service.get_transition_preview(run_state).is_empty():
		push_error("Day 6 well entry should clear transition preview once the route node is selected.")
		quit(1)
		return

	var options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if options.is_empty():
		push_error("Event 1303 has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(options[0].get("id", "")))
	if run_state.current_event_id == "1303":
		run_controller.choose_event_option("__continue__")

	var next_view: Dictionary = run_controller.get_current_route_map_view()
	var next_frontier_ids: Array[String] = _collect_selectable_ids(next_view)
	if next_frontier_ids.size() < 3:
		push_error("Day 6 well morning entry did not expand into route choices: %s" % str(next_frontier_ids))
		quit(1)
		return
	for expected_node_id: String in ["day6_pharmacy_work", "day6_records_push"]:
		if not next_frontier_ids.has(expected_node_id):
			push_error("Day 6 well morning entry did not expose %s after continue: %s" % [expected_node_id, str(next_frontier_ids)])
			quit(1)
			return
	for node: Dictionary in Array(next_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		if str(node.get("target_kind", "")) == "transition":
			push_error("Day 6 well entry regressed back to a transition node instead of live route choices.")
			quit(1)
			return

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids
