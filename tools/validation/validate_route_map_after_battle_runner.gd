extends SceneTree

func _initialize() -> void:
	var root: Window = get_root()
	var run_controller: Node = root.get_node_or_null("RunController")
	var app_state: Node = root.get_node_or_null("AppState")
	if run_controller == null or app_state == null:
		push_error("Missing autoload singletons for route-map-after-battle validation.")
		quit(1)
		return
	if run_controller._content_repository == null:
		run_controller._ready()

	_validate_day1_wang_to_close_frontier(run_controller, app_state)
	_validate_day2_random_battle_return(run_controller, app_state)

	print("validate_route_map_after_battle_runner: OK")
	quit()

func _validate_day1_wang_to_close_frontier(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Failed to start Wang battle for route-map return validation.")
		return

	run_state.world_state.day = 1
	run_state.world_state.current_phase = "day"
	run_controller._route_map_service.set_route_map_cursor(run_state, "day1_wang_event")
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_choose_first_option_then_continue(run_controller, run_state)

	var selectable_ids: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if not selectable_ids.has("day1_close"):
		_fail("Expected day1_close frontier after Wang victory, got %s" % str(selectable_ids))
		return

func _validate_day2_random_battle_return(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_state.world_state.day = 2
	run_state.world_state.current_phase = "day"
	run_state.triggered_event_ids = ["1001", "2001", "9102", "2004", "9202", "1002", "2002"]
	run_controller._route_map_service.clear_route_map_progress(run_state)
	run_controller._route_map_service.set_route_map_cursor(run_state, "day2_clue_room")
	run_controller._set_current_event_and_start_battle(run_state, "9501")
	if run_state.current_battle_state == null:
		_fail("Failed to start random battle 9501 for route-map return validation.")
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	_choose_first_option_then_continue(run_controller, run_state)

	var selectable_ids: Array[String] = _collect_selectable_ids(run_controller.get_current_route_map_view())
	if selectable_ids.is_empty():
		_fail("Route map did not reappear after random battle resolution.")
		return
	if not selectable_ids.has("day2_close") and selectable_ids.size() < 2:
		_fail("Unexpectedly thin frontier after random battle resolution: %s" % str(selectable_ids))
		return

func _choose_first_option_then_continue(run_controller: Node, run_state: RunState) -> void:
	var option_views: Array[Dictionary] = run_controller.get_current_event_option_views()
	if option_views.is_empty():
		_fail("Event %s has no options." % run_state.current_event_id)
		return
	run_controller.choose_event_option(str(option_views[0].get("id", "")))
	if not run_state.current_event_id.is_empty():
		run_controller.choose_event_option("__continue__")

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
