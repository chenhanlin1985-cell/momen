class_name WorldState
extends RefCounted

const LOCATION_RUNTIME_STATE_SCRIPT := preload("res://core/models/location_runtime_state.gd")

var day: int = 1
var max_day: int = 21
var actions_per_day: int = 2
var actions_remaining: int = 2
var current_phase: String = "morning"
var last_action_id: String = ""
var last_action_category: String = ""
var current_action_candidates: Array[String] = []
var current_location_id: String = ""
var last_location_id: String = ""
var location_states: Dictionary = {}
var global_flags: Dictionary = {}
var values: Dictionary = {}
var tags: Array[String] = []

func to_dict() -> Dictionary:
	var location_payload: Dictionary = {}
	for location_id: String in location_states.keys():
		var runtime_state: Variant = location_states[location_id]
		if runtime_state is RefCounted and runtime_state.has_method("to_dict"):
			location_payload[location_id] = runtime_state.to_dict()
		elif runtime_state is Dictionary:
			location_payload[location_id] = Dictionary(runtime_state).duplicate(true)
	return {
		"day": day,
		"max_day": max_day,
		"actions_per_day": actions_per_day,
		"actions_remaining": actions_remaining,
		"current_phase": current_phase,
		"last_action_id": last_action_id,
		"last_action_category": last_action_category,
		"current_action_candidates": current_action_candidates.duplicate(),
		"current_location_id": current_location_id,
		"last_location_id": last_location_id,
		"location_states": location_payload,
		"global_flags": global_flags.duplicate(true),
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
	state.last_action_category = str(data.get("last_action_category", ""))
	state.current_action_candidates = Array(data.get("current_action_candidates", []), TYPE_STRING, "", null)
	state.current_location_id = str(data.get("current_location_id", ""))
	state.last_location_id = str(data.get("last_location_id", ""))
	for location_id: String in data.get("location_states", {}).keys():
		state.location_states[location_id] = LOCATION_RUNTIME_STATE_SCRIPT.new().apply_dict(
			data.get("location_states", {}).get(location_id, {})
		)
	state.global_flags = data.get("global_flags", {}).duplicate(true)
	state.values = data.get("values", {}).duplicate(true)
	state.tags = Array(data.get("tags", []), TYPE_STRING, "", null)
	return state
