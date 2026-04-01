extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    var defs := repo.get_story_event_definitions("default_run")
    for definition in defs:
        var slot := String(definition.get("slot", ""))
        if slot in ["phase_entry", "post_action"]:
            continue
        print("bad_slot=", definition.get("id", ""), " slot=", slot, " location=", definition.get("location_id", ""), " allowed=", definition.get("allowed_locations", []))
    quit()
