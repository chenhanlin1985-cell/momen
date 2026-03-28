class_name WorldState
extends RefCounted

var day: int = 1
var max_day: int = 21
var actions_per_day: int = 2
var actions_remaining: int = 2
var current_phase: String = "morning"
var last_action_id: String = ""
var values: Dictionary = {}
var tags: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"day": day,
		"max_day": max_day,
		"actions_per_day": actions_per_day,
		"actions_remaining": actions_remaining,
		"current_phase": current_phase,
		"last_action_id": last_action_id,
		"values": values.duplicate(true),
		"tags": tags.duplicate()
	}

static func from_dict(data: Dictionary) -> WorldState:
	var state: WorldState = WorldState.new()
	state.day = int(data.get("day", 1))
	state.max_day = int(data.get("max_day", 21))
	state.actions_per_day = int(data.get("actions_per_day", 2))
	state.actions_remaining = int(data.get("actions_remaining", state.actions_per_day))
	state.current_phase = str(data.get("current_phase", "morning"))
	state.last_action_id = str(data.get("last_action_id", ""))
	state.values = data.get("values", {}).duplicate(true)
	state.tags = Array(data.get("tags", []), TYPE_STRING, "", null)
	return state
