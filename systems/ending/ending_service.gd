class_name EndingService
extends RefCounted

const ENDING_RESULT_SCRIPT := preload("res://core/models/ending_result.gd")

var _condition_evaluator: ConditionEvaluator

func _init(condition_evaluator: ConditionEvaluator) -> void:
	_condition_evaluator = condition_evaluator

func resolve_ending(
	run_state: RunState,
	ending_definitions: Array[Dictionary]
) -> RefCounted:
	var sorted_definitions: Array[Dictionary] = ending_definitions.duplicate(true)
	sorted_definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)

	for definition: Dictionary in sorted_definitions:
		var conditions: Array[Dictionary] = Array(
			definition.get("conditions", []),
			TYPE_DICTIONARY,
			"",
			null
		)
		if _condition_evaluator.evaluate_all(run_state, conditions):
			return ENDING_RESULT_SCRIPT.from_dict(definition)

	return ENDING_RESULT_SCRIPT.from_dict({})
