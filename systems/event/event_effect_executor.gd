class_name EventEffectExecutor
extends RefCounted

var _run_state_mutator: RunStateMutator

func _init(run_state_mutator: RunStateMutator) -> void:
	_run_state_mutator = run_state_mutator

func apply_effects(run_state: RunState, effects: Array[Dictionary]) -> void:
	for effect: Dictionary in effects:
		_apply_effect(run_state, effect)

func _apply_effect(run_state: RunState, effect: Dictionary) -> void:
	var effect_type: String = str(effect.get("type", ""))
	match effect_type:
		"modify_resource":
			_run_state_mutator.modify_player_resource(
				run_state,
				str(effect.get("key", "")),
				int(effect.get("delta", 0))
			)
		"modify_stat":
			_run_state_mutator.modify_player_stat(
				run_state,
				str(effect.get("key", "")),
				int(effect.get("delta", 0))
			)
		"add_tag":
			if str(effect.get("scope", "player")) == "world":
				_run_state_mutator.add_world_tag(run_state, str(effect.get("key", "")))
			else:
				_run_state_mutator.add_player_tag(run_state, str(effect.get("key", "")))
		"remove_tag":
			if str(effect.get("scope", "player")) == "world":
				_run_state_mutator.remove_world_tag(run_state, str(effect.get("key", "")))
			else:
				_run_state_mutator.remove_player_tag(run_state, str(effect.get("key", "")))
		"modify_world_value":
			_run_state_mutator.modify_world_value(
				run_state,
				str(effect.get("key", "")),
				int(effect.get("delta", 0))
			)
		"add_knowledge":
			_run_state_mutator.add_knowledge(run_state, str(effect.get("key", "")))
		"modify_npc_relation":
			_run_state_mutator.modify_npc_relation(
				run_state,
				str(effect.get("npc_id", "")),
				str(effect.get("field", "favor")),
				int(effect.get("delta", 0))
			)
		"add_followup_event":
			_run_state_mutator.queue_followup_event(run_state, str(effect.get("key", "")))
		"finish_run":
			_run_state_mutator.finish_run(run_state, str(effect.get("reason_id", "event_resolution")))
		_:
			pass

