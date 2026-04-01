class_name LocationRuntimeState
extends RefCounted

var id: String = ""
var is_unlocked: bool = false
var is_blocked: bool = false
var visit_count: int = 0
var tags: Array[String] = []
var values: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"id": id,
		"is_unlocked": is_unlocked,
		"is_blocked": is_blocked,
		"visit_count": visit_count,
		"tags": tags.duplicate(),
		"values": values.duplicate(true)
	}

func apply_dict(data: Dictionary) -> LocationRuntimeState:
	id = str(data.get("id", ""))
	is_unlocked = _to_bool(data.get("is_unlocked", false))
	is_blocked = _to_bool(data.get("is_blocked", false))
	visit_count = int(data.get("visit_count", 0))
	tags = Array(data.get("tags", []), TYPE_STRING, "", null)
	values = data.get("values", {}).duplicate(true)
	return self

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
