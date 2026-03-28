class_name RunInitializer
extends RefCounted

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
	run_state.world_state = _build_world_state(run_definition)
	run_state.npc_states = _build_npc_states(run_definition, content_repository)
	run_state.active_goals = _build_goals(run_definition, content_repository)
	run_state.log_entries = [
		"新周目开始。",
		"第 %d 天开始。" % run_state.world_state.day
	]
	return run_state

func _build_player_state(
	run_definition: Dictionary,
	meta_progress: MetaProgress
) -> PlayerState:
	var state: PlayerState = PlayerState.new()
	var player_init: Dictionary = run_definition.get("player_init", {})
	state.stats = player_init.get("stats", {}).duplicate(true)
	state.resources = player_init.get("resources", {}).duplicate(true)
	state.tags = Array(player_init.get("tags", []), TYPE_STRING, "", null)
	state.knowledge = meta_progress.discovered_knowledge_keys.duplicate()
	return state

func _build_world_state(run_definition: Dictionary) -> WorldState:
	var state: WorldState = WorldState.new()
	state.day = int(run_definition.get("starting_day", 1))
	state.max_day = int(run_definition.get("max_day", 21))
	state.actions_per_day = int(run_definition.get("actions_per_day", 2))
	state.actions_remaining = state.actions_per_day
	state.current_phase = "morning"
	var world_init: Dictionary = run_definition.get("world_init", {})
	state.values = world_init.get("values", {}).duplicate(true)
	state.tags = Array(world_init.get("tags", []), TYPE_STRING, "", null)
	return state

func _build_npc_states(
	run_definition: Dictionary,
	content_repository: ContentRepository
) -> Array[NpcState]:
	var result: Array[NpcState] = []
	for npc_id: String in run_definition.get("starting_npcs", []):
		var npc_definition: Dictionary = content_repository.get_npc_definition(npc_id)
		if npc_definition.is_empty():
			continue
		result.append(NpcState.from_dict(npc_definition))
	return result

func _build_goals(
	run_definition: Dictionary,
	content_repository: ContentRepository
) -> Array[GoalProgress]:
	var result: Array[GoalProgress] = []
	for goal_id: String in run_definition.get("starting_goal_pool", []):
		var goal_definition: Dictionary = content_repository.get_goal_definition(goal_id)
		if goal_definition.is_empty():
			continue
		result.append(GoalProgress.from_dict(goal_definition))
	return result
