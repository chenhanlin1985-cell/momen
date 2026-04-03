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

	run_controller._run_state_mutator.set_current_event(run_state, "2003")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)):
		push_error("Failed to intrude into elder battle: %s" % str(intrude_result))
		quit(1)
		return
	if run_state.current_battle_state == null:
		push_error("Failed to start elder battle.")
		quit(1)
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_defeat = true
	run_state.current_battle_state.is_player_victory = false
	run_state.current_battle_state.sanity = 0
	run_controller._complete_current_battle()

	var current_event: Dictionary = run_controller.get_current_event()
	if str(current_event.get("id", "")) != "9403":
		push_error("Expected failure event 9403, got %s" % str(current_event.get("id", "")))
		quit(1)
		return
	if run_state.is_run_over:
		push_error("Run ended before failure event option was chosen.")
		quit(1)
		return

	var option_views: Array[Dictionary] = run_controller.get_current_event_option_views()
	if option_views.is_empty():
		push_error("Failure event 9403 has no options.")
		quit(1)
		return
	run_controller.choose_event_option(str(option_views[0].get("id", "")))

	if not run_state.is_run_over:
		push_error("Run did not end after choosing elder failure option.")
		quit(1)
		return
	if run_state.ending_result == null:
		push_error("No ending_result after elder failure flow.")
		quit(1)
		return
	if str(run_state.ending_result.id) != "ending_battle_deviation":
		push_error("Unexpected ending id: %s" % str(run_state.ending_result.id))
		quit(1)
		return

	print("validate_elder_battle_failure_runner: OK")
	print("failure_event=%s" % str(current_event.get("id", "")))
	print("ending_id=%s" % str(run_state.ending_result.id))
	quit()
