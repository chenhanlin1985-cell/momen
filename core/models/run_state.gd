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
	state.is_run_over = bool(data.get("is_run_over", false))
	state.end_reason = str(data.get("end_reason", ""))
	var ending_payload: Dictionary = data.get("ending_result", {})
	if not ending_payload.is_empty():
		state.ending_result = ENDING_RESULT_SCRIPT.from_dict(ending_payload)

	for npc_data: Dictionary in data.get("npc_states", []):
		state.npc_states.append(NpcState.from_dict(npc_data))

	for goal_data: Dictionary in data.get("active_goals", []):
		state.active_goals.append(GoalProgress.from_dict(goal_data))

	return state
