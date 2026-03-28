class_name StoryEventScheduler
extends RefCounted

const CLASS_ORDER: Array[String] = [
	"ending_check",
	"fixed_story",
	"conditional_story",
	"random_filler"
]

var _condition_evaluator: ConditionEvaluator

func _init(condition_evaluator: ConditionEvaluator) -> void:
	_condition_evaluator = condition_evaluator

func find_next_event(
	run_state: RunState,
	content_repository: ContentRepository,
	slot: String
) -> Dictionary:
	var definitions: Array[Dictionary] = content_repository.get_story_event_definitions(run_state.run_id)
	if definitions.is_empty():
		return {}

	for event_class: String in CLASS_ORDER:
		var candidates: Array[Dictionary] = _collect_candidates(run_state, definitions, slot, event_class)
		if candidates.is_empty():
			continue
		if event_class == "random_filler":
			return _pick_weighted_candidate(candidates)
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("schedule_priority", 0)) > int(b.get("schedule_priority", 0))
		)
		return candidates[0]
	return {}

func _collect_candidates(
	run_state: RunState,
	definitions: Array[Dictionary],
	slot: String,
	event_class: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in definitions:
		if str(definition.get("event_class", "")) != event_class:
			continue
		if str(definition.get("slot", "phase_entry")) != slot:
			continue
		if not _is_event_available(run_state, definition):
			continue
		result.append(definition)
	return result

func _is_event_available(run_state: RunState, definition: Dictionary) -> bool:
	var event_id: String = str(definition.get("id", ""))
	var repeatable: bool = bool(definition.get("repeatable", false))
	if not repeatable and run_state.triggered_event_ids.has(event_id):
		return false
	var conditions: Array[Dictionary] = Array(
		definition.get("trigger_conditions", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	return _condition_evaluator.evaluate_all(run_state, conditions)

func _pick_weighted_candidate(candidates: Array[Dictionary]) -> Dictionary:
	if candidates.is_empty():
		return {}
	var total_weight: int = 0
	for candidate: Dictionary in candidates:
		total_weight += max(1, int(candidate.get("random_weight", 1)))

	var roll: int = randi_range(1, total_weight)
	var cursor: int = 0
	for candidate: Dictionary in candidates:
		cursor += max(1, int(candidate.get("random_weight", 1)))
		if roll <= cursor:
			return candidate
	return candidates[0]
