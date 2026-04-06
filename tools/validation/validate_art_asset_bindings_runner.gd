extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

const LOCATION_BACKGROUND_PATHS: Dictionary = {
	"02": "res://assets/art/backgrounds/scenes/02/02_01.png",
	"03": "res://assets/art/backgrounds/scenes/03/03_01.png",
	"04": "res://assets/art/backgrounds/scenes/04/04_01.png",
	"05": "res://assets/art/backgrounds/scenes/05/05_01.png",
	"06": "res://assets/art/backgrounds/scenes/06/06_01.png"
}

const ENDING_ART_PATHS: Dictionary = {
	"ending_battle_deviation": "res://assets/art/backgrounds/scenes/endings/ending_battle_deviation.png.png"
}

func _initialize() -> void:
	var failures: Array[String] = []
	var content_repository = CONTENT_REPOSITORY_SCRIPT.new()

	var expected_paths: Array[String] = [
		"res://assets/art/backgrounds/scenes/02/02_01.png",
		"res://assets/art/backgrounds/scenes/03/03_01.png",
		"res://assets/art/backgrounds/scenes/04/04_01.png",
		"res://assets/art/backgrounds/scenes/05/05_01.png",
		"res://assets/art/backgrounds/scenes/06/06_01.png",
		"res://assets/art/backgrounds/scenes/endings/ending_battle_deviation.png.png",
		"res://assets/art/portraits/npcs/00/9501_default.png",
		"res://assets/art/portraits/npcs/02/02_default.png",
		"res://assets/art/portraits/npcs/03/03_default.png",
		"res://assets/art/portraits/npcs/04/04_default.png"
	]
	for path: String in expected_paths:
		if not FileAccess.file_exists(path.replace("res://", "")):
			failures.append("Missing resource path: %s" % path)

	for npc_id: String in ["02", "03", "04"]:
		var npc_definition: Dictionary = content_repository.get_npc_definition(npc_id)
		var portrait_path: String = str(npc_definition.get("portrait_path", ""))
		if portrait_path.is_empty():
			failures.append("NPC %s portrait_path is empty" % npc_id)
		elif not FileAccess.file_exists(portrait_path.replace("res://", "")):
			failures.append("NPC %s portrait_path missing: %s" % [npc_id, portrait_path])

	for location_id: String in ["02", "03", "04", "05", "06"]:
		var background_path: String = str(LOCATION_BACKGROUND_PATHS.get(location_id, ""))
		if background_path.is_empty():
			failures.append("Location %s missing background_path" % location_id)
		elif not FileAccess.file_exists(background_path.replace("res://", "")):
			failures.append("Location %s background_path missing: %s" % [location_id, background_path])

	var ending_art_path: String = str(ENDING_ART_PATHS.get("ending_battle_deviation", ""))
	if ending_art_path.is_empty():
		failures.append("ending_battle_deviation art path missing")
	elif not FileAccess.file_exists(ending_art_path.replace("res://", "")):
		failures.append("ending_battle_deviation art path missing: %s" % ending_art_path)

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_art_asset_bindings_runner: OK")
	quit()
