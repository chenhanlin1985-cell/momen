class_name BattleService
extends RefCounted

const BATTLE_STATE_SCRIPT := preload("res://core/models/battle_state.gd")
const BATTLE_RULE_SERVICE_SCRIPT := preload("res://systems/battle/battle_rule_service.gd")
const BATTLE_REWARD_SERVICE_SCRIPT := preload("res://systems/battle/battle_reward_service.gd")

var _rule_service: BattleRuleService
var _reward_service: BattleRewardService

func _init() -> void:
	_rule_service = BATTLE_RULE_SERVICE_SCRIPT.new()
	_reward_service = BATTLE_REWARD_SERVICE_SCRIPT.new()

func resolve_card_definition_id(card_ref: String) -> String:
	if not card_ref.contains("#"):
		return card_ref
	return card_ref.get_slice("#", 0)

func create_battle_state(
	battle_definition: Dictionary,
	enemy_mind_definition: Dictionary,
	pollution_profile_definition: Dictionary = {},
	player_level: int = 1,
	owned_card_ids: Array[String] = [],
	removed_card_ids: Array[String] = [],
	card_definitions_by_id: Dictionary = {},
	battle_texts: Dictionary = {}
) -> BattleState:
	var state: BattleState = BATTLE_STATE_SCRIPT.new()
	state.battle_id = str(battle_definition.get("id", ""))
	state.story_id = str(battle_definition.get("story_id", ""))
	state.entry_event_id = str(battle_definition.get("entry_event_id", ""))
	state.result_event_id_success = str(battle_definition.get("result_event_id_success", ""))
	state.result_event_id_failure = str(battle_definition.get("result_event_id_failure", ""))
	state.enemy_mind_id = str(enemy_mind_definition.get("id", ""))
	state.enemy_display_name = str(enemy_mind_definition.get("display_name", state.enemy_mind_id))
	state.enemy_max_hp = int(enemy_mind_definition.get("max_hp", 0))
	state.enemy_hp = int(enemy_mind_definition.get("start_hp", state.enemy_max_hp))
	state.enemy_slot_count = int(enemy_mind_definition.get("slot_count", 2))
	state.enemy_vulnerability_tags = Array(enemy_mind_definition.get("vulnerability_tags", []), TYPE_STRING, "", null)
	state.enemy_resistance_tags = Array(enemy_mind_definition.get("resistance_tags", []), TYPE_STRING, "", null)
	state.pollution_profile_id = str(pollution_profile_definition.get("id", ""))
	state.pollution_profile = Dictionary(pollution_profile_definition).duplicate(true)
	state.vulnerability_base_type_multipliers = Dictionary(enemy_mind_definition.get("vulnerability_base_type_multipliers", {})).duplicate(true)
	state.vulnerability_multi_tag_multipliers = Dictionary(enemy_mind_definition.get("vulnerability_multi_tag_multipliers", {})).duplicate(true)
	state.resistance_extra_cost_by_base_type = Dictionary(enemy_mind_definition.get("resistance_extra_cost_by_base_type", {})).duplicate(true)
	state.resistance_score_delta_by_base_type = Dictionary(enemy_mind_definition.get("resistance_score_delta_by_base_type", {})).duplicate(true)
	state.max_sanity = _resolve_player_max_sanity(battle_definition, player_level)
	state.sanity = state.max_sanity
	state.redraw_cost = int(battle_definition.get("redraw_cost", 0))
	state.end_turn_recoil = int(battle_definition.get("end_turn_recoil", 0))
	state.exp_reward = int(battle_definition.get("exp_reward", 0))
	state.reward_card_ids = Array(battle_definition.get("reward_card_ids", []), TYPE_STRING, "", null)
	var starter_card_ids: Array[String] = Array(battle_definition.get("starter_deck", []), TYPE_STRING, "", null)
	for removed_card_id: String in removed_card_ids:
		starter_card_ids.erase(removed_card_id)
	for card_id: String in owned_card_ids:
		if card_id.is_empty():
			continue
		if removed_card_ids.has(card_id):
			continue
		if starter_card_ids.has(card_id):
			continue
		starter_card_ids.append(card_id)
	state.starter_deck.clear()
	for starter_card_id: String in starter_card_ids:
		state.starter_deck.append(_create_card_ref(state, starter_card_id))
	state.draw_pile = state.starter_deck.duplicate()
	_shuffle_string_array(state.draw_pile)
	state.reset_slots()
	draw_to_hand(state, int(battle_definition.get("initial_hand_size", 0)))
	state.append_log(str(battle_definition.get("opening_log_text", "")))
	_apply_turn_start_pollution(state, card_definitions_by_id, battle_texts)
	return state

func draw_to_hand(battle_state: BattleState, draw_count: int) -> void:
	for _index: int in range(max(draw_count, 0)):
		if battle_state.draw_pile.is_empty():
			_reshuffle_discard_into_draw_pile(battle_state)
		if battle_state.draw_pile.is_empty():
			return
		var next_card_ref: String = battle_state.draw_pile.pop_back()
		battle_state.hand_cards.append(next_card_ref)
		if not battle_state.hand_layout_card_ids.has(next_card_ref):
			battle_state.hand_layout_card_ids.append(next_card_ref)

func redraw_hand(
	battle_state: BattleState,
	redraw_count: int = -1,
	card_definitions_by_id: Dictionary = {},
	battle_texts: Dictionary = {}
) -> Dictionary:
	if battle_state.sanity < battle_state.redraw_cost:
		return {"success": false, "message": "battle.sanity_not_enough"}
	battle_state.sanity = maxi(battle_state.sanity - battle_state.redraw_cost, 0)
	battle_state.used_redraw_count += 1
	while not battle_state.hand_cards.is_empty():
		battle_state.discard_pile.append(battle_state.hand_cards.pop_back())
	var target_draw_count: int = redraw_count if redraw_count >= 0 else battle_state.starter_deck.size()
	draw_to_hand(battle_state, target_draw_count)
	_reset_hand_layout_order(battle_state)
	_refresh_terminal_state(battle_state, {}, {})
	return {"success": true}

func assign_card_to_slot(battle_state: BattleState, slot_index: int, card_ref: String, card_definition: Dictionary) -> Dictionary:
	if slot_index < 0 or slot_index >= battle_state.slot_card_ids.size():
		return {"success": false, "message": "battle.slot_out_of_range"}
	if not battle_state.hand_cards.has(card_ref):
		return {"success": false, "message": "battle.card_not_in_hand"}
	if not _rule_service.can_assign_card_to_slot(slot_index, card_definition):
		return {"success": false, "message": "battle.slot_type_mismatch"}
	var replaced_card_ref: String = str(battle_state.slot_card_ids[slot_index])
	var removed_layout_index: int = battle_state.hand_layout_card_ids.find(card_ref)
	if not replaced_card_ref.is_empty():
		battle_state.hand_cards.append(replaced_card_ref)
		if not battle_state.hand_layout_card_ids.has(replaced_card_ref):
			if removed_layout_index >= 0:
				battle_state.hand_layout_card_ids.insert(removed_layout_index, replaced_card_ref)
			else:
				battle_state.hand_layout_card_ids.append(replaced_card_ref)
	battle_state.hand_cards.erase(card_ref)
	battle_state.slot_card_ids[slot_index] = card_ref
	return {"success": true}

func resolve_turn(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary = {}
) -> Dictionary:
	var resolution: Dictionary = _rule_service.build_resolution(battle_state, card_definitions_by_id)
	if not _to_bool(resolution.get("success", false)):
		return resolution

	var turn_cost: int = _resolve_slot_cost(battle_state, card_definitions_by_id)
	var extra_cost: int = int(resolution.get("resistance_bonus_cost", 0))
	if battle_state.sanity < turn_cost + extra_cost:
		_mark_player_defeat(battle_state)
		var log_text: String = str(
			battle_texts.get(
				"battle.log.no_affordable_play_defeat",
				"鐞嗘櫤宸蹭笉瓒充互缁х画缁勫悎蹇冩垬锛屼綘鐨勫績闃插綋鍦烘簝鏁ｃ€?"
			)
		)
		if not log_text.is_empty():
			battle_state.append_log(log_text)
		return {
			"success": true,
			"battle_over": true,
			"is_player_victory": false,
			"is_player_defeat": true,
			"damage": 0
		}

	var damage: int = int(resolution.get("damage", 0))
	battle_state.enemy_hp = maxi(battle_state.enemy_hp - damage, 0)
	_move_slots_to_discard(battle_state)

	if battle_state.enemy_hp <= 0:
		battle_state.is_battle_over = true
		battle_state.is_player_victory = true
		battle_state.summary_text = "battle.victory"
		return {
			"success": true,
			"battle_over": true,
			"is_player_victory": true,
			"damage": damage,
			"reward_payload": _reward_service.build_reward_payload(battle_state)
		}

	if turn_cost > 0:
		battle_state.sanity = maxi(battle_state.sanity - turn_cost, 0)
	if extra_cost > 0:
		battle_state.sanity = maxi(battle_state.sanity - extra_cost, 0)

	var pollution_sanity_loss: int = _resolve_hand_pollution_sanity_loss(battle_state, card_definitions_by_id)
	battle_state.sanity = maxi(battle_state.sanity - battle_state.end_turn_recoil, 0)
	if pollution_sanity_loss > 0:
		battle_state.sanity = maxi(battle_state.sanity - pollution_sanity_loss, 0)
		battle_state.append_log(
			str(battle_texts.get("battle.log.pollution_recoil", "杂念反噬 {value} 点理智。")).format({
				"value": pollution_sanity_loss
			})
		)
	battle_state.turn_index += 1
	draw_to_hand(battle_state, 2)
	_apply_turn_start_pollution(battle_state, card_definitions_by_id, battle_texts)
	_refresh_terminal_state(battle_state, card_definitions_by_id, battle_texts)
	return {
		"success": true,
		"battle_over": battle_state.is_battle_over,
		"is_player_victory": battle_state.is_player_victory,
		"is_player_defeat": battle_state.is_player_defeat,
		"damage": damage
	}

func build_battle_view(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary
) -> Dictionary:
	var slot_views: Array[Dictionary] = []
	for slot_index: int in range(battle_state.slot_card_ids.size()):
		var card_ref: String = str(battle_state.slot_card_ids[slot_index])
		var card_name: String = _resolve_card_name(card_definitions_by_id, card_ref)
		var role_text: String = _resolve_slot_role_text(slot_index, battle_texts)
		var accepted_group: String = _resolve_slot_card_group(slot_index)
		slot_views.append({
			"slot_index": slot_index,
			"is_selected": slot_index == battle_state.selected_slot_index,
			"accepted_group": accepted_group,
			"role_text": role_text,
			"text": str(
				battle_texts.get(
					"battle.ui.slot_format",
					""
				)
			).format({
				"role": role_text,
				"card": card_name if not card_name.is_empty() else str(battle_texts.get("battle.ui.slot_empty", ""))
			})
		})

	var hand_views: Array[Dictionary] = []
	var layout_index_by_card_id: Dictionary = {}
	for layout_index: int in range(battle_state.hand_layout_card_ids.size()):
		layout_index_by_card_id[str(battle_state.hand_layout_card_ids[layout_index])] = layout_index
	for card_ref: String in battle_state.hand_layout_card_ids:
		if not battle_state.hand_cards.has(card_ref):
			continue
		var definition_id: String = resolve_card_definition_id(card_ref)
		var definition: Dictionary = Dictionary(card_definitions_by_id.get(definition_id, {}))
		var display_text: String = _resolve_card_name(card_definitions_by_id, card_ref)
		if str(definition.get("card_family", "")) == "pollution":
			display_text = "【杂念】%s" % display_text
		hand_views.append({
			"card_ref": card_ref,
			"card_id": definition_id,
			"layout_index": int(layout_index_by_card_id.get(card_ref, 0)),
			"text": display_text,
			"description": str(battle_texts.get(str(definition.get("text_key", "")), "")),
			"role_text": _resolve_card_role_text(definition, battle_texts),
			"card_group": str(definition.get("card_group", "")),
			"detail_text": _build_card_detail_text(
				definition,
				battle_state.enemy_mind_id,
				battle_state.enemy_display_name,
				battle_texts
			),
			"cost_text": str(battle_texts.get("battle.ui.card_cost", "")).format({
				"cost": int(definition.get("cost_sanity", 0))
			})
		})

	var hand_layout_slot_count: int = maxi(battle_state.hand_layout_card_ids.size(), hand_views.size())

	var preview: Dictionary = _rule_service.build_preview(battle_state, card_definitions_by_id)
	var weakness_lines: Array[String] = []
	for tag: String in battle_state.enemy_vulnerability_tags:
		var weakness_key: String = "battle.enemy.%s.vulnerability.%s" % [battle_state.enemy_mind_id, tag]
		var weakness_text: String = str(battle_texts.get(weakness_key, ""))
		if not weakness_text.is_empty():
			weakness_lines.append(weakness_text)
	var resistance_lines: Array[String] = []
	for tag: String in battle_state.enemy_resistance_tags:
		var resistance_key: String = "battle.enemy.%s.resistance.%s" % [battle_state.enemy_mind_id, tag]
		var resistance_text: String = str(battle_texts.get(resistance_key, ""))
		if not resistance_text.is_empty():
			resistance_lines.append(resistance_text)

	var title_text: String = str(battle_texts.get("battle.ui.title", ""))
	var status_text: String = str(battle_texts.get("battle.ui.turn_status", "")).format({
		"turn": battle_state.turn_index
	})
	var player_text: String = str(battle_texts.get("battle.ui.player_status", "")).format({
		"current": battle_state.sanity,
		"max": battle_state.max_sanity
	})
	var enemy_text: String = str(battle_texts.get("battle.ui.enemy_status", "")).format({
		"name": battle_state.enemy_display_name,
		"current": battle_state.enemy_hp,
		"max": battle_state.enemy_max_hp
	})
	var total_multiplier: float = float(preview.get("multiplier", 1.0)) * float(preview.get("vulnerability_factor", 1.0))
	var resistance_delta: int = int(preview.get("resistance_score_delta", 0))
	var calc_formula_text: String = str(battle_texts.get("battle.ui.calc_formula", "")).format({
		"base": int(preview.get("base_score", 0)),
		"multi": _format_multiplier(total_multiplier),
		"damage": int(preview.get("damage", 0))
	})
	if resistance_delta != 0:
		var adjust_key: String = "battle.ui.calc_adjust_plus" if resistance_delta > 0 else "battle.ui.calc_adjust_minus"
		var adjust_text: String = str(battle_texts.get(adjust_key, "")).format({
			"value": abs(resistance_delta)
		})
		calc_formula_text = str(battle_texts.get("battle.ui.calc_formula_adjusted", calc_formula_text)).format({
			"base": int(preview.get("base_score", 0)),
			"multi": _format_multiplier(total_multiplier),
			"adjust": adjust_text,
			"damage": int(preview.get("damage", 0))
		})

	return {
		"title_text": title_text,
		"status_text": status_text,
		"enemy_name_text": battle_state.enemy_display_name,
		"player_text": player_text,
		"enemy_text": enemy_text,
		"content_title_text": str(battle_texts.get("battle.ui.content_title", "当前主体")),
		"hint_title_text": str(battle_texts.get("battle.ui.hint_title", "当前提示")),
		"hint_text": _build_hint_text(battle_state, battle_texts),
		"guide_title_text": str(battle_texts.get("battle.ui.guide_title", "战术提示")),
		"guide_text": _build_strategy_text(battle_state, preview, card_definitions_by_id, battle_texts),
		"calc_title_text": str(battle_texts.get("battle.ui.calc_title", "")),
		"calc_formula_text": calc_formula_text,
		"draw_pile_text": str(battle_texts.get("battle.ui.draw_pile", "")).format({
			"count": battle_state.draw_pile.size()
		}),
		"discard_pile_text": str(battle_texts.get("battle.ui.discard_pile", "")).format({
			"count": battle_state.discard_pile.size()
		}),
		"weakness_title_text": str(battle_texts.get("battle.ui.weakness_title", "")),
		"weakness_text": "\n".join(weakness_lines),
		"resistance_title_text": str(battle_texts.get("battle.ui.resistance_title", "")),
		"resistance_text": "\n".join(resistance_lines),
		"slot_title_text": str(battle_texts.get("battle.ui.slot_title", "")),
		"hand_title_text": str(battle_texts.get("battle.ui.hand_title", "")),
		"log_title_text": str(battle_texts.get("battle.ui.log_title", "")),
		"action_title_text": str(battle_texts.get("battle.ui.action_title", "当前决策")),
		"drag_hint_text": str(battle_texts.get("battle.ui.drag_hint", "")),
		"slot_views": slot_views,
		"hand_views": hand_views,
		"hand_layout_slot_count": hand_layout_slot_count,
		"log_text": "\n".join(battle_state.log_entries),
		"can_redraw": not battle_state.is_battle_over and can_survive_redraw(battle_state),
		"can_resolve": not battle_state.is_battle_over and battle_state.sanity > 0 and _has_ready_slots(battle_state),
		"redraw_text": str(battle_texts.get("battle.ui.redraw", "")),
		"resolve_text": str(battle_texts.get("battle.ui.resolve", ""))
	}

func sync_terminal_state(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary = {}
) -> bool:
	_refresh_terminal_state(battle_state, card_definitions_by_id, battle_texts)
	return battle_state != null and battle_state.is_battle_over

func can_afford_redraw(battle_state: BattleState) -> bool:
	return battle_state.redraw_cost <= 0 or battle_state.sanity >= battle_state.redraw_cost

func can_survive_redraw(battle_state: BattleState) -> bool:
	if battle_state.redraw_cost <= 0:
		return true
	return battle_state.sanity > battle_state.redraw_cost

func can_afford_current_slots(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary
) -> bool:
	if not _has_ready_slots(battle_state):
		return false
	var resolution: Dictionary = _rule_service.build_resolution(battle_state, card_definitions_by_id)
	if not _to_bool(resolution.get("success", false)):
		return false
	var turn_cost: int = _resolve_slot_cost(battle_state, card_definitions_by_id)
	var extra_cost: int = int(resolution.get("resistance_bonus_cost", 0))
	return battle_state.sanity >= turn_cost + extra_cost

func has_any_affordable_play(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary
) -> bool:
	var available_base_ids: Array[String] = []
	var available_multi_ids: Array[String] = []
	for card_id: String in battle_state.slot_card_ids:
		if card_id.is_empty():
			continue
		_append_available_card(card_id, available_base_ids, available_multi_ids, card_definitions_by_id)
	for card_id: String in battle_state.hand_cards:
		if card_id.is_empty():
			continue
		_append_available_card(card_id, available_base_ids, available_multi_ids, card_definitions_by_id)

	for base_card_id: String in available_base_ids:
		var base_definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(base_card_id), {}))
		if base_definition.is_empty():
			continue
		var base_cost: int = int(base_definition.get("cost_sanity", 0))
		var extra_cost: int = _resolve_base_card_extra_cost(battle_state, base_definition)
		for multi_card_id: String in available_multi_ids:
			if multi_card_id == base_card_id:
				continue
			var multi_definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(multi_card_id), {}))
			if multi_definition.is_empty():
				continue
			var total_cost: int = base_cost + int(multi_definition.get("cost_sanity", 0)) + extra_cost
			if battle_state.sanity >= total_cost:
				return true
	return false

func is_softlocked(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary
) -> bool:
	if battle_state == null or battle_state.is_battle_over:
		return false
	return not has_any_affordable_play(battle_state, card_definitions_by_id) and not can_survive_redraw(battle_state)

func _resolve_card_role_text(card_definition: Dictionary, battle_texts: Dictionary) -> String:
	return str(
		battle_texts.get(
			"battle.ui.card_role.%s" % str(card_definition.get("card_group", "")),
			""
		)
	)

func _resolve_slot_role_text(slot_index: int, battle_texts: Dictionary) -> String:
	match slot_index:
		0:
			return str(battle_texts.get("battle.ui.card_role.02", "BASE"))
		1:
			return str(battle_texts.get("battle.ui.card_role.01", "MULTI"))
		_:
			return ""

func _resolve_slot_card_group(slot_index: int) -> String:
	match slot_index:
		0:
			return "02"
		1:
			return "01"
		_:
			return ""

func _resolve_slot_cost(battle_state: BattleState, card_definitions_by_id: Dictionary) -> int:
	var total_cost: int = 0
	for card_id: String in battle_state.slot_card_ids:
		if card_id.is_empty():
			continue
		var definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(card_id), {}))
		total_cost += int(definition.get("cost_sanity", 0))
	return total_cost

func _resolve_base_card_extra_cost(battle_state: BattleState, base_definition: Dictionary) -> int:
	var card_type: String = str(base_definition.get("card_type", ""))
	return int(Dictionary(battle_state.resistance_extra_cost_by_base_type).get(card_type, 0))

func _append_available_card(
	card_ref: String,
	available_base_ids: Array[String],
	available_multi_ids: Array[String],
	card_definitions_by_id: Dictionary
) -> void:
	var definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(card_ref), {}))
	match str(definition.get("card_group", "")):
		"02":
			available_base_ids.append(card_ref)
		"01":
			available_multi_ids.append(card_ref)

func _refresh_terminal_state(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary
) -> void:
	if battle_state == null or battle_state.is_battle_over:
		return
	if battle_state.sanity <= 0:
		_mark_player_defeat(battle_state)
		return
	if card_definitions_by_id.is_empty():
		return
	if is_softlocked(battle_state, card_definitions_by_id):
		_mark_player_defeat(battle_state)
		var log_text: String = str(
			battle_texts.get(
				"battle.log.no_affordable_play_defeat",
				"理智已不足以继续组合心战，你的心防当场溃散。"
			)
		)
		if not log_text.is_empty():
			battle_state.append_log(log_text)

func _mark_player_defeat(battle_state: BattleState) -> void:
	battle_state.is_battle_over = true
	battle_state.is_player_victory = false
	battle_state.is_player_defeat = true
	battle_state.summary_text = "battle.defeat"

func _build_card_detail_text(
	card_definition: Dictionary,
	enemy_mind_id: String,
	enemy_display_name: String,
	battle_texts: Dictionary
) -> String:
	var lines: Array[String] = []
	if str(card_definition.get("card_family", "")) == "pollution":
		lines.append(str(battle_texts.get("battle.ui.detail_pollution", "杂念牌")))
	var role_text: String = _resolve_card_role_text(card_definition, battle_texts)
	if not role_text.is_empty():
		lines.append(role_text)
	var cost: int = int(card_definition.get("cost_sanity", 0))
	lines.append(str(battle_texts.get("battle.ui.card_cost", "")).format({"cost": cost}))
	var base_score: int = int(card_definition.get("base_score", 0))
	if base_score > 0:
		lines.append(str(battle_texts.get("battle.ui.detail_base", "")).format({"value": base_score}))
	var multiplier_tags: Dictionary = Dictionary(card_definition.get("multiplier_tags", {}))
	if not multiplier_tags.is_empty():
		var multiplier_parts: Array[String] = []
		for key: String in multiplier_tags.keys():
			multiplier_parts.append("%s x%s" % [key, _format_multiplier(float(multiplier_tags[key]))])
		lines.append(str(battle_texts.get("battle.ui.detail_multi", "")).format({"value": ", ".join(multiplier_parts)}))
	var effect_tags: Array[String] = Array(card_definition.get("effect_tags", []), TYPE_STRING, "", null)
	if not effect_tags.is_empty():
		lines.append(str(battle_texts.get("battle.ui.detail_tags", "")).format({"value": ", ".join(effect_tags)}))
	var enemy_bonus_text: String = _build_enemy_specific_bonus_text(
		card_definition,
		enemy_mind_id,
		enemy_display_name,
		battle_texts
	)
	if not enemy_bonus_text.is_empty():
		lines.append(enemy_bonus_text)
	var description: String = str(battle_texts.get(str(card_definition.get("text_key", "")), ""))
	if not description.is_empty():
		lines.append("")
		lines.append(description)
	var pollution_kind: String = str(card_definition.get("pollution_kind", ""))
	if pollution_kind == "reverse_multi":
		lines.append(
			str(battle_texts.get("battle.ui.detail_reverse_multi", "常态倍率 x{normal}；命中反制情绪后翻转为 x{reverse}。")).format({
				"normal": _format_multiplier(float(card_definition.get("default_multiplier", 1.0))),
				"reverse": _format_multiplier(float(card_definition.get("reverse_multiplier", 1.0)))
			})
		)
	elif pollution_kind == "hand_aura":
		lines.append(
			str(battle_texts.get("battle.ui.detail_hand_aura", "留在手中时，所有 BASE 基础分 {value}。")).format({
				"value": int(card_definition.get("hand_base_score_delta", 0))
			})
		)
	var end_turn_sanity_loss: int = int(card_definition.get("end_turn_sanity_loss", 0))
	if end_turn_sanity_loss > 0:
		lines.append(
			str(battle_texts.get("battle.ui.detail_end_turn_loss", "回合结束仍在手中：理智 -{value}。")).format({
				"value": end_turn_sanity_loss
			})
		)
	return "\n".join(lines)

func _build_strategy_text(
	battle_state: BattleState,
	preview: Dictionary,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary
) -> String:
	var lines: Array[String] = []
	var pollution_lines: Array[String] = _build_pollution_counterplay_lines(
		battle_state,
		card_definitions_by_id,
		battle_texts
	)
	if bool(preview.get("is_ready", false)):
		lines.append_array(_build_preview_explanation_lines(preview, battle_state, card_definitions_by_id, battle_texts))
	else:
		lines.append(str(
			battle_texts.get(
				"battle.ui.guide_intro_slots",
				"先放入一张情绪牌做 BASE，再放入一张线索牌做 MULTI，面板会直接算出这一回合的伤害。"
			)
		))
	if not pollution_lines.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append(str(battle_texts.get("battle.ui.guide_counterplay_prefix", "手牌洞察：")))
		lines.append_array(pollution_lines)
	if lines.is_empty():
		lines.append(str(
			battle_texts.get(
				"battle.ui.guide_intro_fallback",
				"优先顺着敌人的破绽去接情绪，再留意杂念牌能不能被反过来利用。"
			)
		))
	return "\n".join(lines)

func _build_enemy_specific_bonus_text(
	card_definition: Dictionary,
	enemy_mind_id: String,
	enemy_display_name: String,
	battle_texts: Dictionary
) -> String:
	var bonuses: Dictionary = Dictionary(card_definition.get("enemy_mind_multiplier_bonuses", {}))
	if bonuses.is_empty():
		return ""
	if enemy_mind_id.is_empty() or not bonuses.has(enemy_mind_id):
		return ""
	return str(
		battle_texts.get(
			"battle.ui.detail_enemy_bonus_current",
			"当前对【{enemy}】额外触发 x{value}。"
		)
	).format({
		"enemy": enemy_display_name,
		"value": _format_multiplier(float(bonuses.get(enemy_mind_id, 1.0)))
	})

func _build_preview_explanation_lines(
	preview: Dictionary,
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary
) -> Array[String]:
	var lines: Array[String] = []
	var base_card_id: String = str(preview.get("base_card_id", ""))
	var multi_card_id: String = str(preview.get("multi_card_id", ""))
	var base_definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(base_card_id), {}))
	var multi_definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(multi_card_id), {}))
	var base_name: String = _resolve_card_name(card_definitions_by_id, base_card_id)
	var multi_name: String = _resolve_card_name(card_definitions_by_id, multi_card_id)
	lines.append(str(
		battle_texts.get(
			"battle.ui.guide_preview_summary",
			"当前组合：用【{base}】去接《{multi}》，预计造成 {damage} 点伤害。"
		)
	).format({
		"base": base_name,
		"multi": multi_name,
		"damage": int(preview.get("damage", 0))
	}))
	var multiplier: float = float(preview.get("multiplier", 1.0))
	var vulnerability_factor: float = float(preview.get("vulnerability_factor", 1.0))
	var resistance_delta: int = int(preview.get("resistance_score_delta", 0))
	var turn_cost: int = _resolve_slot_cost(battle_state, card_definitions_by_id)
	var extra_cost: int = int(preview.get("resistance_bonus_cost", 0))
	lines.append(str(
		battle_texts.get(
			"battle.ui.guide_preview_formula",
			"这一步会消耗理智 {cost}，倍率 x{multi}，敌方修正 x{vulnerability}。"
		)
	).format({
		"cost": turn_cost + extra_cost,
		"multi": _format_multiplier(multiplier),
		"vulnerability": _format_multiplier(vulnerability_factor)
	}))
	if str(multi_definition.get("pollution_kind", "")) == "reverse_multi":
		var reverse_tags: Array[String] = Array(multi_definition.get("reverse_base_tags", []), TYPE_STRING, "", null)
		var base_effect_tags: Array[String] = Array(base_definition.get("effect_tags", []), TYPE_STRING, "", null)
		var reverse_hit: bool = false
		for tag: String in reverse_tags:
			if base_effect_tags.has(tag):
				reverse_hit = true
				break
		var reverse_label: String = _join_effect_tag_labels(reverse_tags, battle_texts)
		if reverse_hit:
			lines.append(str(
				battle_texts.get(
					"battle.ui.guide_reverse_hit",
					"这张杂念已经被【{counter}】反制，倍率翻转成 x{value}。"
				)
			).format({
				"counter": reverse_label,
				"value": _format_multiplier(float(multi_definition.get("reverse_multiplier", 1.0)))
			}))
		else:
			lines.append(str(
				battle_texts.get(
					"battle.ui.guide_reverse_miss",
					"这张杂念还没被反制；换成【{counter}】去接，倍率会翻到 x{value}。"
				)
			).format({
				"counter": reverse_label,
				"value": _format_multiplier(float(multi_definition.get("reverse_multiplier", 1.0)))
			}))
	if resistance_delta != 0 or extra_cost > 0:
		lines.append(str(
			battle_texts.get(
				"battle.ui.guide_resistance",
				"这一步还会吃到敌方抗性：额外理智 {extra_cost}，伤害修正 {damage_adjust}。"
			)
		).format({
			"extra_cost": extra_cost,
			"damage_adjust": resistance_delta
		}))
	var enemy_bonus_factor: float = _resolve_enemy_specific_multiplier_factor(battle_state, multi_definition)
	if enemy_bonus_factor > 1.0:
		lines.append(str(
			battle_texts.get(
				"battle.ui.guide_enemy_bonus_applied",
				"这张牌对【{enemy}】触发了额外倍率 x{value}。"
			)
		).format({
			"enemy": battle_state.enemy_display_name,
			"value": _format_multiplier(enemy_bonus_factor)
		}))
	return lines

func _resolve_enemy_specific_multiplier_factor(
	battle_state: BattleState,
	card_definition: Dictionary
) -> float:
	var bonuses: Dictionary = Dictionary(card_definition.get("enemy_mind_multiplier_bonuses", {}))
	if bonuses.is_empty():
		return 1.0
	var enemy_mind_id: String = str(battle_state.enemy_mind_id, "")
	if enemy_mind_id.is_empty() or not bonuses.has(enemy_mind_id):
		return 1.0
	return float(bonuses.get(enemy_mind_id, 1.0))

func _build_pollution_counterplay_lines(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary
) -> Array[String]:
	var lines: Array[String] = []
	for card_id: String in battle_state.hand_cards:
		var definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(card_id), {}))
		if str(definition.get("card_family", "")) != "pollution":
			continue
		var pollution_kind: String = str(definition.get("pollution_kind", ""))
		var card_name: String = _resolve_card_name(card_definitions_by_id, card_id)
		if pollution_kind == "reverse_multi":
			var reverse_tags: Array[String] = Array(definition.get("reverse_base_tags", []), TYPE_STRING, "", null)
			lines.append(str(
				battle_texts.get(
					"battle.ui.guide_pollution_reverse",
					"《{card}》平时只有 x{normal}；用【{counter}】去接，就能翻成 x{reverse}。"
				)
			).format({
				"card": card_name,
				"normal": _format_multiplier(float(definition.get("default_multiplier", 1.0))),
				"counter": _join_effect_tag_labels(reverse_tags, battle_texts),
				"reverse": _format_multiplier(float(definition.get("reverse_multiplier", 1.0)))
			}))
		elif pollution_kind == "hand_aura":
			lines.append(str(
				battle_texts.get(
					"battle.ui.guide_pollution_aura",
					"《{card}》留在手里会改写你的 BASE 值；这回合不想吃罚，就尽快处理掉它。"
				)
			).format({
				"card": card_name
			}))
	return lines

func _join_effect_tag_labels(tags: Array[String], battle_texts: Dictionary) -> String:
	var labels: Array[String] = []
	for tag: String in tags:
		var label: String = _resolve_effect_tag_label(tag, battle_texts)
		if not label.is_empty():
			labels.append(label)
	if labels.is_empty():
		return str(battle_texts.get("battle.ui.unknown_counter", "对应情绪"))
	return " / ".join(labels)

func _resolve_effect_tag_label(tag: String, battle_texts: Dictionary) -> String:
	match tag:
		"01":
			return str(battle_texts.get("battle.ui.effect_tag.01", "贪"))
		"02":
			return str(battle_texts.get("battle.ui.effect_tag.02", "嗔"))
		"03":
			return str(battle_texts.get("battle.ui.effect_tag.03", "痴"))
		"04":
			return str(battle_texts.get("battle.ui.effect_tag.04", "敢赌命"))
		_:
			return tag

func _apply_turn_start_pollution(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary
) -> void:
	if battle_state.last_pollution_turn_applied == battle_state.turn_index:
		return
	var intent_definition: Dictionary = _resolve_turn_intent_definition(battle_state)
	battle_state.current_intent_card_ids = Array(intent_definition.get("inject_card_ids", []), TYPE_STRING, "", null)
	battle_state.current_intent_text = str(
		battle_texts.get(
			str(intent_definition.get("intent_text_key", "")),
			str(battle_texts.get("battle.ui.drag_hint", ""))
		)
	)
	for card_id: String in battle_state.current_intent_card_ids:
		if not card_definitions_by_id.has(card_id):
			continue
		var card_ref: String = _create_card_ref(battle_state, card_id)
		battle_state.hand_cards.append(card_ref)
		battle_state.hand_layout_card_ids.append(card_ref)
		battle_state.append_log(
			str(battle_texts.get("battle.log.pollution_injected", "敌人的反制将【{card}】塞进了你的手牌。")).format({
				"card": _resolve_card_name(card_definitions_by_id, card_id)
			})
		)
	battle_state.last_pollution_turn_applied = battle_state.turn_index

func _resolve_turn_intent_definition(battle_state: BattleState) -> Dictionary:
	if battle_state.pollution_profile.is_empty():
		return {}
	var threshold_intents: Array[Dictionary] = Array(
		Dictionary(battle_state.pollution_profile).get("threshold_intents", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	threshold_intents.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("hp_lte", 0)) > int(b.get("hp_lte", 0))
	)
	for threshold_intent: Dictionary in threshold_intents:
		var threshold_id: String = str(threshold_intent.get("id", ""))
		if threshold_id.is_empty():
			continue
		if battle_state.triggered_pollution_threshold_ids.has(threshold_id):
			continue
		if battle_state.enemy_hp > int(threshold_intent.get("hp_lte", -1)):
			continue
		battle_state.triggered_pollution_threshold_ids.append(threshold_id)
		return threshold_intent
	var turn_intents: Array[Dictionary] = Array(
		Dictionary(battle_state.pollution_profile).get("turn_intents", []),
		TYPE_DICTIONARY,
		"",
		null
	)
	if turn_intents.is_empty():
		return {}
	var intent_index: int = maxi(battle_state.turn_index - 1, 0) % turn_intents.size()
	return turn_intents[intent_index]

func _resolve_hand_pollution_sanity_loss(
	battle_state: BattleState,
	card_definitions_by_id: Dictionary
) -> int:
	var total_loss: int = 0
	for card_id: String in battle_state.hand_cards:
		var definition: Dictionary = Dictionary(card_definitions_by_id.get(resolve_card_definition_id(card_id), {}))
		if str(definition.get("card_family", "")) != "pollution":
			continue
		total_loss += int(definition.get("end_turn_sanity_loss", 0))
	return total_loss

func _build_hint_text(battle_state: BattleState, battle_texts: Dictionary) -> String:
	var lines: Array[String] = []
	if not battle_state.current_intent_text.is_empty():
		lines.append(
			str(battle_texts.get("battle.ui.intent_prefix", "敌方意图：{value}")).format({
				"value": battle_state.current_intent_text
			})
		)
	var drag_hint: String = str(battle_texts.get("battle.ui.drag_hint", ""))
	if not drag_hint.is_empty():
		lines.append(drag_hint)
	return "\n".join(lines)

func _resolve_player_max_sanity(battle_definition: Dictionary, player_level: int) -> int:
	var base_sanity: int = int(battle_definition.get("max_sanity", 0))
	var level_bonus: int = maxi(player_level - 1, 0)
	return max(base_sanity + level_bonus, 1)

func _format_multiplier(value: float) -> String:
	return "%0.1f" % value

func _reshuffle_discard_into_draw_pile(battle_state: BattleState) -> void:
	while not battle_state.discard_pile.is_empty():
		battle_state.draw_pile.append(battle_state.discard_pile.pop_back())
	_shuffle_string_array(battle_state.draw_pile)

func _move_slots_to_discard(battle_state: BattleState) -> void:
	for card_id: String in battle_state.slot_card_ids:
		if card_id.is_empty():
			continue
		battle_state.discard_pile.append(card_id)
	battle_state.reset_slots()
	_reset_hand_layout_order(battle_state)

func _resolve_card_name(card_definitions_by_id: Dictionary, card_id: String) -> String:
	if card_id.is_empty():
		return ""
	var definition_id: String = resolve_card_definition_id(card_id)
	return str(Dictionary(card_definitions_by_id.get(definition_id, {})).get("display_name", definition_id))

func _has_ready_slots(battle_state: BattleState) -> bool:
	if battle_state.slot_card_ids.size() < 2:
		return false
	for card_id: String in battle_state.slot_card_ids:
		if card_id.is_empty():
			return false
	return true

func _shuffle_string_array(values: Array[String]) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.randomize()
	for index: int in range(values.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		var current_value: String = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current_value

func _reset_hand_layout_order(battle_state: BattleState) -> void:
	battle_state.hand_layout_card_ids = battle_state.hand_cards.duplicate()

func _create_card_ref(battle_state: BattleState, definition_id: String) -> String:
	var card_ref: String = "%s#%d" % [definition_id, battle_state.next_card_instance_seq]
	battle_state.next_card_instance_seq += 1
	return card_ref

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
