extends SceneTree
func _init():
    var importer = load("res://systems/content/story_csv_importer.gd").new()
    var events = importer.import_directory("res://content/story/act1/csv")
    for id in ["conditional_senior_test", "conditional_patrol_interrogation"]:
        var ev := {}
        for definition in events:
            if String(definition.get("id", "")) == id:
                ev = definition
                break
        print(id, ":", ev.get("presentation_type", ""), ",", ev.get("dialogue_resource_path", ""), ",", ev.get("dialogue_start_cue", ""), ",", ev.get("speaker_npc_id", ""), ",", ev.get("participants", []))
    quit()
