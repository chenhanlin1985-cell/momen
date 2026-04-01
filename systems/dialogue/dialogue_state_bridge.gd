class_name DialogueStateBridge
extends RefCounted

var _run_state: RunState
var _run_state_mutator: RunStateMutator
var _warned_write_calls: Dictionary = {}


func _init(run_state_mutator: RunStateMutator) -> void:
	_run_state_mutator = run_state_mutator


func bind_run(run_state: RunState) -> void:
	_run_state = run_state


var flags: Dictionary:
	get:
		return _run_state.world_state.global_flags if _run_state != null else {}


var stats: Dictionary:
	get:
		return _run_state.player_state.stats if _run_state != null else {}


var resources: Dictionary:
	get:
		return _run_state.player_state.resources if _run_state != null else {}


func has_flag(flag_id: String) -> bool:
	if _run_state == null:
		return false
	return _to_bool(_run_state.world_state.global_flags.get(flag_id, false))


func set_flag(flag_id: String, value: Variant = true) -> void:
	_warn_write_disabled("set_flag", {"flag_id": flag_id, "value": value})


func clear_flag(flag_id: String) -> void:
	_warn_write_disabled("clear_flag", {"flag_id": flag_id})


func add_clue(delta: int = 1) -> void:
	_warn_write_disabled("add_clue", {"delta": delta})


func add_exposure(delta: int = 1) -> void:
	_warn_write_disabled("add_exposure", {"delta": delta})


func add_pollution(delta: int = 1) -> void:
	_warn_write_disabled("add_pollution", {"delta": delta})


func add_stat(stat_id: String, delta: int = 1) -> void:
	_warn_write_disabled("add_stat", {"stat_id": stat_id, "delta": delta})


func npc_favor(npc_id: String) -> int:
	if _run_state == null:
		return 0
	for npc_state: NpcState in _run_state.npc_states:
		if npc_state.id == npc_id:
			return npc_state.favor
	return 0


func npc_alert(npc_id: String) -> int:
	if _run_state == null:
		return 0
	for npc_state: NpcState in _run_state.npc_states:
		if npc_state.id == npc_id:
			return npc_state.alert
	return 0


func modify_npc_favor(npc_id: String, delta: int = 1) -> void:
	_warn_write_disabled("modify_npc_favor", {"npc_id": npc_id, "delta": delta})


func modify_npc_alert(npc_id: String, delta: int = 1) -> void:
	_warn_write_disabled("modify_npc_alert", {"npc_id": npc_id, "delta": delta})


func log_note(message: String) -> void:
	_warn_write_disabled("log_note", {"message": message})


func _warn_write_disabled(method_name: String, payload: Dictionary = {}) -> void:
	if _warned_write_calls.get(method_name, false):
		return
	_warned_write_calls[method_name] = true
	push_warning(
		"DialogueStateBridge.%s is disabled. Dialogue state must resolve through EventService/CSV options. payload=%s"
		% [method_name, JSON.stringify(payload)]
	)

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
