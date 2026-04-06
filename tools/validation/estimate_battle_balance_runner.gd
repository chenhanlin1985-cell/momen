extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const BATTLE_SERVICE_SCRIPT := preload("res://systems/battle/battle_service.gd")
const BATTLE_RULE_SERVICE_SCRIPT := preload("res://systems/battle/battle_rule_service.gd")

const BATTLE_IDS: Array[String] = ["9101", "9201", "9301", "9401", "9501"]
const RUNS_PER_BATTLE: int = 200
const MAX_TURNS: int = 30
const STRATEGIES: Array[String] = ["random", "greedy"]

var _repository: ContentRepository
var _battle_service: BattleService
var _rule_service: BattleRuleService
var _battle_texts: Dictionary
var _card_definitions_by_id: Dictionary = {}

func _initialize() -> void:
	_repository = CONTENT_REPOSITORY_SCRIPT.new()
	_battle_service = BATTLE_SERVICE_SCRIPT.new()
	_rule_service = BATTLE_RULE_SERVICE_SCRIPT.new()
	_battle_texts = _repository.get_battle_texts()
	for card_definition: Dictionary in _repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		_card_definitions_by_id[card_id] = card_definition

	for battle_id: String in BATTLE_IDS:
		for strategy_name: String in STRATEGIES:
			_estimate_battle(battle_id, strategy_name)

	quit()

func _estimate_battle(battle_id: String, strategy_name: String) -> void:
	var wins: int = 0
	var losses: int = 0
	var total_turns: int = 0
	var deckout_losses: int = 0
	var redraws_used: int = 0
	for _run_index: int in RUNS_PER_BATTLE:
		var battle_state: BattleState = _create_battle_state(battle_id)
		var outcome: Dictionary = _simulate_battle(battle_state, strategy_name)
		if bool(outcome.get("victory", false)):
			wins += 1
		else:
			losses += 1
			if bool(outcome.get("softlock_loss", false)):
				deckout_losses += 1
		total_turns += int(outcome.get("turns", 0))
		redraws_used += int(outcome.get("redraws", 0))

	var win_rate: float = float(wins) / float(RUNS_PER_BATTLE)
	var avg_turns: float = float(total_turns) / float(RUNS_PER_BATTLE)
	var avg_redraws: float = float(redraws_used) / float(RUNS_PER_BATTLE)
	print("%s\tstrategy=%s\twins=%d\tlosses=%d\twin_rate=%.3f\tavg_turns=%.2f\tavg_redraws=%.2f\tsoftlock_losses=%d" % [
		battle_id,
		strategy_name,
		wins,
		losses,
		win_rate,
		avg_turns,
		avg_redraws,
		deckout_losses
	])

func _create_battle_state(battle_id: String) -> BattleState:
	var battle_definition: Dictionary = _repository.get_battle_definition(battle_id)
	var enemy_definition: Dictionary = _repository.get_battle_enemy_mind_definition(
		str(battle_definition.get("enemy_mind_id", ""))
	)
	var pollution_profile_definition: Dictionary = _repository.get_battle_pollution_profile_definition(
		str(enemy_definition.get("counter_profile_id", ""))
	)
	return _battle_service.create_battle_state(
		battle_definition,
		enemy_definition,
		pollution_profile_definition,
		1,
		[],
		[],
		_card_definitions_by_id,
		_battle_texts
	)

func _simulate_battle(battle_state: BattleState, strategy_name: String) -> Dictionary:
	var turns: int = 0
	var redraws: int = 0
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("%s:%s:%s" % [battle_state.battle_id, strategy_name, Time.get_ticks_usec()])
	while not battle_state.is_battle_over and turns < MAX_TURNS:
		var best_play: Dictionary = _find_affordable_play(battle_state, strategy_name, rng)
		if best_play.is_empty():
			if _battle_service.can_afford_redraw(battle_state):
				var redraw_result: Dictionary = _battle_service.redraw_hand(
					battle_state,
					battle_state.hand_cards.size(),
					_card_definitions_by_id,
					_battle_texts
				)
				redraws += 1
				if not bool(redraw_result.get("success", false)) or battle_state.is_battle_over:
					break
				continue
			_force_terminal_check(battle_state)
			break

		battle_state.reset_slots()
		battle_state.slot_card_ids[0] = str(best_play.get("base_id", ""))
		battle_state.slot_card_ids[1] = str(best_play.get("multi_id", ""))
		var resolve_result: Dictionary = _battle_service.resolve_turn(
			battle_state,
			_card_definitions_by_id,
			_battle_texts
		)
		turns += 1
		if not bool(resolve_result.get("success", false)) and not battle_state.is_battle_over:
			_force_terminal_check(battle_state)
			break

	return {
		"victory": battle_state.is_player_victory,
		"turns": max(turns, battle_state.turn_index - 1),
		"redraws": redraws,
		"softlock_loss": battle_state.is_player_defeat and not battle_state.is_player_victory
	}

func _find_affordable_play(
	battle_state: BattleState,
	strategy_name: String,
	rng: RandomNumberGenerator
) -> Dictionary:
	var base_ids: Array[String] = []
	var multi_ids: Array[String] = []
	for card_id: String in battle_state.hand_cards:
		var definition: Dictionary = Dictionary(_card_definitions_by_id.get(card_id, {}))
		match str(definition.get("card_group", "")):
			"02":
				base_ids.append(card_id)
			"01":
				multi_ids.append(card_id)

	var affordable_plays: Array[Dictionary] = []
	for base_id: String in base_ids:
		for multi_id: String in multi_ids:
			var simulation_state: BattleState = BattleState.from_dict(battle_state.to_dict())
			simulation_state.slot_card_ids[0] = base_id
			simulation_state.slot_card_ids[1] = multi_id
			var resolution: Dictionary = _rule_service.build_resolution(simulation_state, _card_definitions_by_id)
			if not bool(resolution.get("success", false)):
				continue
			var base_definition: Dictionary = Dictionary(_card_definitions_by_id.get(base_id, {}))
			var multi_definition: Dictionary = Dictionary(_card_definitions_by_id.get(multi_id, {}))
			var total_cost: int = int(base_definition.get("cost_sanity", 0)) + int(multi_definition.get("cost_sanity", 0)) + int(resolution.get("resistance_bonus_cost", 0))
			if battle_state.sanity < total_cost:
				continue
			affordable_plays.append({
				"base_id": base_id,
				"multi_id": multi_id,
				"score": _score_play(base_definition, multi_definition, resolution, total_cost)
			})
	if affordable_plays.is_empty():
		return {}
	if strategy_name == "random":
		return affordable_plays[rng.randi_range(0, affordable_plays.size() - 1)]
	affordable_plays.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("score", -INF)) > float(b.get("score", -INF))
	)
	return affordable_plays[0]

func _score_play(base_definition: Dictionary, multi_definition: Dictionary, resolution: Dictionary, total_cost: int) -> float:
	var damage: float = float(resolution.get("damage", 0))
	var score: float = damage * 10.0 - float(total_cost) * 1.5
	if str(multi_definition.get("card_family", "")) == "pollution":
		score += 4.0
		if str(multi_definition.get("pollution_kind", "")) == "reverse_multi":
			var reverse_tags: Array[String] = Array(multi_definition.get("reverse_base_tags", []), TYPE_STRING, "", null)
			var base_effect_tags: Array[String] = Array(base_definition.get("effect_tags", []), TYPE_STRING, "", null)
			for tag: String in reverse_tags:
				if base_effect_tags.has(tag):
					score += 8.0
					break
	return score

func _force_terminal_check(battle_state: BattleState) -> void:
	battle_state.reset_slots()
	var base_card_id: String = _find_first_card_in_hand_by_group(battle_state, "02")
	var multi_card_id: String = _find_first_card_in_hand_by_group(battle_state, "01")
	if base_card_id.is_empty() or multi_card_id.is_empty():
		battle_state.is_battle_over = true
		battle_state.is_player_defeat = true
		return
	battle_state.slot_card_ids[0] = base_card_id
	battle_state.slot_card_ids[1] = multi_card_id
	_battle_service.resolve_turn(battle_state, _card_definitions_by_id, _battle_texts)

func _find_first_card_in_hand_by_group(battle_state: BattleState, group_id: String) -> String:
	for card_id: String in battle_state.hand_cards:
		var definition: Dictionary = Dictionary(_card_definitions_by_id.get(card_id, {}))
		if str(definition.get("card_group", "")) == group_id:
			return card_id
	return ""
