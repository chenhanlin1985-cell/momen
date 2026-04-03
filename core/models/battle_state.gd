class_name BattleState
extends RefCounted

var battle_id: String = ""
var story_id: String = ""
var entry_event_id: String = ""
var result_event_id_success: String = ""
var result_event_id_failure: String = ""

var enemy_mind_id: String = ""
var enemy_display_name: String = ""
var enemy_max_hp: int = 0
var enemy_hp: int = 0
var enemy_slot_count: int = 2
var enemy_vulnerability_tags: Array[String] = []
var enemy_resistance_tags: Array[String] = []
var pollution_profile_id: String = ""
var pollution_profile: Dictionary = {}
var current_intent_text: String = ""
var current_intent_card_ids: Array[String] = []
var triggered_pollution_threshold_ids: Array[String] = []
var last_pollution_turn_applied: int = 0
var vulnerability_base_type_multipliers: Dictionary = {}
var vulnerability_multi_tag_multipliers: Dictionary = {}
var resistance_extra_cost_by_base_type: Dictionary = {}
var resistance_score_delta_by_base_type: Dictionary = {}

var max_sanity: int = 0
var sanity: int = 0
var redraw_cost: int = 0
var end_turn_recoil: int = 0
var exp_reward: int = 0
var reward_card_ids: Array[String] = []

var turn_index: int = 1
var starter_deck: Array[String] = []
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var hand_cards: Array[String] = []
var slot_card_ids: Array[String] = []
var selected_slot_index: int = -1

var used_redraw_count: int = 0
var is_battle_over: bool = false
var is_player_victory: bool = false
var is_player_defeat: bool = false
var summary_text: String = ""
var log_entries: Array[String] = []

func to_dict() -> Dictionary:
	return {
		"battle_id": battle_id,
		"story_id": story_id,
		"entry_event_id": entry_event_id,
		"result_event_id_success": result_event_id_success,
		"result_event_id_failure": result_event_id_failure,
		"enemy_mind_id": enemy_mind_id,
		"enemy_display_name": enemy_display_name,
		"enemy_max_hp": enemy_max_hp,
		"enemy_hp": enemy_hp,
		"enemy_slot_count": enemy_slot_count,
		"enemy_vulnerability_tags": enemy_vulnerability_tags.duplicate(),
		"enemy_resistance_tags": enemy_resistance_tags.duplicate(),
		"pollution_profile_id": pollution_profile_id,
		"pollution_profile": pollution_profile.duplicate(true),
		"current_intent_text": current_intent_text,
		"current_intent_card_ids": current_intent_card_ids.duplicate(),
		"triggered_pollution_threshold_ids": triggered_pollution_threshold_ids.duplicate(),
		"last_pollution_turn_applied": last_pollution_turn_applied,
		"vulnerability_base_type_multipliers": vulnerability_base_type_multipliers.duplicate(true),
		"vulnerability_multi_tag_multipliers": vulnerability_multi_tag_multipliers.duplicate(true),
		"resistance_extra_cost_by_base_type": resistance_extra_cost_by_base_type.duplicate(true),
		"resistance_score_delta_by_base_type": resistance_score_delta_by_base_type.duplicate(true),
		"max_sanity": max_sanity,
		"sanity": sanity,
		"redraw_cost": redraw_cost,
		"end_turn_recoil": end_turn_recoil,
		"exp_reward": exp_reward,
		"reward_card_ids": reward_card_ids.duplicate(),
		"turn_index": turn_index,
		"starter_deck": starter_deck.duplicate(),
		"draw_pile": draw_pile.duplicate(),
		"discard_pile": discard_pile.duplicate(),
		"hand_cards": hand_cards.duplicate(),
		"slot_card_ids": slot_card_ids.duplicate(),
		"selected_slot_index": selected_slot_index,
		"used_redraw_count": used_redraw_count,
		"is_battle_over": is_battle_over,
		"is_player_victory": is_player_victory,
		"is_player_defeat": is_player_defeat,
		"summary_text": summary_text,
		"log_entries": log_entries.duplicate()
	}

static func from_dict(data: Dictionary) -> BattleState:
	var state: BattleState = BattleState.new()
	state.battle_id = str(data.get("battle_id", ""))
	state.story_id = str(data.get("story_id", ""))
	state.entry_event_id = str(data.get("entry_event_id", ""))
	state.result_event_id_success = str(data.get("result_event_id_success", ""))
	state.result_event_id_failure = str(data.get("result_event_id_failure", ""))
	state.enemy_mind_id = str(data.get("enemy_mind_id", ""))
	state.enemy_display_name = str(data.get("enemy_display_name", ""))
	state.enemy_max_hp = int(data.get("enemy_max_hp", 0))
	state.enemy_hp = int(data.get("enemy_hp", state.enemy_max_hp))
	state.enemy_slot_count = int(data.get("enemy_slot_count", 2))
	state.enemy_vulnerability_tags = Array(data.get("enemy_vulnerability_tags", []), TYPE_STRING, "", null)
	state.enemy_resistance_tags = Array(data.get("enemy_resistance_tags", []), TYPE_STRING, "", null)
	state.pollution_profile_id = str(data.get("pollution_profile_id", ""))
	state.pollution_profile = Dictionary(data.get("pollution_profile", {})).duplicate(true)
	state.current_intent_text = str(data.get("current_intent_text", ""))
	state.current_intent_card_ids = Array(data.get("current_intent_card_ids", []), TYPE_STRING, "", null)
	state.triggered_pollution_threshold_ids = Array(data.get("triggered_pollution_threshold_ids", []), TYPE_STRING, "", null)
	state.last_pollution_turn_applied = int(data.get("last_pollution_turn_applied", 0))
	state.vulnerability_base_type_multipliers = Dictionary(data.get("vulnerability_base_type_multipliers", {})).duplicate(true)
	state.vulnerability_multi_tag_multipliers = Dictionary(data.get("vulnerability_multi_tag_multipliers", {})).duplicate(true)
	state.resistance_extra_cost_by_base_type = Dictionary(data.get("resistance_extra_cost_by_base_type", {})).duplicate(true)
	state.resistance_score_delta_by_base_type = Dictionary(data.get("resistance_score_delta_by_base_type", {})).duplicate(true)
	state.max_sanity = int(data.get("max_sanity", 0))
	state.sanity = int(data.get("sanity", state.max_sanity))
	state.redraw_cost = int(data.get("redraw_cost", 0))
	state.end_turn_recoil = int(data.get("end_turn_recoil", 0))
	state.exp_reward = int(data.get("exp_reward", 0))
	state.reward_card_ids = Array(data.get("reward_card_ids", []), TYPE_STRING, "", null)
	state.turn_index = int(data.get("turn_index", 1))
	state.starter_deck = Array(data.get("starter_deck", []), TYPE_STRING, "", null)
	state.draw_pile = Array(data.get("draw_pile", []), TYPE_STRING, "", null)
	state.discard_pile = Array(data.get("discard_pile", []), TYPE_STRING, "", null)
	state.hand_cards = Array(data.get("hand_cards", []), TYPE_STRING, "", null)
	state.slot_card_ids = Array(data.get("slot_card_ids", []), TYPE_STRING, "", null)
	state.selected_slot_index = int(data.get("selected_slot_index", -1))
	state.used_redraw_count = int(data.get("used_redraw_count", 0))
	state.is_battle_over = _to_bool(data.get("is_battle_over", false))
	state.is_player_victory = _to_bool(data.get("is_player_victory", false))
	state.is_player_defeat = _to_bool(data.get("is_player_defeat", false))
	state.summary_text = str(data.get("summary_text", ""))
	state.log_entries = Array(data.get("log_entries", []), TYPE_STRING, "", null)
	return state

func reset_slots() -> void:
	slot_card_ids.clear()
	for _slot_index: int in range(max(enemy_slot_count, 0)):
		slot_card_ids.append("")
	selected_slot_index = -1

func append_log(message: String) -> void:
	if message.strip_edges().is_empty():
		return
	log_entries.append(message)

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
