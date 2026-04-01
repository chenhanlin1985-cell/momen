extends SceneTree
func make_run() -> Array:
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
    return [repo, run, npcs]
func _init() -> void:
    for interaction_id in ["steward_probe_records", "patrol_report_anomaly"]:
        var bundle: Array = make_run()
        var repo: ContentRepository = bundle[0]
        var run: RunState = bundle[1]
        var npcs: NpcService = bundle[2]
        print("test=", interaction_id, " actions=", run.world_state.actions_remaining)
        print(" available=", npcs.get_available_interactions_for_current_location(run, repo).map(func(item): return item.get("id", "")))
        var result: Dictionary = npcs.interact(run, repo, interaction_id)
        print(" result=", result, " current_event=", run.current_event_id, " actions_after=", run.world_state.actions_remaining)
    quit()
