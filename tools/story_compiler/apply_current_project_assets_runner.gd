extends SceneTree

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")

func _initialize() -> void:
	var compiler = COMPILER_SCRIPT.new()
	var result: Dictionary = compiler.apply_current_project_assets(true)
	if not _to_bool(result.get("success", false)):
		for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
			push_error(error_text)
		quit(1)
		return
	var dialogue_paths: Array = Array(result.get("dialogue_asset_files", []))
	var csv_paths: Array = Array(result.get("csv_asset_files", []))
	var merged_paths: Array[String] = []
	for path_variant: Variant in dialogue_paths:
		var path_text: String = str(path_variant)
		if not path_text.is_empty() and not merged_paths.has(path_text):
			merged_paths.append(path_text)
	for path_variant: Variant in csv_paths:
		var path_text: String = str(path_variant)
		if not path_text.is_empty() and not merged_paths.has(path_text):
			merged_paths.append(path_text)
	print("Applied current project assets")
	for path_text: String in merged_paths:
		print(path_text)
	quit()

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var text: String = String(value).strip_edges().to_lower()
			return text == "true" or text == "1" or text == "yes"
		_:
			return value != null
