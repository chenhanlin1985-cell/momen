extends SceneTree
func _init() -> void:
    var repo := ContentRepository.new()
    for event_id in ["dlg_herb_steward_probe", "dlg_patrol_report_anomaly"]:
        var definition := repo.get_story_event_definition("default_run", event_id)
        print("id=", event_id)
        print(" trigger=", definition.get("trigger_conditions", []))
        print(" block=", definition.get("block_conditions", []))
        print(" options=", Array(definition.get("options", []), TYPE_DICTIONARY, "", null).size())
    quit()
