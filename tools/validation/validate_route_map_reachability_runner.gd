extends SceneTree

func _initialize() -> void:
	var route_dir := "res://content/story/act1/route_map"
	var dir := DirAccess.open(route_dir)
	if dir == null:
		push_error("validate_route_map_reachability_runner: failed to open route map dir")
		quit(1)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.begins_with("day_") and file_name.ends_with(".json"):
			_validate_route_map_file("%s/%s" % [route_dir, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()

	print("validate_route_map_reachability_runner: OK")
	quit()

func _validate_route_map_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("validate_route_map_reachability_runner: failed to read %s" % path)
		quit(1)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("validate_route_map_reachability_runner: invalid json %s" % path)
		quit(1)
		return
	var template: Dictionary = parsed
	var incoming_by_id: Dictionary = {}
	for edge: Dictionary in Array(template.get("edges", []), TYPE_DICTIONARY, "", null):
		var to_id: String = str(edge.get("to", ""))
		if to_id.is_empty():
			continue
		incoming_by_id[to_id] = true

	for node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		var node_id: String = str(node.get("node_id", ""))
		if node_id.is_empty():
			continue
		if not incoming_by_id.has(node_id):
			push_error("validate_route_map_reachability_runner: orphan node %s in %s" % [node_id, path])
			quit(1)
			return
