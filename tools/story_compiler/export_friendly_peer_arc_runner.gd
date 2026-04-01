extends SceneTree

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")

func _initialize() -> void:
	var compiler = COMPILER_SCRIPT.new()
	var result: Dictionary = compiler.export_friendly_peer_current_arc_markdown(true)
	if not _to_bool(result.get("success", false)):
		for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
			push_error(error_text)
		quit(1)
		return
	print("Exported friendly peer current arc Markdown")
	print(str(result.get("output_path", "")))
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
