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

func refresh_goal_progress(run_state: RunState, content_repository: ContentRepository) -> void:
	var changed: bool = true
	while changed:
		changed = false
		for goal: GoalProgress in run_state.active_goals:
			if goal.completed or goal.failed:
				continue
			if _has_conditions(goal.failure_conditions) and _condition_evaluator.evaluate_all(
				run_state,
				goal.failure_conditions
			):
				_run_state_mutator.mark_goal_failed(run_state, goal)
				changed = true
				continue
			if _has_conditions(goal.completion_conditions) and _condition_evaluator.evaluate_all(
				run_state,
				goal.completion_conditions
			):
				_run_state_mutator.mark_goal_completed(run_state, goal)
				_activate_next_goals(run_state, goal, content_repository)
				changed = true

func _has_conditions(conditions: Array[Dictionary]) -> bool:
	return not conditions.is_empty()


func _activate_next_goals(
	run_state: RunState,
	goal: GoalProgress,
	content_repository: ContentRepository
) -> void:
	for next_goal_id: String in goal.next_goal_ids:
		var definition: Dictionary = content_repository.get_goal_definition(next_goal_id)
		if definition.is_empty():
			continue
		_run_state_mutator.add_goal(run_state, GoalProgress.from_dict(definition))
