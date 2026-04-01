extends SceneTree
func _init():
    var scene := load("res://tools/story_mount/story_mount_browser.tscn")
    var inst = scene.instantiate()
    print("mount_browser_loaded=", inst != null)
    if inst != null:
        inst.free()
    quit()
