extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    for event_id in ["conditional_record_discovery", "act1_res_hidden_stash", "conditional_whisper_deepens"]:
        var definition := repo.get_story_event_definition("default_run", event_id)
        print("id=", event_id, " slot=", definition.get("slot", ""), " pool=", definition.get("pool_id", ""), " loc=", definition.get("location_id", ""), " allowed=", definition.get("allowed_locations", []))
    quit()
