class_name MainGameViewModel
extends RefCounted

static func build(
	run_state: RunState,
	visible_actions: Array[Dictionary],
	current_event: Dictionary,
	event_hints: Array[String],
	current_event_option_views: Array[Dictionary]
) -> Dictionary:
	var goal_lines: Array[String] = []
	for goal: GoalProgress in run_state.active_goals:
		var state_text: String = "进行中"
		if goal.completed:
			state_text = "已完成"
		elif goal.failed:
			state_text = "已失败"
		goal_lines.append("%s [%s]" % [goal.display_name, state_text])

	var action_lines: Array[String] = []
	for action: Dictionary in visible_actions:
		action_lines.append(str(action.get("display_name", action.get("id", ""))))

	var event_text: String = ""
	if not current_event.is_empty():
		event_text = "%s\n%s" % [
			str(current_event.get("title", "")),
			str(current_event.get("description", ""))
		]

	var ending_text: String = ""
	if run_state.ending_result != null:
		ending_text = "%s\n%s" % [
			run_state.ending_result.title,
			run_state.ending_result.description
		]

	var story_text: String = _build_story_text(run_state)
	var phase_text: String = _describe_phase(run_state.world_state.current_phase)
	var stats_text: String = "体魄 %d  心智 %d  悟性 %d  诡感 %d  手腕 %d" % [
		int(run_state.player_state.stats.get("physique", 0)),
		int(run_state.player_state.stats.get("mind", 0)),
		int(run_state.player_state.stats.get("insight", 0)),
		int(run_state.player_state.stats.get("occult", 0)),
		int(run_state.player_state.stats.get("tact", 0))
	]
	var hint_text: String = "当前暂无新的线索节点。"
	if not event_hints.is_empty():
		hint_text = "\n".join(event_hints)

	var option_hint_text: String = ""
	if not current_event_option_views.is_empty():
		var lines: Array[String] = []
		for option_view: Dictionary in current_event_option_views:
			if bool(option_view.get("is_available", false)):
				continue
			lines.append("%s\n%s" % [
				str(option_view.get("text", "")),
				str(option_view.get("unmet_text", ""))
			])
		option_hint_text = "\n\n".join(lines)

	return {
		"day_text": "第 %d / %d 天 | %s | 今日剩余行动 %d" % [
			run_state.world_state.day,
			run_state.world_state.max_day,
			phase_text,
			run_state.world_state.actions_remaining
		],
		"resource_text": "血气 %d  灵石 %d  神识 %d  线索 %d  污染 %d  暴露 %d" % [
			int(run_state.player_state.resources.get("blood_qi", 0)),
			int(run_state.player_state.resources.get("spirit_stone", 0)),
			int(run_state.player_state.resources.get("spirit_sense", 0)),
			int(run_state.player_state.resources.get("clue_fragments", 0)),
			int(run_state.player_state.resources.get("pollution", 0)),
			int(run_state.player_state.resources.get("exposure", 0))
		],
		"track_text": "调查推进 %d  |  异变推进 %d" % [
			int(run_state.world_state.values.get("investigation_progress", 0)),
			int(run_state.world_state.values.get("anomaly_progress", 0))
		],
		"stats_text": stats_text,
		"story_text": story_text,
		"goal_text": "\n".join(goal_lines),
		"action_text": ", ".join(action_lines),
		"event_text": event_text,
		"hint_text": hint_text,
		"option_hint_text": option_hint_text,
		"log_text": "\n".join(run_state.log_entries),
		"ending_text": ending_text
	}

static func _build_story_text(run_state: RunState) -> String:
	if run_state.is_run_over:
		return "第七夜已经结束。你在调查推进与异变推进之间做出的取舍，决定了自己最后留下来的样子。"
	if run_state.player_state.knowledge.has("anomaly_source_identified"):
		return "你已经确认井下封着会模仿人声的异常。现在的问题不是查不查，而是异变推进得比你更快还是更慢。"
	if run_state.player_state.knowledge.has("well_sealed_in_past"):
		return "你知道西井曾被人为压下过一次。接下来需要在地点间搜集更多线索碎片，赶在世界先失控之前拼出真相。"
	if run_state.player_state.tags.has("heard_west_well_voice"):
		return "你已经确认西井的声音不是错觉。白天去哪里，决定你会更快接近真相，还是让异变在夜里先一步推进。"
	return "你刚进入别院，西井被反复告诫不要靠近。晨间看似平静，但真正的推进会在白天地点选择和夜间异常里逐步显形。"

static func _describe_phase(phase: String) -> String:
	var labels: Dictionary = {
		"morning": "晨间阶段",
		"day": "白天行动",
		"night": "夜间异常",
		"closing": "收束阶段"
	}
	return str(labels.get(phase, phase))
