class_name RouteMapService
extends RefCounted

const TEMPLATE_PATH_PATTERN := "res://content/story/act1/route_map/day_%02d.json"
const ROUTE_MAP_CURSOR_DAY_KEY := "_route_map_cursor_day"
const ROUTE_MAP_CURSOR_NODE_KEY := "_route_map_cursor_node_id"
const ROUTE_MAP_VISITED_DAY_KEY := "_route_map_visited_day"
const ROUTE_MAP_VISITED_NODE_IDS_KEY := "_route_map_visited_node_ids"
const ROUTE_MAP_TRANSITION_PREVIEW_KEY := "_route_map_transition_preview"
const ROUTE_MAP_DAY_GAP_COLUMNS := 1

const NODE_TYPE_FALLBACK_BY_ACTION_CATEGORY := {
	"talk": "dialogue",
	"investigate": "story",
	"work": "reward",
	"rest": "review",
	"combat": "battle"
}

const NODE_TYPE_LABELS := {
	"story": "剧情",
	"dialogue": "对话",
	"reward": "奖励",
	"shop": "商店",
	"review": "整备",
	"battle": "战斗",
	"risk": "风险"
}

const BUTTON_KIND_BY_NODE_TYPE := {
	"story": "event_story",
	"dialogue": "event_dialogue",
	"reward": "event_reward",
	"shop": "event_shop",
	"review": "event_review",
	"battle": "event_battle",
	"risk": "event_random"
}

const ROUTE_LABELS := {
	"route_records": "账册线",
	"route_seek_senior": "疯长老线",
	"route_well": "化骨池线",
	"route_lie_low": "暂避锋芒"
}

const ROUTE_DESCRIPTIONS := {
	"route_records": "你正在把药房、旧账和补漏动作收成一条更明确的账册路线。",
	"route_seek_senior": "你正在把疯长老这条高风险高回报的路线经营成真正可走的门路。",
	"route_well": "你正在把化骨池异响和异常痕迹收束成一条危险但独特的路线。",
	"route_lie_low": "你暂时更偏向压低存在感，避免在时机未成熟前把自己提前送出去。"
}

func build_route_map_view(
	run_state: RunState,
	content_repository: ContentRepository,
	condition_evaluator: ConditionEvaluator,
	candidate_ids: Array[String],
	forced_frontier_event_id: String = ""
) -> Dictionary:
	if run_state == null:
		return {}

	var current_day: int = run_state.world_state.day
	var current_day_template: Dictionary = _load_day_template(current_day)
	var action_definitions: Dictionary = {}
	for action_id: String in candidate_ids:
		var definition: Dictionary = content_repository.get_action_definition(action_id)
		if definition.is_empty():
			continue
		action_definitions[action_id] = definition

	if current_day_template.is_empty() and action_definitions.is_empty():
		return {}

	var templates: Array[Dictionary] = _load_campaign_templates()
	if templates.is_empty():
		return {}

	var current_route_key: String = _resolve_current_route_key(run_state)
	var current_route_text: String = str(ROUTE_LABELS.get(current_route_key, "尚未明确主押路线"))
	var current_route_description: String = str(
		ROUTE_DESCRIPTIONS.get(
			current_route_key,
			"这一拍更像是在观察和试探。你还没把自己真正压到某条明确路线之上。"
		)
	)
	var current_day_title: String = str(current_day_template.get("title", "第%d天白天" % current_day))
	var current_day_description: String = str(
		current_day_template.get(
			"description",
			"白天的路线图已经连成一张连续大图。当前只会解锁你今天真正能推进的那一段。"
		)
	)
	var visited_node_ids: Array[String] = _get_visited_node_ids(run_state)
	var visited_path_text: String = _build_visited_path_text(current_day_template, visited_node_ids)

	var start_node: Dictionary = {
		"id": "start",
		"title": "起点",
		"hint": "整张白天路线图会一直向右延展。当前高亮区域是今天。",
		"column": 0,
		"lane": 1,
		"node_type": "story",
		"type_label": "总览",
		"route_key": "",
		"route_label": "",
		"is_route_active": false,
		"focus_state": "neutral",
		"button_kind": "event_story",
		"is_start": true
	}

	var nodes: Array[Dictionary] = []
	var edges: Array[Dictionary] = []
	var day_sections: Array[Dictionary] = []
	var column_offset: int = 0
	var previous_close_id: String = "start"
	for template_entry: Dictionary in templates:
		var template_day: int = int(template_entry.get("day", 0))
		var template: Dictionary = Dictionary(template_entry.get("template", {}))
		var section_start_column: int = column_offset + 1
		var max_column: int = _get_template_max_column(template)
		var section_end_column: int = section_start_column + max_column - 1
		day_sections.append({
			"day": template_day,
			"title": str(template.get("title", "第%d天白天" % template_day)),
			"start_column": section_start_column,
			"end_column": section_end_column,
			"is_current": template_day == current_day
		})

		var frontier_ids: Array[String] = Array([], TYPE_STRING, "", null)
		if template_day == current_day:
			frontier_ids = Array(_get_frontier_node_ids(run_state, template), TYPE_STRING, "", null)
			if not forced_frontier_event_id.is_empty():
				var forced_ids: Array[String] = _get_forced_frontier_node_ids(template, forced_frontier_event_id)
				if not forced_ids.is_empty():
					frontier_ids = forced_ids
		nodes.append_array(
			_build_campaign_day_node_views(
				run_state,
				content_repository,
				condition_evaluator,
				template,
				template_day,
				current_day,
				column_offset,
				action_definitions,
				current_route_key,
				frontier_ids,
				visited_node_ids,
				forced_frontier_event_id
			)
		)
		edges.append_array(_build_campaign_edges(template, column_offset, previous_close_id))
		var day_close_id: String = _find_transition_node_id(template)
		if not day_close_id.is_empty():
			previous_close_id = day_close_id
		column_offset += max_column + ROUTE_MAP_DAY_GAP_COLUMNS

	nodes.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("column", 0)) == int(b.get("column", 0)):
			return int(a.get("lane", 0)) < int(b.get("lane", 0))
		return int(a.get("column", 0)) < int(b.get("column", 0))
	)

	var description: String = "%s\n\n当前：第%d天\n%s" % [current_day_description, current_day, current_route_description]
	if not current_route_key.is_empty():
		description += "\n\n当前主押：%s" % current_route_text

	return {
		"title": "昼间总路线图 · 第%d天" % current_day,
		"description": description,
		"summary": str(current_day_template.get("summary", "")),
		"current_day": current_day,
		"current_day_text": "第%d天" % current_day,
		"current_day_title": current_day_title,
		"current_day_description": current_day_description,
		"current_route_key": current_route_key,
		"current_route_text": current_route_text,
		"current_route_description": current_route_description,
		"visited_node_ids": visited_node_ids,
		"visited_path_text": visited_path_text,
		"day_sections": day_sections,
		"start_node": start_node,
		"nodes": nodes,
		"edges": edges
	}

func has_template_for_day(day: int) -> bool:
	return not _load_day_template(day).is_empty()

func has_event_target_for_day(day: int, event_id: String) -> bool:
	if event_id.is_empty():
		return false
	var template: Dictionary = _load_day_template(day)
	if template.is_empty():
		return false
	for template_node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(template_node.get("target_kind", "")) != "event":
			continue
		if str(template_node.get("target_id", "")) == event_id:
			return true
	return false

func get_template_action_ids(day: int) -> Array[String]:
	var template: Dictionary = _load_day_template(day)
	if template.is_empty():
		return []
	var action_ids: Array[String] = []
	for template_node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(template_node.get("target_kind", "action")) != "action":
			continue
		var target_id: String = str(template_node.get("target_id", ""))
		if target_id.is_empty() or action_ids.has(target_id):
			continue
		action_ids.append(target_id)
	return action_ids

func get_frontier_action_ids(run_state: RunState, available_action_ids: Array[String]) -> Array[String]:
	var template: Dictionary = _load_day_template(run_state.world_state.day)
	if template.is_empty():
		return []
	var available_by_id: Dictionary = {}
	for action_id: String in available_action_ids:
		available_by_id[action_id] = true
	var selected_ids: Array[String] = []
	for template_node: Dictionary in _get_frontier_template_nodes(run_state, template):
		if str(template_node.get("target_kind", "action")) != "action":
			continue
		var target_id: String = str(template_node.get("target_id", ""))
		if target_id.is_empty() or not available_by_id.has(target_id):
			continue
		selected_ids.append(target_id)
	return selected_ids

func has_remaining_route_map_choices(
	run_state: RunState,
	content_repository: ContentRepository,
	condition_evaluator: ConditionEvaluator,
	available_action_ids: Array[String]
) -> bool:
	var template: Dictionary = _load_day_template(run_state.world_state.day)
	if template.is_empty():
		return false
	var available_by_id: Dictionary = {}
	for action_id: String in available_action_ids:
		available_by_id[action_id] = true
	for template_node: Dictionary in _get_frontier_template_nodes(run_state, template):
		var target_kind: String = str(template_node.get("target_kind", "action"))
		var target_id: String = str(template_node.get("target_id", ""))
		if target_kind == "action" and available_by_id.has(target_id):
			return true
		if target_kind == "event":
			var event_definition: Dictionary = content_repository.get_story_event_definition(run_state.run_id, target_id)
			if event_definition.is_empty():
				continue
			return true
		if target_kind == "transition":
			return true
	return false

func set_route_map_cursor(run_state: RunState, node_id: String) -> void:
	run_state.world_state.values[ROUTE_MAP_CURSOR_DAY_KEY] = run_state.world_state.day
	run_state.world_state.global_flags[ROUTE_MAP_CURSOR_NODE_KEY] = node_id
	run_state.world_state.values[ROUTE_MAP_VISITED_DAY_KEY] = run_state.world_state.day
	var visited_node_ids: Array[String] = _get_visited_node_ids(run_state)
	if not visited_node_ids.has(node_id):
		visited_node_ids.append(node_id)
	run_state.world_state.global_flags[ROUTE_MAP_VISITED_NODE_IDS_KEY] = visited_node_ids.duplicate()

func clear_route_map_progress(run_state: RunState) -> void:
	run_state.world_state.values.erase(ROUTE_MAP_CURSOR_DAY_KEY)
	run_state.world_state.global_flags.erase(ROUTE_MAP_CURSOR_NODE_KEY)
	run_state.world_state.values.erase(ROUTE_MAP_VISITED_DAY_KEY)
	run_state.world_state.global_flags.erase(ROUTE_MAP_VISITED_NODE_IDS_KEY)

func set_transition_preview(run_state: RunState, preview: Dictionary) -> void:
	run_state.world_state.values[ROUTE_MAP_TRANSITION_PREVIEW_KEY] = preview.duplicate(true)

func get_transition_preview(run_state: RunState) -> Dictionary:
	var preview: Variant = run_state.world_state.values.get(ROUTE_MAP_TRANSITION_PREVIEW_KEY, {})
	if preview is Dictionary:
		return Dictionary(preview).duplicate(true)
	return {}

func clear_transition_preview(run_state: RunState) -> void:
	run_state.world_state.values.erase(ROUTE_MAP_TRANSITION_PREVIEW_KEY)

func has_route_map_cursor_for_current_day(run_state: RunState) -> bool:
	if run_state == null:
		return false
	return not _get_route_map_cursor_node_id(run_state).is_empty()

func advance_cursor_to_matching_successor_event(run_state: RunState, target_event_id: String) -> bool:
	if run_state == null or target_event_id.is_empty():
		return false
	var template: Dictionary = _load_day_template(run_state.world_state.day)
	if template.is_empty():
		return false
	for template_node: Dictionary in _get_frontier_template_nodes(run_state, template):
		if str(template_node.get("target_kind", "")) != "event":
			continue
		if str(template_node.get("target_id", "")) != target_event_id:
			continue
		var node_id: String = str(template_node.get("node_id", ""))
		if node_id.is_empty():
			return false
		set_route_map_cursor(run_state, node_id)
		return true
	return false

func get_immediate_transition_target_event_id(day: int, node_id: String) -> String:
	if day <= 0 or node_id.is_empty():
		return ""
	var template: Dictionary = _load_day_template(day)
	if template.is_empty():
		return ""
	var successor_ids: Array[String] = []
	for edge: Dictionary in Array(template.get("edges", []), TYPE_DICTIONARY, "", null):
		if str(edge.get("from", "")) != node_id:
			continue
		var to_id: String = str(edge.get("to", ""))
		if to_id.is_empty() or successor_ids.has(to_id):
			continue
		successor_ids.append(to_id)
	if successor_ids.size() != 1:
		return ""
	for template_node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(template_node.get("node_id", "")) != successor_ids[0]:
			continue
		if str(template_node.get("target_kind", "")) != "event":
			return ""
		return str(template_node.get("target_id", ""))
	return ""

func build_transition_view(run_state: RunState, preview: Dictionary) -> Dictionary:
	if run_state == null or preview.is_empty():
		return {}
	var node_id: String = str(preview.get("id", "transition_continue"))
	var node_type: String = str(preview.get("node_type", "story"))
	var title: String = str(preview.get("title", "继续推进"))
	var hint: String = str(preview.get("hint", "确认后进入下一段流程。"))
	var summary: String = str(preview.get("summary", hint))
	var node_view: Dictionary = {
		"id": node_id,
		"target_kind": "transition",
		"is_terminal": true,
		"title": title,
		"hint": hint,
		"column": 1,
		"lane": 0,
		"node_type": node_type,
		"type_label": str(preview.get("type_label", NODE_TYPE_LABELS.get(node_type, "节点"))),
		"button_kind": str(preview.get("button_kind", BUTTON_KIND_BY_NODE_TYPE.get(node_type, "event_story"))),
		"route_key": "",
		"route_label": "",
		"is_route_active": false,
		"focus_state": "neutral",
		"is_locked": false,
		"lock_reason_text": ""
	}
	return {
		"title": str(preview.get("view_title", "后续选择")),
		"description": str(preview.get("view_description", "当前事件已结束，请明确选择下一步推进。")),
		"summary": summary,
		"current_route_key": "",
		"current_route_text": str(preview.get("phase_text", "")),
		"current_route_description": "",
		"current_day": 0,
		"current_day_text": "",
		"visited_node_ids": [],
		"visited_path_text": str(preview.get("visited_path_text", "")),
		"day_sections": [],
		"start_node": {
			"id": "start",
			"title": str(preview.get("start_title", "当前进度")),
			"hint": str(preview.get("start_hint", summary)),
			"column": 0,
			"lane": 0,
			"node_type": "story",
			"type_label": "当前",
			"route_key": "",
			"route_label": "",
			"is_route_active": false,
			"focus_state": "neutral",
			"button_kind": "event_story",
			"is_start": true
		},
		"nodes": [node_view],
		"edges": [{"from": "start", "to": node_id}]
	}

func _resolve_current_route_key(run_state: RunState) -> String:
	var ordered_keys: Array[String] = [
		"route_records",
		"route_seek_senior",
		"route_well",
		"route_lie_low"
	]
	for route_key: String in ordered_keys:
		if _to_bool(run_state.world_state.global_flags.get(route_key, false)):
			return route_key
	return ""

func _load_campaign_templates() -> Array[Dictionary]:
	var templates: Array[Dictionary] = []
	for day: int in range(1, 15):
		var template: Dictionary = _load_day_template(day)
		if template.is_empty():
			continue
		templates.append({
			"day": day,
			"template": template
		})
	return templates

func _load_day_template(day: int) -> Dictionary:
	var path: String = TEMPLATE_PATH_PATTERN % day
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return Dictionary(parsed).duplicate(true)
	return {}

func _build_campaign_day_node_views(
	run_state: RunState,
	content_repository: ContentRepository,
	condition_evaluator: ConditionEvaluator,
	template: Dictionary,
	template_day: int,
	current_day: int,
	column_offset: int,
	action_definitions: Dictionary,
	current_route_key: String,
	frontier_ids: Array[String],
	visited_node_ids: Array[String],
	forced_frontier_event_id: String
) -> Array[Dictionary]:
	var node_views: Array[Dictionary] = []
	for template_node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		var adjusted_node: Dictionary = template_node.duplicate(true)
		adjusted_node["column"] = int(template_node.get("column", 1)) + column_offset
		adjusted_node["day"] = template_day

		var local_node_id: String = str(template_node.get("node_id", ""))
		var is_current_day: bool = template_day == current_day
		var is_frontier: bool = is_current_day and frontier_ids.has(local_node_id)
		var is_visited: bool = is_current_day and visited_node_ids.has(local_node_id)

		var node_view: Dictionary = {}
		if is_frontier:
			node_view = _build_frontier_node_view(
				run_state,
				content_repository,
				condition_evaluator,
				adjusted_node,
				action_definitions,
				current_route_key,
				forced_frontier_event_id
			)
		else:
			node_view = _build_static_node_view_from_template(adjusted_node, current_route_key)
			node_view["is_locked"] = true
			node_view["lock_reason_text"] = _build_non_frontier_lock_reason(
				template_day,
				current_day,
				is_visited
			)

		node_view["day"] = template_day
		node_view["day_text"] = "第%d天" % template_day
		node_view["is_current_day"] = is_current_day
		node_view["is_past_day"] = template_day < current_day
		node_view["is_future_day"] = template_day > current_day
		node_view["is_completed"] = is_visited or template_day < current_day
		node_views.append(node_view)
	return node_views

func _build_frontier_node_view(
	run_state: RunState,
	content_repository: ContentRepository,
	condition_evaluator: ConditionEvaluator,
	template_node: Dictionary,
	action_definitions: Dictionary,
	current_route_key: String,
	forced_frontier_event_id: String
) -> Dictionary:
	var target_kind: String = str(template_node.get("target_kind", "action"))
	var target_id: String = str(template_node.get("target_id", ""))
	if target_kind == "action":
		if action_definitions.has(target_id):
			return _build_action_node_view_from_template(
				template_node,
				Dictionary(action_definitions.get(target_id, {})),
				current_route_key
			)
		var unavailable_view: Dictionary = _build_static_node_view_from_template(template_node, current_route_key)
		unavailable_view["is_locked"] = true
		unavailable_view["lock_reason_text"] = "当前这个行动没有出现在今天的可用候选里。"
		return unavailable_view
	if target_kind == "event":
		var event_definition: Dictionary = content_repository.get_story_event_definition(run_state.run_id, target_id)
		if event_definition.is_empty():
			var missing_event_view: Dictionary = _build_static_node_view_from_template(template_node, current_route_key)
			missing_event_view["is_locked"] = true
			missing_event_view["lock_reason_text"] = "这个事件当前无法读取。"
			return missing_event_view
		if not forced_frontier_event_id.is_empty() and target_id == forced_frontier_event_id:
			return _build_event_node_view_from_template(template_node, event_definition, current_route_key)
		var lock_reason_text: String = _get_story_event_lock_reason(
			run_state,
			condition_evaluator,
			event_definition,
			template_node,
			current_route_key
		)
		if lock_reason_text.is_empty():
			return _build_event_node_view_from_template(template_node, event_definition, current_route_key)
		var locked_event_view: Dictionary = _build_event_node_view_from_template(template_node, event_definition, current_route_key)
		locked_event_view["is_locked"] = true
		locked_event_view["lock_reason_text"] = lock_reason_text
		return locked_event_view
	if target_kind == "transition":
		return _build_transition_node_view_from_template(template_node, current_route_key)
	var fallback_view: Dictionary = _build_static_node_view_from_template(template_node, current_route_key)
	fallback_view["is_locked"] = true
	fallback_view["lock_reason_text"] = "这个节点当前无法进入。"
	return fallback_view

func _build_static_node_view_from_template(template_node: Dictionary, current_route_key: String) -> Dictionary:
	var node_type: String = str(template_node.get("node_type", "story"))
	var route_key: String = str(template_node.get("route_key", ""))
	var target_kind: String = str(template_node.get("target_kind", "action"))
	var target_id: String = str(template_node.get("target_id", ""))
	return {
		"id": str(template_node.get("node_id", target_id)),
		"target_kind": target_kind,
		"target_action_id": target_id if target_kind == "action" else "",
		"target_event_id": target_id if target_kind == "event" else "",
		"target_transition_kind": str(template_node.get("target_transition_kind", "")),
		"target_id": target_id,
		"title": str(template_node.get("title", target_id)),
		"hint": str(template_node.get("hint", "")),
		"column": int(template_node.get("column", 1)),
		"lane": int(template_node.get("lane", 0)),
		"node_type": node_type,
		"type_label": str(template_node.get("type_label", NODE_TYPE_LABELS.get(node_type, "节点"))),
		"button_kind": str(template_node.get("button_kind", BUTTON_KIND_BY_NODE_TYPE.get(node_type, "event_story"))),
		"route_key": route_key,
		"route_label": str(ROUTE_LABELS.get(route_key, "")),
		"is_route_active": route_key == current_route_key and not current_route_key.is_empty(),
		"focus_state": _resolve_focus_state(route_key, current_route_key),
		"is_locked": false,
		"lock_reason_text": "",
		"is_terminal": target_kind == "transition"
	}

func _build_campaign_edges(template: Dictionary, column_offset: int, previous_close_id: String) -> Array[Dictionary]:
	var edges: Array[Dictionary] = []
	for edge: Dictionary in Array(template.get("edges", []), TYPE_DICTIONARY, "", null):
		var from_id: String = str(edge.get("from", ""))
		var to_id: String = str(edge.get("to", ""))
		if to_id.is_empty():
			continue
		if from_id == "start":
			edges.append({"from": previous_close_id, "to": to_id})
		else:
			edges.append({"from": from_id, "to": to_id})
	return edges

func _get_template_max_column(template: Dictionary) -> int:
	var max_column: int = 0
	for node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		max_column = max(max_column, int(node.get("column", 0)))
	return max(max_column, 1)

func _find_transition_node_id(template: Dictionary) -> String:
	var best_node_id: String = ""
	var best_column: int = -1
	for node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(node.get("target_kind", "action")) != "transition":
			continue
		var column: int = int(node.get("column", 0))
		if column < best_column:
			continue
		best_column = column
		best_node_id = str(node.get("node_id", ""))
	return best_node_id

func _build_non_frontier_lock_reason(template_day: int, current_day: int, is_visited: bool) -> String:
	if is_visited:
		return "这一步今天已经走过了。"
	if template_day < current_day:
		return "这一天已经过去，路线只作为回顾显示。"
	if template_day > current_day:
		return "会在第%d天开启。" % template_day
	return "需要先走到前一节点。"

func _build_action_node_view_from_template(template_node: Dictionary, action_definition: Dictionary, current_route_key: String) -> Dictionary:
	var node_type: String = str(template_node.get("node_type", _resolve_fallback_node_type(action_definition)))
	var route_key: String = str(template_node.get("route_key", ""))
	var title: String = str(template_node.get("title", action_definition.get("display_name", action_definition.get("id", ""))))
	var hint: String = str(template_node.get("hint", action_definition.get("description", "")))
	return {
		"id": str(template_node.get("node_id", action_definition.get("id", ""))),
		"target_kind": "action",
		"target_action_id": str(action_definition.get("id", "")),
		"target_id": str(action_definition.get("id", "")),
		"title": title,
		"hint": hint,
		"column": int(template_node.get("column", 1)),
		"lane": int(template_node.get("lane", 0)),
		"node_type": node_type,
		"type_label": str(template_node.get("type_label", NODE_TYPE_LABELS.get(node_type, "节点"))),
		"button_kind": str(template_node.get("button_kind", BUTTON_KIND_BY_NODE_TYPE.get(node_type, "action"))),
		"location_id": str(action_definition.get("target_location_id", "")),
		"action_category": str(action_definition.get("action_category", "")),
		"risk_weight": int(action_definition.get("risk_weight", 0)),
		"route_key": route_key,
		"route_label": str(ROUTE_LABELS.get(route_key, "")),
		"is_route_active": route_key == current_route_key and not current_route_key.is_empty(),
		"focus_state": _resolve_focus_state(route_key, current_route_key),
		"is_locked": false,
		"lock_reason_text": ""
	}

func _build_event_node_view_from_template(template_node: Dictionary, event_definition: Dictionary, current_route_key: String) -> Dictionary:
	var node_type: String = str(template_node.get("node_type", "story"))
	var route_key: String = str(template_node.get("route_key", ""))
	var title: String = str(template_node.get("title", event_definition.get("title", event_definition.get("id", ""))))
	var hint: String = str(template_node.get("hint", event_definition.get("description", "")))
	return {
		"id": str(template_node.get("node_id", event_definition.get("id", ""))),
		"target_kind": "event",
		"target_event_id": str(event_definition.get("id", "")),
		"target_id": str(event_definition.get("id", "")),
		"title": title,
		"hint": hint,
		"column": int(template_node.get("column", 1)),
		"lane": int(template_node.get("lane", 0)),
		"node_type": node_type,
		"type_label": str(template_node.get("type_label", NODE_TYPE_LABELS.get(node_type, "节点"))),
		"button_kind": str(template_node.get("button_kind", BUTTON_KIND_BY_NODE_TYPE.get(node_type, "action"))),
		"location_id": str(event_definition.get("location_id", "")),
		"action_category": "story_event",
		"risk_weight": int(event_definition.get("schedule_priority", 0)),
		"route_key": route_key,
		"route_label": str(ROUTE_LABELS.get(route_key, "")),
		"is_route_active": route_key == current_route_key and not current_route_key.is_empty(),
		"focus_state": _resolve_focus_state(route_key, current_route_key),
		"is_locked": false,
		"lock_reason_text": ""
	}

func _build_transition_node_view_from_template(template_node: Dictionary, current_route_key: String) -> Dictionary:
	var node_type: String = str(template_node.get("node_type", "review"))
	var route_key: String = str(template_node.get("route_key", ""))
	return {
		"id": str(template_node.get("node_id", "")),
		"target_kind": "transition",
		"target_transition_kind": str(template_node.get("target_transition_kind", "advance_then_phase_entry")),
		"is_terminal": true,
		"title": str(template_node.get("title", "继续推进")),
		"hint": str(template_node.get("hint", "确认后进入下一段流程。")),
		"column": int(template_node.get("column", 1)),
		"lane": int(template_node.get("lane", 0)),
		"node_type": node_type,
		"type_label": str(template_node.get("type_label", NODE_TYPE_LABELS.get(node_type, "节点"))),
		"button_kind": str(template_node.get("button_kind", BUTTON_KIND_BY_NODE_TYPE.get(node_type, "event_story"))),
		"route_key": route_key,
		"route_label": str(ROUTE_LABELS.get(route_key, "")),
		"is_route_active": route_key == current_route_key and not current_route_key.is_empty(),
		"focus_state": _resolve_focus_state(route_key, current_route_key),
		"is_locked": false,
		"lock_reason_text": ""
	}

func _get_frontier_template_nodes(run_state: RunState, template: Dictionary) -> Array[Dictionary]:
	var template_nodes: Array[Dictionary] = Array(template.get("nodes", []), TYPE_DICTIONARY, "", null)
	var frontier_ids: Array[String] = _get_frontier_node_ids(run_state, template)
	if frontier_ids.is_empty():
		return template_nodes
	var nodes_by_id: Dictionary = {}
	for template_node: Dictionary in template_nodes:
		nodes_by_id[str(template_node.get("node_id", ""))] = template_node
	var frontier_nodes: Array[Dictionary] = []
	for node_id: String in frontier_ids:
		if not nodes_by_id.has(node_id):
			continue
		frontier_nodes.append(Dictionary(nodes_by_id.get(node_id, {})))
	return frontier_nodes

func _get_frontier_node_ids(run_state: RunState, template: Dictionary) -> Array[String]:
	var template_edges: Array[Dictionary] = Array(template.get("edges", []), TYPE_DICTIONARY, "", null)
	var from_id: String = _get_route_map_cursor_node_id(run_state)
	if from_id.is_empty():
		from_id = "start"
	var frontier_ids: Array[String] = []
	for edge: Dictionary in template_edges:
		if str(edge.get("from", "")) != from_id:
			continue
		var to_id: String = str(edge.get("to", ""))
		if to_id.is_empty() or frontier_ids.has(to_id):
			continue
		frontier_ids.append(to_id)
	return frontier_ids

func _get_forced_frontier_node_ids(template: Dictionary, target_event_id: String) -> Array[String]:
	var frontier_ids: Array[String] = []
	for template_node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(template_node.get("target_kind", "")) != "event":
			continue
		if str(template_node.get("target_id", "")) != target_event_id:
			continue
		var node_id: String = str(template_node.get("node_id", ""))
		if node_id.is_empty() or frontier_ids.has(node_id):
			continue
		frontier_ids.append(node_id)
	return frontier_ids

func _get_route_map_cursor_node_id(run_state: RunState) -> String:
	var cursor_day: int = int(run_state.world_state.values.get(ROUTE_MAP_CURSOR_DAY_KEY, 0))
	if cursor_day != run_state.world_state.day:
		return ""
	return str(run_state.world_state.global_flags.get(ROUTE_MAP_CURSOR_NODE_KEY, ""))

func _get_visited_node_ids(run_state: RunState) -> Array[String]:
	var visited_day: int = int(run_state.world_state.values.get(ROUTE_MAP_VISITED_DAY_KEY, 0))
	if visited_day != run_state.world_state.day:
		return []
	return Array(run_state.world_state.global_flags.get(ROUTE_MAP_VISITED_NODE_IDS_KEY, []), TYPE_STRING, "", null)

func _build_visited_path_text(template: Dictionary, visited_node_ids: Array[String]) -> String:
	if visited_node_ids.is_empty():
		return ""
	var title_parts: Array[String] = []
	for node_id: String in visited_node_ids:
		var node_title: String = _get_template_node_title(template, node_id)
		title_parts.append(node_title if not node_title.is_empty() else node_id)
	return "已走路径：%s" % " -> ".join(title_parts)

func _get_template_node_title(template: Dictionary, node_id: String) -> String:
	for template_node: Dictionary in Array(template.get("nodes", []), TYPE_DICTIONARY, "", null):
		if str(template_node.get("node_id", "")) != node_id:
			continue
		return str(template_node.get("title", node_id))
	return ""

func _resolve_fallback_node_type(action_definition: Dictionary) -> String:
	var action_category: String = str(action_definition.get("action_category", ""))
	if action_category == "investigate" and int(action_definition.get("risk_weight", 0)) >= 6:
		return "risk"
	return str(NODE_TYPE_FALLBACK_BY_ACTION_CATEGORY.get(action_category, "story"))

func _resolve_focus_state(node_route_key: String, current_route_key: String) -> String:
	if current_route_key.is_empty() or node_route_key.is_empty():
		return "neutral"
	if node_route_key == current_route_key:
		return "active"
	return "off_route"

func _get_story_event_lock_reason(
	run_state: RunState,
	condition_evaluator: ConditionEvaluator,
	definition: Dictionary,
	template_node: Dictionary,
	current_route_key: String
) -> String:
	var event_id: String = str(definition.get("id", ""))
	if event_id.is_empty():
		return str(template_node.get("locked_invalid_hint", "当前节点暂时不可进入。"))
	if not _to_bool(definition.get("repeatable", false)) and run_state.triggered_event_ids.has(event_id):
		return str(template_node.get("locked_repeat_hint", "这个关键节点你已经走过了。"))
	var block_conditions: Array[Dictionary] = Array(definition.get("block_conditions", []), TYPE_DICTIONARY, "", null)
	if not block_conditions.is_empty() and condition_evaluator.evaluate_all(run_state, block_conditions):
		return str(template_node.get("locked_blocked_hint", "这条路线眼下被别的局势卡住了。"))
	var conditions: Array[Dictionary] = Array(definition.get("trigger_conditions", []), TYPE_DICTIONARY, "", null)
	if condition_evaluator.evaluate_all(run_state, conditions):
		return ""
	var node_route_key: String = str(template_node.get("route_key", ""))
	var route_reason_text: String = _build_route_lock_reason(template_node, node_route_key, current_route_key)
	if not route_reason_text.is_empty():
		return route_reason_text
	var unmet_descriptions: Array[String] = condition_evaluator.get_unmet_descriptions(run_state, conditions)
	var template_condition_hint: String = str(template_node.get("locked_condition_hint", ""))
	if not template_condition_hint.is_empty():
		return template_condition_hint
	if unmet_descriptions.is_empty():
		return str(template_node.get("locked_fallback_hint", "当前条件还不够，暂时进不去。"))
	return "解锁条件：%s" % "；".join(unmet_descriptions.slice(0, min(unmet_descriptions.size(), 2)))

func _build_route_lock_reason(template_node: Dictionary, node_route_key: String, current_route_key: String) -> String:
	if node_route_key.is_empty():
		return str(template_node.get("locked_routeless_hint", ""))
	var route_label: String = str(ROUTE_LABELS.get(node_route_key, node_route_key))
	if current_route_key.is_empty():
		return str(template_node.get("locked_route_hint", "你还没把今天的推进真正压到%s，这个关键节点暂时不会打开。" % route_label))
	if current_route_key == node_route_key:
		return ""
	var current_route_label: String = str(ROUTE_LABELS.get(current_route_key, current_route_key))
	return str(template_node.get("locked_off_route_hint", "你当前主押的是%s，还没有切到%s。" % [current_route_label, route_label]))

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
