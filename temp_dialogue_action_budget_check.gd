extends SceneTree
func _init() -> void:
    var run_controller: Node = get_root().get_node("RunController")
    var app_state: Node = get_root().get_node("AppState")
    run_controller.start_new_run()
    if not app_state.current_run_state.current_event_id.is_empty():
        run_controller.complete_current_dialogue_event()
    var run: RunState = app_state.current_run_state
    print("after intro phase=", run.world_state.current_phase, " actions=", run.world_state.actions_remaining)
    var before: Array[Dictionary] = run_controller.get_available_npc_interactions()
    print("dorm buttons=", before.map(func(item): return {"id": item.get("id", ""), "consumes": item.get("consumes_action", null)}))
    run_controller.perform_npc_interaction("friendly_peer_ask_well")
    run = app_state.current_run_state
    print("after click event=", run.current_event_id, " actions=", run.world_state.actions_remaining)
    run_controller.complete_current_dialogue_event()
    run = app_state.current_run_state
    print("after finish dialogue phase=", run.world_state.current_phase, " actions=", run.world_state.actions_remaining)
    print("corridor move test:")
    run_controller.move_to_location("corridor")
    var corridor_buttons: Array[Dictionary] = run_controller.get_available_npc_interactions()
    print("corridor buttons=", corridor_buttons.map(func(item): return item.get("id", "")))
    quit()
