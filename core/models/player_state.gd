class_name PlayerState
extends RefCounted

var stats: Dictionary = {}
var resources: Dictionary = {}
var tags: Array[String] = []
var statuses: Array[String] = []
var knowledge: Array[String] = []
var battle_card_ids: Array[String] = []
var removed_battle_card_ids: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"stats": stats.duplicate(true),
		"resources": resources.duplicate(true),
		"tags": tags.duplicate(),
		"statuses": statuses.duplicate(),
		"knowledge": knowledge.duplicate(),
		"battle_card_ids": battle_card_ids.duplicate(),
		"removed_battle_card_ids": removed_battle_card_ids.duplicate()
	}

static func from_dict(data: Dictionary) -> PlayerState:
	var state: PlayerState = PlayerState.new()
	state.stats = data.get("stats", {}).duplicate(true)
	state.resources = data.get("resources", {}).duplicate(true)
	state.tags = Array(data.get("tags", []), TYPE_STRING, "", null)
	state.statuses = Array(data.get("statuses", []), TYPE_STRING, "", null)
	state.knowledge = Array(data.get("knowledge", []), TYPE_STRING, "", null)
	state.battle_card_ids = Array(data.get("battle_card_ids", []), TYPE_STRING, "", null)
	state.removed_battle_card_ids = Array(data.get("removed_battle_card_ids", []), TYPE_STRING, "", null)
	return state
