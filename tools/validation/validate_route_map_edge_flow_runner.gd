extends SceneTree

const ROUTE_MAP_DIR := "res://content/story/act1/route_map"

func _initialize() -> void:
	var failures: Array[String] = []
	var dir := DirAccess.open(ROUTE_MAP_DIR)
	if dir == null:
		push_error("Unable to open %s" % ROUTE_MAP_DIR)
		quit(1)
		return

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			_validate_template("%s/%s" % [ROUTE_MAP_DIR, file_name], failures)
		file_name = dir.get_next()
	dir.list_dir_end()

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_route_map_edge_flow_runner: OK")
	quit()

func _validate_template(path: String, failures: Array[String]) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("Unable to read route map template %s" % path)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		failures.append("Route map template %s is not valid JSON object" % path)
		return
	var template: Dictionary = Dictionary(parsed)
	var columns_by_id: Dictionary = {}
	for node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		columns_by_id[str(node.get("node_id", ""))] = int(node.get("column", 0))
	for edge: Dictionary in Array(template.get("edges", []), TYPE_DICTIONARY, "", null):
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))
		if from_id == "start" or to_id.is_empty():
			continue
		if not columns_by_id.has(from_id) or not columns_by_id.has(to_id):
			failures.append("%s edge %s -> %s references missing node column" % [path, from_id, to_id])
			continue
		var from_column: int = int(columns_by_id.get(from_id, 0))
		var to_column: int = int(columns_by_id.get(to_id, 0))
		if to_column <= from_column:
			failures.append(
				"%s edge %s(%d) -> %s(%d) does not move route map forward" %
				[path, from_id, from_column, to_id, to_column]
			)
