extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    var init := preload("res://systems/run/run_initializer.gd").new()
    var meta := preload("res://core/models/meta_progress.gd").new()
    var run := init.create_run("default_run", meta, repo)
    var evaluator := ConditionEvaluator.new()
    var mutator := RunStateMutator.new()
    var npcs := preload("res://systems/npc/npc_service.gd").new(evaluator, mutator)
    var events := preload("res://systems/event/event_service.gd").new(evaluator, mutator)
    var day_flow := preload("res://systems/flow/day_flow_service.gd").new(mutator)

    events.resolve_current_or_next_event(run, repo, "phase_entry")
    mutator.mark_event_triggered(run, run.current_event_id)
    mutator.clear_current_event(run)
    day_flow.advance_after_event(run)
    run.world_state.current_location_id = "corridor"

    print("day=", run.world_state.day, " phase=", run.world_state.current_phase, " location=", run.world_state.current_location_id)
    var interactions := npcs.get_available_interactions_for_current_location(run, repo)
    for interaction in interactions:
        print("interaction=", interaction.get("id", ""), " dialogue_event=", interaction.get("dialogue_event_id", ""), " consumes=", interaction.get("consumes_action", false), " display=", interaction.get("display_name", ""))
        var result := npcs.interact(run, repo, String(interaction.get("id", "")))
        print(" result=", result)
    quit()
