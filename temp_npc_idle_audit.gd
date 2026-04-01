extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    var init := preload("res://systems/run/run_initializer.gd").new()
    var meta := preload("res://core/models/meta_progress.gd").new()
    var run := init.create_run("default_run", meta, repo)
    var evaluator := ConditionEvaluator.new()
    var mutator := RunStateMutator.new()
    var npcs := preload("res://systems/npc/npc_service.gd").new(evaluator, mutator)

    run.world_state.current_phase = "day"
    var cases := [
        ["dormitory", "friendly_peer", ["dlg_friendly_peer_well_warning"]],
        ["herb_front", "outer_senior_brother", ["dlg_outer_senior_guidance", "conditional_senior_test"]],
        ["corridor", "herb_steward", ["dlg_herb_steward_probe"]],
        ["corridor", "night_patrol_disciple", ["dlg_patrol_report_anomaly", "conditional_patrol_interrogation"]]
    ]
    for item in cases:
        run.world_state.current_location_id = item[0]
        run.triggered_event_ids.clear()
        for event_id in item[2]:
            run.triggered_event_ids.append(event_id)
        var idle := npcs.get_idle_interaction_for_npc(run, repo, item[1])
        print(item[1], " idle=", idle.get("id", "<none>"))
    quit()
