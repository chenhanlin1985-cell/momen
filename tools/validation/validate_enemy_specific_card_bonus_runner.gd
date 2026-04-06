extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const BATTLE_SERVICE_SCRIPT := preload("res://systems/battle/battle_service.gd")
const BATTLE_RULE_SERVICE_SCRIPT := preload("res://systems/battle/battle_rule_service.gd")

func _initialize() -> void:
	var content_repository = CONTENT_REPOSITORY_SCRIPT.new()
	var battle_service = BATTLE_SERVICE_SCRIPT.new()
	var battle_rule_service = BATTLE_RULE_SERVICE_SCRIPT.new()

	var card_lookup: Dictionary = {}
	for card_definition: Dictionary in content_repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		card_lookup[card_id] = card_definition

	var wang_state = _create_state("9201", content_repository, battle_service, card_lookup)
	var patrol_state = _create_state("9301", content_repository, battle_service, card_lookup)
	if wang_state == null or patrol_state == null:
		push_error("validate_enemy_specific_card_bonus_runner: failed to create battle state")
		quit(1)
		return

	wang_state.slot_card_ids[0] = _find_card_ref_by_definition_id(wang_state, battle_service, "9122")
	wang_state.slot_card_ids[1] = _find_card_ref_by_definition_id(wang_state, battle_service, "9131")
	patrol_state.slot_card_ids[0] = _find_card_ref_by_definition_id(patrol_state, battle_service, "9122")
	patrol_state.slot_card_ids[1] = _find_card_ref_by_definition_id(patrol_state, battle_service, "9131")
	if wang_state.slot_card_ids[0].is_empty() or wang_state.slot_card_ids[1].is_empty():
		push_error("validate_enemy_specific_card_bonus_runner: failed to find required cards in Wang state")
		quit(1)
		return
	if patrol_state.slot_card_ids[0].is_empty() or patrol_state.slot_card_ids[1].is_empty():
		push_error("validate_enemy_specific_card_bonus_runner: failed to find required cards in patrol state")
		quit(1)
		return

	var wang_resolution: Dictionary = battle_rule_service.build_resolution(wang_state, card_lookup)
	var patrol_resolution: Dictionary = battle_rule_service.build_resolution(patrol_state, card_lookup)

	if not bool(wang_resolution.get("success", false)) or not bool(patrol_resolution.get("success", false)):
		push_error("validate_enemy_specific_card_bonus_runner: resolution failed")
		quit(1)
		return

	var wang_multiplier: float = float(wang_resolution.get("multiplier", 1.0))
	var patrol_multiplier: float = float(patrol_resolution.get("multiplier", 1.0))
	if wang_multiplier <= patrol_multiplier:
		push_error(
			"validate_enemy_specific_card_bonus_runner: expected Wang multiplier > patrol multiplier, got %s <= %s"
			% [wang_multiplier, patrol_multiplier]
		)
		quit(1)
		return

	print("validate_enemy_specific_card_bonus_runner: OK")
	quit()

func _create_state(
	battle_id: String,
	content_repository,
	battle_service,
	card_lookup: Dictionary
):
	var battle_definition: Dictionary = content_repository.get_battle_definition(battle_id)
	var enemy_mind_definition: Dictionary = content_repository.get_battle_enemy_mind_definition(
		str(battle_definition.get("enemy_mind_id", ""))
	)
	var pollution_profile_definition: Dictionary = content_repository.get_battle_pollution_profile_definition(
		str(enemy_mind_definition.get("counter_profile_id", ""))
	)
	return battle_service.create_battle_state(
		battle_definition,
		enemy_mind_definition,
		pollution_profile_definition,
		1,
		Array(["9131", "9122"], TYPE_STRING, "", null),
		Array([], TYPE_STRING, "", null),
		card_lookup,
		content_repository.get_battle_texts()
	)

func _find_card_ref_by_definition_id(battle_state, battle_service, definition_id: String) -> String:
	for card_ref: String in battle_state.hand_cards:
		if battle_service.resolve_card_definition_id(card_ref) == definition_id:
			return card_ref
	for card_ref: String in battle_state.draw_pile:
		if battle_service.resolve_card_definition_id(card_ref) == definition_id:
			return card_ref
	return ""
