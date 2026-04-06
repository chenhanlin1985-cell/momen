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

	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state after start_new_run().")
		quit(1)
		return

	_log_state("after_start", run_controller, run_state)

	var opening_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if opening_options.is_empty():
		push_error("Opening event has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(opening_options[0].get("id", "")))
	_log_state("after_1001", run_controller, run_state)
	if run_state.current_event_id == "1001":
		run_controller.choose_event_option("__continue__")
		_log_state("after_1001_continue", run_controller, run_state)

	var route_map_view: Dictionary = run_controller.get_current_route_map_view()
	_print_route_map("after_1001_map", route_map_view)
	var first_frontier_ids: Array[String] = _collect_selectable_ids(route_map_view)
	if not first_frontier_ids.has("day1_liu_battle"):
		push_error("Day 1 map did not expose Liu node as selectable frontier: %s" % str(first_frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day1_liu_battle")
	_log_state("after_select_liu_node", run_controller, run_state)

	var liu_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	var intrude_found: bool = false
	for option_view: Dictionary in liu_options:
		if str(option_view.get("id", "")) == "__intrude__":
			intrude_found = true
			break
	if not intrude_found:
		push_error("Liu event does not expose __intrude__.")
		quit(1)
		return
	run_controller.choose_event_option("__intrude__")
	if run_state.current_battle_state == null:
		push_error("Liu battle did not start.")
		quit(1)
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_log_state("after_liu_battle_complete", run_controller, run_state)

	var liu_result_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if liu_result_options.is_empty():
		push_error("Liu result event has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(liu_result_options[0].get("id", "")))
	_log_state("after_9102", run_controller, run_state)
	if run_state.current_event_id == "9102":
		run_controller.choose_event_option("__continue__")
		_log_state("after_9102_continue", run_controller, run_state)

	var post_liu_map: Dictionary = run_controller.get_current_route_map_view()
	_print_route_map("after_9102_map", post_liu_map)
	var second_frontier_ids: Array[String] = _collect_selectable_ids(post_liu_map)
	if not second_frontier_ids.has("day1_wang_event"):
		push_error("Post-Liu map did not expose Wang node as selectable frontier: %s" % str(second_frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day1_wang_event")
	_log_state("after_select_wang_node", run_controller, run_state)
	if run_state.current_event_id != "2004":
		push_error("Expected Wang event 2004 after selecting Wang node, got %s" % run_state.current_event_id)
		quit(1)
		return

	var wang_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if wang_options.is_empty():
		push_error("Wang event 2004 has no options.")
		quit(1)
		return
	var wang_intrude_found: bool = false
	for option_view: Dictionary in wang_options:
		if str(option_view.get("id", "")) == "__intrude__":
			wang_intrude_found = true
			break
	if not wang_intrude_found:
		push_error("Wang event does not expose __intrude__.")
		quit(1)
		return
	run_controller.choose_event_option("__intrude__")
	_log_state("after_2004_intrude", run_controller, run_state)
	if run_state.current_battle_state == null:
		push_error("Wang battle did not start.")
		quit(1)
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_log_state("after_wang_battle_complete", run_controller, run_state)

	var wang_result_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if wang_result_options.is_empty():
		push_error("Wang result event has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(wang_result_options[0].get("id", "")))
	_log_state("after_9202", run_controller, run_state)
	if run_state.current_event_id == "9202":
		run_controller.choose_event_option("__continue__")
		_log_state("after_9202_continue", run_controller, run_state)

	var close_map: Dictionary = run_controller.get_current_route_map_view()
	_print_route_map("after_2004_map", close_map)
	var close_frontier_ids: Array[String] = _collect_selectable_ids(close_map)
	if not close_frontier_ids.has("day1_close"):
		push_error("Post-Wang map did not expose day1_close as selectable frontier: %s" % str(close_frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day1_close")
	_log_state("after_day1_close", run_controller, run_state)
	if run_state.current_event_id != "1002":
		push_error("Expected 1002 after day1_close, got %s" % run_state.current_event_id)
		quit(1)
		return

	var day2_opening_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if day2_opening_options.is_empty():
		push_error("Day 2 opening event 1002 has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(day2_opening_options[0].get("id", "")))
	_log_state("after_1002", run_controller, run_state)
	if run_state.current_event_id == "1002":
		run_controller.choose_event_option("__continue__")
		_log_state("after_1002_continue", run_controller, run_state)

	var day2_map: Dictionary = run_controller.get_current_route_map_view()
	_print_route_map("after_1002_map", day2_map)
	var day2_frontier_ids: Array[String] = _collect_selectable_ids(day2_map)
	if day2_frontier_ids != ["day2_liu_entry"]:
		push_error("Expected Day 2 to force the Liu entry node after 1002, got %s" % str(day2_frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day2_liu_entry")
	_log_state("after_select_day2_liu_entry", run_controller, run_state)
	if run_state.current_event_id != "2002":
		push_error("Expected 2002 after selecting day2_liu_entry, got %s" % run_state.current_event_id)
		quit(1)
		return

	var day2_liu_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if day2_liu_options.is_empty():
		push_error("Event 2002 has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(day2_liu_options[0].get("id", "")))
	_log_state("after_2002", run_controller, run_state)
	if run_state.current_event_id == "2002":
		run_controller.choose_event_option("__continue__")
		_log_state("after_2002_continue", run_controller, run_state)

	var day2_choices_map: Dictionary = run_controller.get_current_route_map_view()
	_print_route_map("after_2002_map", day2_choices_map)
	var day2_choice_frontier_ids: Array[String] = _collect_selectable_ids(day2_choices_map)
	if day2_choice_frontier_ids.size() < 3:
		push_error("Expected Day 2 frontier choices after 2002, got %s" % str(day2_choice_frontier_ids))
		quit(1)
		return

	print("validate_day1_route_chain_runner: OK")
	quit()

func _log_state(label: String, run_controller: Node, run_state: RunState) -> void:
	print("--- %s ---" % label)
	print("day=%d phase=%s current_event=%s battle=%s cursor_day=%s cursor_node=%s transition=%s" % [
		run_state.world_state.day,
		run_state.world_state.current_phase,
		run_state.current_event_id,
		"yes" if run_state.current_battle_state != null else "no",
		str(run_state.world_state.values.get("_route_map_cursor_day", "")),
		str(run_state.world_state.global_flags.get("_route_map_cursor_node_id", "")),
		str(run_state.world_state.values.get("_route_map_transition_preview", {}))
	])
	if run_state.current_event_id.is_empty():
		var view: Dictionary = run_controller.get_current_route_map_view()
		print("route_map_title=%s" % str(view.get("title", "")))

func _print_route_map(label: String, route_map_view: Dictionary) -> void:
	print("--- %s ---" % label)
	var nodes: Array[Dictionary] = Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null)
	for node: Dictionary in nodes:
		print("%s day=%s locked=%s target=%s:%s" % [
			str(node.get("id", "")),
			str(node.get("day", "")),
			str(node.get("is_locked", false)),
			str(node.get("target_kind", "")),
			str(node.get("target_id", node.get("target_event_id", node.get("target_action_id", ""))))
		])

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids
