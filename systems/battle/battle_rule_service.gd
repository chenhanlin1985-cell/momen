class_name BattleRuleService
extends RefCounted

const SLOT_BASE: int = 0
const SLOT_MULTI: int = 1

func build_resolution(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary
) -> Dictionary:
	if battle_state.slot_card_ids.size() < 2:
		return {
			"success": false,
			"message": "battle.slots_incomplete"
		}

	var base_card_id: String = str(battle_state.slot_card_ids[SLOT_BASE])
	var multi_card_id: String = str(battle_state.slot_card_ids[SLOT_MULTI])
	var base_card: Dictionary = Dictionary(card_definitions_by_id.get(_resolve_card_definition_id(base_card_id), {}))
	var multi_card: Dictionary = Dictionary(card_definitions_by_id.get(_resolve_card_definition_id(multi_card_id), {}))
	if base_card.is_empty() or multi_card.is_empty():
		return {
			"success": false,
			"message": "battle.cards_missing"
		}

	var base_score: int = _resolve_base_score(battle_state, base_card, card_definitions_by_id)
	var multiplier: float = _resolve_multiplier(battle_state, multi_card, base_card)
	var vulnerability_factor: float = _resolve_vulnerability_factor(battle_state, multi_card, base_card)
	var resistance_bonus_cost: int = _resolve_resistance_bonus_cost(battle_state, base_card)
	var resistance_score_delta: int = _resolve_resistance_score_delta(battle_state, base_card)
	var total_damage: int = maxi(int(round(base_score * multiplier * vulnerability_factor)) + resistance_score_delta, 0)

	return {
		"success": true,
		"base_card_id": base_card_id,
		"multi_card_id": multi_card_id,
		"base_score": base_score,
		"multiplier": multiplier,
		"vulnerability_factor": vulnerability_factor,
		"resistance_bonus_cost": resistance_bonus_cost,
		"resistance_score_delta": resistance_score_delta,
		"damage": total_damage
	}

func can_assign_card_to_slot(slot_index: int, card_definition: Dictionary) -> bool:
	match slot_index:
		SLOT_BASE:
			return str(card_definition.get("card_group", "")) == "02"
		SLOT_MULTI:
			return str(card_definition.get("card_group", "")) == "01"
		_:
			return false

func build_preview(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary
) -> Dictionary:
	if battle_state.slot_card_ids.size() < 2:
		return {
			"base_score": 0,
			"multiplier": 1.0,
			"vulnerability_factor": 1.0,
			"resistance_score_delta": 0,
			"damage": 0,
			"is_ready": false
		}
	var base_card_id: String = str(battle_state.slot_card_ids[SLOT_BASE])
	var multi_card_id: String = str(battle_state.slot_card_ids[SLOT_MULTI])
	if base_card_id.is_empty() or multi_card_id.is_empty():
		return {
			"base_score": 0,
			"multiplier": 1.0,
			"vulnerability_factor": 1.0,
			"resistance_score_delta": 0,
			"damage": 0,
			"is_ready": false
		}
	var resolution: Dictionary = build_resolution(battle_state, card_definitions_by_id)
	resolution["is_ready"] = bool(resolution.get("success", false))
	return resolution

func _resolve_multiplier(
	battle_state: BattleState,
	multi_card: Dictionary,
	base_card: Dictionary
) -> float:
	var multiplier: float = 1.0
	if str(multi_card.get("pollution_kind", "")) == "reverse_multi":
		var reverse_tags: Array[String] = Array(multi_card.get("reverse_base_tags", []), TYPE_STRING, "", null)
		var base_effect_tags: Array[String] = Array(base_card.get("effect_tags", []), TYPE_STRING, "", null)
		for tag: String in reverse_tags:
			if base_effect_tags.has(tag):
				multiplier = float(multi_card.get("reverse_multiplier", 1.0))
				return _apply_enemy_specific_multiplier(battle_state, multi_card, multiplier)
		multiplier = float(multi_card.get("default_multiplier", 1.0))
		return _apply_enemy_specific_multiplier(battle_state, multi_card, multiplier)
	var card_type: String = str(base_card.get("card_type", ""))
	var multiplier_tags: Dictionary = Dictionary(multi_card.get("multiplier_tags", {}))
	multiplier = float(multiplier_tags.get(card_type, 1.0))
	return _apply_enemy_specific_multiplier(battle_state, multi_card, multiplier)

func _resolve_base_score(
	battle_state: BattleState,
	base_card: Dictionary,
	card_definitions_by_id: Dictionary
) -> int:
	var total_score: int = int(base_card.get("base_score", 0))
	for card_id: String in battle_state.hand_cards:
		var hand_card: Dictionary = Dictionary(card_definitions_by_id.get(_resolve_card_definition_id(card_id), {}))
		if str(hand_card.get("pollution_kind", "")) != "hand_aura":
			continue
		total_score += int(hand_card.get("hand_base_score_delta", 0))
	return maxi(total_score, 0)

func _resolve_vulnerability_factor(
	battle_state: BattleState,
	multi_card: Dictionary,
	base_card: Dictionary
) -> float:
	var factor: float = 1.0
	var card_type: String = str(base_card.get("card_type", ""))
	var base_type_multipliers: Dictionary = Dictionary(battle_state.vulnerability_base_type_multipliers)
	if base_type_multipliers.has(card_type):
		factor *= float(base_type_multipliers.get(card_type, 1.0))
	var clue_tags: Array[String] = Array(multi_card.get("effect_tags", []), TYPE_STRING, "", null)
	var multi_tag_multipliers: Dictionary = Dictionary(battle_state.vulnerability_multi_tag_multipliers)
	for tag: String in clue_tags:
		if not multi_tag_multipliers.has(tag):
			continue
		factor *= float(multi_tag_multipliers.get(tag, 1.0))
	return factor

func _resolve_resistance_bonus_cost(battle_state: BattleState, base_card: Dictionary) -> int:
	var card_type: String = str(base_card.get("card_type", ""))
	return int(Dictionary(battle_state.resistance_extra_cost_by_base_type).get(card_type, 0))

func _resolve_resistance_score_delta(battle_state: BattleState, base_card: Dictionary) -> int:
	var card_type: String = str(base_card.get("card_type", ""))
	return int(Dictionary(battle_state.resistance_score_delta_by_base_type).get(card_type, 0))

func _apply_enemy_specific_multiplier(
	battle_state: BattleState,
	card_definition: Dictionary,
	base_multiplier: float
) -> float:
	var bonuses: Dictionary = Dictionary(card_definition.get("enemy_mind_multiplier_bonuses", {}))
	if bonuses.is_empty():
		return base_multiplier
	var enemy_mind_id: String = str(battle_state.enemy_mind_id, "")
	if enemy_mind_id.is_empty() or not bonuses.has(enemy_mind_id):
		return base_multiplier
	return base_multiplier * float(bonuses.get(enemy_mind_id, 1.0))

func _resolve_card_definition_id(card_ref: String) -> String:
	if not card_ref.contains("#"):
		return card_ref
	return card_ref.get_slice("#", 0)
