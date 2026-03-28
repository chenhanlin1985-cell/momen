class_name ContentRepository
extends RefCounted

const ACTIONS_PATH: String = "res://content/actions/action_definitions.json"
const NPCS_PATH: String = "res://content/npcs/npc_definitions.json"
const GOALS_PATH: String = "res://content/goals/goal_definitions.json"
const RUNS_PATH: String = "res://content/runs/run_definitions.json"
const ENDINGS_PATH: String = "res://content/endings/ending_definitions.json"
const EVENTS_PATH: String = "res://content/events/event_definitions.json"
const STORY_EVENT_SOURCE_JSON: String = "json"
const STORY_EVENT_SOURCE_CSV: String = "csv"

var _actions_by_id: Dictionary = {}
var _npcs_by_id: Dictionary = {}
var _goals_by_id: Dictionary = {}
var _runs_by_id: Dictionary = {}
var _ending_definitions: Array[Dictionary] = []
var _events_by_id: Dictionary = {}
var _story_events_by_run_id: Dictionary = {}

func _init() -> void:
	_actions_by_id = _index_by_id(_load_array_file(ACTIONS_PATH))
	_npcs_by_id = _index_by_id(_load_array_file(NPCS_PATH))
	_goals_by_id = _index_by_id(_load_array_file(GOALS_PATH))
	_runs_by_id = _index_by_id(_load_array_file(RUNS_PATH))
	_ending_definitions = _load_array_file(ENDINGS_PATH)
	_events_by_id = _index_by_id(_load_array_file(EVENTS_PATH))
	_story_events_by_run_id = _build_story_event_lookup()

func get_run_definition(run_id: String) -> Dictionary:
	return _runs_by_id.get(run_id, {}).duplicate(true)

func get_action_definition(action_id: String) -> Dictionary:
	return _actions_by_id.get(action_id, {}).duplicate(true)

func get_npc_definition(npc_id: String) -> Dictionary:
	return _npcs_by_id.get(npc_id, {}).duplicate(true)

func get_goal_definition(goal_id: String) -> Dictionary:
	return _goals_by_id.get(goal_id, {}).duplicate(true)

func get_ending_definitions() -> Array[Dictionary]:
	return _ending_definitions.duplicate(true)

func get_event_definition(event_id: String) -> Dictionary:
	return _events_by_id.get(event_id, {}).duplicate(true)

func get_all_event_definitions() -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	for event_id: String in _events_by_id.keys():
		definitions.append(_events_by_id[event_id].duplicate(true))
	return definitions

func get_story_event_definition(run_id: String, event_id: String) -> Dictionary:
	var indexed: Dictionary = _story_events_by_run_id.get(run_id, {})
	return indexed.get(event_id, {}).duplicate(true)

func get_story_event_definitions(run_id: String) -> Array[Dictionary]:
	var indexed: Dictionary = _story_events_by_run_id.get(run_id, {})
	var definitions: Array[Dictionary] = []
	for event_id: String in indexed.keys():
		definitions.append(indexed[event_id].duplicate(true))
	return definitions

func import_story_events_from_csv(csv_dir: String) -> Array[Dictionary]:
	var importer: StoryCsvImporter = StoryCsvImporter.new()
	return importer.import_directory(csv_dir)

func get_visible_actions(
	run_state: RunState,
	condition_evaluator: ConditionEvaluator
) -> Array[Dictionary]:
	var visible_actions: Array[Dictionary] = []
	for action_id: String in _actions_by_id.keys():
		var definition: Dictionary = _actions_by_id[action_id]
		if not bool(definition.get("is_visible", true)):
			continue
		var conditions: Array[Dictionary] = Array(
			definition.get("availability_conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		if condition_evaluator.evaluate_all(run_state, conditions):
			visible_actions.append(definition.duplicate(true))
	visible_actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	return visible_actions

func _load_array_file(path: String) -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("无法读取内容文件: %s" % path)
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error("内容文件格式错误: %s" % path)
		return []
	var result: Array[Dictionary] = []
	for item: Variant in parsed:
		if item is Dictionary:
			result.append(item.duplicate(true))
	return result

func _index_by_id(items: Array[Dictionary]) -> Dictionary:
	var indexed: Dictionary = {}
	for item: Dictionary in items:
		var item_id: String = str(item.get("id", ""))
		if item_id.is_empty():
			continue
		indexed[item_id] = item
	return indexed

func _build_story_event_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for run_id: String in _runs_by_id.keys():
		var run_definition: Dictionary = _runs_by_id[run_id]
		var indexed: Dictionary = _index_story_event_definitions(
			_load_story_event_definitions_for_run(run_definition)
		)
		lookup[run_id] = indexed
	return lookup

func _load_story_event_definitions_for_run(run_definition: Dictionary) -> Array[Dictionary]:
	var source: String = str(run_definition.get("story_event_source", STORY_EVENT_SOURCE_JSON))
	var definitions: Array[Dictionary] = []

	if source == STORY_EVENT_SOURCE_CSV:
		var csv_dir: String = str(run_definition.get("story_csv_dir", ""))
		if not csv_dir.is_empty():
			definitions = import_story_events_from_csv(csv_dir)

	if definitions.is_empty():
		for path: String in run_definition.get("story_event_paths", []):
			for definition: Dictionary in _load_array_file(path):
				definitions.append(definition)

	return definitions

func _index_story_event_definitions(definitions: Array[Dictionary]) -> Dictionary:
	var indexed: Dictionary = {}
	for definition: Dictionary in definitions:
		var event_id: String = str(definition.get("id", ""))
		if event_id.is_empty():
			continue
		indexed[event_id] = definition
	return indexed
