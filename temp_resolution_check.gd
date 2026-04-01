extends SceneTree
func _init():
    var repo := ContentRepository.new()
    var init := preload("res://systems/run/run_initializer.gd").new()
    var meta := preload("res://core/models/meta_progress.gd").new()
    var run := init.create_run("default_run", meta, repo)
    var ending_service := preload("res://systems/ending/ending_service.gd").new(ConditionEvaluator.new())
    var flow := repo.get_main_story_flow_definition("default_run")
    var endings := repo.get_ending_definitions()

    run.world_state.global_flags["knows_cousin_secret"] = true
    run.world_state.global_flags["learned_blood_stealth"] = true
    for npc_state in run.npc_states:
        if npc_state.id == "friendly_peer":
            npc_state.favor = 2
        if npc_state.id == "herb_steward":
            npc_state.alert = 2
    var result := ending_service.resolve_story_flow_ending(run, flow, endings)
    print("flow_ending_id=", result.id)
    print("flow_ending_title=", result.title)
    quit()
