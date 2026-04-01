extends SceneTree

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")

func _initialize() -> void:
	var compiler = COMPILER_SCRIPT.new()
	var apply_result: Dictionary = compiler.apply_current_project_assets(true)
	if not _to_bool(apply_result.get("success", false)):
		_emit_errors(apply_result)
		quit(1)
		return
	var validate_result: Dictionary = compiler.compile_markdown(false)
	if not _to_bool(validate_result.get("success", false)):
		_emit_errors(validate_result)
		quit(1)
		return
	print("Markdown compiled and applied to current project structure")
	quit()

func _emit_errors(result: Dictionary) -> void:
	for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
		push_error(error_text)

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
