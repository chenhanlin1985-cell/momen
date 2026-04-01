class_name RunState
extends RefCounted

const ENDING_RESULT_SCRIPT := preload("res://core/models/ending_result.gd")

var run_id: String = ""
var story_id: String = ""
var player_state: PlayerState = PlayerState.new()
var world_state: WorldState = WorldState.new()
var npc_states: Array[NpcState] = []
var active_goals: Array[GoalProgress] = []
var log_entries: Array[String] = []
var queued_event_ids: Array[String] = []
var triggered_event_ids: Array[String] = []
var current_event_id: String = ""
var current_event_result_text: String = ""
var current_dialogue_mode: String = ""
var current_dialogue_body_override_text: String = ""
var current_dialogue_portrait_override_label: String = ""
var current_dialogue_intrusion_tag: String = ""
var current_dialogue_intrusion_used: bool = false
var is_run_over: bool = false
var end_reason: String = ""
var ending_result = null

func to_dict() -> Dictionary:
	var npc_payload: Array[Dictionary] = []
	for npc_state: NpcState in npc_states:
		npc_payload.append(npc_state.to_dict())

	var goal_payload: Array[Dictionary] = []
	for goal: GoalProgress in active_goals:
		goal_payload.append(goal.to_dict())

	return {
		"run_id": run_id,
		"story_id": story_id,
		"player_state": player_state.to_dict(),
		"world_state": world_state.to_dict(),
		"npc_states": npc_payload,
		"active_goals": goal_payload,
		"log_entries": log_entries.duplicate(),
		"queued_event_ids": queued_event_ids.duplicate(),
		"triggered_event_ids": triggered_event_ids.duplicate(),
		"current_event_id": current_event_id,
		"current_event_result_text": current_event_result_text,
		"current_dialogue_mode": current_dialogue_mode,
		"current_dialogue_body_override_text": current_dialogue_body_override_text,
		"current_dialogue_portrait_override_label": current_dialogue_portrait_override_label,
		"current_dialogue_intrusion_tag": current_dialogue_intrusion_tag,
		"current_dialogue_intrusion_used": current_dialogue_intrusion_used,
		"is_run_over": is_run_over,
		"end_reason": end_reason,
		"ending_result": {} if ending_result == null else ending_result.to_dict()
	}

static func from_dict(data: Dictionary) -> RunState:
	var state: RunState = RunState.new()
	state.run_id = str(data.get("run_id", ""))
	state.story_id = str(data.get("story_id", ""))
	state.player_state = PlayerState.from_dict(data.get("player_state", {}))
	state.world_state = WorldState.from_dict(data.get("world_state", {}))
	state.log_entries = Array(data.get("log_entries", []), TYPE_STRING, "", null)
	state.queued_event_ids = Array(data.get("queued_event_ids", []), TYPE_STRING, "", null)
	state.triggered_event_ids = Array(data.get("triggered_event_ids", []), TYPE_STRING, "", null)
	state.current_event_id = str(data.get("current_event_id", ""))
	state.current_event_result_text = str(data.get("current_event_result_text", ""))
	state.current_dialogue_mode = str(data.get("current_dialogue_mode", ""))
	state.current_dialogue_body_override_text = str(data.get("current_dialogue_body_override_text", ""))
	state.current_dialogue_portrait_override_label = str(data.get("current_dialogue_portrait_override_label", ""))
	state.current_dialogue_intrusion_tag = str(data.get("current_dialogue_intrusion_tag", ""))
	state.current_dialogue_intrusion_used = _to_bool(data.get("current_dialogue_intrusion_used", false))
	state.is_run_over = _to_bool(data.get("is_run_over", false))
	state.end_reason = str(data.get("end_reason", ""))
	var ending_payload: Dictionary = data.get("ending_result", {})
	if not ending_payload.is_empty():
		state.ending_result = ENDING_RESULT_SCRIPT.from_dict(ending_payload)

	for npc_data: Dictionary in data.get("npc_states", []):
		state.npc_states.append(NpcState.from_dict(npc_data))

	for goal_data: Dictionary in data.get("active_goals", []):
		state.active_goals.append(GoalProgress.from_dict(goal_data))

	return state

static func _to_bool(value: Variant) -> bool:
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
