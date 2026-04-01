extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    var ids := ["conditional_record_discovery", "conditional_senior_test", "conditional_patrol_interrogation"]
    for event_id in ids:
        var definition := repo.get_story_event_definition("default_run", event_id)
        print("id=", event_id)
        print("slot=", definition.get("slot", ""), " category=", definition.get("content_category", ""), " location=", definition.get("location_id", ""), " allowed=", definition.get("allowed_locations", []))
        print("trigger_conditions=", definition.get("trigger_conditions", []))
        print("block_conditions=", definition.get("block_conditions", []))
    quit()
