extends SceneTree

const TARGET_EVENT_EXPECTATIONS: Dictionary = {
	"2002": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "reward",
		"option_ids": ["2002_opt_01", "2002_opt_02"]
	},
	"2102": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "reward",
		"option_ids": ["2102_opt_01", "2102_opt_02"]
	},
	"2201": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "reward",
		"option_ids": ["2201_opt_01", "2201_opt_02"]
	},
	"2202": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "reward",
		"option_ids": ["2202_opt_01", "2202_opt_02"]
	},
	"2203": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "reward",
		"option_ids": ["2203_opt_01", "2203_opt_02"]
	},
	"2008": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "dialogue",
		"option_ids": ["2008_opt_01"]
	},
	"2007": {
		"presentation_type": "standard_event",
		"scene_mode": "dialogue",
		"event_type_key": "reward",
		"option_ids": ["2007_opt_01"]
	}
}

func _initialize() -> void:
	var root: Window = get_root()
	var run_controller: Node = root.get_node_or_null("RunController")
	var app_state: Node = root.get_node_or_null("AppState")
	if run_controller == null or app_state == null:
		push_error("Missing autoload singletons RunController/AppState.")
		quit(1)
		return
	if run_controller._content_repository == null:
		run_controller._ready()

	run_controller.start_new_run()
	var run_state: RunState = app_state.current_run_state
	if run_state == null:
		push_error("No run state after start_new_run().")
		quit(1)
		return

	var failures: Array[String] = []
	for event_id: String in TARGET_EVENT_EXPECTATIONS.keys():
		var expectation: Dictionary = Dictionary(TARGET_EVENT_EXPECTATIONS.get(event_id, {}))
		run_controller._run_state_mutator.set_current_event(run_state, event_id)
		app_state.set_run_state(run_state)

		var event_definition: Dictionary = run_controller.get_current_event()
		var option_views: Array[Dictionary] = run_controller.get_current_event_option_views()
		var option_ids: Array[String] = []
		var has_stage_action: bool = false
		for option_view: Dictionary in option_views:
			option_ids.append(str(option_view.get("id", "")))
			if bool(option_view.get("is_stage_action", false)):
				has_stage_action = true

		var view_model: Dictionary = MainGameViewModel.build(
			run_state,
			run_controller.get_current_location(),
			run_controller.get_present_npcs(),
			run_controller.get_visible_actions(),
			event_definition,
			run_controller.get_event_hints(),
			option_views,
			run_controller.get_current_location_mount_trace(),
			run_controller.get_present_npc_state_event_trace(),
			run_controller.get_attribute_roles()
		)
		var scene_mode: String = str(view_model.get("scene_mode", ""))
		var event_type_key: String = str(view_model.get("event_type_key", ""))

		print("%s\ttype=%s\tscene=%s\ttag=%s\tmode=%s\toptions=%s" % [
			event_id,
			str(event_definition.get("presentation_type", "")),
			scene_mode,
			event_type_key,
			str(event_definition.get("dialogue_mode", "")),
			",".join(option_ids)
		])

		if str(event_definition.get("presentation_type", "")) != str(expectation.get("presentation_type", "")):
			failures.append("%s presentation_type mismatch" % event_id)
		if scene_mode != str(expectation.get("scene_mode", "")):
			failures.append("%s scene_mode mismatch: %s" % [event_id, scene_mode])
		if event_type_key != str(expectation.get("event_type_key", "")):
			failures.append("%s event_type_key mismatch: %s" % [event_id, event_type_key])
		if option_views.is_empty():
			failures.append("%s has no option views" % event_id)
		if has_stage_action:
			failures.append("%s still exposes stage action options" % event_id)
		if option_ids.has("__intrude__"):
			failures.append("%s still exposes __intrude__" % event_id)
		if option_ids.has("__observe__"):
			failures.append("%s still exposes __observe__" % event_id)
		var expected_option_ids: Array[String] = Array(expectation.get("option_ids", []), TYPE_STRING, "", null)
		if option_ids != expected_option_ids:
			failures.append("%s option ids mismatch: %s" % [event_id, ",".join(option_ids)])

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_non_battle_dialogue_runner: OK")
	quit()
