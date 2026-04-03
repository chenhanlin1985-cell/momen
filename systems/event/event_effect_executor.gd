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
		"set_flag":
			_run_state_mutator.set_global_flag(
				run_state,
				str(effect.get("key", "")),
				effect.get("value", true)
			)
		"clear_flag":
			_run_state_mutator.clear_global_flag(
				run_state,
				str(effect.get("key", ""))
			)
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
		"add_battle_card":
			_run_state_mutator.add_battle_card(run_state, str(effect.get("key", "")))
		"remove_battle_card":
			_run_state_mutator.remove_battle_card(run_state, str(effect.get("key", "")))
		"add_npc_tag":
			_run_state_mutator.add_npc_tag(
				run_state,
				str(effect.get("npc_id", "")),
				str(effect.get("key", ""))
			)
		"remove_npc_tag":
			_run_state_mutator.remove_npc_tag(
				run_state,
				str(effect.get("npc_id", "")),
				str(effect.get("key", ""))
			)
		"set_npc_available":
			_run_state_mutator.set_npc_available(
				run_state,
				str(effect.get("npc_id", "")),
				_to_bool(effect.get("value", true))
			)
		"unlock_location":
			_run_state_mutator.unlock_location(run_state, str(effect.get("target_id", effect.get("key", ""))))
		"block_location":
			_run_state_mutator.block_location(run_state, str(effect.get("target_id", effect.get("key", ""))))
		"unblock_location":
			_run_state_mutator.unblock_location(run_state, str(effect.get("target_id", effect.get("key", ""))))
		"add_followup_event":
			_run_state_mutator.queue_followup_event(run_state, str(effect.get("key", "")))
		"finish_run":
			var finish_reason: String = str(effect.get("reason_id", ""))
			if finish_reason.is_empty():
				finish_reason = str(effect.get("key", ""))
			if finish_reason.is_empty():
				finish_reason = "event_resolution"
			_run_state_mutator.finish_run(run_state, finish_reason)
		_:
			pass

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
