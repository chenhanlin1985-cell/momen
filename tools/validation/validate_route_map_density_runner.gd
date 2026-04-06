extends SceneTree

func _initialize() -> void:
	var failures: Array[String] = []
	var expectations := {
		2: {"min_nodes": 10, "min_events": 3, "min_columns": 4},
		3: {"min_nodes": 10, "min_events": 4, "min_columns": 4},
		4: {"min_nodes": 10, "min_events": 4, "min_columns": 5},
		5: {"min_nodes": 10, "min_events": 4, "min_columns": 5},
		6: {"min_nodes": 10, "min_events": 4, "min_columns": 5}
	}
	for day: int in expectations.keys():
		var path: String = "res://content/story/act1/route_map/day_%02d.json" % day
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			failures.append("missing template %s" % path)
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if not (parsed is Dictionary):
			failures.append("invalid json %s" % path)
			continue
		var template: Dictionary = parsed
		var nodes: Array[Dictionary] = Array(template.get("nodes", []), TYPE_DICTIONARY, "", null)
		var event_count: int = 0
		var max_column: int = 0
		for node: Dictionary in nodes:
			if str(node.get("target_kind", "action")) == "event":
				event_count += 1
			max_column = max(max_column, int(node.get("column", 0)))
		var day_expectation: Dictionary = Dictionary(expectations.get(day, {}))
		if nodes.size() < int(day_expectation.get("min_nodes", 0)):
			failures.append("day %d expected at least %d nodes, got %d" % [day, int(day_expectation.get("min_nodes", 0)), nodes.size()])
		if event_count < int(day_expectation.get("min_events", 0)):
			failures.append("day %d expected at least %d direct event nodes, got %d" % [day, int(day_expectation.get("min_events", 0)), event_count])
		if max_column < int(day_expectation.get("min_columns", 0)):
			failures.append("day %d expected at least %d columns, got %d" % [day, int(day_expectation.get("min_columns", 0)), max_column])
	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		printerr("validate_route_map_density_runner: FAILED")
		quit(1)
		return
	print("validate_route_map_density_runner: OK")
	quit()
