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
		if not dir.current_is_dir() and file_name.begins_with("day_") and file_name.ends_with(".json"):
			_validate_template("%s/%s" % [ROUTE_MAP_DIR, file_name], failures)
		file_name = dir.get_next()
	dir.list_dir_end()

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_route_map_graph_integrity_runner: OK")
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
	var nodes: Array[Dictionary] = Array(template.get("nodes", []), TYPE_DICTIONARY, "", null)
	var edges: Array[Dictionary] = Array(template.get("edges", []), TYPE_DICTIONARY, "", null)
	if nodes.is_empty():
		failures.append("%s has no nodes" % path)
		return

	var nodes_by_id: Dictionary = {}
	var columns_by_id: Dictionary = {}
	var incoming: Dictionary = {}
	var outgoing: Dictionary = {}
	var transition_count: int = 0

	for node: Dictionary in nodes:
		var node_id: String = str(node.get("node_id", ""))
		if node_id.is_empty():
			failures.append("%s contains node with empty node_id" % path)
			continue
		if nodes_by_id.has(node_id):
			failures.append("%s contains duplicate node_id %s" % [path, node_id])
			continue
		nodes_by_id[node_id] = node
		columns_by_id[node_id] = int(node.get("column", 0))
		if str(node.get("target_kind", "")) == "transition":
			transition_count += 1

	if transition_count <= 0:
		failures.append("%s has no explicit transition end node" % path)

	var seen_edges: Dictionary = {}
	for edge: Dictionary in edges:
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))
		if from_id.is_empty() or to_id.is_empty():
			failures.append("%s contains edge with empty endpoint %s -> %s" % [path, from_id, to_id])
			continue
		var edge_key: String = "%s->%s" % [from_id, to_id]
		if seen_edges.has(edge_key):
			failures.append("%s contains duplicate edge %s" % [path, edge_key])
			continue
		seen_edges[edge_key] = true

		if from_id != "start" and not nodes_by_id.has(from_id):
			failures.append("%s edge %s references missing source node" % [path, edge_key])
			continue
		if not nodes_by_id.has(to_id):
			failures.append("%s edge %s references missing target node" % [path, edge_key])
			continue

		incoming[to_id] = int(incoming.get(to_id, 0)) + 1
		outgoing[from_id] = int(outgoing.get(from_id, 0)) + 1

		if from_id != "start":
			var from_column: int = int(columns_by_id.get(from_id, 0))
			var to_column: int = int(columns_by_id.get(to_id, 0))
			if to_column <= from_column:
				failures.append(
					"%s edge %s(%d) -> %s(%d) does not move route map forward" %
					[path, from_id, from_column, to_id, to_column]
				)

	var reachable_from_start: Dictionary = _walk_from("start", edges)
	var reversible_edges: Array[Dictionary] = []
	for edge: Dictionary in edges:
		reversible_edges.append({"from": str(edge.get("to", "")), "to": str(edge.get("from", ""))})
	var can_reach_terminal: Dictionary = {}
	for node: Dictionary in nodes:
		if str(node.get("target_kind", "")) == "transition":
			can_reach_terminal[str(node.get("node_id", ""))] = true
	var reverse_reachable: Dictionary = _walk_from_many(can_reach_terminal.keys(), reversible_edges)

	for node: Dictionary in nodes:
		var node_id: String = str(node.get("node_id", ""))
		if node_id.is_empty():
			continue
		if not reachable_from_start.has(node_id):
			failures.append("%s node %s is not reachable from start" % [path, node_id])
		if int(incoming.get(node_id, 0)) <= 0:
			failures.append("%s node %s has no incoming edge" % [path, node_id])
		var target_kind: String = str(node.get("target_kind", ""))
		if target_kind != "transition" and int(outgoing.get(node_id, 0)) <= 0:
			failures.append("%s node %s has no outgoing edge" % [path, node_id])
		if target_kind != "transition" and not reverse_reachable.has(node_id):
			failures.append("%s node %s cannot reach a transition end node" % [path, node_id])

func _walk_from(start_id: String, edges: Array[Dictionary]) -> Dictionary:
	var queue: Array[String] = [start_id]
	var visited: Dictionary = {start_id: true}
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for edge: Dictionary in edges:
			if str(edge.get("from", "")) != current:
				continue
			var next_id: String = str(edge.get("to", ""))
			if next_id.is_empty() or visited.has(next_id):
				continue
			visited[next_id] = true
			queue.append(next_id)
	return visited

func _walk_from_many(start_ids: Array, edges: Array[Dictionary]) -> Dictionary:
	var queue: Array[String] = []
	var visited: Dictionary = {}
	for start_id_variant: Variant in start_ids:
		var start_id: String = str(start_id_variant)
		if start_id.is_empty() or visited.has(start_id):
			continue
		visited[start_id] = true
		queue.append(start_id)
	while not queue.is_empty():
		var current: String = queue.pop_front()
		for edge: Dictionary in edges:
			if str(edge.get("from", "")) != current:
				continue
			var next_id: String = str(edge.get("to", ""))
			if next_id.is_empty() or visited.has(next_id):
				continue
			visited[next_id] = true
			queue.append(next_id)
	return visited
