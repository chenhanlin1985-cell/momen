extends SceneTree

const ROUTE_MAP_DIR := "res://content/story/act1/route_map"
const BANNED_HINT_SNIPPETS := [
	"后续阶段",
	"最后后续"
]

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

	print("validate_route_map_copy_runner: OK")
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
	for node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		var node_id: String = str(node.get("node_id", ""))
		var hint: String = str(node.get("hint", ""))
		for snippet: String in BANNED_HINT_SNIPPETS:
			if hint.contains(snippet):
				failures.append("%s node %s still contains banned generic copy '%s'" % [path, node_id, snippet])

