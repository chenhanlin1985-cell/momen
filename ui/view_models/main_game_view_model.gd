class_name MainGameViewModel
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")


static func build(
	run_state: RunState,
	available_locations: Array[Dictionary],
	current_location: Dictionary,
	present_npcs: Array[Dictionary],
	visible_actions: Array[Dictionary],
	npc_interactions: Array[Dictionary],
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

	var location_lines: Array[String] = []
	for location_definition: Dictionary in available_locations:
		var listed_location_name: String = str(location_definition.get("display_name", location_definition.get("id", "")))
		var location_note: String = str(location_definition.get("description", ""))
		if str(location_definition.get("id", "")) == run_state.world_state.current_location_id:
			listed_location_name = GAME_TEXT.format_text("view_model.location_current_prefix", [listed_location_name])
		location_lines.append("%s\n%s" % [listed_location_name, location_note] if not location_note.is_empty() else listed_location_name)

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

	var interaction_lines: Array[String] = []
	for interaction: Dictionary in npc_interactions:
		interaction_lines.append(
			GAME_TEXT.format_text(
				"view_model.interaction_line",
				[
					str(interaction.get("npc_display_name", interaction.get("npc_id", ""))),
					str(interaction.get("display_name", interaction.get("id", "")))
				]
			)
		)

	var event_title: String = ""
	var event_body: String = ""
	var event_text: String = ""
	var event_presentation_type: String = "standard_event"
	var event_speaker_text: String = ""
	var event_portrait_text: String = ""
	if not current_event.is_empty():
		event_presentation_type = str(current_event.get("presentation_type", "standard_event"))
		event_title = str(current_event.get("title", GAME_TEXT.text("view_model.current_event_title")))
		event_body = str(current_event.get("description", ""))
		if _to_bool(current_event.get("awaiting_continue", false)):
			event_body = str(current_event.get("result_text", event_body))
		if event_presentation_type == "combat_event":
			event_body = _build_combat_body(current_event, event_body)
		event_speaker_text = str(current_event.get("speaker_display_name", event_title))
		event_portrait_text = str(
			current_event.get(
				"speaker_portrait_placeholder",
				GAME_TEXT.format_text("view_model.portrait_placeholder", [event_speaker_text])
			)
		)
		event_text = "%s\n%s" % [event_title, event_body]

	var ending_text: String = ""
	var ending_title: String = ""
	var ending_body: String = ""
	if run_state.ending_result != null:
		ending_title = run_state.ending_result.title
		ending_body = run_state.ending_result.description
		ending_text = "%s\n%s" % [ending_title, ending_body]

	var story_text: String = _build_story_text(run_state)
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
	if not current_event.is_empty():
		stage_title = event_title
		stage_body = event_body
	elif run_state.is_run_over:
		stage_title = ending_title if not ending_title.is_empty() else GAME_TEXT.text("view_model.stage_titles.ending")
		stage_body = ending_body if not ending_body.is_empty() else GAME_TEXT.text("view_model.ending_body_fallback")

	var status_text: String = GAME_TEXT.format_text(
		"view_model.status.available_actions",
		[", ".join(action_lines) if not action_lines.is_empty() else GAME_TEXT.text("view_model.status.none")]
	)
	if not current_event.is_empty():
		if event_presentation_type == "dialogue_event":
			status_text = GAME_TEXT.format_text("view_model.status.dialogue", [event_speaker_text])
		elif event_presentation_type == "combat_event":
			status_text = GAME_TEXT.format_text("view_model.status.combat", [event_title])
		else:
			status_text = event_text
	elif run_state.is_run_over:
		status_text = ending_text if not ending_text.is_empty() else GAME_TEXT.format_text("view_model.status.run_over", [run_state.end_reason])

	var scene_mode: String = "location"
	if not current_event.is_empty():
		scene_mode = "dialogue" if event_presentation_type == "dialogue_event" else "event"
	elif run_state.is_run_over:
		scene_mode = "ending"

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
		"event_presentation_type": event_presentation_type,
		"event_speaker_text": event_speaker_text,
		"event_portrait_text": event_portrait_text,
		"ending_title_text": ending_title,
		"ending_body_text": ending_body,
		"stage_title_text": stage_title,
		"stage_body_text": stage_body,
		"npc_text": "\n".join(npc_lines) if not npc_lines.is_empty() else GAME_TEXT.text("view_model.empty.npc_text"),
		"stats_text": stats_text,
		"attribute_roles_text": attribute_roles_text,
		"story_text": story_text,
		"goal_text": "\n".join(goal_text_lines) if not goal_text_lines.is_empty() else GAME_TEXT.text("view_model.empty.goal_text"),
		"action_text": ", ".join(action_lines),
		"interaction_text": ", ".join(interaction_lines),
		"event_text": event_text,
		"hint_text": hint_text,
		"location_mount_text": _build_location_mount_text(current_location, location_mount_traces),
		"npc_state_event_text": _build_npc_state_event_text(npc_state_event_traces),
		"option_hint_text": option_hint_text,
		"log_text": "\n".join(run_state.log_entries),
		"ending_text": ending_text,
		"location_list_text": "\n\n".join(location_lines),
		"status_text": status_text
	}


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


static func _build_combat_body(current_event: Dictionary, description: String) -> String:
	var lines: Array[String] = []
	var combatant_name: String = str(current_event.get("combatant_name", ""))
	if not combatant_name.is_empty():
		lines.append(GAME_TEXT.format_text("view_model.combat.opponent", [combatant_name]))
	var combat_guard: int = int(current_event.get("combat_guard", 0))
	var combat_damage: int = int(current_event.get("combat_damage", 0))
	var combat_hp: int = int(current_event.get("combat_hp", 0))
	if combat_guard > 0 or combat_damage > 0 or combat_hp > 0:
		lines.append(GAME_TEXT.format_text("view_model.combat.stats", [combat_guard, combat_damage, combat_hp]))
	var combat_escape_target: int = int(current_event.get("combat_escape_target", 0))
	if combat_escape_target > 0:
		lines.append(GAME_TEXT.format_text("view_model.combat.escape", [combat_escape_target]))
	if description.is_empty():
		return "\n".join(lines)
	if lines.is_empty():
		return description
	return "%s\n\n%s" % ["\n".join(lines), description]


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
