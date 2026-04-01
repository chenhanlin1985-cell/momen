class_name GoalProgress
extends RefCounted

var id: String = ""
var display_name: String = ""
var description: String = ""
var completion_conditions: Array[Dictionary] = []
var failure_conditions: Array[Dictionary] = []
var reward_tags: Array[String] = []
var priority: int = 0
var goal_type: String = "task"
var next_goal_ids: Array[String] = []
var completed: bool = false
var failed: bool = false

func to_dict() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"description": description,
		"completion_conditions": completion_conditions.duplicate(true),
		"failure_conditions": failure_conditions.duplicate(true),
		"reward_tags": reward_tags.duplicate(),
		"priority": priority,
		"goal_type": goal_type,
		"next_goal_ids": next_goal_ids.duplicate(),
		"completed": completed,
		"failed": failed
	}

static func from_dict(data: Dictionary) -> GoalProgress:
	var goal: GoalProgress = GoalProgress.new()
	goal.id = str(data.get("id", ""))
	goal.display_name = str(data.get("display_name", ""))
	goal.description = str(data.get("description", ""))
	goal.completion_conditions = Array(data.get("completion_conditions", []), TYPE_DICTIONARY, "", null)
	goal.failure_conditions = Array(data.get("failure_conditions", []), TYPE_DICTIONARY, "", null)
	goal.reward_tags = Array(data.get("reward_tags", []), TYPE_STRING, "", null)
	goal.priority = int(data.get("priority", 0))
	goal.goal_type = str(data.get("goal_type", "task"))
	goal.next_goal_ids = Array(data.get("next_goal_ids", []), TYPE_STRING, "", null)
	goal.completed = _to_bool(data.get("completed", false))
	goal.failed = _to_bool(data.get("failed", false))
	return goal

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
