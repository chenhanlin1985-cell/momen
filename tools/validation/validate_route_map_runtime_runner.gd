extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const ROUTE_MAP_SERVICE_SCRIPT := preload("res://systems/route/route_map_service.gd")
const RUN_INITIALIZER_SCRIPT := preload("res://systems/run/run_initializer.gd")
const CONDITION_EVALUATOR_SCRIPT := preload("res://systems/condition/condition_evaluator.gd")

func _initialize() -> void:
	var repository: ContentRepository = CONTENT_REPOSITORY_SCRIPT.new()
	var initializer: RunInitializer = RUN_INITIALIZER_SCRIPT.new()
	var route_map_service: RouteMapService = ROUTE_MAP_SERVICE_SCRIPT.new()
	var condition_evaluator: ConditionEvaluator = CONDITION_EVALUATOR_SCRIPT.new()
	var run_state: RunState = initializer.create_run("default_run", MetaProgress.new(), repository)
	run_state.world_state.day = 1
	run_state.world_state.current_phase = "morning"
	var day1_view: Dictionary = route_map_service.build_route_map_view(
		run_state,
		repository,
		condition_evaluator,
		[],
		"2001"
	)
	if day1_view.is_empty():
		printerr("validate_route_map_runtime_runner: FAILED expected day 1 opening map to build")
		quit(1)
		return
	var day1_sections: Array[Dictionary] = Array(day1_view.get("day_sections", []), TYPE_DICTIONARY, "", null)
	if day1_sections.size() < 6:
		printerr("validate_route_map_runtime_runner: FAILED expected continuous map to include day 1 through day 6")
		quit(1)
		return
	var day1_nodes: Array[Dictionary] = Array(day1_view.get("nodes", []), TYPE_DICTIONARY, "", null)
	var day1_frontier_ids: Array[String] = []
	var day1_future_visible: bool = false
	for node: Dictionary in day1_nodes:
		if int(node.get("day", 0)) > 1:
			day1_future_visible = true
		if bool(node.get("is_locked", false)):
			continue
		day1_frontier_ids.append(str(node.get("id", "")))
	if day1_frontier_ids != ["day1_liu_battle"]:
		printerr("validate_route_map_runtime_runner: FAILED expected day 1 frontier to start at Liu battle, got %s" % str(day1_frontier_ids))
		quit(1)
		return
	if not day1_future_visible:
		printerr("validate_route_map_runtime_runner: FAILED expected day 1 map to expose future-day structure")
		quit(1)
		return
	run_state.world_state.day = 4
	run_state.world_state.current_phase = "day"
	run_state.world_state.global_flags["route_records"] = true

	var available_action_ids: Array[String] = route_map_service.get_template_action_ids(4)
	var frontier_action_ids: Array[String] = route_map_service.get_frontier_action_ids(run_state, available_action_ids)
	var view_data: Dictionary = route_map_service.build_route_map_view(
		run_state,
		repository,
		condition_evaluator,
		frontier_action_ids
	)
	if view_data.is_empty():
		printerr("validate_route_map_runtime_runner: FAILED empty initial route map view")
		quit(1)
		return

	if int(view_data.get("current_day", 0)) != 4:
		printerr("validate_route_map_runtime_runner: FAILED expected current day 4")
		quit(1)
		return

	var day_sections: Array[Dictionary] = Array(view_data.get("day_sections", []), TYPE_DICTIONARY, "", null)
	if day_sections.size() < 6:
		printerr("validate_route_map_runtime_runner: FAILED expected continuous map to include at least 6 day sections")
		quit(1)
		return

	var initial_nodes: Array[Dictionary] = Array(view_data.get("nodes", []), TYPE_DICTIONARY, "", null)
	var selectable_initial_nodes: Array[Dictionary] = []
	var future_day_nodes: int = 0
	for node: Dictionary in initial_nodes:
		if int(node.get("day", 0)) > 4:
			future_day_nodes += 1
		if bool(node.get("is_locked", false)):
			continue
		selectable_initial_nodes.append(node)
	if selectable_initial_nodes.size() < 5:
		printerr("validate_route_map_runtime_runner: FAILED expected at least 5 selectable initial nodes, got %d" % selectable_initial_nodes.size())
		quit(1)
		return
	if future_day_nodes == 0:
		printerr("validate_route_map_runtime_runner: FAILED expected continuous map to expose future-day structure")
		quit(1)
		return

	var initial_event_count: int = 0
	for node: Dictionary in selectable_initial_nodes:
		if str(node.get("target_kind", "")) == "event":
			initial_event_count += 1
	if initial_event_count != 0:
		printerr("validate_route_map_runtime_runner: FAILED selectable initial nodes should still only expose step-one nodes")
		quit(1)
		return

	route_map_service.set_route_map_cursor(run_state, "day4_peer_talk")
	var followup_action_ids: Array[String] = route_map_service.get_frontier_action_ids(run_state, available_action_ids)
	var followup_view: Dictionary = route_map_service.build_route_map_view(
		run_state,
		repository,
		condition_evaluator,
		followup_action_ids
	)
	var followup_nodes: Array[Dictionary] = Array(followup_view.get("nodes", []), TYPE_DICTIONARY, "", null)
	var followup_frontier_nodes: Array[Dictionary] = []
	var locked_count: int = 0
	var elder_locked_reason_ok: bool = false
	for node: Dictionary in followup_nodes:
		if int(node.get("day", 0)) == 4 and str(node.get("id", "")).begins_with("day4_"):
			if str(node.get("id", "")) in ["day4_elder_event", "day4_liu_test_event"]:
				followup_frontier_nodes.append(node)
		if bool(node.get("is_locked", false)):
			locked_count += 1
			if str(node.get("id", "")) == "day4_elder_event":
				elder_locked_reason_ok = not str(node.get("lock_reason_text", "")).is_empty()

	if followup_frontier_nodes.size() < 2:
		printerr("validate_route_map_runtime_runner: FAILED expected visible follow-up nodes after route progression")
		quit(1)
		return

	var followup_event_count: int = 0
	for node: Dictionary in followup_frontier_nodes:
		if str(node.get("target_kind", "")) == "event":
			followup_event_count += 1
	if followup_event_count == 0:
		printerr("validate_route_map_runtime_runner: FAILED expected direct follow-up event nodes to remain visible on the continuous map")
		quit(1)
		return
	if locked_count == 0:
		printerr("validate_route_map_runtime_runner: FAILED expected locked nodes to remain on the continuous map")
		quit(1)
		return
	if not elder_locked_reason_ok:
		printerr("validate_route_map_runtime_runner: FAILED expected elder follow-up node to expose route-facing hint")
		quit(1)
		return

	var visited_node_ids: Array[String] = Array(followup_view.get("visited_node_ids", []), TYPE_STRING, "", null)
	if not visited_node_ids.has("day4_peer_talk"):
		printerr("validate_route_map_runtime_runner: FAILED expected visited path to include selected node")
		quit(1)
		return
	if str(followup_view.get("visited_path_text", "")).is_empty():
		printerr("validate_route_map_runtime_runner: FAILED expected non-empty visited path text")
		quit(1)
		return

	print("validate_route_map_runtime_runner: OK")
	quit()
