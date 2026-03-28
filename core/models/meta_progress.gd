class_name MetaProgress
extends RefCounted

var completed_run_count: int = 0
var unlocked_inheritance_ids: Array[String] = []
var discovered_knowledge_keys: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"completed_run_count": completed_run_count,
		"unlocked_inheritance_ids": unlocked_inheritance_ids.duplicate(),
		"discovered_knowledge_keys": discovered_knowledge_keys.duplicate()
	}

static func from_dict(data: Dictionary) -> MetaProgress:
	var progress: MetaProgress = MetaProgress.new()
	progress.completed_run_count = int(data.get("completed_run_count", 0))
	progress.unlocked_inheritance_ids = Array(
		data.get("unlocked_inheritance_ids", []),
		TYPE_STRING,
		"",
		null
	)
	progress.discovered_knowledge_keys = Array(
		data.get("discovered_knowledge_keys", []),
		TYPE_STRING,
		"",
		null
	)
	return progress

