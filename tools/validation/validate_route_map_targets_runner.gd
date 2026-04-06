extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

func _initialize() -> void:
	var repository: ContentRepository = CONTENT_REPOSITORY_SCRIPT.new()
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
		for node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
			var target_kind: String = str(node.get("target_kind", "action"))
			var node_id: String = str(node.get("node_id", ""))
			var target_id: String = str(node.get("target_id", ""))
			if target_kind == "transition":
				var transition_kind: String = str(node.get("target_transition_kind", ""))
				if transition_kind.is_empty():
					failures.append("%s has empty target_transition_kind" % node_id)
				continue
			if target_id.is_empty():
				failures.append("%s has empty target_id" % node_id)
				continue
			if target_kind == "action" and repository.get_action_definition(target_id).is_empty():
				failures.append("%s points to missing action %s" % [str(node.get("node_id", "")), target_id])
			elif target_kind == "event" and repository.get_story_event_definition("default_run", target_id).is_empty():
				failures.append("%s points to missing event %s" % [str(node.get("node_id", "")), target_id])
	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		printerr("validate_route_map_targets_runner: FAILED")
		quit(1)
		return
	print("validate_route_map_targets_runner: OK")
	quit()
