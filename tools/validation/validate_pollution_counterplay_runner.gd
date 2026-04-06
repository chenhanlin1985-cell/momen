extends SceneTree

const CONTENT_REPOSITORY_SCRIPT := preload("res://systems/content/content_repository.gd")

func _initialize() -> void:
	var repository: ContentRepository = CONTENT_REPOSITORY_SCRIPT.new()
	var failures: Array[String] = []

	for card_definition: Dictionary in repository.get_battle_card_definitions():
		if str(card_definition.get("card_family", "")) != "pollution":
			continue
		var card_id: String = str(card_definition.get("id", ""))
		var pollution_kind: String = str(card_definition.get("pollution_kind", ""))
		match pollution_kind:
			"reverse_multi":
				var reverse_tags: Array[String] = Array(card_definition.get("reverse_base_tags", []), TYPE_STRING, "", null)
				if reverse_tags.is_empty():
					failures.append("%s reverse_multi pollution lacks reverse_base_tags" % card_id)
				if float(card_definition.get("reverse_multiplier", 1.0)) <= float(card_definition.get("default_multiplier", 1.0)):
					failures.append("%s reverse_multi pollution lacks a real upside window" % card_id)
			"hand_aura":
				if abs(int(card_definition.get("hand_base_score_delta", 0))) > 1:
					failures.append("%s hand_aura pollution penalty exceeds soft limit without explicit counterplay" % card_id)
			_:
				failures.append("%s uses unknown pollution kind %s" % [card_id, pollution_kind])

	if not failures.is_empty():
		for failure: String in failures:
			push_error(failure)
		quit(1)
		return

	print("validate_pollution_counterplay_runner: OK")
	quit()
