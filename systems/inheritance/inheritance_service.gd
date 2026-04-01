class_name InheritanceService
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")


func generate_options(run_state: RunState) -> Array[Dictionary]:
	if not run_state.is_run_over:
		return []
	return [
		{
			"id": "fragmented_memory_placeholder",
			"display_name": GAME_TEXT.text("inheritance_service.placeholder_name"),
			"description": GAME_TEXT.text("inheritance_service.placeholder_description")
		}
	]
