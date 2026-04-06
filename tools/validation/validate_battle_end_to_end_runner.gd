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

	_validate_wang_success(run_controller, app_state)
	_validate_wang_failure(run_controller, app_state)
	_validate_random_battle_failure(run_controller, app_state)
	_validate_elder_failure(run_controller, app_state)

	print("validate_battle_end_to_end_runner: OK")
	quit()

func _validate_wang_success(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Wang success path failed to start battle.")
		return

	_finish_current_battle(run_controller, run_state, true)
	if run_state.current_event_id != "9202":
		_fail("Expected Wang success event 9202, got %s" % run_state.current_event_id)
		return
	if run_state.current_battle_resolution_text.is_empty():
		_fail("Expected non-empty battle resolution text before Wang success event.")
		return

	_choose_first_option(run_controller, run_state)
	if run_state.current_event_id == "9202":
		run_controller.choose_event_option("__continue__")
	if not run_state.current_event_id.is_empty():
		_fail("Wang success event did not clear after continue, still at %s" % run_state.current_event_id)
		return
	if not run_state.current_battle_resolution_text.is_empty():
		_fail("Battle resolution text leaked after Wang success continue.")
		return

func _validate_wang_failure(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Wang failure path failed to start battle.")
		return

	_finish_current_battle(run_controller, run_state, false)
	if run_state.current_event_id != "9203":
		_fail("Expected Wang failure event 9203, got %s" % run_state.current_event_id)
		return
	_choose_first_option(run_controller, run_state)
	if not run_state.is_run_over:
		_fail("Wang failure path did not finish run.")
		return
	if run_state.ending_result == null or str(run_state.ending_result.id) != "ending_battle_deviation":
		_fail("Wang failure path ended in wrong ending.")
		return

func _validate_random_battle_failure(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._set_current_event_and_start_battle(run_state, "9501")
	if run_state.current_battle_state == null:
		_fail("Random battle 9501 failed to start.")
		return

	_finish_current_battle(run_controller, run_state, false)
	if run_state.current_event_id != "9503":
		_fail("Expected random battle failure event 9503, got %s" % run_state.current_event_id)
		return
	_choose_first_option(run_controller, run_state)
	if not run_state.is_run_over:
		_fail("Random battle failure path did not finish run.")
		return

func _validate_elder_failure(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2003")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Elder failure path failed to start battle.")
		return

	_finish_current_battle(run_controller, run_state, false)
	if run_state.current_event_id != "9403":
		_fail("Expected elder failure event 9403, got %s" % run_state.current_event_id)
		return
	_choose_first_option(run_controller, run_state)
	if not run_state.is_run_over:
		_fail("Elder failure path did not finish run.")
		return

func _finish_current_battle(run_controller: Node, run_state: RunState, victory: bool) -> void:
	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = victory
	run_state.current_battle_state.is_player_defeat = not victory
	run_state.current_battle_state.sanity = 0 if not victory else run_state.current_battle_state.sanity
	run_controller._complete_current_battle()

func _choose_first_option(run_controller: Node, run_state: RunState) -> void:
	var option_views: Array[Dictionary] = run_controller.get_current_event_option_views()
	if option_views.is_empty():
		_fail("Current event %s has no options." % run_state.current_event_id)
		return
	run_controller.choose_event_option(str(option_views[0].get("id", "")))

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
