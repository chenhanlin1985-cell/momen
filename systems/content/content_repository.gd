class_name ContentRepository
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")
const STORY_CSV_IMPORTER_SCRIPT := preload("res://systems/content/story_csv_importer.gd")
const ACTIONS_PATH: String = "res://content/actions/action_definitions.json"
const NPCS_PATH: String = "res://content/npcs/npc_definitions.json"
const NPC_INTERACTIONS_PATH: String = "res://content/npcs/npc_interactions.json"
const GOALS_PATH: String = "res://content/goals/goal_definitions.json"
const RUNS_PATH: String = "res://content/runs/run_definitions.json"
const ENDINGS_PATH: String = "res://content/endings/ending_definitions.json"
const EVENTS_PATH: String = "res://content/events/event_definitions.json"
const LOCATIONS_PATH: String = "res://content/locations/location_definitions.json"
const ENEMIES_PATH: String = "res://content/enemies/enemy_definitions.json"
const BATTLE_CARDS_PATH: String = "res://content/battle/card_definitions.json"
const BATTLE_ENEMY_MINDS_PATH: String = "res://content/battle/enemy_mind_definitions.json"
const BATTLE_DEFINITIONS_PATH: String = "res://content/battle/battle_definitions.json"
const BATTLE_POLLUTION_PROFILES_PATH: String = "res://content/battle/pollution_profiles.json"
const BATTLE_TEXTS_PATH: String = "res://content/battle/battle_texts.json"
const DIALOGUE_ENCOUNTER_MANIFEST_PATH: String = "res://content/dialogue/encounters/_manifest.json"

var _actions_by_id: Dictionary = {}
var _npcs_by_id: Dictionary = {}
var _npc_interactions_by_id: Dictionary = {}
var _goals_by_id: Dictionary = {}
var _runs_by_id: Dictionary = {}
var _ending_definitions: Array[Dictionary] = []
var _events_by_id: Dictionary = {}
var _locations_by_id: Dictionary = {}
var _enemies_by_id: Dictionary = {}
var _battle_cards_by_id: Dictionary = {}
var _battle_enemy_minds_by_id: Dictionary = {}
var _battle_definitions_by_id: Dictionary = {}
var _battle_pollution_profiles_by_id: Dictionary = {}
var _battle_texts_by_id: Dictionary = {}
var _story_events_by_run_id: Dictionary = {}
var _main_story_flows_by_run_id: Dictionary = {}
var _dialogue_encounters_by_event_id: Dictionary = {}
var _dialogue_encounter_texts_by_id: Dictionary = {}

func _init() -> void:
	_actions_by_id = _index_by_id(_load_array_file(ACTIONS_PATH))
	_npcs_by_id = _index_by_id(_load_array_file(NPCS_PATH))
	_npc_interactions_by_id = _index_by_id(_load_array_file(NPC_INTERACTIONS_PATH))
	_goals_by_id = _index_by_id(_load_array_file(GOALS_PATH))
	_runs_by_id = _index_by_id(_load_array_file(RUNS_PATH))
	_ending_definitions = _load_array_file(ENDINGS_PATH)
	_events_by_id = _index_by_id(_load_array_file(EVENTS_PATH))
	_locations_by_id = _index_by_id(_load_array_file(LOCATIONS_PATH))
	_enemies_by_id = _index_by_id(_load_array_file(ENEMIES_PATH))
	_battle_cards_by_id = _index_by_id(_load_array_file(BATTLE_CARDS_PATH))
	_battle_enemy_minds_by_id = _index_by_id(_load_array_file(BATTLE_ENEMY_MINDS_PATH))
	_battle_definitions_by_id = _index_by_id(_load_array_file(BATTLE_DEFINITIONS_PATH))
	_battle_pollution_profiles_by_id = _index_by_id(_load_array_file(BATTLE_POLLUTION_PROFILES_PATH))
	_battle_texts_by_id = _load_dictionary_file(BATTLE_TEXTS_PATH)
	_story_events_by_run_id = _build_story_event_lookup()
	_main_story_flows_by_run_id = _build_main_story_flow_lookup()
	_build_dialogue_encounter_content()

func get_run_definition(run_id: String) -> Dictionary:
	return _runs_by_id.get(run_id, {}).duplicate(true)

func get_action_definition(action_id: String) -> Dictionary:
	return _actions_by_id.get(action_id, {}).duplicate(true)

func get_npc_definition(npc_id: String) -> Dictionary:
	return _npcs_by_id.get(npc_id, {}).duplicate(true)

func get_npc_state_event_ids(npc_id: String) -> Array[String]:
	var definition: Dictionary = get_npc_definition(npc_id)
	return Array(definition.get("state_event_ids", []), TYPE_STRING, "", null)

func get_npc_definitions(story_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for npc_id: String in _npcs_by_id.keys():
		var definition: Dictionary = _npcs_by_id[npc_id]
		var npc_story_id: String = str(definition.get("story_id", ""))
		if not story_id.is_empty() and not npc_story_id.is_empty() and npc_story_id != story_id:
			continue
		result.append(definition.duplicate(true))
	return result

func get_npc_interaction_definition(interaction_id: String) -> Dictionary:
	return _npc_interactions_by_id.get(interaction_id, {}).duplicate(true)

func get_npc_interaction_definitions(story_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for interaction_id: String in _npc_interactions_by_id.keys():
		var definition: Dictionary = _npc_interactions_by_id[interaction_id]
		var interaction_story_id: String = str(definition.get("story_id", ""))
		if not story_id.is_empty() and not interaction_story_id.is_empty() and interaction_story_id != story_id:
			continue
		result.append(definition.duplicate(true))
	return result

func get_present_npcs_for_location(run_state: RunState, location_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.current_location_id != location_id or not npc_state.is_available:
			continue
		var definition: Dictionary = get_npc_definition(npc_state.id)
		if definition.is_empty():
			continue
		definition["favor"] = npc_state.favor
		definition["alert"] = npc_state.alert
		definition["current_location_id"] = npc_state.current_location_id
		definition["is_available"] = npc_state.is_available
		definition["runtime_tags"] = npc_state.tags.duplicate()
		result.append(definition)
	return result

func get_goal_definition(goal_id: String) -> Dictionary:
	return _goals_by_id.get(goal_id, {}).duplicate(true)

func get_location_definition(location_id: String) -> Dictionary:
	return _locations_by_id.get(location_id, {}).duplicate(true)

func get_location_content_slots(location_id: String) -> Dictionary:
	var definition: Dictionary = get_location_definition(location_id)
	return Dictionary(definition.get("content_slots", {})).duplicate(true)

func get_location_definitions(story_id: String = "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for location_id: String in _locations_by_id.keys():
		var definition: Dictionary = _locations_by_id[location_id]
		var location_story_id: String = str(definition.get("story_id", ""))
		if not story_id.is_empty() and not location_story_id.is_empty() and location_story_id != story_id:
			continue
		result.append(definition.duplicate(true))
	return result

func get_enemy_definition(enemy_id: String) -> Dictionary:
	return _enemies_by_id.get(enemy_id, {}).duplicate(true)

func get_enemy_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for enemy_id: String in _enemies_by_id.keys():
		result.append(_enemies_by_id[enemy_id].duplicate(true))
	return result

func get_battle_card_definition(card_id: String) -> Dictionary:
	return _battle_cards_by_id.get(card_id, {}).duplicate(true)

func get_battle_card_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for card_id: String in _battle_cards_by_id.keys():
		result.append(_battle_cards_by_id[card_id].duplicate(true))
	return result

func get_battle_enemy_mind_definition(enemy_mind_id: String) -> Dictionary:
	return _battle_enemy_minds_by_id.get(enemy_mind_id, {}).duplicate(true)

func get_battle_definition(battle_id: String) -> Dictionary:
	return _battle_definitions_by_id.get(battle_id, {}).duplicate(true)

func get_battle_pollution_profile_definition(profile_id: String) -> Dictionary:
	return _battle_pollution_profiles_by_id.get(profile_id, {}).duplicate(true)

func get_battle_definition_by_entry_event_id(event_id: String) -> Dictionary:
	for battle_id: String in _battle_definitions_by_id.keys():
		var definition: Dictionary = Dictionary(_battle_definitions_by_id[battle_id])
		if str(definition.get("entry_event_id", "")) == event_id:
			return definition.duplicate(true)
	return {}

func get_battle_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for battle_id: String in _battle_definitions_by_id.keys():
		result.append(_battle_definitions_by_id[battle_id].duplicate(true))
	return result

func get_battle_texts() -> Dictionary:
	return _battle_texts_by_id.duplicate(true)

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

func get_story_event_definitions_by_category(run_id: String, content_category: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in get_story_event_definitions(run_id):
		if str(definition.get("content_category", "")) != content_category:
			continue
		result.append(definition)
	return result

func get_story_event_definitions_for_location(run_id: String, location_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in get_story_event_definitions(run_id):
		if str(definition.get("location_id", "")) == location_id:
			result.append(definition)
			continue
		var allowed_locations: Array[String] = Array(definition.get("allowed_locations", []), TYPE_STRING, "", null)
		if allowed_locations.has(location_id):
			result.append(definition)
	return result

func get_story_event_definitions_for_participant(run_id: String, participant_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in get_story_event_definitions(run_id):
		var participants: Array[String] = Array(definition.get("participants", []), TYPE_STRING, "", null)
		if participants.has(participant_id):
			result.append(definition)
	return result

func get_main_story_flow_definition(run_id: String) -> Dictionary:
	return Dictionary(_main_story_flows_by_run_id.get(run_id, {})).duplicate(true)

func get_dialogue_encounter_definition(event_id: String) -> Dictionary:
	var definition: Dictionary = Dictionary(_dialogue_encounters_by_event_id.get(event_id, {})).duplicate(true)
	if definition.is_empty():
		return {}
	return Dictionary(_resolve_dialogue_text_references(definition))

func import_story_events_from_csv(csv_dir: String) -> Array[Dictionary]:
	var importer = STORY_CSV_IMPORTER_SCRIPT.new()
	return importer.import_directory(csv_dir)

func get_visible_actions(
	run_state: RunState,
	condition_evaluator: ConditionEvaluator,
	location_id: String = ""
) -> Array[Dictionary]:
	var visible_actions: Array[Dictionary] = []
	var resolved_location_id: String = location_id if not location_id.is_empty() else run_state.world_state.current_location_id
	var location_categories: Array[String] = []
	if not resolved_location_id.is_empty():
		var location_definition: Dictionary = get_location_definition(resolved_location_id)
		location_categories = Array(location_definition.get("base_actions", []), TYPE_STRING, "", null)
	for action_id: String in _actions_by_id.keys():
		var definition: Dictionary = _actions_by_id[action_id]
		if not _to_bool(definition.get("is_visible", true)):
			continue
		var allowed_locations: Array[String] = Array(
			definition.get("allowed_locations", []),
			TYPE_STRING,
			"",
			null
		)
		if not resolved_location_id.is_empty() and not allowed_locations.is_empty() and not allowed_locations.has(resolved_location_id):
			continue
		var action_category: String = str(definition.get("action_category", ""))
		if not location_categories.is_empty() and not action_category.is_empty() and not location_categories.has(action_category):
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


func get_visible_day_node_actions(
	run_state: RunState,
	condition_evaluator: ConditionEvaluator
) -> Array[Dictionary]:
	var visible_actions: Array[Dictionary] = []
	for action_id: String in _actions_by_id.keys():
		var definition: Dictionary = _actions_by_id[action_id]
		if not _to_bool(definition.get("is_visible", true)):
			continue
		var conditions: Array[Dictionary] = Array(
			definition.get("availability_conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		if not condition_evaluator.evaluate_all(run_state, conditions):
			continue
		visible_actions.append(definition.duplicate(true))
	visible_actions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("sort_order", 0)) < int(b.get("sort_order", 0))
	)
	return visible_actions

func _load_array_file(path: String) -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error(GAME_TEXT.format_text("content_repository.errors.read_content_failed", [path], path))
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		push_error(GAME_TEXT.format_text("content_repository.errors.invalid_content_format", [path], path))
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

func _build_main_story_flow_lookup() -> Dictionary:
	var lookup: Dictionary = {}
	for run_id: String in _runs_by_id.keys():
		var run_definition: Dictionary = _runs_by_id[run_id]
		var path: String = str(run_definition.get("main_story_flow_path", ""))
		if path.is_empty():
			lookup[run_id] = {}
			continue
		lookup[run_id] = _load_dictionary_file(path)
	return lookup

func _build_dialogue_encounter_content() -> void:
	var definitions: Array[Dictionary] = []
	_dialogue_encounter_texts_by_id = {}
	for entry: Dictionary in _load_array_file(DIALOGUE_ENCOUNTER_MANIFEST_PATH):
		var logic_path: String = str(entry.get("logic_path", ""))
		var text_path: String = str(entry.get("text_path", ""))
		if not logic_path.is_empty():
			definitions.append_array(_load_array_file(logic_path))
		if not text_path.is_empty():
			_dialogue_encounter_texts_by_id.merge(_load_dictionary_file(text_path), true)
	_dialogue_encounters_by_event_id = _index_by_event_id(definitions, "event_id")

func _load_story_event_definitions_for_run(run_definition: Dictionary) -> Array[Dictionary]:
	var definitions: Array[Dictionary] = []
	var csv_dir: String = str(run_definition.get("story_csv_dir", ""))
	if not csv_dir.is_empty():
		definitions = import_story_events_from_csv(csv_dir)

	return definitions

func _load_dictionary_file(path: String) -> Dictionary:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error(GAME_TEXT.format_text("content_repository.errors.read_content_failed", [path], path))
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error(GAME_TEXT.format_text("content_repository.errors.invalid_content_format", [path], path))
		return {}
	return Dictionary(parsed).duplicate(true)

func _index_story_event_definitions(definitions: Array[Dictionary]) -> Dictionary:
	var indexed: Dictionary = {}
	for definition: Dictionary in definitions:
		var event_id: String = str(definition.get("id", ""))
		if event_id.is_empty():
			continue
		indexed[event_id] = definition
	return indexed

func _index_by_event_id(items: Array[Dictionary], key_name: String) -> Dictionary:
	var indexed: Dictionary = {}
	for item: Dictionary in items:
		var item_id: String = str(item.get(key_name, ""))
		if item_id.is_empty():
			continue
		indexed[item_id] = item
	return indexed

func _resolve_dialogue_text_references(value: Variant) -> Variant:
	if value is Dictionary:
		var resolved: Dictionary = {}
		for raw_key: Variant in value.keys():
			var key: String = str(raw_key)
			if _is_dialogue_text_reference_key(key):
				var target_key: String = key.trim_suffix("_id")
				resolved[target_key] = _resolve_dialogue_text(str(value[raw_key]))
				continue
			resolved[key] = _resolve_dialogue_text_references(value[raw_key])
		return resolved

	if value is Array:
		var resolved_array: Array = []
		for item: Variant in value:
			resolved_array.append(_resolve_dialogue_text_references(item))
		return resolved_array

	return value

func _is_dialogue_text_reference_key(key: String) -> bool:
	if key.ends_with("_text_id"):
		return true
	return key == "label_id" or key == "domain_label_id" or key == "description_id"

func _resolve_dialogue_text(text_id: String) -> String:
	return str(_dialogue_encounter_texts_by_id.get(text_id, text_id))

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized: String = str(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1" or normalized == "yes"
		_:
			return value != null
