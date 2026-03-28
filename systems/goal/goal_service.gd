class_name GoalService
extends RefCounted

var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator

func _init(
	condition_evaluator: ConditionEvaluator,
	run_state_mutator: RunStateMutator
) -> void:
	_condition_evaluator = condition_evaluator
	_run_state_mutator = run_state_mutator

func refresh_goal_progress(run_state: RunState) -> void:
	for goal: GoalProgress in run_state.active_goals:
		if goal.completed or goal.failed:
			continue
		if _has_conditions(goal.failure_conditions) and _condition_evaluator.evaluate_all(
			run_state,
			goal.failure_conditions
		):
			_run_state_mutator.mark_goal_failed(run_state, goal)
			continue
		if _has_conditions(goal.completion_conditions) and _condition_evaluator.evaluate_all(
			run_state,
			goal.completion_conditions
		):
			_run_state_mutator.mark_goal_completed(run_state, goal)

func _has_conditions(conditions: Array[Dictionary]) -> bool:
	return not conditions.is_empty()
