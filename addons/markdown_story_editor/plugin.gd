@tool
extends EditorPlugin

const PANEL_SCENE := preload("res://tools/story_compiler/markdown_story_editor.tscn")

var _panel: Control


func _enter_tree() -> void:
	_panel = PANEL_SCENE.instantiate()
	_panel.name = "Markdown 剧本"
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _panel)


func _exit_tree() -> void:
	if is_instance_valid(_panel):
		remove_control_from_docks(_panel)
		_panel.queue_free()
