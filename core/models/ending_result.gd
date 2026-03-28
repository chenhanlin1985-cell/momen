class_name EndingResult
extends RefCounted

var id: String = ""
var title: String = ""
var description: String = ""
var outcome_type: String = ""

func to_dict() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"description": description,
		"outcome_type": outcome_type
	}

static func from_dict(data: Dictionary) -> RefCounted:
	var result = load("res://core/models/ending_result.gd").new()
	result.id = str(data.get("id", ""))
	result.title = str(data.get("title", ""))
	result.description = str(data.get("description", ""))
	result.outcome_type = str(data.get("outcome_type", ""))
	return result
