extends SceneTree
func _init():
    var scene: PackedScene = load("res://tools/story_mount/story_event_builder.tscn")
    var inst: Node = scene.instantiate()
    print("event builder loaded=", inst != null)
    inst.free()
    quit()
