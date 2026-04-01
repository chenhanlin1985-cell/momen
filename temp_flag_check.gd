extends SceneTree

func _init():
    var repo := ContentRepository.new()
    var defs := repo.get_story_event_definitions("default_run")
    var target := {}
    for d in defs:
        if String(d.get("id", "")) == "act1_day2_missing_rumor":
            target = d
            break

    print("found=", not target.is_empty())
    print("req_flags=", target.get("req_flags", []))
    print("trigger_conditions=", target.get("trigger_conditions", []))

    var init := preload("res://systems/run/run_initializer.gd").new()
    var meta := preload("res://core/models/meta_progress.gd").new()
    var run := init.create_run("default_run", meta, repo)
    run.world_state.day = 2
    run.world_state.current_phase = "morning"
    run.player_state.resources["clue_fragments"] = 2

    var evaluator := ConditionEvaluator.new()
    print(
        "can_trigger=",
        evaluator.evaluate_all(
            run,
            Array(target.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
        )
    )
    quit()
