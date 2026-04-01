class_name RunStateMutator
extends RefCounted

const LOCATION_RUNTIME_STATE_SCRIPT := preload("res://core/models/location_runtime_state.gd")
const GAME_TEXT := preload("res://systems/content/game_text.gd")
const PLAYER_LEVEL_KEY := "level"
const PLAYER_EXPERIENCE_KEY := "experience"


func modify_player_resource(run_state: RunState, key: String, delta: int) -> void:
	var next_value: int = int(run_state.player_state.resources.get(key, 0)) + delta
	run_state.player_state.resources[key] = max(next_value, 0)
	if key == PLAYER_EXPERIENCE_KEY:
		_resolve_player_level_up(run_state)


func modify_player_stat(run_state: RunState, key: String, delta: int) -> void:
	run_state.player_state.stats[key] = int(run_state.player_state.stats.get(key, 0)) + delta


func add_player_tag(run_state: RunState, tag: String) -> void:
	if not run_state.player_state.tags.has(tag):
		run_state.player_state.tags.append(tag)


func consume_action_point(run_state: RunState) -> void:
	run_state.world_state.actions_remaining -= 1


func append_log(run_state: RunState, message: String) -> void:
	run_state.log_entries.append(message)


func queue_followup_event(run_state: RunState, event_id: String) -> void:
	if not run_state.queued_event_ids.has(event_id):
		run_state.queued_event_ids.append(event_id)


func dequeue_followup_event(run_state: RunState, event_id: String) -> void:
	run_state.queued_event_ids.erase(event_id)


func set_current_event(run_state: RunState, event_id: String) -> void:
	if run_state.current_event_id != event_id:
		run_state.current_event_result_text = ""
		_reset_dialogue_state(run_state)
	run_state.current_event_id = event_id


func clear_current_event(run_state: RunState) -> void:
	run_state.current_event_id = ""
	run_state.current_event_result_text = ""
	_reset_dialogue_state(run_state)


func set_current_event_result_text(run_state: RunState, result_text: String) -> void:
	run_state.current_event_result_text = result_text


func set_current_dialogue_mode(run_state: RunState, mode: String) -> void:
	run_state.current_dialogue_mode = mode


func set_current_dialogue_body_override_text(run_state: RunState, body_text: String) -> void:
	run_state.current_dialogue_body_override_text = body_text


func set_current_dialogue_portrait_override_label(run_state: RunState, portrait_label: String) -> void:
	run_state.current_dialogue_portrait_override_label = portrait_label


func set_current_dialogue_intrusion(run_state: RunState, intrusion_tag: String) -> void:
	run_state.current_dialogue_intrusion_tag = intrusion_tag
	run_state.current_dialogue_intrusion_used = not intrusion_tag.is_empty()


func _reset_dialogue_state(run_state: RunState) -> void:
	run_state.current_dialogue_mode = ""
	run_state.current_dialogue_body_override_text = ""
	run_state.current_dialogue_portrait_override_label = ""
	run_state.current_dialogue_intrusion_tag = ""
	run_state.current_dialogue_intrusion_used = false


func mark_event_triggered(run_state: RunState, event_id: String) -> void:
	if not run_state.triggered_event_ids.has(event_id):
		run_state.triggered_event_ids.append(event_id)


func start_next_day(run_state: RunState) -> void:
	run_state.world_state.day += 1
	run_state.world_state.actions_remaining = run_state.world_state.actions_per_day
	run_state.world_state.current_phase = "morning"
	run_state.world_state.last_action_id = ""
	run_state.world_state.last_action_category = ""


func set_phase(run_state: RunState, phase: String) -> void:
	run_state.world_state.current_phase = phase


func set_last_action_id(run_state: RunState, action_id: String) -> void:
	run_state.world_state.last_action_id = action_id


func set_last_action_category(run_state: RunState, action_category: String) -> void:
	run_state.world_state.last_action_category = action_category


func set_current_location_id(run_state: RunState, location_id: String) -> void:
	run_state.world_state.last_location_id = run_state.world_state.current_location_id
	run_state.world_state.current_location_id = location_id


func ensure_location_state(run_state: RunState, location_id: String, starts_unlocked: bool = false) -> Variant:
	var existing: Variant = run_state.world_state.location_states.get(location_id)
	if existing is RefCounted and existing.has_method("to_dict"):
		return existing
	if existing is Dictionary:
		var restored: Variant = LOCATION_RUNTIME_STATE_SCRIPT.new().apply_dict(existing)
		run_state.world_state.location_states[location_id] = restored
		return restored

	var runtime_state: Variant = LOCATION_RUNTIME_STATE_SCRIPT.new()
	runtime_state.id = location_id
	runtime_state.is_unlocked = starts_unlocked
	run_state.world_state.location_states[location_id] = runtime_state
	return runtime_state


func unlock_location(run_state: RunState, location_id: String) -> void:
	var runtime_state: Variant = ensure_location_state(run_state, location_id)
	runtime_state.is_unlocked = true


func block_location(run_state: RunState, location_id: String) -> void:
	var runtime_state: Variant = ensure_location_state(run_state, location_id)
	runtime_state.is_blocked = true


func unblock_location(run_state: RunState, location_id: String) -> void:
	var runtime_state: Variant = ensure_location_state(run_state, location_id)
	runtime_state.is_blocked = false


func increment_location_visit_count(run_state: RunState, location_id: String) -> void:
	var runtime_state: Variant = ensure_location_state(run_state, location_id)
	runtime_state.visit_count += 1


func add_location_tag(run_state: RunState, location_id: String, tag: String) -> void:
	var runtime_state: Variant = ensure_location_state(run_state, location_id)
	if not runtime_state.tags.has(tag):
		runtime_state.tags.append(tag)


func modify_location_value(run_state: RunState, location_id: String, key: String, delta: int) -> void:
	var runtime_state: Variant = ensure_location_state(run_state, location_id)
	runtime_state.values[key] = int(runtime_state.values.get(key, 0)) + delta


func finish_run(run_state: RunState, reason: String) -> void:
	run_state.is_run_over = true
	run_state.end_reason = reason


func set_ending_result(run_state: RunState, ending_result: RefCounted) -> void:
	run_state.ending_result = ending_result


func add_world_tag(run_state: RunState, tag: String) -> void:
	if not run_state.world_state.tags.has(tag):
		run_state.world_state.tags.append(tag)


func set_global_flag(run_state: RunState, key: String, value: Variant = true) -> void:
	run_state.world_state.global_flags[key] = value


func clear_global_flag(run_state: RunState, key: String) -> void:
	run_state.world_state.global_flags.erase(key)


func remove_world_tag(run_state: RunState, tag: String) -> void:
	run_state.world_state.tags.erase(tag)


func modify_world_value(run_state: RunState, key: String, delta: int) -> void:
	run_state.world_state.values[key] = int(run_state.world_state.values.get(key, 0)) + delta


func add_knowledge(run_state: RunState, key: String) -> void:
	if not run_state.player_state.knowledge.has(key):
		run_state.player_state.knowledge.append(key)


func remove_player_tag(run_state: RunState, tag: String) -> void:
	run_state.player_state.tags.erase(tag)


func modify_npc_relation(run_state: RunState, npc_id: String, field: String, delta: int) -> void:
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.id != npc_id:
			continue
		if field == "alert":
			npc_state.alert += delta
			return
		npc_state.favor += delta
		return


func add_npc_tag(run_state: RunState, npc_id: String, tag: String) -> void:
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.id != npc_id:
			continue
		if not npc_state.tags.has(tag):
			npc_state.tags.append(tag)
		return


func remove_npc_tag(run_state: RunState, npc_id: String, tag: String) -> void:
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.id != npc_id:
			continue
		npc_state.tags.erase(tag)
		return


func set_npc_available(run_state: RunState, npc_id: String, is_available: bool) -> void:
	for npc_state: NpcState in run_state.npc_states:
		if npc_state.id != npc_id:
			continue
		npc_state.is_available = is_available
		return


func get_player_level(run_state: RunState) -> int:
	return max(int(run_state.player_state.resources.get(PLAYER_LEVEL_KEY, 1)), 1)


func get_player_experience(run_state: RunState) -> int:
	return max(int(run_state.player_state.resources.get(PLAYER_EXPERIENCE_KEY, 0)), 0)


func get_next_level_experience_required(run_state: RunState) -> int:
	return _experience_required_for_level(get_player_level(run_state))


func _resolve_player_level_up(run_state: RunState) -> void:
	var current_level: int = get_player_level(run_state)
	var current_experience: int = get_player_experience(run_state)
	var did_level_up: bool = false
	while current_experience >= _experience_required_for_level(current_level):
		current_experience -= _experience_required_for_level(current_level)
		current_level += 1
		did_level_up = true
		append_log(run_state, GAME_TEXT.format_text("run_state_mutator.logs.level_up", [current_level]))
	run_state.player_state.resources[PLAYER_LEVEL_KEY] = current_level
	run_state.player_state.resources[PLAYER_EXPERIENCE_KEY] = current_experience
	if did_level_up:
		append_log(
			run_state,
			GAME_TEXT.format_text(
				"run_state_mutator.logs.level_progress",
				[current_experience, _experience_required_for_level(current_level)]
			)
		)


func _experience_required_for_level(level: int) -> int:
	return 4 + max(level - 1, 0) * 2


func mark_goal_completed(run_state: RunState, goal: GoalProgress) -> void:
	goal.completed = true
	append_log(run_state, GAME_TEXT.format_text("run_state_mutator.logs.goal_completed", [goal.display_name]))


func mark_goal_failed(run_state: RunState, goal: GoalProgress) -> void:
	goal.failed = true
	append_log(run_state, GAME_TEXT.format_text("run_state_mutator.logs.goal_failed", [goal.display_name]))


func add_goal(run_state: RunState, goal: GoalProgress) -> void:
	for existing: GoalProgress in run_state.active_goals:
		if existing.id == goal.id:
			return
	run_state.active_goals.append(goal)
	append_log(run_state, GAME_TEXT.format_text("run_state_mutator.logs.goal_added", [goal.display_name], "新目标: %s"))
