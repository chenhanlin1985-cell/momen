extends Node

const DEFAULT_RUN_ID: String = "default_run"
const ENDING_SERVICE_SCRIPT := preload("res://systems/ending/ending_service.gd")

var _content_repository: ContentRepository
var _run_initializer: RunInitializer
var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator
var _action_service: ActionService
var _day_flow_service: DayFlowService
var _goal_service: GoalService
var _event_service: EventService
var _ending_service
var _inheritance_service: InheritanceService

func _ready() -> void:
	_content_repository = ContentRepository.new()
	_run_initializer = RunInitializer.new()
	_condition_evaluator = ConditionEvaluator.new()
	_run_state_mutator = RunStateMutator.new()
	_action_service = ActionService.new(_condition_evaluator, _run_state_mutator)
	_day_flow_service = DayFlowService.new(_run_state_mutator)
	_goal_service = GoalService.new(_condition_evaluator, _run_state_mutator)
	_event_service = EventService.new(_condition_evaluator, _run_state_mutator)
	_ending_service = ENDING_SERVICE_SCRIPT.new(_condition_evaluator)
	_inheritance_service = InheritanceService.new()

func start_new_run(run_id: String = DEFAULT_RUN_ID) -> void:
	var run_state: RunState = _run_initializer.create_run(
		run_id,
		AppState.meta_progress,
		_content_repository
	)
	_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
	_advance_through_empty_non_day_phases(run_state)
	AppState.set_run_state(run_state)
	AppState.emit_run_started(run_state)

func perform_action(action_id: String) -> void:
	if AppState.current_run_state == null:
		AppState.raise_error("当前没有运行中的周目。")
		return
	if not AppState.current_run_state.current_event_id.is_empty():
		AppState.raise_error("请先处理当前事件。")
		return
	if AppState.current_run_state.world_state.current_phase != "day":
		AppState.raise_error("当前不是白天行动阶段。")
		return

	var action_definition: Dictionary = _content_repository.get_action_definition(action_id)
	if action_definition.is_empty():
		AppState.raise_error("未找到行动定义: %s" % action_id)
		return

	var result: Dictionary = _action_service.execute_action(
		AppState.current_run_state,
		action_definition
	)
	if not result.get("success", false):
		AppState.raise_error(result.get("message", "行动执行失败。"))
		return

	_event_service.collect_action_followups(
		AppState.current_run_state,
		_content_repository,
		action_definition,
		result
	)
	_goal_service.refresh_goal_progress(AppState.current_run_state)
	_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "post_action")
	if AppState.current_run_state.current_event_id.is_empty():
		_day_flow_service.advance_after_action(AppState.current_run_state)
		_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
		_advance_through_empty_non_day_phases(AppState.current_run_state)

	if AppState.current_run_state.is_run_over:
		var ending_result = _ending_service.resolve_ending(
			AppState.current_run_state,
			_content_repository.get_ending_definitions()
		)
		_run_state_mutator.set_ending_result(AppState.current_run_state, ending_result)
		_run_state_mutator.append_log(
			AppState.current_run_state,
			"结局达成: %s" % ending_result.title
		)
		var inheritance_options: Array[Dictionary] = _inheritance_service.generate_options(
			AppState.current_run_state
		)
		_run_state_mutator.append_log(
			AppState.current_run_state,
			"可选遗产数量: %d" % inheritance_options.size()
		)

	AppState.set_run_state(AppState.current_run_state)

func get_visible_actions() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	if AppState.current_run_state.world_state.current_phase != "day":
		return []
	return _content_repository.get_visible_actions(
		AppState.current_run_state,
		_condition_evaluator
	)

func get_current_event() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	return _event_service.get_current_event_definition(
		AppState.current_run_state,
		_content_repository
	)

func get_event_hints() -> Array[String]:
	if AppState.current_run_state == null:
		return []
	return _event_service.get_event_hints(
		AppState.current_run_state,
		_content_repository
	)

func choose_event_option(option_id: String) -> void:
	if AppState.current_run_state == null:
		AppState.raise_error("当前没有运行中的周目。")
		return

	var result: Dictionary = _event_service.choose_option(
		AppState.current_run_state,
		_content_repository,
		option_id
	)
	if not bool(result.get("success", false)):
		AppState.raise_error(str(result.get("message", "事件结算失败。")))
		return

	_goal_service.refresh_goal_progress(AppState.current_run_state)
	if AppState.current_run_state.current_event_id.is_empty():
		_day_flow_service.advance_after_event(AppState.current_run_state)
		_event_service.resolve_current_or_next_event(AppState.current_run_state, _content_repository, "phase_entry")
		_advance_through_empty_non_day_phases(AppState.current_run_state)
	if AppState.current_run_state.is_run_over:
		var ending_result = _ending_service.resolve_ending(
			AppState.current_run_state,
			_content_repository.get_ending_definitions()
		)
		_run_state_mutator.set_ending_result(AppState.current_run_state, ending_result)
		_run_state_mutator.append_log(
			AppState.current_run_state,
			"结局达成: %s" % ending_result.title
		)
	AppState.set_run_state(AppState.current_run_state)

func get_current_event_option_views() -> Array[Dictionary]:
	if AppState.current_run_state == null:
		return []
	return _event_service.get_current_event_option_views(
		AppState.current_run_state,
		_content_repository
	)

func _advance_through_empty_non_day_phases(run_state: RunState) -> void:
	var guard: int = 0
	while (
		guard < 8
		and not run_state.is_run_over
		and run_state.current_event_id.is_empty()
		and run_state.world_state.current_phase != "day"
	):
		guard += 1
		_day_flow_service.advance_after_event(run_state)
		_event_service.resolve_current_or_next_event(run_state, _content_repository, "phase_entry")
