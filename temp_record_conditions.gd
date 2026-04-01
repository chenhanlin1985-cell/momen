extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    var definition := repo.get_story_event_definition("default_run", "conditional_record_discovery")
    print("trigger_conditions=", definition.get("trigger_conditions", []))
    print("block_conditions=", definition.get("block_conditions", []))
    quit()
