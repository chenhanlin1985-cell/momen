class_name NpcState
extends RefCounted

var id: String = ""
var display_name: String = ""
var role: String = ""
var faction_id: String = ""
var tags: Array[String] = []
var favor: int = 0
var alert: int = 0
var flags: Dictionary = {}
var secrets: Array[String] = []
var preferred_actions: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"role": role,
		"faction_id": faction_id,
		"tags": tags.duplicate(),
		"favor": favor,
		"alert": alert,
		"flags": flags.duplicate(true),
		"secrets": secrets.duplicate(),
		"preferred_actions": preferred_actions.duplicate()
	}

static func from_dict(data: Dictionary) -> NpcState:
	var state: NpcState = NpcState.new()
	state.id = str(data.get("id", ""))
	state.display_name = str(data.get("display_name", ""))
	state.role = str(data.get("role", ""))
	state.faction_id = str(data.get("faction_id", ""))
	state.tags = Array(data.get("tags", []), TYPE_STRING, "", null)
	state.favor = int(data.get("favor", data.get("initial_relation", {}).get("favor", 0)))
	state.alert = int(data.get("alert", data.get("initial_relation", {}).get("alert", 0)))
	state.flags = data.get("flags", data.get("initial_flags", {})).duplicate(true)
	state.secrets = Array(data.get("secrets", []), TYPE_STRING, "", null)
	state.preferred_actions = Array(data.get("preferred_actions", []), TYPE_STRING, "", null)
	return state

