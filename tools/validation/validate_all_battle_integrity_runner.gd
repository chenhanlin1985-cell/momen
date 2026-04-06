extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")
const BATTLE_SERVICE_SCRIPT := preload("res://systems/battle/battle_service.gd")

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

	var failures: Array[String] = []
	for battle_definition: Dictionary in repository.get_battle_definitions():
		_validate_battle_definition(
			battle_service,
			repository,
			card_definitions_by_id,
			battle_texts,
			battle_definition,
			failures
		)

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_all_battle_integrity_runner: OK")
	quit()

func _validate_battle_definition(
	battle_service: BattleService,
	repository: ContentRepository,
	card_definitions_by_id: Dictionary,
	battle_texts: Dictionary,
	battle_definition: Dictionary,
	failures: Array[String]
) -> void:
	var battle_id: String = str(battle_definition.get("id", ""))
	var enemy_id: String = str(battle_definition.get("enemy_mind_id", ""))
	var enemy_definition: Dictionary = repository.get_battle_enemy_mind_definition(enemy_id)
	if enemy_definition.is_empty():
		failures.append("%s missing enemy mind definition %s" % [battle_id, enemy_id])
		return

	var success_event_id: String = str(battle_definition.get("result_event_id_success", ""))
	var failure_event_id: String = str(battle_definition.get("result_event_id_failure", ""))
	if repository.get_story_event_definition("default_run", success_event_id).is_empty():
		failures.append("%s missing success event %s" % [battle_id, success_event_id])
	if repository.get_story_event_definition("default_run", failure_event_id).is_empty():
		failures.append("%s missing failure event %s" % [battle_id, failure_event_id])

	var starter_deck: Array[String] = Array(battle_definition.get("starter_deck", []), TYPE_STRING, "", null)
	var has_base: bool = false
	var has_multi: bool = false
	for card_id: String in starter_deck:
		var card_definition: Dictionary = Dictionary(card_definitions_by_id.get(card_id, {}))
		if card_definition.is_empty():
			failures.append("%s starter deck missing card %s" % [battle_id, card_id])
			continue
		match str(card_definition.get("card_group", "")):
			"02":
				has_base = true
			"01":
				has_multi = true
	if not has_base or not has_multi:
		failures.append("%s starter deck must contain both base and multi cards" % battle_id)

	if int(battle_definition.get("initial_hand_size", 0)) < 2:
		failures.append("%s initial hand size must be at least 2" % battle_id)

	var pollution_profile: Dictionary = repository.get_battle_pollution_profile_definition(
		str(enemy_definition.get("counter_profile_id", ""))
	)
	var battle_state: BattleState = battle_service.create_battle_state(
		battle_definition,
		enemy_definition,
		pollution_profile,
		1,
		[],
		[],
		card_definitions_by_id,
		battle_texts
	)
	if battle_state.hand_cards.size() < 2:
		failures.append("%s initial hand contains fewer than 2 cards" % battle_id)
		return

	if not battle_service.has_any_affordable_play(battle_state, card_definitions_by_id) and not battle_service.can_survive_redraw(battle_state):
		failures.append("%s initial battle state starts in unwinnable softlock" % battle_id)

	battle_state.sanity = 0
	battle_service.sync_terminal_state(battle_state, card_definitions_by_id, battle_texts)
	if not battle_state.is_battle_over or not battle_state.is_player_defeat:
		failures.append("%s zero-sanity state should terminate as defeat" % battle_id)
