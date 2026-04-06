extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const ROUTE_MAP_SERVICE_SCRIPT := preload("res://systems/route/route_map_service.gd")
const RUN_INITIALIZER_SCRIPT := preload("res://systems/run/run_initializer.gd")
const CONDITION_EVALUATOR_SCRIPT := preload("res://systems/condition/condition_evaluator.gd")

const FORCED_ENTRY_EXPECTATIONS := [
	{
		"day": 1,
		"phase": "morning",
		"target_event_id": "2001",
		"expected_frontier": ["day1_liu_battle"]
	},
	{
		"day": 2,
		"phase": "morning",
		"target_event_id": "2002",
		"expected_frontier": ["day2_liu_entry"]
	},
	{
		"day": 3,
		"phase": "morning",
		"target_event_id": "1102",
		"expected_frontier": ["day3_morning_entry"]
	},
	{
		"day": 5,
		"phase": "morning",
		"target_event_id": "1103",
		"expected_frontier": ["day5_morning_entry"]
	},
	{
		"day": 6,
		"phase": "morning",
		"target_event_id": "1104",
		"expected_frontier": ["day6_morning_entry"]
	},
	{
		"day": 6,
		"phase": "morning",
		"target_event_id": "1303",
		"expected_frontier": ["day6_well_mark_entry"],
		"flags": {
			"route_well": true
		}
	}
]

func _initialize() -> void:
	var repository: ContentRepository = CONTENT_REPOSITORY_SCRIPT.new()
	var initializer: RunInitializer = RUN_INITIALIZER_SCRIPT.new()
	var route_map_service: RouteMapService = ROUTE_MAP_SERVICE_SCRIPT.new()
	var condition_evaluator: ConditionEvaluator = CONDITION_EVALUATOR_SCRIPT.new()

	for expectation: Dictionary in FORCED_ENTRY_EXPECTATIONS:
		var run_state: RunState = initializer.create_run("default_run", MetaProgress.new(), repository)
		run_state.world_state.day = int(expectation.get("day", 1))
		run_state.world_state.current_phase = str(expectation.get("phase", "morning"))
		for flag_key: String in Dictionary(expectation.get("flags", {})).keys():
			run_state.world_state.global_flags[flag_key] = Dictionary(expectation.get("flags", {})).get(flag_key)
		var view_data: Dictionary = route_map_service.build_route_map_view(
			run_state,
			repository,
			condition_evaluator,
			[],
			str(expectation.get("target_event_id", ""))
		)
		if view_data.is_empty():
			push_error("Forced-entry alignment failed: empty map for day %d" % int(expectation.get("day", 0)))
			quit(1)
			return
		var actual_frontier: Array[String] = _collect_selectable_ids(view_data)
		var expected_frontier: Array[String] = Array(expectation.get("expected_frontier", []), TYPE_STRING, "", null)
		if actual_frontier != expected_frontier:
			push_error(
				"Forced-entry alignment failed for day %d target %s: expected %s got %s" % [
					int(expectation.get("day", 0)),
					str(expectation.get("target_event_id", "")),
					str(expected_frontier),
					str(actual_frontier)
				]
			)
			quit(1)
			return

	print("validate_route_map_forced_entry_alignment_runner: OK")
	quit()

func _collect_selectable_ids(route_map_view: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for node: Dictionary in Array(route_map_view.get("nodes", []), TYPE_DICTIONARY, "", null):
		if bool(node.get("is_locked", false)):
			continue
		ids.append(str(node.get("id", "")))
	return ids
