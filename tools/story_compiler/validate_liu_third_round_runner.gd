extends SceneTree

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")
const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const RUN_INITIALIZER_SCRIPT := preload("res://systems/run/run_initializer.gd")
const CONDITION_EVALUATOR_SCRIPT := preload("res://systems/condition/condition_evaluator.gd")
const RUN_STATE_MUTATOR_SCRIPT := preload("res://systems/state/run_state_mutator.gd")
const NPC_SERVICE_SCRIPT := preload("res://systems/npc/npc_service.gd")
const EVENT_SERVICE_SCRIPT := preload("res://systems/event/event_service.gd")
const META_PROGRESS_SCRIPT := preload("res://core/models/meta_progress.gd")

const RUN_ID := "default_run"
const TARGET_INTERACTION_ID := "friendly_peer_first_report"
const TARGET_EVENT_ID := "friendly_peer_md_2102"

func _initialize() -> void:
	var compiler = COMPILER_SCRIPT.new()
	var compile_result: Dictionary = compiler.apply_current_project_assets(true)
	if not _to_bool(compile_result.get("success", false)):
		_fail("Markdown assets writeback failed: %s" % str(compile_result.get("errors", [])))
		return

	var content_repository = CONTENT_REPOSITORY_SCRIPT.new()
	var run_initializer = RUN_INITIALIZER_SCRIPT.new()
	var condition_evaluator = CONDITION_EVALUATOR_SCRIPT.new()
	var run_state_mutator = RUN_STATE_MUTATOR_SCRIPT.new()
	var npc_service = NPC_SERVICE_SCRIPT.new(condition_evaluator, run_state_mutator)
	var event_service = EVENT_SERVICE_SCRIPT.new(condition_evaluator, run_state_mutator)
	var meta_progress = META_PROGRESS_SCRIPT.new()
	var run_state: RunState = run_initializer.create_run(RUN_ID, meta_progress, content_repository)

	run_state.world_state.day = 3
	run_state.world_state.current_phase = "day"
	run_state.world_state.current_location_id = "dormitory"
	run_state.world_state.actions_remaining = run_state.world_state.actions_per_day
	run_state_mutator.set_global_flag(run_state, "liu_informant_active", true)

	var event_definition: Dictionary = content_repository.get_story_event_definition(RUN_ID, TARGET_EVENT_ID)
	if event_definition.is_empty():
		_fail("Missing story event definition: %s" % TARGET_EVENT_ID)
		return
	if str(event_definition.get("presentation_type", "")) != "dialogue_event":
		_fail("Expected %s to be dialogue_event, got %s" % [TARGET_EVENT_ID, str(event_definition.get("presentation_type", ""))])
		return

	var interactions: Array[Dictionary] = npc_service.get_available_interactions_for_current_location(run_state, content_repository)
	var target_interaction: Dictionary = {}
	for interaction: Dictionary in interactions:
		if str(interaction.get("id", "")) == TARGET_INTERACTION_ID:
			target_interaction = interaction
			break
	if target_interaction.is_empty():
		_fail("Missing NPC interaction: %s" % TARGET_INTERACTION_ID)
		return

	var interact_result: Dictionary = npc_service.interact(run_state, content_repository, TARGET_INTERACTION_ID)
	if not _to_bool(interact_result.get("success", false)):
		_fail("NPC interaction failed: %s" % str(interact_result))
		return
	if str(interact_result.get("opened_event_id", "")) != TARGET_EVENT_ID:
		_fail("Expected opened_event_id %s, got %s" % [TARGET_EVENT_ID, str(interact_result.get("opened_event_id", ""))])
		return

	run_state_mutator.set_current_event(run_state, TARGET_EVENT_ID)
	var current_event: Dictionary = event_service.get_current_event_definition(run_state, content_repository)
	if current_event.is_empty():
		_fail("Current event definition failed to resolve for %s" % TARGET_EVENT_ID)
		return
	if str(current_event.get("presentation_type", "")) != "dialogue_event":
		_fail("Resolved current event is not dialogue_event: %s" % str(current_event.get("presentation_type", "")))
		return
	if Dictionary(current_event.get("dialogue_encounter", {})).is_empty():
		_fail("Dialogue encounter not attached for %s" % TARGET_EVENT_ID)
		return

	var option_views: Array[Dictionary] = event_service.get_current_event_option_views(run_state, content_repository)
	var option_ids: Array[String] = []
	for option_view: Dictionary in option_views:
		option_ids.append(str(option_view.get("id", "")))
	var expected_stage_ids: Array[String] = ["__observe__", "__intrude__", "__talk__"]
	for expected_id: String in expected_stage_ids:
		if not option_ids.has(expected_id):
			_fail("Missing dialogue stage option %s in %s" % [expected_id, str(option_ids)])
			return

	print("Liu third-round validation passed")
	print("interaction_id=%s" % TARGET_INTERACTION_ID)
	print("event_id=%s" % TARGET_EVENT_ID)
	print("presentation_type=%s" % str(current_event.get("presentation_type", "")))
	print("option_ids=%s" % str(option_ids))
	quit()

func _fail(message: String) -> void:
	push_error(message)
	quit(1)

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var text: String = String(value).strip_edges().to_lower()
			return text == "true" or text == "1" or text == "yes"
		_:
			return value != null
