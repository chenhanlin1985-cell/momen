extends SceneTree


func _init() -> void:
	var repo := ContentRepository.new()
	var init := preload("res://systems/run/run_initializer.gd").new()
	var meta := preload("res://core/models/meta_progress.gd").new()
	var run := init.create_run("default_run", meta, repo)
	var evaluator := ConditionEvaluator.new()
	var mutator := RunStateMutator.new()
	var events := preload("res://systems/event/event_service.gd").new(evaluator, mutator)
	var day_flow := preload("res://systems/flow/day_flow_service.gd").new(mutator)

	events.resolve_current_or_next_event(run, repo, "phase_entry")
	if not run.current_event_id.is_empty():
		mutator.mark_event_triggered(run, run.current_event_id)
		mutator.clear_current_event(run)
	day_flow.advance_after_event(run)

	mutator.set_current_event(run, "dlg_friendly_peer_well_warning")
	var first_result: Dictionary = events.choose_option(run, repo, "ask_what_heard")
	print("first_result_success=", first_result.get("success", false))
	print("after_first current_event=", run.current_event_id, " result_text=", run.current_event_result_text)

	mutator.set_current_event(run, "dlg_herb_steward_probe")
	var second_definition: Dictionary = events.get_current_event_definition(run, repo)
	print("second_event_id=", second_definition.get("id", ""))
	print("second_awaiting=", second_definition.get("awaiting_continue", false))
	print("second_result_text=", second_definition.get("result_text", "<none>"))
	print("second_option_count=", events.get_current_event_option_views(run, repo).size())
	quit()
