extends SceneTree


func _init() -> void:
	var repo := ContentRepository.new()
	var init := preload("res://systems/run/run_initializer.gd").new()
	var meta := preload("res://core/models/meta_progress.gd").new()
	var run := init.create_run("default_run", meta, repo)
	var evaluator := ConditionEvaluator.new()
	var mutator := RunStateMutator.new()
	var npcs := preload("res://systems/npc/npc_service.gd").new(evaluator, mutator)
	var events := preload("res://systems/event/event_service.gd").new(evaluator, mutator)
	var day_flow := preload("res://systems/flow/day_flow_service.gd").new(mutator)

	events.resolve_current_or_next_event(run, repo, "phase_entry")
	if not run.current_event_id.is_empty():
		mutator.mark_event_triggered(run, run.current_event_id)
		mutator.clear_current_event(run)
	day_flow.advance_after_event(run)

	run.world_state.current_location_id = "dormitory"
	print("start_day_actions=", run.world_state.actions_remaining)
	var first_result: Dictionary = npcs.interact(run, repo, "friendly_peer_ask_well")
	print("first_dialogue=", first_result, " actions_after_first=", run.world_state.actions_remaining)
	if str(first_result.get("opened_event_id", "")) != "":
		mutator.set_current_event(run, str(first_result.get("opened_event_id", "")))
		mutator.mark_event_triggered(run, run.current_event_id)
		mutator.clear_current_event(run)

	run.world_state.current_location_id = "corridor"
	var second_buttons: Array[Dictionary] = npcs.get_available_interactions_for_current_location(run, repo)
	print("corridor_buttons=", second_buttons.map(func(item): return item.get("id", "")))
	var second_result: Dictionary = npcs.interact(run, repo, "steward_probe_records")
	print("second_dialogue=", second_result, " actions_after_second=", run.world_state.actions_remaining)
	quit()
