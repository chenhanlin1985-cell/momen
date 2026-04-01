class_name EventService
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")
const EVENT_EFFECT_EXECUTOR_SCRIPT := preload("res://systems/event/event_effect_executor.gd")
const STORY_EVENT_SCHEDULER_SCRIPT := preload("res://systems/event/story_event_scheduler.gd")
const DIALOGUE_MODE_HUB: String = "hub"
const DIALOGUE_MODE_OBSERVE: String = "observe"
const DIALOGUE_MODE_INTRUDE: String = "intrude"
const DIALOGUE_MODE_TALK: String = "talk"

var _condition_evaluator: ConditionEvaluator
var _run_state_mutator: RunStateMutator
var _effect_executor
var _story_scheduler

func _init(
	condition_evaluator: ConditionEvaluator,
	run_state_mutator: RunStateMutator
) -> void:
	_condition_evaluator = condition_evaluator
	_run_state_mutator = run_state_mutator
	_effect_executor = EVENT_EFFECT_EXECUTOR_SCRIPT.new(run_state_mutator)
	_story_scheduler = STORY_EVENT_SCHEDULER_SCRIPT.new(condition_evaluator)

func collect_action_followups(
	run_state: RunState,
	content_repository: ContentRepository,
	action_definition: Dictionary,
	action_result: Dictionary
) -> void:
	_run_state_mutator.set_last_action_id(
		run_state,
		str(action_definition.get("trigger_action_id", action_definition.get("id", "")))
	)
	_run_state_mutator.set_last_action_category(
		run_state,
		str(action_definition.get("action_category", ""))
	)

	if content_repository.get_story_event_definitions(run_state.run_id).is_empty():
		for event_id: String in action_result.get("linked_event_pool", []):
			_run_state_mutator.queue_followup_event(run_state, event_id)

	var risk_weight: int = int(action_definition.get("risk_weight", 0))
	if risk_weight > 0:
		_run_state_mutator.append_log(
			run_state,
			GAME_TEXT.format_text("event_service.logs.risk_up", [risk_weight], str(risk_weight))
		)

func resolve_current_or_next_event(
	run_state: RunState,
	content_repository: ContentRepository,
	slot: String = "phase_entry"
) -> void:
	if run_state.is_run_over or not run_state.current_event_id.is_empty():
		return

	var next_definition: Dictionary = _story_scheduler.find_next_event(run_state, content_repository, slot)
	if not next_definition.is_empty():
		_run_state_mutator.set_current_event(run_state, str(next_definition.get("id", "")))
		return

	var queued_event_id: String = _get_next_queued_event_id(run_state, content_repository)
	if not queued_event_id.is_empty():
		_run_state_mutator.set_current_event(run_state, queued_event_id)

func choose_option(
	run_state: RunState,
	content_repository: ContentRepository,
	option_id: String
) -> Dictionary:
	var event_definition: Dictionary = get_current_event_definition(run_state, content_repository)
	if event_definition.is_empty():
		return {"success": false, "message": GAME_TEXT.text("event_service.errors.no_current_event")}

	if _to_bool(event_definition.get("awaiting_continue", false)):
		if option_id != "__continue__":
			return {"success": false, "message": GAME_TEXT.text("event_service.errors.option_unavailable")}
		var finished_event_id: String = str(event_definition.get("id", ""))
		_run_state_mutator.mark_event_triggered(run_state, finished_event_id)
		_run_state_mutator.clear_current_event(run_state)
		return {"success": true, "continued": true}

	if _handle_dialogue_stage_control(run_state, event_definition, option_id):
		return {"success": true, "stage_control": true}

	var option_definition: Dictionary = _find_option_definition(event_definition, option_id)
	if option_definition.is_empty():
		return {"success": false, "message": GAME_TEXT.text("event_service.errors.option_missing")}

	var conditions: Array[Dictionary] = Array(option_definition.get("conditions", []), TYPE_DICTIONARY, "", null)
	if not _condition_evaluator.evaluate_all(run_state, conditions):
		return {"success": false, "message": GAME_TEXT.text("event_service.errors.option_unavailable")}

	var event_id: String = str(event_definition.get("id", ""))
	option_definition = _resolve_dialogue_option_override(event_definition, option_definition)
	var check_result: Dictionary = _resolve_option_check(run_state, option_definition)
	var outcome: String = str(check_result.get("outcome", "always"))
	var result_text: String = _resolve_option_result_text(option_definition, outcome)
	var effects: Array[Dictionary] = _filter_effects_by_outcome(
		Array(option_definition.get("effects", []), TYPE_DICTIONARY, "", null),
		outcome
	)
	effects.append_array(_build_critical_effects(check_result))

	_effect_executor.apply_effects(run_state, effects)

	var log_text: String = str(check_result.get("log_text", ""))
	if not log_text.is_empty():
		_run_state_mutator.append_log(run_state, log_text)
	var critical_text: String = str(check_result.get("critical_text", ""))
	if not critical_text.is_empty():
		_run_state_mutator.append_log(run_state, critical_text)
	if not result_text.is_empty():
		_run_state_mutator.set_current_event_result_text(run_state, result_text)
	else:
		_run_state_mutator.mark_event_triggered(run_state, event_id)
		_run_state_mutator.clear_current_event(run_state)

	return {
		"success": true,
		"check_performed": _to_bool(check_result.get("performed", false)),
		"check_passed": _to_bool(check_result.get("passed", true)),
		"outcome": outcome,
		"is_critical_success": _to_bool(check_result.get("critical_success", false)),
		"is_critical_failure": _to_bool(check_result.get("critical_failure", false))
	}

func get_current_event_definition(
	run_state: RunState,
	content_repository: ContentRepository
) -> Dictionary:
	var definition: Dictionary = {}
	if run_state.current_event_id.is_empty():
		return {}

	var story_definition: Dictionary = content_repository.get_story_event_definition(
		run_state.run_id,
		run_state.current_event_id
	)
	if not story_definition.is_empty():
		definition = story_definition
	else:
		definition = content_repository.get_event_definition(run_state.current_event_id)

	if definition.is_empty():
		return {}

	if str(definition.get("presentation_type", "")).is_empty():
		definition["presentation_type"] = "standard_event"
	if not run_state.current_event_result_text.is_empty():
		definition["result_text"] = run_state.current_event_result_text
		definition["awaiting_continue"] = true

	var encounter_definition: Dictionary = content_repository.get_dialogue_encounter_definition(run_state.current_event_id)
	if str(definition.get("presentation_type", "standard_event")) == "dialogue_event" and not encounter_definition.is_empty():
		definition["dialogue_encounter"] = encounter_definition
		definition["dialogue_mode"] = _resolve_dialogue_mode(run_state)
		definition["dialogue_body_override_text"] = run_state.current_dialogue_body_override_text
		definition["dialogue_portrait_override_label"] = run_state.current_dialogue_portrait_override_label
		definition["dialogue_intrusion_tag"] = run_state.current_dialogue_intrusion_tag
		definition["dialogue_intrusion_used"] = run_state.current_dialogue_intrusion_used

	var combat_enemy_id: String = str(definition.get("combat_enemy_id", ""))
	if not combat_enemy_id.is_empty():
		var enemy_definition: Dictionary = content_repository.get_enemy_definition(combat_enemy_id)
		if not enemy_definition.is_empty():
			definition["combatant_name"] = str(
				enemy_definition.get("display_name", definition.get("combatant_name", combat_enemy_id))
			)
			if int(definition.get("combat_guard", 0)) <= 0:
				definition["combat_guard"] = int(enemy_definition.get("guard", 0))
			if int(definition.get("combat_damage", 0)) <= 0:
				definition["combat_damage"] = int(enemy_definition.get("damage", 0))
			if int(definition.get("combat_hp", 0)) <= 0:
				definition["combat_hp"] = int(enemy_definition.get("hp", 0))
			if int(definition.get("combat_escape_target", 0)) <= 0:
				definition["combat_escape_target"] = int(enemy_definition.get("escape_target", 0))

	var speaker_npc_id: String = _resolve_speaker_npc_id(definition, content_repository)
	if not speaker_npc_id.is_empty():
		var npc_definition: Dictionary = content_repository.get_npc_definition(speaker_npc_id)
		if not npc_definition.is_empty():
			var resolved_portrait_label: String = _resolve_dialogue_portrait_label(definition)
			var resolved_portrait_path: String = _resolve_npc_portrait_path(npc_definition, resolved_portrait_label)
			definition["speaker_npc_id"] = speaker_npc_id
			definition["speaker_display_name"] = str(npc_definition.get("display_name", speaker_npc_id))
			definition["speaker_portrait_label"] = resolved_portrait_label
			definition["speaker_portrait_path"] = resolved_portrait_path
			definition["speaker_portrait_placeholder"] = str(
				npc_definition.get(
					"portrait_placeholder",
					GAME_TEXT.format_text(
						"event_service.speaker_portrait_placeholder",
						[str(npc_definition.get("display_name", speaker_npc_id))]
					)
				)
			)

	return definition

func _resolve_speaker_npc_id(
	definition: Dictionary,
	content_repository: ContentRepository
) -> String:
	var explicit_speaker_id: String = str(definition.get("speaker_npc_id", "")).strip_edges()
	if not explicit_speaker_id.is_empty() and explicit_speaker_id != "player":
		var explicit_npc_definition: Dictionary = content_repository.get_npc_definition(explicit_speaker_id)
		if not explicit_npc_definition.is_empty():
			return explicit_speaker_id

	var participants: Array[String] = Array(definition.get("participants", []), TYPE_STRING, "", null)
	for participant_id: String in participants:
		if participant_id == "player":
			continue
		var participant_definition: Dictionary = content_repository.get_npc_definition(participant_id)
		if not participant_definition.is_empty():
			return participant_id

	return ""

func _resolve_npc_portrait_path(npc_definition: Dictionary, portrait_label: String) -> String:
	if portrait_label.strip_edges().is_empty() or portrait_label == "默认":
		return str(npc_definition.get("portrait_path", ""))
	var portrait_variants: Dictionary = Dictionary(npc_definition.get("portrait_variants", {}))
	var variant_path: String = str(portrait_variants.get(portrait_label, "")).strip_edges()
	if not variant_path.is_empty():
		return variant_path
	return str(npc_definition.get("portrait_path", ""))

func _resolve_dialogue_portrait_label(definition: Dictionary) -> String:
	var explicit_override: String = str(definition.get("dialogue_portrait_override_label", "")).strip_edges()
	if not explicit_override.is_empty():
		return explicit_override
	var encounter_definition: Dictionary = Dictionary(definition.get("dialogue_encounter", {}))
	if encounter_definition.is_empty():
		return ""
	var mode: String = str(definition.get("dialogue_mode", DIALOGUE_MODE_HUB))
	var intrusion_id: String = str(definition.get("dialogue_intrusion_tag", "")).strip_edges()
	if mode == DIALOGUE_MODE_OBSERVE:
		return str(encounter_definition.get("observation_portrait_label", "")).strip_edges()
	if mode == DIALOGUE_MODE_TALK:
		if not intrusion_id.is_empty():
			var selected_intrusion: Dictionary = _find_intrusion_definition(encounter_definition, intrusion_id)
			var talk_label: String = str(selected_intrusion.get("talk_portrait_label", "")).strip_edges()
			if not talk_label.is_empty():
				return talk_label
			var selected_label: String = str(selected_intrusion.get("selected_portrait_label", "")).strip_edges()
			if not selected_label.is_empty():
				return selected_label
		return str(encounter_definition.get("talk_portrait_label", "")).strip_edges()
	return str(encounter_definition.get("opening_portrait_label", "")).strip_edges()

func get_current_event_option_views(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[Dictionary]:
	var event_definition: Dictionary = get_current_event_definition(run_state, content_repository)
	if event_definition.is_empty():
		return []
	var presentation_type: String = str(event_definition.get("presentation_type", "standard_event"))
	if _to_bool(event_definition.get("awaiting_continue", false)):
		if presentation_type == "dialogue_event":
			return []
		return [{
			"id": "__continue__",
			"text": GAME_TEXT.text("dialogue_panel.continue_button", "继续"),
			"is_available": true,
			"unmet_text": "",
			"check_text": "",
			"check_tag_text": "",
			"difficulty_text": "",
			"is_continue": true
		}]

	if presentation_type == "dialogue_event" and not Dictionary(event_definition.get("dialogue_encounter", {})).is_empty():
		return _build_dialogue_stage_option_views(run_state, event_definition)

	var result: Array[Dictionary] = []
	for option_definition: Dictionary in event_definition.get("options", []):
		var check_definition: Dictionary = Dictionary(option_definition.get("check", {}))
		var conditions: Array[Dictionary] = Array(option_definition.get("conditions", []), TYPE_DICTIONARY, "", null)
		var is_available: bool = _condition_evaluator.evaluate_all(run_state, conditions)
		var unmet: Array[String] = _condition_evaluator.get_unmet_descriptions(run_state, conditions)
		result.append({
			"id": str(option_definition.get("id", "")),
			"text": str(option_definition.get("text", "")),
			"is_available": is_available,
			"unmet_text": "" if unmet.is_empty() else GAME_TEXT.text("event_service.unmet_prefix") + "、".join(unmet),
			"check_text": _describe_option_check(check_definition),
			"check_tag_text": _describe_check_tag(check_definition),
			"difficulty_text": _describe_check_difficulty(run_state, check_definition)
		})
	return result

func _handle_dialogue_stage_control(
	run_state: RunState,
	event_definition: Dictionary,
	option_id: String
) -> bool:
	if str(event_definition.get("presentation_type", "standard_event")) != "dialogue_event":
		return false
	var encounter_definition: Dictionary = Dictionary(event_definition.get("dialogue_encounter", {}))
	if encounter_definition.is_empty():
		return false

	match option_id:
		"__observe__":
			_run_state_mutator.set_current_dialogue_body_override_text(run_state, "")
			_run_state_mutator.set_current_dialogue_portrait_override_label(run_state, "")
			_run_state_mutator.set_current_dialogue_mode(run_state, DIALOGUE_MODE_OBSERVE)
			return true
		"__intrude__":
			_run_state_mutator.set_current_dialogue_body_override_text(run_state, "")
			_run_state_mutator.set_current_dialogue_portrait_override_label(run_state, "")
			_run_state_mutator.set_current_dialogue_mode(run_state, DIALOGUE_MODE_INTRUDE)
			return true
		"__talk__":
			_run_state_mutator.set_current_dialogue_body_override_text(run_state, "")
			_run_state_mutator.set_current_dialogue_portrait_override_label(run_state, "")
			_run_state_mutator.set_current_dialogue_mode(run_state, DIALOGUE_MODE_TALK)
			return true
		"__back__":
			_run_state_mutator.set_current_dialogue_body_override_text(run_state, "")
			_run_state_mutator.set_current_dialogue_portrait_override_label(run_state, "")
			_run_state_mutator.set_current_dialogue_mode(run_state, DIALOGUE_MODE_HUB)
			return true

	if not option_id.begins_with("__intrusion__:"):
		return false
	if run_state.current_dialogue_intrusion_used:
		return false

	var intrusion_id: String = option_id.trim_prefix("__intrusion__:")
	var intrusion_definition: Dictionary = _find_intrusion_definition(encounter_definition, intrusion_id)
	if intrusion_definition.is_empty():
		return false

	_run_state_mutator.set_current_dialogue_intrusion(run_state, intrusion_id)
	_run_state_mutator.set_current_dialogue_body_override_text(
		run_state,
		str(intrusion_definition.get("selected_hint_text", ""))
	)
	_run_state_mutator.set_current_dialogue_portrait_override_label(
		run_state,
		str(intrusion_definition.get("selected_portrait_label", ""))
	)
	_run_state_mutator.set_current_dialogue_mode(run_state, DIALOGUE_MODE_HUB)
	var intrusion_log: String = str(intrusion_definition.get("apply_log_text", ""))
	if not intrusion_log.is_empty():
		_run_state_mutator.append_log(run_state, intrusion_log)
	return true

func _resolve_dialogue_option_override(event_definition: Dictionary, option_definition: Dictionary) -> Dictionary:
	if str(event_definition.get("presentation_type", "standard_event")) != "dialogue_event":
		return option_definition

	var encounter_definition: Dictionary = Dictionary(event_definition.get("dialogue_encounter", {}))
	if encounter_definition.is_empty():
		return option_definition

	var intrusion_id: String = str(event_definition.get("dialogue_intrusion_tag", ""))
	if intrusion_id.is_empty():
		return option_definition

	var intrusion_definition: Dictionary = _find_intrusion_definition(encounter_definition, intrusion_id)
	if intrusion_definition.is_empty():
		return option_definition

	var option_overrides: Dictionary = Dictionary(intrusion_definition.get("option_overrides", {}))
	var option_id: String = str(option_definition.get("id", ""))
	var override_definition: Dictionary = Dictionary(option_overrides.get(option_id, {}))
	if override_definition.is_empty():
		override_definition = Dictionary(intrusion_definition.get("fallback_option_override", {}))
	if override_definition.is_empty():
		return option_definition

	var resolved: Dictionary = option_definition.duplicate(true)
	for key: Variant in override_definition.keys():
		resolved[key] = override_definition[key]
	return resolved

func _build_dialogue_stage_option_views(run_state: RunState, event_definition: Dictionary) -> Array[Dictionary]:
	var mode: String = str(event_definition.get("dialogue_mode", DIALOGUE_MODE_HUB))
	var encounter_definition: Dictionary = Dictionary(event_definition.get("dialogue_encounter", {}))
	if mode == DIALOGUE_MODE_INTRUDE:
		return _build_dialogue_intrusion_option_views(event_definition, encounter_definition)
	if mode == DIALOGUE_MODE_TALK:
		return _build_dialogue_talk_option_views(run_state, event_definition)
	return _build_dialogue_hub_option_views(event_definition, encounter_definition)

func _build_dialogue_hub_option_views(event_definition: Dictionary, encounter_definition: Dictionary) -> Array[Dictionary]:
	var views: Array[Dictionary] = []
	var observed: bool = str(event_definition.get("dialogue_mode", "")) == DIALOGUE_MODE_OBSERVE
	views.append({
		"id": "__observe__",
		"text": "观察",
		"is_available": true,
		"unmet_text": "",
		"check_text": "查看她此刻的情绪、破绽和异常反应" if not observed else "你已经看清她此刻最明显的情绪与破绽",
		"check_tag_text": "",
		"difficulty_text": "",
		"is_stage_action": true
	})
	views.append({
		"id": "__intrude__",
		"text": "入侵",
		"is_available": not _to_bool(event_definition.get("dialogue_intrusion_used", false)),
		"unmet_text": "本轮对话已经植入过一次魔念" if _to_bool(event_definition.get("dialogue_intrusion_used", false)) else "",
		"check_text": _describe_selected_intrusion(event_definition, encounter_definition),
		"check_tag_text": "",
		"difficulty_text": "",
		"is_stage_action": true
	})
	views.append({
		"id": "__talk__",
		"text": "对话",
		"is_available": true,
		"unmet_text": "",
		"check_text": "进入正式对话，选择这一轮的试探、逼问或摊牌方式",
		"check_tag_text": "",
		"difficulty_text": "",
		"is_stage_action": true
	})
	return views

func _build_dialogue_intrusion_option_views(event_definition: Dictionary, encounter_definition: Dictionary) -> Array[Dictionary]:
	var views: Array[Dictionary] = []
	for intrusion_definition: Dictionary in encounter_definition.get("intrusions", []):
		var available: bool = not _to_bool(event_definition.get("dialogue_intrusion_used", false))
		var unmet_text: String = ""
		if _to_bool(event_definition.get("dialogue_intrusion_used", false)):
			unmet_text = "本轮对话已经植入过一次魔念"
		views.append({
			"id": "__intrusion__:%s" % str(intrusion_definition.get("id", "")),
			"text": str(intrusion_definition.get("label", intrusion_definition.get("id", ""))),
			"is_available": available,
			"unmet_text": unmet_text,
			"check_text": str(intrusion_definition.get("description", "")),
			"check_tag_text": str(intrusion_definition.get("domain_label", "魔念")),
			"difficulty_text": "",
			"is_stage_action": true
		})
	views.append({
		"id": "__back__",
		"text": "返回",
		"is_available": true,
		"unmet_text": "",
		"check_text": "回到当前对话局的决策台",
		"check_tag_text": "",
		"difficulty_text": "",
		"is_stage_action": true,
		"is_continue": true
	})
	return views

func _build_dialogue_talk_option_views(run_state: RunState, event_definition: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for option_definition: Dictionary in event_definition.get("options", []):
		var resolved_option: Dictionary = _resolve_dialogue_option_override(event_definition, option_definition)
		var conditions: Array[Dictionary] = Array(resolved_option.get("conditions", []), TYPE_DICTIONARY, "", null)
		var is_available: bool = _condition_evaluator.evaluate_all(run_state, conditions)
		var unmet: Array[String] = _condition_evaluator.get_unmet_descriptions(run_state, conditions)
		var check_definition: Dictionary = Dictionary(resolved_option.get("check", {}))
		result.append({
			"id": str(resolved_option.get("id", "")),
			"text": str(resolved_option.get("text", "")),
			"is_available": is_available,
			"unmet_text": "" if unmet.is_empty() else GAME_TEXT.text("event_service.unmet_prefix") + "、".join(unmet),
			"check_text": _describe_option_check(check_definition),
			"check_tag_text": _describe_check_tag(check_definition),
			"difficulty_text": _describe_check_difficulty(run_state, check_definition),
			"is_stage_action": false
		})
	return result

func _describe_selected_intrusion(event_definition: Dictionary, encounter_definition: Dictionary) -> String:
	var intrusion_id: String = str(event_definition.get("dialogue_intrusion_tag", ""))
	if intrusion_id.is_empty():
		return "尚未植入魔念"
	var intrusion_definition: Dictionary = _find_intrusion_definition(encounter_definition, intrusion_id)
	if intrusion_definition.is_empty():
		return "当前魔念已植入"
	return "已植入 %s" % str(intrusion_definition.get("label", intrusion_id))

func _find_intrusion_definition(encounter_definition: Dictionary, intrusion_id: String) -> Dictionary:
	for intrusion_definition: Dictionary in encounter_definition.get("intrusions", []):
		if str(intrusion_definition.get("id", "")) == intrusion_id:
			return intrusion_definition
	return {}

func _resolve_dialogue_mode(run_state: RunState) -> String:
	if run_state.current_dialogue_mode.is_empty():
		return DIALOGUE_MODE_HUB
	return run_state.current_dialogue_mode

func get_event_hints(
	run_state: RunState,
	content_repository: ContentRepository
) -> Array[String]:
	var hints: Array[String] = []
	var definitions: Array[Dictionary] = content_repository.get_story_event_definitions(run_state.run_id)
	var class_order: Dictionary = {
		"ending_check": 400,
		"fixed_story": 300,
		"conditional_story": 200,
		"random_filler": 100
	}
	definitions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_class: int = int(class_order.get(str(a.get("event_class", "")), 0))
		var b_class: int = int(class_order.get(str(b.get("event_class", "")), 0))
		if a_class == b_class:
			return int(a.get("schedule_priority", 0)) > int(b.get("schedule_priority", 0))
		return a_class > b_class
	)
	for definition: Dictionary in definitions:
		if not _is_hint_candidate(run_state, definition):
			continue
		var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
		if not block_conditions.is_empty() and _condition_evaluator.evaluate_all(run_state, block_conditions):
			continue
		var conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
		var unmet: Array[String] = _condition_evaluator.get_unmet_descriptions(run_state, conditions)
		if unmet.is_empty():
			continue
		hints.append("%s: %s" % [str(definition.get("title", "")), ", ".join(unmet)])
		if hints.size() >= 3:
			break
	return hints

func _resolve_option_check(run_state: RunState, option_definition: Dictionary) -> Dictionary:
	var check_definition: Dictionary = Dictionary(option_definition.get("check", {}))
	if check_definition.is_empty():
		return {"performed": false, "passed": true, "outcome": "always", "log_text": ""}

	var gated_result: Dictionary = _evaluate_check_gate(run_state, check_definition)
	if not _to_bool(gated_result.get("passed", true)):
		return gated_result

	var system: String = str(check_definition.get("system", "")).to_lower()
	var source_value: int = _get_check_source_value(run_state, check_definition)
	var target: int = int(check_definition.get("target", 0))
	var bonus: int = int(check_definition.get("bonus", 0))

	match system:
		"d20":
			var roll: int = randi_range(1, 20)
			var modifier: int = source_value * 2 + bonus
			var total: int = roll + modifier
			var passed: bool = total >= target
			var critical_success: bool = roll == 20
			var critical_failure: bool = roll == 1
			return {
				"performed": true,
				"passed": passed,
				"outcome": "success" if passed else "failure",
				"system": system,
				"critical_success": critical_success,
				"critical_failure": critical_failure,
				"critical_text": _build_critical_text(system, critical_success, critical_failure),
				"log_text": GAME_TEXT.format_text(
					"event_service.check_logs.d20",
					[
						roll,
						modifier,
						total,
						target,
						_describe_result_label(passed)
					]
				)
			}
		"d100":
			var roll_percent: int = randi_range(1, 100)
			var threshold: int = clampi(target + source_value * 15 + bonus, 1, 95)
			var passed_percent: bool = roll_percent <= threshold
			var critical_success_percent: bool = roll_percent <= 5
			var critical_failure_percent: bool = roll_percent >= 96
			return {
				"performed": true,
				"passed": passed_percent,
				"outcome": "success" if passed_percent else "failure",
				"system": system,
				"critical_success": critical_success_percent,
				"critical_failure": critical_failure_percent,
				"critical_text": _build_critical_text(system, critical_success_percent, critical_failure_percent),
				"log_text": GAME_TEXT.format_text(
					"event_service.check_logs.d100",
					[
						roll_percent,
						threshold,
						_describe_result_label(passed_percent)
					]
				)
			}
		_:
			return {"performed": false, "passed": true, "outcome": "always", "log_text": ""}

func _evaluate_check_gate(run_state: RunState, check_definition: Dictionary) -> Dictionary:
	var required_npc_tag: String = str(check_definition.get("required_npc_tag", ""))
	if not required_npc_tag.is_empty():
		var required_npc_id: String = str(check_definition.get("required_npc_id", ""))
		var required_npc_label: String = str(check_definition.get("required_npc_label", required_npc_id))
		var required_tag_label: String = str(check_definition.get("required_npc_tag_label", required_npc_tag))
		for npc_state: NpcState in run_state.npc_states:
			if npc_state.id != required_npc_id:
				continue
			if npc_state.tags.has(required_npc_tag):
				return {"performed": false, "passed": true, "outcome": "always", "log_text": ""}
			return {
				"performed": false,
				"passed": false,
				"outcome": "failure",
				"log_text": "%s没有露出破绽：%s" % [required_npc_label, required_tag_label]
			}
		return {
			"performed": false,
			"passed": false,
			"outcome": "failure",
			"log_text": "%s当前不在场，无法捕捉破绽：%s" % [required_npc_label, required_tag_label]
		}
	return {"performed": false, "passed": true, "outcome": "always", "log_text": ""}

func _get_check_source_value(run_state: RunState, check_definition: Dictionary) -> int:
	var source: String = str(check_definition.get("source", "stat"))
	match source:
		"stat":
			return int(run_state.player_state.stats.get(str(check_definition.get("key", "")), 0))
		"resource":
			return int(run_state.player_state.resources.get(str(check_definition.get("key", "")), 0))
		"npc_relation":
			var npc_id: String = str(check_definition.get("npc_id", ""))
			var field: String = str(check_definition.get("field", "favor"))
			for npc_state: NpcState in run_state.npc_states:
				if npc_state.id != npc_id:
					continue
				return npc_state.alert if field == "alert" else npc_state.favor
			return 0
		_:
			return 0

func _resolve_option_result_text(option_definition: Dictionary, outcome: String) -> String:
	match outcome:
		"success":
			var success_text: String = str(option_definition.get("success_result_text", ""))
			if not success_text.is_empty():
				return success_text
		"failure":
			var failure_text: String = str(option_definition.get("failure_result_text", ""))
			if not failure_text.is_empty():
				return failure_text
	return str(option_definition.get("result_text", ""))

func _filter_effects_by_outcome(effects: Array[Dictionary], outcome: String) -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	for effect: Dictionary in effects:
		var effect_outcome: String = str(effect.get("outcome", "always"))
		if effect_outcome.is_empty() or effect_outcome == "always" or effect_outcome == outcome:
			filtered.append(effect)
	return filtered

func _build_critical_effects(check_result: Dictionary) -> Array[Dictionary]:
	var effects: Array[Dictionary] = []
	if _to_bool(check_result.get("critical_success", false)):
		effects.append({
			"type": "modify_resource",
			"scope": "player",
			"key": "clue_fragments",
			"delta": 1
		})
	if _to_bool(check_result.get("critical_failure", false)):
		var system: String = str(check_result.get("system", ""))
		var risk_key: String = "pollution" if system == "d100" else "exposure"
		effects.append({
			"type": "modify_resource",
			"scope": "player",
			"key": risk_key,
			"delta": 1
		})
	return effects

func _describe_option_check(check_definition: Dictionary) -> String:
	if check_definition.is_empty():
		return ""

	var system: String = str(check_definition.get("system", "")).to_lower()
	var source: String = str(check_definition.get("source", "stat"))
	var key: String = str(check_definition.get("key", ""))
	var target: int = int(check_definition.get("target", 0))
	var bonus: int = int(check_definition.get("bonus", 0))
	var source_label: String = _describe_check_source(source, key, check_definition)

	match system:
		"d20":
			return GAME_TEXT.format_text(
				"event_service.check_descriptions.d20",
				[source_label, bonus, target]
			)
		"d100":
			return GAME_TEXT.format_text(
				"event_service.check_descriptions.d100",
				[target, source_label, bonus]
			)
		_:
			return ""

func _describe_check_tag(check_definition: Dictionary) -> String:
	if check_definition.is_empty():
		return ""

	var system: String = str(check_definition.get("system", "")).to_lower()
	var source: String = str(check_definition.get("source", "stat"))
	var key: String = str(check_definition.get("key", ""))
	var source_label: String = _describe_check_source(source, key, check_definition)
	var required_npc_tag_label: String = str(check_definition.get("required_npc_tag_label", ""))
	var required_npc_label: String = str(check_definition.get("required_npc_label", ""))
	var prefix: String = ""
	if not required_npc_tag_label.is_empty():
		prefix = "需抓住%s的%s" % [required_npc_label, required_npc_tag_label]

	match system:
		"d20":
			var text: String = GAME_TEXT.format_text("event_service.check_tags.d20", [source_label])
			return text if prefix.is_empty() else "%s / %s" % [prefix, text]
		"d100":
			var text: String = GAME_TEXT.format_text("event_service.check_tags.d100", [source_label])
			return text if prefix.is_empty() else "%s / %s" % [prefix, text]
		_:
			return prefix

func _describe_check_difficulty(run_state: RunState, check_definition: Dictionary) -> String:
	if check_definition.is_empty():
		return ""

	var system: String = str(check_definition.get("system", "")).to_lower()
	var source_value: int = _get_check_source_value(run_state, check_definition)
	var target: int = int(check_definition.get("target", 0))
	var bonus: int = int(check_definition.get("bonus", 0))

	match system:
		"d20":
			var needed_roll: int = target - (source_value * 2 + bonus)
			if needed_roll <= 7:
				return GAME_TEXT.text("event_service.difficulty_labels.normal")
			if needed_roll <= 12:
				return GAME_TEXT.text("event_service.difficulty_labels.risky")
			if needed_roll <= 16:
				return GAME_TEXT.text("event_service.difficulty_labels.hard")
			return GAME_TEXT.text("event_service.difficulty_labels.desperate")
		"d100":
			var threshold: int = clampi(target + source_value * 15 + bonus, 1, 95)
			if threshold >= 70:
				return GAME_TEXT.text("event_service.difficulty_labels.normal")
			if threshold >= 45:
				return GAME_TEXT.text("event_service.difficulty_labels.risky")
			if threshold >= 25:
				return GAME_TEXT.text("event_service.difficulty_labels.hard")
			return GAME_TEXT.text("event_service.difficulty_labels.desperate")
		_:
			return ""

func _describe_check_source(source: String, key: String, check_definition: Dictionary) -> String:
	var labels: Dictionary = GAME_TEXT.dict("event_service.source_labels")
	match source:
		"stat", "resource":
			return str(labels.get(key, key))
		"npc_relation":
			var npc_id: String = str(check_definition.get("npc_id", ""))
			var field: String = str(check_definition.get("field", "favor"))
			var relation_label: String = str(
				GAME_TEXT.dict("event_service.relation_labels").get(field, field)
			)
			return "%s%s" % [npc_id, relation_label]
		_:
			return key

func _build_critical_text(system: String, critical_success: bool, critical_failure: bool) -> String:
	if critical_success:
		return GAME_TEXT.text("event_service.critical.success_d100") if system == "d100" else GAME_TEXT.text("event_service.critical.success_d20")
	if critical_failure:
		return GAME_TEXT.text("event_service.critical.failure_d100") if system == "d100" else GAME_TEXT.text("event_service.critical.failure_d20")
	return ""

func _describe_result_label(passed: bool) -> String:
	return GAME_TEXT.text("event_service.result_labels.success") if passed else GAME_TEXT.text("event_service.result_labels.failure")

func _get_next_queued_event_id(
	run_state: RunState,
	content_repository: ContentRepository
) -> String:
	for event_id: String in run_state.queued_event_ids:
		var definition: Dictionary = content_repository.get_event_definition(event_id)
		if definition.is_empty():
			continue
		if _is_legacy_event_available(run_state, definition):
			_run_state_mutator.dequeue_followup_event(run_state, event_id)
			return event_id
	return ""

func _is_legacy_event_available(run_state: RunState, definition: Dictionary) -> bool:
	var event_id: String = str(definition.get("id", ""))
	var repeatable: bool = _to_bool(definition.get("repeatable", false))
	if not repeatable and run_state.triggered_event_ids.has(event_id):
		return false
	var conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
	var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
	if not block_conditions.is_empty() and _condition_evaluator.evaluate_all(run_state, block_conditions):
		return false
	return _condition_evaluator.evaluate_all(run_state, conditions)

func _find_option_definition(event_definition: Dictionary, option_id: String) -> Dictionary:
	for option_definition: Dictionary in event_definition.get("options", []):
		if str(option_definition.get("id", "")) == option_id:
			return option_definition
	return {}

func _is_hint_candidate(run_state: RunState, definition: Dictionary) -> bool:
	var event_id: String = str(definition.get("id", ""))
	if run_state.triggered_event_ids.has(event_id) or run_state.current_event_id == event_id:
		return false

	var day_condition_match: bool = false
	for condition: Dictionary in definition.get("trigger_conditions", []):
		if str(condition.get("type", "")) != "day_range":
			continue
		var min_day: int = int(condition.get("min", 1))
		var max_day: int = int(condition.get("max", 999))
		day_condition_match = run_state.world_state.day >= min_day and run_state.world_state.day <= max_day
		break
	if not day_condition_match:
		return false

	var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
	if not block_conditions.is_empty() and _condition_evaluator.evaluate_all(run_state, block_conditions):
		return false
	return true

func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var normalized: String = str(value).strip_edges().to_lower()
			return normalized == "true" or normalized == "1" or normalized == "yes"
		_:
			return value != null
