extends SceneTree

func _init() -> void:
	var run_controller: Node = get_root().get_node("RunController")
	var app_state: Node = get_root().get_node("AppState")

	run_controller.start_new_run()
	if not app_state.current_run_state.current_event_id.is_empty():
		run_controller.complete_current_dialogue_event()

	var run: RunState = app_state.current_run_state
	print("after_start phase=", run.world_state.current_phase, " location=", run.world_state.current_location_id, " current_event=", run.current_event_id)
	print("start_interactions=", run_controller.get_available_npc_interactions().map(func(item): return item.get("id", "")))

	run_controller.perform_npc_interaction("1102")
	run = app_state.current_run_state
	print("after_open event=", run.current_event_id, " phase=", run.world_state.current_phase)
	print("hub_options=", run_controller.get_current_event_option_views().map(func(item): return item.get("id", "")))

	run_controller.choose_event_option("__talk__")
	run = app_state.current_run_state
	print("after_talk_mode event=", run.current_event_id, " phase=", run.world_state.current_phase)
	print("talk_options=", run_controller.get_current_event_option_views().map(func(item): return item.get("id", "")))

	var option_views: Array[Dictionary] = run_controller.get_current_event_option_views()
	if not option_views.is_empty():
		run_controller.choose_event_option(str(option_views[0].get("id", "")))

	run = app_state.current_run_state
	print("after_pick_option event=", run.current_event_id, " phase=", run.world_state.current_phase)
	print("result_current_event_title=", run_controller.get_current_event().get("title", ""))

	run_controller.complete_current_dialogue_event()
	run = app_state.current_run_state
	print("after_finish event=", run.current_event_id, " phase=", run.world_state.current_phase, " location=", run.world_state.current_location_id)
	print("after_finish_interactions=", run_controller.get_available_npc_interactions().map(func(item): return item.get("id", "")))
	quit()
