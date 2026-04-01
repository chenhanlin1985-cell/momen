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
	var before := events.get_current_event_definition(run, repo)
	print("before awaiting=", before.get("awaiting_continue", false), " options=", Array(before.get("options", []), TYPE_DICTIONARY, "", null).size())

	var result: Dictionary = events.choose_option(run, repo, "ask_what_heard")
	print("choose success=", result.get("success", false), " current_event=", run.current_event_id, " result_text=", run.current_event_result_text)

	var after := events.get_current_event_definition(run, repo)
	print("after awaiting=", after.get("awaiting_continue", false), " body=", after.get("result_text", ""))
	print("after options=", events.get_current_event_option_views(run, repo).size())

	mutator.mark_event_triggered(run, run.current_event_id)
	mutator.clear_current_event(run)
	print("after clear current_event=", run.current_event_id, " result_text=", run.current_event_result_text)
	quit()
