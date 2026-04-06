extends SceneTree

func _initialize() -> void:
	var file: FileAccess = FileAccess.open("res://content/dialogue/texts/outer_senior_texts.json", FileAccess.READ)
	if file == null:
		printerr("validate_outer_senior_texts_runner: FAILED to open file")
		quit(1)
		return
	var raw: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(raw)
	if not (parsed is Dictionary):
		printerr("validate_outer_senior_texts_runner: FAILED to parse JSON")
		quit(1)
		return
	var texts: Dictionary = parsed
	for key: String in ["2003.opening", "2007.opening", "2003.observe", "2007.observe"]:
		if str(texts.get(key, "")).strip_edges().is_empty():
			printerr("validate_outer_senior_texts_runner: missing key %s" % key)
			quit(1)
			return
	print("validate_outer_senior_texts_runner: OK")
	quit()
