extends SceneTree


func _init() -> void:
	var repo := ContentRepository.new()
	var init := preload("res://systems/run/run_initializer.gd").new()
	var meta := preload("res://core/models/meta_progress.gd").new()
	var run := init.create_run("default_run", meta, repo)
	var evaluator := ConditionEvaluator.new()
	var mutator := RunStateMutator.new()
	var day_flow := preload("res://systems/flow/day_flow_service.gd").new(mutator)
	var events := preload("res://systems/event/event_service.gd").new(evaluator, mutator)
	var locations := preload("res://systems/location/location_service.gd").new(evaluator, mutator)
	var npcs := preload("res://systems/npc/npc_service.gd").new(evaluator, mutator)

	print("check=day_phase_stays_manual")
	run.world_state.current_phase = "day"
	run.world_state.actions_remaining = 0
	day_flow.advance_after_action(run)
	print("after_action_phase=", run.world_state.current_phase)
	day_flow.advance_after_event(run)
	print("after_event_phase=", run.world_state.current_phase)

	print("check=no_auto_npc_dialogue")
	run = init.create_run("default_run", meta, repo)
	run.world_state.current_phase = "day"
	run.world_state.current_location_id = "dormitory"
	events.resolve_current_or_next_event(run, repo, "phase_entry")
	print("auto_day_event=", run.current_event_id if not run.current_event_id.is_empty() else "<none>")

	print("check=manual_location_followup")
	run = init.create_run("default_run", meta, repo)
	run.world_state.current_phase = "day"
	run.world_state.day = 4
	run.world_state.current_location_id = "herb_records"
	run.world_state.actions_remaining = 0
	run.player_state.resources["clue_fragments"] = 3
	run.world_state.last_action_category = "investigate"
	run.world_state.global_flags["met_wang_deacon"] = true
	var visible_actions: Array[Dictionary] = locations.get_available_actions_for_current_location(run, repo)
	var record_action_id := ""
	for action_definition: Dictionary in visible_actions:
		if str(action_definition.get("story_event_id", "")) == "conditional_record_discovery":
			record_action_id = str(action_definition.get("id", ""))
			break
	print("record_followup_action=", record_action_id if not record_action_id.is_empty() else "<missing>")

	print("check=manual_npc_followup")
	run = init.create_run("default_run", meta, repo)
	run.world_state.current_phase = "day"
	run.world_state.day = 4
	run.world_state.current_location_id = "herb_front"
	run.world_state.actions_remaining = 0
	run.world_state.global_flags["met_mad_elder"] = true
	run.world_state.last_action_id = "corridor"
	run.player_state.tags.append("route_seek_senior")
	var interactions: Array[Dictionary] = npcs.get_available_interactions_for_current_location(run, repo)
	var senior_followup_id := ""
	for interaction_definition: Dictionary in interactions:
		if str(interaction_definition.get("dialogue_event_id", "")) == "conditional_senior_test":
			senior_followup_id = str(interaction_definition.get("id", ""))
			break
	print("senior_followup_interaction=", senior_followup_id if not senior_followup_id.is_empty() else "<missing>")
	if not senior_followup_id.is_empty():
		var result: Dictionary = npcs.interact(run, repo, senior_followup_id)
		print("senior_followup_opened=", result.get("opened_event_id", "<none>"))

	quit()
