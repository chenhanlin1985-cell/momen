extends SceneTree
func _init() -> void:
    var run_controller: Node = get_root().get_node("RunController")
    var app_state: Node = get_root().get_node("AppState")
    run_controller.start_new_run()
    var run: RunState = app_state.current_run_state
    print("start phase=", run.world_state.current_phase, " current_event=", run.current_event_id)
    if not run.current_event_id.is_empty():
        run_controller.complete_current_dialogue_event()
    run = app_state.current_run_state
    print("after start event phase=", run.world_state.current_phase, " current_event=", run.current_event_id)
    run_controller.move_to_location("corridor")
    run = app_state.current_run_state
    print("after move phase=", run.world_state.current_phase, " location=", run.world_state.current_location_id, " current_event=", run.current_event_id)
    var interactions: Array[Dictionary] = run_controller.get_available_npc_interactions()
    print("buttons=", interactions.map(func(item): return item.get("id", "")))
    run_controller.perform_npc_interaction("steward_probe_records")
    run = app_state.current_run_state
    var event_def: Dictionary = run_controller.get_current_event()
    print("after click event=", run.current_event_id, " presentation=", event_def.get("presentation_type", ""), " title=", event_def.get("title", ""))
    quit()
