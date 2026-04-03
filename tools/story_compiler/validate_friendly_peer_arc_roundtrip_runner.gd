extends SceneTree

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")

const TARGET_EVENT_IDS: Array[String] = [
	"2001",
	"2002",
	"2102"
]

func _initialize() -> void:
	var compiler = COMPILER_SCRIPT.new()
	var before_export: Dictionary = compiler.export_friendly_peer_current_arc_markdown(false)
	if not _ensure_success(before_export):
		return
	var before_bundles_json: String = JSON.stringify(Array(before_export.get("bundles", [])).duplicate(true), "\t")
	var apply_result: Dictionary = compiler.apply_current_project_assets(true)
	if not _ensure_success(apply_result):
		return
	var after_export: Dictionary = compiler.export_friendly_peer_current_arc_markdown(false)
	if not _ensure_success(after_export):
		return
	var after_bundles_json: String = JSON.stringify(Array(after_export.get("bundles", [])).duplicate(true), "\t")
	if before_bundles_json != after_bundles_json:
		push_error("Friendly peer arc roundtrip mismatch")
		quit(1)
		return
	var compiled_result: Dictionary = compiler.compile_markdown(false)
	if not _ensure_success(compiled_result):
		return
	var found_event_ids: Dictionary = {}
	for event_variant: Variant in Array(compiled_result.get("events", [])):
		var event_definition: Dictionary = Dictionary(event_variant)
		found_event_ids[str(event_definition.get("runtime_event_id", compiler._build_draft_event_id(event_definition)))] = true
	for event_id: String in TARGET_EVENT_IDS:
		if not found_event_ids.has(event_id):
			push_error("Markdown compile output missing event: %s" % event_id)
			quit(1)
			return
	print("Friendly peer arc roundtrip validation passed")
	quit()

func _ensure_success(result: Dictionary) -> bool:
	if _to_bool(result.get("success", false)):
		return true
	for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
		push_error(error_text)
	quit(1)
	return false

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
