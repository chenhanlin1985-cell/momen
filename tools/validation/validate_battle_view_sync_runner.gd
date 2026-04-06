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
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		push_error("Failed to start Wang battle for sync validation.")
		quit(1)
		return

	var battle_state: BattleState = run_state.current_battle_state
	battle_state.sanity = 1
	battle_state.hand_cards = ["9111", "9113"]
	battle_state.slot_card_ids[0] = ""
	battle_state.slot_card_ids[1] = ""
	battle_state.selected_slot_index = -1

	var did_finish: bool = run_controller.sync_current_battle_state()
	if not did_finish:
		push_error("Expected sync_current_battle_state to finish a 1-sanity dead turn.")
		quit(1)
		return
	if run_state.current_battle_state != null:
		push_error("Battle state should be cleared after sync-triggered defeat.")
		quit(1)
		return
	if run_state.current_event_id != "9203":
		push_error("Expected Wang defeat event 9203 after sync-triggered defeat, got %s." % run_state.current_event_id)
		quit(1)
		return

	print("validate_battle_view_sync_runner: OK")
	quit()
