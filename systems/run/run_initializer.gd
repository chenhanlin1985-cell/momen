class_name RunInitializer
extends RefCounted

const LOCATION_RUNTIME_STATE_SCRIPT := preload("res://core/models/location_runtime_state.gd")
const GAME_TEXT := preload("res://systems/content/game_text.gd")


func create_run(
	run_id: String,
	meta_progress: MetaProgress,
	content_repository: ContentRepository
) -> RunState:
	var run_definition: Dictionary = content_repository.get_run_definition(run_id)
	var run_state: RunState = RunState.new()
	run_state.run_id = run_id
	run_state.story_id = str(run_definition.get("story_id", ""))
	run_state.player_state = _build_player_state(run_definition, meta_progress)
	run_state.world_state = _build_world_state(run_definition, content_repository)
	run_state.npc_states = _build_npc_states(run_definition, content_repository)
	run_state.active_goals = _build_goals(run_definition, content_repository)
	run_state.log_entries = [
		GAME_TEXT.text("run_initializer.logs.new_run"),
		GAME_TEXT.format_text("run_initializer.logs.day_start", [run_state.world_state.day])
	]
	return run_state


func _build_player_state(run_definition: Dictionary, meta_progress: MetaProgress) -> PlayerState:
	var state: PlayerState = PlayerState.new()
	var player_init: Dictionary = run_definition.get("player_init", {})
	state.stats = player_init.get("stats", {}).duplicate(true)
	state.resources = player_init.get("resources", {}).duplicate(true)
	if not state.resources.has("level"):
		state.resources["level"] = 1
	if not state.resources.has("experience"):
		state.resources["experience"] = 0
	state.tags = Array(player_init.get("tags", []), TYPE_STRING, "", null)
	state.knowledge = meta_progress.discovered_knowledge_keys.duplicate()
	return state


func _build_world_state(run_definition: Dictionary, content_repository: ContentRepository) -> WorldState:
	var state: WorldState = WorldState.new()
	state.day = int(run_definition.get("starting_day", 1))
	state.max_day = int(run_definition.get("max_day", 21))
	state.actions_per_day = int(run_definition.get("actions_per_day", 2))
	state.actions_remaining = state.actions_per_day
	state.current_phase = "morning"
	var world_init: Dictionary = run_definition.get("world_init", {})
	state.global_flags = world_init.get("global_flags", {}).duplicate(true)
	state.values = world_init.get("values", {}).duplicate(true)
	state.tags = Array(world_init.get("tags", []), TYPE_STRING, "", null)
	state.current_location_id = str(run_definition.get("starting_location_id", "01"))
	state.last_location_id = ""
	state.location_states = _build_location_states(run_definition, content_repository)
	return state


func _build_location_states(run_definition: Dictionary, content_repository: ContentRepository) -> Dictionary:
	var result: Dictionary = {}
	var starting_unlocked: Array[String] = Array(run_definition.get("starting_unlocked_locations", []), TYPE_STRING, "", null)
	for definition: Dictionary in content_repository.get_location_definitions(str(run_definition.get("story_id", ""))):
		var runtime_state: Variant = LOCATION_RUNTIME_STATE_SCRIPT.new()
		runtime_state.id = str(definition.get("id", ""))
		runtime_state.is_unlocked = _to_bool(definition.get("starts_unlocked", false)) or starting_unlocked.has(runtime_state.id)
		runtime_state.is_blocked = _to_bool(definition.get("starts_blocked", false))
		result[runtime_state.id] = runtime_state
	return result


func _build_npc_states(run_definition: Dictionary, content_repository: ContentRepository) -> Array[NpcState]:
	var result: Array[NpcState] = []
	var starting_locations: Dictionary = run_definition.get("starting_npc_locations", {}).duplicate(true)
	for npc_id: String in run_definition.get("starting_npcs", []):
		var npc_definition: Dictionary = content_repository.get_npc_definition(npc_id)
		if npc_definition.is_empty():
			continue
		if starting_locations.has(npc_id):
			npc_definition["current_location_id"] = str(starting_locations[npc_id])
		result.append(NpcState.from_dict(npc_definition))
	return result


func _build_goals(run_definition: Dictionary, content_repository: ContentRepository) -> Array[GoalProgress]:
	var result: Array[GoalProgress] = []
	for goal_id: String in run_definition.get("starting_goal_pool", []):
		var goal_definition: Dictionary = content_repository.get_goal_definition(goal_id)
		if goal_definition.is_empty():
			continue
		result.append(GoalProgress.from_dict(goal_definition))
	return result

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
