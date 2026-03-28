@tool
class_name StoryGraphValidator
extends RefCounted

func validate(graph: Dictionary) -> Array[String]:
	var warnings: Array[String] = []
	var nodes: Dictionary = graph.get("nodes", {})
	var incoming_counts: Dictionary = {}

	for node_id: String in nodes.keys():
		incoming_counts[node_id] = 0

	for node_id: String in nodes.keys():
		var node_data: Dictionary = nodes[node_id]
		var edges: Array[Dictionary] = node_data.get("edges", [])
		for edge: Dictionary in edges:
			var target_id: String = str(edge.get("to_id", ""))
			if not nodes.has(target_id):
				warnings.append("事件 %s 指向了不存在的后续事件 %s" % [node_id, target_id])
				continue
			incoming_counts[target_id] = int(incoming_counts.get(target_id, 0)) + 1

	for node_id: String in nodes.keys():
		var node_data: Dictionary = nodes[node_id]
		var day_min: int = int(node_data.get("day_min", 0))
		var phase: String = str(node_data.get("phase", "unknown"))
		var edges: Array[Dictionary] = node_data.get("edges", [])
		var repeatable: bool = bool(node_data.get("repeatable", false))
		var option_count: int = Array(node_data.get("options", []), TYPE_DICTIONARY, "", null).size()

		if day_min <= 0:
			warnings.append("事件 %s 缺少 day_range" % node_id)
		if phase == "unknown":
			warnings.append("事件 %s 缺少 phase_is" % node_id)
		if option_count == 0:
			warnings.append("事件 %s 没有选项" % node_id)
		if not repeatable and int(incoming_counts.get(node_id, 0)) == 0 and day_min > 1:
			warnings.append("事件 %s 没有显式入口" % node_id)
		if edges.is_empty() and phase == "night" and day_min == 7:
			warnings.append("终夜事件 %s 依赖结局判定收束" % node_id)

	return warnings
