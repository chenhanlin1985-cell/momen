extends SceneTree

func _init():
    var repo := ContentRepository.new()
    var flow := repo.get_main_story_flow_definition("default_run")
    var endings := repo.get_ending_definitions()
    var defs := repo.get_story_event_definitions("default_run")
    var init := preload("res://systems/run/run_initializer.gd").new()
    var meta := preload("res://core/models/meta_progress.gd").new()
    var run := init.create_run("default_run", meta, repo)

    print("flow_loaded=", not flow.is_empty())
    print("flow_nodes=", Array(flow.get("nodes", [])).size())
    print("flags=", run.world_state.global_flags)
    print("ending_count=", endings.size())

    var key_events := [
        "act1_day2_missing_rumor",
        "dlg_friendly_peer_well_warning",
        "dlg_herb_steward_probe",
        "dlg_outer_senior_guidance",
        "dlg_patrol_report_anomaly",
        "act1_day7_final_judgement"
    ]
    for event_id in key_events:
        var found := {}
        for d in defs:
            if String(d.get("id", "")) == event_id:
                found = d
                break
        print("event=", event_id, " found=", not found.is_empty(), " req_flags=", found.get("req_flags", []), " presentation=", found.get("presentation_type", ""))

    var npc_defs := repo.get_npc_definitions("act1_well_whisper")
    for npc in npc_defs:
        print("npc=", npc.get("id", ""), " name=", npc.get("display_name", ""), " loc=", npc.get("default_location_id", ""))

    quit()
