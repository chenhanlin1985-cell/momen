extends SceneTree

func _initialize() -> void:
	var root: Window = get_root()
	var run_controller: Node = root.get_node_or_null("RunController")
	var app_state: Node = root.get_node_or_null("AppState")
	var save_service: Node = root.get_node_or_null("SaveService")
	if run_controller == null or app_state == null or save_service == null:
		push_error("Missing required autoloads for battle save/restore validation.")
		quit(1)
		return
	if run_controller._content_repository == null:
		run_controller._ready()

	_validate_restore_mid_battle(run_controller, app_state, save_service)
	_validate_restore_after_battle_result(run_controller, app_state, save_service)

	print("validate_battle_save_restore_runner: OK")
	quit()

func _validate_restore_mid_battle(run_controller: Node, app_state: Node, save_service: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Failed to enter Wang battle before save.")
		return

	var battle_state: BattleState = run_state.current_battle_state
	battle_state.selected_slot_index = 1
	battle_state.slot_card_ids[0] = "9121"
	battle_state.slot_card_ids[1] = "9112"
	var payload: Dictionary = save_service.build_run_save_payload()
	save_service.restore_run_state(payload)

	var restored_run_state: RunState = app_state.current_run_state
	if restored_run_state.current_battle_state == null:
		_fail("Battle state missing after restoring mid-battle save.")
		return
	if restored_run_state.current_event_id != "2004":
		_fail("Expected event 2004 after restoring mid-battle save, got %s" % restored_run_state.current_event_id)
		return
	if restored_run_state.current_battle_state.selected_slot_index != 1:
		_fail("Selected slot index was not preserved across mid-battle save.")
		return
	if restored_run_state.current_battle_state.slot_card_ids[0] != "9121" or restored_run_state.current_battle_state.slot_card_ids[1] != "9112":
		_fail("Battle slot contents were not preserved across mid-battle save.")
		return
	if run_controller.get_current_route_map_view().size() != 0:
		_fail("Route map should stay hidden while restoring mid-battle state.")
		return

func _validate_restore_after_battle_result(run_controller: Node, app_state: Node, save_service: Node) -> void:
	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	run_controller._run_state_mutator.set_current_event(run_state, "2004")
	var intrude_result: Dictionary = run_controller._event_service.choose_option(
		run_state,
		run_controller._content_repository,
		"__intrude__"
	)
	if not bool(intrude_result.get("success", false)) or run_state.current_battle_state == null:
		_fail("Failed to enter Wang battle before result restore.")
		return

	run_state.current_battle_state.is_battle_over = true
	run_state.current_battle_state.is_player_victory = true
	run_state.current_battle_state.is_player_defeat = false
	run_controller._complete_current_battle()
	var payload: Dictionary = save_service.build_run_save_payload()
	save_service.restore_run_state(payload)

	var restored_run_state: RunState = app_state.current_run_state
	if restored_run_state.current_battle_state != null:
		_fail("Battle state should be cleared after restoring post-battle result state.")
		return
	if restored_run_state.current_event_id != "9202":
		_fail("Expected success result event 9202 after restore, got %s" % restored_run_state.current_event_id)
		return
	if restored_run_state.current_battle_resolution_text.is_empty():
		_fail("Battle resolution text missing after restoring post-battle result state.")
		return
	if run_controller.get_current_route_map_view().size() != 0:
		_fail("Route map should stay hidden while result event is active after restore.")
		return

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
