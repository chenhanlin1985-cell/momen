class_name MainGameViewModel
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")
static func build(
	run_state: RunState,
	current_location: Dictionary,
	present_npcs: Array[Dictionary],
	visible_actions: Array[Dictionary],
	current_event: Dictionary,
	event_hints: Array[String],
	current_event_option_views: Array[Dictionary],
	location_mount_traces: Array[Dictionary],
	npc_state_event_traces: Array[Dictionary],
	attribute_roles: Dictionary
) -> Dictionary:
	var level: int = max(int(run_state.player_state.resources.get("level", 1)), 1)
	var experience: int = max(int(run_state.player_state.resources.get("experience", 0)), 0)
	var experience_required: int = 4 + max(level - 1, 0) * 2
	var main_goal_lines: Array[String] = []
	var task_lines: Array[String] = []
	for goal: GoalProgress in run_state.active_goals:
		if goal.failed:
			continue
		var target_lines: Array[String] = main_goal_lines if goal.goal_type == "main_goal" else task_lines
		if goal.goal_type == "main_goal":
			target_lines.append(goal.display_name)
			if not goal.description.is_empty():
				target_lines.append(goal.description)
			continue
		if goal.completed:
			continue
		target_lines.append("• %s" % goal.display_name)
		if not goal.description.is_empty():
			target_lines.append("  %s" % goal.description)

	var goal_text_lines: Array[String] = []
	if not main_goal_lines.is_empty():
		goal_text_lines.append(GAME_TEXT.text("view_model.goal_sections.main", "主目标"))
		goal_text_lines.append_array(main_goal_lines)
	if not task_lines.is_empty():
		if not goal_text_lines.is_empty():
			goal_text_lines.append("")
		goal_text_lines.append(GAME_TEXT.text("view_model.goal_sections.tasks", "当前任务"))
		goal_text_lines.append_array(task_lines)

	var npc_lines: Array[String] = []
	for npc_definition: Dictionary in present_npcs:
		npc_lines.append(
			GAME_TEXT.format_text(
				"view_model.npc_relation_line",
				[
					str(npc_definition.get("display_name", npc_definition.get("id", ""))),
					int(npc_definition.get("favor", 0)),
					int(npc_definition.get("alert", 0))
				]
			)
		)

	var action_lines: Array[String] = []
	for action_definition: Dictionary in visible_actions:
		action_lines.append(str(action_definition.get("display_name", action_definition.get("id", ""))))

	var event_title: String = ""
	var event_body: String = ""
	var event_text: String = ""
	var event_speaker_text: String = ""
	var event_portrait_text: String = ""
	var event_type_key: String = ""
	var event_type_text: String = ""
	var event_type_description_text: String = ""
	var event_type_short_text: String = ""
	var has_battle: bool = run_state.current_battle_state != null
	var is_dialogue_event: bool = false
	if not current_event.is_empty():
		is_dialogue_event = str(current_event.get("presentation_type", "standard_event")) == "dialogue_event"
		event_title = str(current_event.get("title", GAME_TEXT.text("view_model.current_event_title")))
		event_body = str(current_event.get("description", ""))
		if _to_bool(current_event.get("awaiting_continue", false)):
			event_body = str(current_event.get("result_text", event_body))
		event_speaker_text = str(current_event.get("speaker_display_name", event_title))
		event_portrait_text = str(
			current_event.get(
				"speaker_portrait_placeholder",
				GAME_TEXT.format_text("view_model.portrait_placeholder", [event_speaker_text])
			)
		)
		event_text = "%s\n%s" % [event_title, event_body]
		var event_type_data: Dictionary = _resolve_gameplay_event_type(current_event, has_battle, run_state)
		event_type_key = str(event_type_data.get("key", ""))
		event_type_text = str(event_type_data.get("full", ""))
		event_type_description_text = str(event_type_data.get("description", ""))
		event_type_short_text = str(event_type_data.get("short", ""))

	var ending_text: String = ""
	var ending_title: String = ""
	var ending_body: String = ""
	var ending_outcome_type: String = ""
	if run_state.ending_result != null:
		ending_title = run_state.ending_result.title
		ending_body = run_state.ending_result.description
		ending_outcome_type = str(run_state.ending_result.outcome_type)
		ending_text = "%s\n%s" % [ending_title, ending_body]

	var story_text: String = _build_story_text(run_state)
	var summary_text: String = story_text
	var phase_text: String = _describe_phase(run_state.world_state.current_phase)
	var activity_text: String = _describe_activity_text(run_state.world_state.current_phase)
	var stats_text: String = GAME_TEXT.format_text(
		"view_model.stats_line",
		[
			level,
			experience,
			experience_required,
			int(run_state.player_state.stats.get("physique", 0)),
			int(run_state.player_state.stats.get("mind", 0)),
			int(run_state.player_state.stats.get("insight", 0)),
			int(run_state.player_state.stats.get("occult", 0)),
			int(run_state.player_state.stats.get("tact", 0))
		]
	)
	var attribute_roles_text: String = _build_attribute_roles_text(attribute_roles)

	var hint_text: String = GAME_TEXT.text("view_model.default_hint")
	if not event_hints.is_empty():
		hint_text = "\n".join(event_hints)

	var option_hint_text: String = ""
	if not current_event_option_views.is_empty():
		var lines: Array[String] = []
		for option_view: Dictionary in current_event_option_views:
			if _to_bool(option_view.get("is_available", false)):
				continue
			lines.append("%s\n%s" % [str(option_view.get("text", "")), str(option_view.get("unmet_text", ""))])
		option_hint_text = "\n\n".join(lines)

	var location_name: String = str(current_location.get("display_name", run_state.world_state.current_location_id))
	var location_description: String = str(current_location.get("description", ""))
	var location_scene_text: String = location_description if not location_description.is_empty() else GAME_TEXT.text("view_model.default_location_scene")

	var stage_title: String = GAME_TEXT.text("view_model.stage_titles.location")
	var stage_body: String = "%s\n\n%s" % [location_name, location_scene_text]
	if run_state.is_run_over:
		stage_title = ending_title if not ending_title.is_empty() else GAME_TEXT.text("view_model.stage_titles.ending")
		stage_body = ending_body if not ending_body.is_empty() else GAME_TEXT.text("view_model.ending_body_fallback")
	elif not current_event.is_empty():
		stage_title = event_type_text if not event_type_text.is_empty() else event_title
		stage_body = event_body
		summary_text = _build_compact_summary_text(event_title, event_body)

	var status_text: String = GAME_TEXT.format_text(
		"view_model.status.available_actions",
		[", ".join(action_lines) if not action_lines.is_empty() else GAME_TEXT.text("view_model.status.none")]
	)
	if run_state.is_run_over:
		status_text = ending_text if not ending_text.is_empty() else GAME_TEXT.format_text("view_model.status.run_over", [run_state.end_reason])
	elif has_battle:
		status_text = GAME_TEXT.format_text(
			"view_model.status.battle",
			[str(run_state.current_battle_state.enemy_display_name)]
		)
	elif not current_event.is_empty():
		if is_dialogue_event:
			status_text = GAME_TEXT.format_text(
				"view_model.status.dialogue_typed" if not event_type_text.is_empty() else "view_model.status.dialogue",
				[event_speaker_text, event_type_text] if not event_type_text.is_empty() else [event_speaker_text]
			)
		else:
			status_text = "%s\n%s" % [event_type_text, event_text] if not event_type_text.is_empty() else event_text

	var scene_mode: String = "location"
	if run_state.is_run_over:
		scene_mode = "ending"
	elif has_battle:
		scene_mode = "battle"
	elif not current_event.is_empty():
		scene_mode = "dialogue" if is_dialogue_event else "event"

	return {
		"scene_mode": scene_mode,
		"day_text": GAME_TEXT.format_text("view_model.hud.day", [run_state.world_state.day, run_state.world_state.max_day]),
		"phase_text": phase_text,
		"remaining_action_text": activity_text,
		"resource_text": GAME_TEXT.format_text(
			"view_model.hud.resources",
			[
				int(run_state.player_state.resources.get("blood_qi", 0)),
				int(run_state.player_state.resources.get("spirit_stone", 0)),
				int(run_state.player_state.resources.get("spirit_sense", 0)),
				int(run_state.player_state.resources.get("clue_fragments", 0)),
				int(run_state.player_state.resources.get("pollution", 0)),
				int(run_state.player_state.resources.get("exposure", 0))
			]
		),
		"track_text": GAME_TEXT.format_text(
			"view_model.hud.track",
			[
				int(run_state.world_state.values.get("investigation_progress", 0)),
				int(run_state.world_state.values.get("anomaly_progress", 0))
			]
		),
		"location_text": GAME_TEXT.format_text("view_model.hud.location", [location_name]),
		"event_title_text": event_title,
		"event_body_text": event_body,
		"event_type_text": event_type_text,
		"event_type_description_text": event_type_description_text,
		"event_type_key": event_type_key,
		"event_type_short_text": event_type_short_text,
		"event_speaker_text": event_speaker_text,
		"event_portrait_text": event_portrait_text,
		"ending_title_text": ending_title,
		"ending_body_text": ending_body,
		"ending_outcome_type": ending_outcome_type,
		"stage_title_text": stage_title,
		"stage_body_text": stage_body,
		"npc_text": "\n".join(npc_lines) if not npc_lines.is_empty() else GAME_TEXT.text("view_model.empty.npc_text"),
		"stats_text": stats_text,
		"attribute_roles_text": attribute_roles_text,
		"story_text": story_text,
		"summary_text": summary_text,
		"goal_text": "\n".join(goal_text_lines) if not goal_text_lines.is_empty() else GAME_TEXT.text("view_model.empty.goal_text"),
		"action_text": ", ".join(action_lines),
		"event_text": event_text,
		"hint_text": hint_text,
		"location_mount_text": _build_location_mount_text(current_location, location_mount_traces),
		"npc_state_event_text": _build_npc_state_event_text(npc_state_event_traces),
		"option_hint_text": option_hint_text,
		"log_text": "\n".join(run_state.log_entries),
		"ending_text": ending_text,
		"status_text": status_text
	}


static func _resolve_gameplay_event_type(current_event: Dictionary, has_battle: bool, run_state: RunState) -> Dictionary:
	var event_id: String = str(current_event.get("id", current_event.get("event_id", "")))
	var battle_id: String = str(current_event.get("battle_id", ""))
	if has_battle:
		if run_state.current_battle_state != null:
			battle_id = str(run_state.current_battle_state.battle_id)
		return _resolve_battle_type_text(event_id, battle_id)
	if _is_review_event(event_id):
		return {
			"key": "review",
			"full": GAME_TEXT.text("view_model.event_types.review"),
			"description": GAME_TEXT.text("view_model.event_type_descriptions.review"),
			"short": GAME_TEXT.text("view_model.event_types_short.review")
		}
	if _is_shop_event(event_id):
		return {
			"key": "shop",
			"full": GAME_TEXT.text("view_model.event_types.shop"),
			"description": GAME_TEXT.text("view_model.event_type_descriptions.shop"),
			"short": GAME_TEXT.text("view_model.event_types_short.shop")
		}
	if not battle_id.is_empty():
		return _resolve_battle_type_text(event_id, battle_id)
	var event_class: String = str(current_event.get("event_class", ""))
	var content_category: String = str(current_event.get("content_category", ""))
	if event_class == "random_filler" or content_category == "random_disturbance":
		return {
			"key": "random",
			"full": GAME_TEXT.text("view_model.event_types.random"),
			"description": GAME_TEXT.text("view_model.event_type_descriptions.random"),
			"short": GAME_TEXT.text("view_model.event_types_short.random")
		}
	if _is_reward_event(event_id):
		return {
			"key": "reward",
			"full": GAME_TEXT.text("view_model.event_types.reward"),
			"description": GAME_TEXT.text("view_model.event_type_descriptions.reward"),
			"short": GAME_TEXT.text("view_model.event_types_short.reward")
		}
	if str(current_event.get("presentation_type", "")) == "dialogue_event":
		return {
			"key": "dialogue",
			"full": GAME_TEXT.text("view_model.event_types.dialogue"),
			"description": GAME_TEXT.text("view_model.event_type_descriptions.dialogue"),
			"short": GAME_TEXT.text("view_model.event_types_short.dialogue")
		}
	return {
		"key": "story",
		"full": GAME_TEXT.text("view_model.event_types.story"),
		"description": GAME_TEXT.text("view_model.event_type_descriptions.story"),
		"short": GAME_TEXT.text("view_model.event_types_short.story")
	}


static func _resolve_battle_type_text(event_id: String, battle_id: String) -> Dictionary:
	var battle_key: String = "normal_battle"
	if battle_id == "9101" or event_id == "2001":
		battle_key = "boss_battle"
	elif battle_id in ["9201", "9301", "9401"] or event_id in ["2004", "2005", "2003"]:
		battle_key = "elite_battle"
	return {
		"key": battle_key,
		"full": GAME_TEXT.text("view_model.event_types.%s" % battle_key),
		"description": GAME_TEXT.text("view_model.event_type_descriptions.%s" % battle_key),
		"short": GAME_TEXT.text("view_model.event_types_short.%s" % battle_key)
	}


static func _is_reward_event(event_id: String) -> bool:
	return event_id in [
		"1301", "1302", "1303",
		"2002", "2007", "2102",
		"2201", "2202", "2203",
		"2301", "2302", "2303",
		"2401", "2402", "2403",
		"conditional_record_discovery",
		"conditional_whisper_deepens"
	]


static func _is_review_event(event_id: String) -> bool:
	return event_id in ["3301", "3302"]


static func _is_shop_event(event_id: String) -> bool:
	return event_id in ["3401", "3402"]


static func _build_compact_summary_text(event_title: String, event_body: String) -> String:
	var trimmed_title: String = event_title.strip_edges()
	var trimmed_body: String = event_body.strip_edges()
	if trimmed_body.is_empty():
		return trimmed_title
	var first_block: String = String(trimmed_body.split("\n\n", false)[0]).strip_edges()
	if trimmed_title.is_empty():
		return first_block
	return "%s\n%s" % [trimmed_title, first_block]


static func _build_attribute_roles_text(attribute_roles: Dictionary) -> String:
	var ordered_keys: Array[String] = ["physique", "mind", "insight", "occult", "tact"]
	var labels: Dictionary = GAME_TEXT.dict("view_model.attribute_labels")
	var lines: Array[String] = []
	for key: String in ordered_keys:
		var role_text: String = str(attribute_roles.get(key, ""))
		if role_text.is_empty():
			continue
		lines.append("%s：%s" % [str(labels.get(key, key)), role_text])
	return "\n".join(lines) if not lines.is_empty() else GAME_TEXT.text("view_model.empty.attribute_roles")

static func _build_location_mount_text(current_location: Dictionary, location_mount_traces: Array[Dictionary]) -> String:
	var content_slots: Dictionary = Dictionary(current_location.get("content_slots", {}))
	if content_slots.is_empty():
		return GAME_TEXT.text("view_model.empty.location_mount")

	var lines: Array[String] = []
	var fixed_events: Array[String] = Array(content_slots.get("fixed_events", []), TYPE_STRING, "", null)
	var investigation_events: Array[String] = Array(content_slots.get("investigation_events", []), TYPE_STRING, "", null)
	var random_events: Array[String] = Array(content_slots.get("random_events", []), TYPE_STRING, "", null)
	var resident_npcs: Array[String] = Array(content_slots.get("resident_npcs", []), TYPE_STRING, "", null)

	lines.append(GAME_TEXT.format_text("view_model.mount_summary.resident_npcs", [resident_npcs.size()]))
	lines.append(GAME_TEXT.format_text("view_model.mount_summary.fixed_events", [fixed_events.size()]))
	lines.append(GAME_TEXT.format_text("view_model.mount_summary.investigation_events", [investigation_events.size()]))
	lines.append(GAME_TEXT.format_text("view_model.mount_summary.random_events", [random_events.size()]))

	if not location_mount_traces.is_empty():
		lines.append("")
		lines.append(GAME_TEXT.text("view_model.mount_summary.category_trace"))
		lines.append_array(_group_trace_lines(location_mount_traces))
	return "\n".join(lines)


static func _build_npc_state_event_text(npc_state_event_traces: Array[Dictionary]) -> String:
	if npc_state_event_traces.is_empty():
		return GAME_TEXT.text("view_model.empty.npc_state_event")

	var lines: Array[String] = []
	lines.append(GAME_TEXT.text("view_model.mount_summary.npc_category_trace"))
	lines.append_array(_group_trace_lines(npc_state_event_traces, true))
	return "\n".join(lines)


static func _group_trace_lines(traces: Array[Dictionary], include_npc_name: bool = false) -> Array[String]:
	var grouped: Dictionary = {}
	for trace: Dictionary in traces:
		var category: String = str(trace.get("content_category", "location_content"))
		if not grouped.has(category):
			grouped[category] = []
		grouped[category].append(trace)

	var ordered_categories: Array[String] = ["main_story", "npc_state", "location_content", "random_disturbance"]
	var category_labels: Dictionary = GAME_TEXT.dict("view_model.categories")
	var lines: Array[String] = []
	for category: String in ordered_categories:
		if not grouped.has(category):
			continue
		lines.append("[%s]" % str(category_labels.get(category, category)))
		for trace: Dictionary in grouped[category]:
			var title_text: String = str(trace.get("title", trace.get("id", "")))
			if include_npc_name:
				title_text = "%s · %s" % [str(trace.get("npc_name", trace.get("npc_id", ""))), title_text]
			lines.append("%s %s：%s" % [
				_trace_status_prefix(str(trace.get("status", ""))),
				title_text,
				str(trace.get("reason_text", ""))
			])
		lines.append("")
	if not lines.is_empty():
		lines.pop_back()
	return lines


static func _trace_status_prefix(status: String) -> String:
	var labels: Dictionary = GAME_TEXT.dict("view_model.trace_status")
	return str(labels.get(status, GAME_TEXT.text("view_model.trace_status.pending")))


static func _build_story_text(run_state: RunState) -> String:
	if run_state.is_run_over:
		return GAME_TEXT.text("view_model.story_text.run_over")
	if run_state.world_state.current_phase == "day":
		return GAME_TEXT.text("view_model.story_text.day")
	if run_state.world_state.current_phase == "night":
		return GAME_TEXT.text("view_model.story_text.night")
	return GAME_TEXT.text("view_model.story_text.default")


static func _describe_phase(phase: String) -> String:
	var labels: Dictionary = GAME_TEXT.dict("view_model.phase_labels")
	return str(labels.get(phase, phase))


static func _describe_activity_text(phase: String) -> String:
	var labels: Dictionary = GAME_TEXT.dict("view_model.activity_labels")
	return str(labels.get(phase, GAME_TEXT.text("view_model.activity_labels.default")))

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
