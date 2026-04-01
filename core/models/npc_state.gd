class_name NpcState
extends RefCounted

var id: String = ""
var display_name: String = ""
var role: String = ""
var faction_id: String = ""
var tags: Array[String] = []
var favor: int = 0
var alert: int = 0
var current_location_id: String = ""
var is_available: bool = true
var flags: Dictionary = {}
var values: Dictionary = {}
var secrets: Array[String] = []
var preferred_actions: Array[String] = []
var available_interactions: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"role": role,
		"faction_id": faction_id,
		"tags": tags.duplicate(),
		"favor": favor,
		"alert": alert,
		"current_location_id": current_location_id,
		"is_available": is_available,
		"flags": flags.duplicate(true),
		"values": values.duplicate(true),
		"secrets": secrets.duplicate(),
		"preferred_actions": preferred_actions.duplicate(),
		"available_interactions": available_interactions.duplicate()
	}

static func from_dict(data: Dictionary) -> NpcState:
	var state: NpcState = NpcState.new()
	state.id = str(data.get("id", ""))
	state.display_name = str(data.get("display_name", ""))
	state.role = str(data.get("role", ""))
	state.faction_id = str(data.get("faction_id", ""))
	state.tags = Array(data.get("tags", []), TYPE_STRING, "", null)
	state.tags.append_array(Array(data.get("initial_status_tags", []), TYPE_STRING, "", null))
	state.favor = int(data.get("favor", data.get("initial_relation", {}).get("favor", 0)))
	state.alert = int(data.get("alert", data.get("initial_relation", {}).get("alert", 0)))
	state.current_location_id = str(data.get("current_location_id", data.get("default_location_id", "")))
	state.is_available = _to_bool(data.get("is_available", data.get("initial_flags", {}).get("interactable", true)))
	state.flags = data.get("flags", data.get("initial_flags", {})).duplicate(true)
	state.values = data.get("values", {}).duplicate(true)
	state.secrets = Array(data.get("secrets", []), TYPE_STRING, "", null)
	state.preferred_actions = Array(data.get("preferred_actions", []), TYPE_STRING, "", null)
	state.available_interactions = Array(data.get("available_interactions", []), TYPE_STRING, "", null)
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
