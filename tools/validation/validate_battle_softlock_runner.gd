extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const BATTLE_SERVICE_SCRIPT := preload("res://systems/battle/battle_service.gd")

const BATTLE_IDS: Array[String] = ["9101", "9201", "9301", "9401", "9501"]

func _initialize() -> void:
	var repository: ContentRepository = CONTENT_REPOSITORY_SCRIPT.new()
	var battle_service: BattleService = BATTLE_SERVICE_SCRIPT.new()
	var battle_texts: Dictionary = repository.get_battle_texts()
	var card_definitions_by_id: Dictionary = {}
	for card_definition: Dictionary in repository.get_battle_card_definitions():
		var card_id: String = str(card_definition.get("id", ""))
		if card_id.is_empty():
			continue
		card_definitions_by_id[card_id] = card_definition

	for battle_id: String in BATTLE_IDS:
		_validate_zero_sanity_softlock_resolution(
			battle_service,
			repository,
			card_definitions_by_id,
			battle_texts,
			battle_id
		)
		_validate_redraw_to_zero_is_terminal(
			battle_service,
			repository,
			card_definitions_by_id,
			battle_texts,
			battle_id
		)

	print("validate_battle_softlock_runner: OK")
	quit()

func _create_battle_state(
	battle_service: BattleService,
	repository: ContentRepository,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary,
	battle_id: String
) -> BattleState:
	var battle_definition: Dictionary = repository.get_battle_definition(battle_id)
	var enemy_definition: Dictionary = repository.get_battle_enemy_mind_definition(
		str(battle_definition.get("enemy_mind_id", ""))
	)
	var pollution_definition: Dictionary = repository.get_battle_pollution_profile_definition(
		str(enemy_definition.get("counter_profile_id", ""))
	)
	return battle_service.create_battle_state(
		battle_definition,
		enemy_definition,
		pollution_definition,
		1,
		[],
		[],
		card_definitions_by_id,
		battle_texts
	)

func _validate_zero_sanity_softlock_resolution(
	battle_service: BattleService,
	repository: ContentRepository,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary,
	battle_id: String
) -> void:
	var battle_state: BattleState = _create_battle_state(
		battle_service,
		repository,
		card_definitions_by_id,
		battle_texts,
		battle_id
	)
	battle_state.sanity = 0
	battle_state.hand_cards = ["9111", "9121"]
	battle_state.slot_card_ids[0] = "9121"
	battle_state.slot_card_ids[1] = "9111"

	var battle_view: Dictionary = battle_service.build_battle_view(
		battle_state,
		card_definitions_by_id,
		battle_texts
	)
	if bool(battle_view.get("can_resolve", true)) or bool(battle_view.get("can_redraw", true)):
		push_error("%s should disable both resolve and redraw at zero sanity." % battle_id)
		quit(1)
		return

	var result: Dictionary = battle_service.resolve_turn(
		battle_state,
		card_definitions_by_id,
		battle_texts
	)
	if not bool(result.get("battle_over", false)) or not battle_state.is_player_defeat:
		push_error("%s should convert zero-sanity resolve into a clean defeat." % battle_id)
		quit(1)
		return

func _validate_redraw_to_zero_is_terminal(
	battle_service: BattleService,
	repository: ContentRepository,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary,
	battle_id: String
) -> void:
	var battle_state: BattleState = _create_battle_state(
		battle_service,
		repository,
		card_definitions_by_id,
		battle_texts,
		battle_id
	)
	battle_state.sanity = 1
	var redraw_result: Dictionary = battle_service.redraw_hand(
		battle_state,
		battle_state.hand_cards.size(),
		card_definitions_by_id,
		battle_texts
	)
	if not bool(redraw_result.get("success", false)):
		push_error("%s redraw at 1 sanity should still execute before terminal evaluation." % battle_id)
		quit(1)
		return
	if not battle_state.is_battle_over or not battle_state.is_player_defeat:
		push_error("%s redrawing down to zero sanity should immediately end in defeat." % battle_id)
		quit(1)
		return
