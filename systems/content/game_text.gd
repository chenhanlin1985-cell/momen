class_name GameText
extends RefCounted

const TEXTS_PATHS: Array[String] = [
	"res://content/text/ui_texts.json",
	"res://content/text/dialogue_ui_texts.json",
	"res://content/text/opening_ui_texts.json"
]

static var _loaded: bool = false
static var _texts: Dictionary = {}


static func text(key: String, fallback: String = "") -> String:
	var value: Variant = value_at(key, fallback)
	return str(value)


static func dict(key: String, fallback: Dictionary = {}) -> Dictionary:
	var value: Variant = value_at(key, fallback)
	if value is Dictionary:
		return Dictionary(value).duplicate(true)
	return fallback.duplicate(true)


static func value_at(key: String, fallback: Variant = null) -> Variant:
	_ensure_loaded()
	if key.is_empty():
		return fallback

	var current: Variant = _texts
	for segment: String in key.split("."):
		if not (current is Dictionary) or not Dictionary(current).has(segment):
			return fallback
		current = Dictionary(current)[segment]
	return current


static func format_text(key: String, values: Variant, fallback: String = "") -> String:
	var template: String = text(key, fallback)
	if not template.contains("%"):
		return template
	if values is Array:
		return template % values
	return template % values


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_texts = {}
	for path: String in TEXTS_PATHS:
		if not FileAccess.file_exists(path):
			continue
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file == null:
			continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			_merge_texts(_texts, Dictionary(parsed))

static func _merge_texts(target: Dictionary, source: Dictionary) -> void:
	for key: Variant in source.keys():
		var key_string: String = str(key)
		var source_value: Variant = source[key]
		if target.has(key_string) and target[key_string] is Dictionary and source_value is Dictionary:
			var merged_nested: Dictionary = Dictionary(target[key_string]).duplicate(true)
			_merge_texts(merged_nested, Dictionary(source_value))
			target[key_string] = merged_nested
			continue
		target[key_string] = source_value
