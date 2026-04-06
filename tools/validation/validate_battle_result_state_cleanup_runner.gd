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

	_validate_wang_success_cleanup(run_controller, app_state)
	_validate_wang_failure_cleanup(run_controller, app_state)

	print("validate_battle_result_state_cleanup_runner: OK")
	quit()

func _validate_wang_success_cleanup(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Could not start Wang battle for cleanup validation.")
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()

	if run_state.current_battle_state != null:
		_fail("Battle state was not cleared after Wang victory.")
		return
	if run_state.current_battle_resolution_text.is_empty():
		_fail("Battle resolution text missing after Wang victory.")
		return

	var current_event: Dictionary = run_controller.get_current_event()
	if current_event.is_empty():
		_fail("Wang success event should still be present immediately after battle resolution.")
		return
	if str(current_event.get("description", "")).find(str(run_state.current_battle_resolution_text)) == -1:
		_fail("Wang success event description does not include battle resolution text.")
		return
	if run_controller.get_current_event_option_views().is_empty():
		_fail("Wang success event should still expose options after battle resolution.")
		return

	run_controller.choose_event_option(str(run_controller.get_current_event_option_views()[0].get("id", "")))
	if run_state.current_event_id == "9202":
		run_controller.choose_event_option("__continue__")

	if not run_state.current_battle_resolution_text.is_empty():
		_fail("Battle resolution text leaked after Wang success continue.")
		return
	if run_state.current_battle_state != null:
		_fail("Battle state leaked after Wang success continue.")
		return
	if not run_controller.get_current_event().is_empty():
		_fail("Current event should be clear after Wang success continue.")
		return

func _validate_wang_failure_cleanup(run_controller: Node, app_state: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Could not start Wang battle for failure cleanup validation.")
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = false
	run_state.current_battle_state.is_player_defeat = true
	run_state.current_battle_state.sanity = 0
	run_controller._complete_current_battle()

	if run_state.current_battle_state != null:
		_fail("Battle state was not cleared after Wang defeat.")
		return
	if run_state.current_event_id != "9203":
		_fail("Expected Wang defeat event 9203, got %s" % run_state.current_event_id)
		return

	run_controller.choose_event_option(str(run_controller.get_current_event_option_views()[0].get("id", "")))
	if not run_state.is_run_over:
		_fail("Run did not end after Wang defeat option.")
		return
	if run_state.current_battle_state != null:
		_fail("Battle state leaked after Wang defeat ending.")
		return
	if not run_state.current_battle_resolution_text.is_empty():
		_fail("Battle resolution text leaked after Wang defeat ending.")
		return

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
