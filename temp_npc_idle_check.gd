extends SceneTree


func _init() -> void:
	var repo := ContentRepository.new()
	var init := preload("res://systems/run/run_initializer.gd").new()
	var meta := preload("res://core/models/meta_progress.gd").new()
	var run := init.create_run("default_run", meta, repo)
	var evaluator := ConditionEvaluator.new()
	var mutator := RunStateMutator.new()
	var npcs := preload("res://systems/npc/npc_service.gd").new(evaluator, mutator)

	run.world_state.current_phase = "day"
	run.world_state.current_location_id = "dormitory"

	var before: Array[Dictionary] = npcs.get_available_interactions_for_current_location(run, repo)
	print("before_buttons=", before.map(func(item: Dictionary): return item.get("id", "")))
	print("before_idle=", npcs.get_idle_interaction_for_npc(run, repo, "friendly_peer").get("id", "<none>"))

	run.triggered_event_ids.append("dlg_friendly_peer_well_warning")
	var after: Array[Dictionary] = npcs.get_available_interactions_for_current_location(run, repo)
	print("after_buttons=", after.map(func(item: Dictionary): return item.get("id", "")))
	print("after_idle=", npcs.get_idle_interaction_for_npc(run, repo, "friendly_peer").get("id", "<none>"))
	quit()
