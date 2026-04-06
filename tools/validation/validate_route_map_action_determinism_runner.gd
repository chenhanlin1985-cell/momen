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

	_advance_to_day2_route_choices(run_controller, run_state)

	var day2_map: Dictionary = run_controller.get_current_route_map_view()
	var frontier_ids: Array[String] = _collect_selectable_ids(day2_map)
	if not frontier_ids.has("day2_rest"):
		push_error("Expected day2_rest to be selectable on Day 2, got %s" % str(frontier_ids))
		quit(1)
		return

	run_controller.select_route_map_node("day2_rest")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Selecting day2_rest should open action feedback event, got %s" % run_state.current_event_id)
		quit(1)
		return
	if run_state.current_battle_state != null:
		push_error("Selecting day2_rest should not immediately open a battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return
	var action_feedback_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	if action_feedback_options.size() != 1 or str(action_feedback_options[0].get("id", "")) != "__continue__":
		push_error("Action feedback event should expose only __continue__, got %s" % str(action_feedback_options))
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_rest_map: Dictionary = run_controller.get_current_route_map_view()
	var post_rest_frontier: Array[String] = _collect_selectable_ids(post_rest_map)
	if post_rest_frontier != ["day2_lie_low_reflection", "day2_close"]:
		push_error("Expected day2_rest to advance to day2_lie_low_reflection, got %s" % str(post_rest_frontier))
		quit(1)
		return
	if post_rest_frontier.has("day2_random_battle"):
		push_error("day2_rest should not directly expose day2_random_battle, got %s" % str(post_rest_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day2_lie_low_reflection")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Selecting day2_lie_low_reflection should open action feedback event, got %s" % run_state.current_event_id)
		quit(1)
		return
	if run_state.current_battle_state != null:
		push_error("Selecting day2_lie_low_reflection should not immediately open a battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_reflection_map: Dictionary = run_controller.get_current_route_map_view()
	var post_reflection_frontier: Array[String] = _collect_selectable_ids(post_reflection_map)
	if post_reflection_frontier != ["day2_lie_low_blend"]:
		push_error("Expected day2_lie_low_reflection to continue to day2_lie_low_blend, got %s" % str(post_reflection_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day2_lie_low_blend")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Selecting day2_lie_low_blend should open action feedback event, got %s" % run_state.current_event_id)
		quit(1)
		return
	if run_state.current_battle_state != null:
		push_error("Selecting day2_lie_low_blend should not immediately open a battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_blend_map: Dictionary = run_controller.get_current_route_map_view()
	var post_blend_frontier: Array[String] = _collect_selectable_ids(post_blend_map)
	if post_blend_frontier != ["day2_pharmacy_work"]:
		push_error("Expected day2_lie_low_blend to continue to day2_pharmacy_work, got %s" % str(post_blend_frontier))
		quit(1)
		return

	run_controller.select_route_map_node("day2_pharmacy_work")
	if run_state.current_event_id != "__route_map_action_feedback__":
		push_error("Selecting day2_pharmacy_work should open action feedback event, got %s" % run_state.current_event_id)
		quit(1)
		return
	if run_state.current_battle_state != null:
		push_error("Selecting day2_pharmacy_work should not immediately open a battle, got %s" % run_state.current_battle_state.battle_id)
		quit(1)
		return
	run_controller.choose_event_option("__continue__")

	var post_work_map: Dictionary = run_controller.get_current_route_map_view()
	var post_work_frontier: Array[String] = _collect_selectable_ids(post_work_map)
	if post_work_frontier != ["day2_close"]:
		push_error("Expected day2_pharmacy_work to continue to day2_close, got %s" % str(post_work_frontier))
		quit(1)
		return

	print("validate_route_map_action_determinism_runner: OK")
	quit()

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
	var liu_result_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	run_controller.choose_event_option(str(liu_result_options[0].get("id", "")))
	if run_state.current_event_id == "9102":
		run_controller.choose_event_option("__continue__")

	run_controller.select_route_map_node("day1_wang_event")
	run_controller.choose_event_option("__intrude__")
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	var wang_result_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	run_controller.choose_event_option(str(wang_result_options[0].get("id", "")))
	if run_state.current_event_id == "9202":
		run_controller.choose_event_option("__continue__")

	run_controller.select_route_map_node("day1_close")
	var day2_opening_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	run_controller.choose_event_option(str(day2_opening_options[0].get("id", "")))
	if run_state.current_event_id == "1002":
		run_controller.choose_event_option("__continue__")

	run_controller.select_route_map_node("day2_liu_entry")
	var liu_day2_options: Array[Dictionary] = run_controller.get_current_event_option_views()
	run_controller.choose_event_option(str(liu_day2_options[0].get("id", "")))
	if run_state.current_event_id == "2002":
		run_controller.choose_event_option("__continue__")

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids
