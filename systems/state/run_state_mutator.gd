class_name RunStateMutator
extends RefCounted

func modify_player_resource(run_state: RunState, key: String, delta: int) -> void:
	run_state.player_state.resources[key] = int(run_state.player_state.resources.get(key, 0)) + delta

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
	run_state.current_event_id = event_id

func clear_current_event(run_state: RunState) -> void:
	run_state.current_event_id = ""

func mark_event_triggered(run_state: RunState, event_id: String) -> void:
	if not run_state.triggered_event_ids.has(event_id):
		run_state.triggered_event_ids.append(event_id)

func start_next_day(run_state: RunState) -> void:
	run_state.world_state.day += 1
	run_state.world_state.actions_remaining = run_state.world_state.actions_per_day
	run_state.world_state.current_phase = "morning"
	run_state.world_state.last_action_id = ""

func set_phase(run_state: RunState, phase: String) -> void:
	run_state.world_state.current_phase = phase

func set_last_action_id(run_state: RunState, action_id: String) -> void:
	run_state.world_state.last_action_id = action_id

func finish_run(run_state: RunState, reason: String) -> void:
	run_state.is_run_over = true
	run_state.end_reason = reason

func set_ending_result(run_state: RunState, ending_result: RefCounted) -> void:
	run_state.ending_result = ending_result

func add_world_tag(run_state: RunState, tag: String) -> void:
	if not run_state.world_state.tags.has(tag):
		run_state.world_state.tags.append(tag)

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

func mark_goal_completed(run_state: RunState, goal: GoalProgress) -> void:
	goal.completed = true
	append_log(run_state, "目标完成: %s" % goal.display_name)

func mark_goal_failed(run_state: RunState, goal: GoalProgress) -> void:
	goal.failed = true
	append_log(run_state, "目标失败: %s" % goal.display_name)
