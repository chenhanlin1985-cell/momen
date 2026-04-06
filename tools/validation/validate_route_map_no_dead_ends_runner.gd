extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	for day: int in [2, 3, 4, 5, 6]:
		var path: String = "res://content/story/act1/route_map/day_%02d.json" % day
		if not FileAccess.file_exists(path):
			failures.append("missing template %s" % path)
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("cannot open template %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			failures.append("invalid json %s" % path)
			continue
		var template: Dictionary = parsed
		var nodes: Array[Dictionary] = Array(template.get("nodes", []), TYPE_DICTIONARY, "", null)
		var outgoing: Dictionary = {}
		for edge: Dictionary in Array(template.get("edges", []), TYPE_DICTIONARY, "", null):
			var from_id: String = str(edge.get("from", ""))
			if from_id.is_empty():
				continue
			outgoing[from_id] = int(outgoing.get(from_id, 0)) + 1
		var transition_count: int = 0
		for node: Dictionary in nodes:
			var node_id: String = str(node.get("node_id", ""))
			var target_kind: String = str(node.get("target_kind", "action"))
			if target_kind == "transition":
				transition_count += 1
				continue
			if int(outgoing.get(node_id, 0)) <= 0:
				failures.append("day %d node %s has no outgoing edge" % [day, node_id])
		if transition_count == 0:
			failures.append("day %d has no explicit transition end node" % day)
	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		printerr("validate_route_map_no_dead_ends_runner: FAILED")
		quit(1)
		return
	print("validate_route_map_no_dead_ends_runner: OK")
	quit()
