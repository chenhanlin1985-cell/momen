extends SceneTree

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")

func _initialize() -> void:
	var compiler = COMPILER_SCRIPT.new()
	var result: Dictionary = compiler.apply_current_dialogue_assets(true)
	if not _to_bool(result.get("success", false)):
		for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
			push_error(error_text)
		quit(1)
		return
	var event_ids: Array = Array(result.get("dialogue_asset_event_ids", []))
	var file_paths: Array = Array(result.get("dialogue_asset_files", []))
	print("Applied dialogue assets for %d events" % event_ids.size())
	for path: String in file_paths:
		print(path)
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
