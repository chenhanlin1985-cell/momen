class_name MainGameScreen
extends Control

@onready var _day_label: Label = %DayLabel
@onready var _resource_label: Label = %ResourceLabel
@onready var _track_label: Label = %TrackLabel
@onready var _stats_label: Label = %StatsLabel
@onready var _story_label: Label = %StoryLabel
@onready var _goal_label: Label = %GoalLabel
@onready var _hint_label: Label = %HintLabel
@onready var _option_hint_label: Label = %OptionHintLabel
@onready var _status_label: Label = %StatusLabel
@onready var _actions_container: VBoxContainer = %ActionsContainer
@onready var _log_label: RichTextLabel = %LogLabel

func _ready() -> void:
	AppState.run_state_changed.connect(_refresh)
	AppState.error_raised.connect(_show_error)
	if AppState.current_run_state == null:
		RunController.start_new_run()
	else:
		_refresh(AppState.current_run_state)

func _refresh(run_state: RunState) -> void:
	var visible_actions: Array[Dictionary] = RunController.get_visible_actions()
	var current_event: Dictionary = RunController.get_current_event()
	var event_hints: Array[String] = RunController.get_event_hints()
	var current_event_option_views: Array[Dictionary] = RunController.get_current_event_option_views()
	var view_model: Dictionary = MainGameViewModel.build(
		run_state,
		visible_actions,
		current_event,
		event_hints,
		current_event_option_views
	)

	_day_label.text = str(view_model.get("day_text", ""))
	_resource_label.text = str(view_model.get("resource_text", ""))
	_track_label.text = str(view_model.get("track_text", ""))
	_stats_label.text = str(view_model.get("stats_text", ""))
	_story_label.text = str(view_model.get("story_text", ""))
	_goal_label.text = str(view_model.get("goal_text", ""))
	_hint_label.text = str(view_model.get("hint_text", ""))
	_option_hint_label.text = str(view_model.get("option_hint_text", ""))
	_log_label.text = str(view_model.get("log_text", ""))

	if run_state.is_run_over:
		var ending_text: String = str(view_model.get("ending_text", ""))
		if ending_text.is_empty():
			_status_label.text = "本局结束: %s" % run_state.end_reason
		else:
			_status_label.text = ending_text
	elif not current_event.is_empty():
		_status_label.text = str(view_model.get("event_text", ""))
	else:
		_status_label.text = "可用行动: %s" % str(view_model.get("action_text", ""))

	_rebuild_action_buttons(visible_actions, current_event, run_state.is_run_over)

func _show_error(message: String) -> void:
	_status_label.text = message

func _rebuild_action_buttons(
	visible_actions: Array[Dictionary],
	current_event: Dictionary,
	is_run_over: bool
) -> void:
	for child: Node in _actions_container.get_children():
		child.queue_free()

	if is_run_over:
		var restart_button: Button = Button.new()
		restart_button.text = "开始下一局"
		restart_button.pressed.connect(_on_restart_pressed)
		_actions_container.add_child(restart_button)
		return

	if not current_event.is_empty():
		for option_view: Dictionary in RunController.get_current_event_option_views():
			var button: Button = Button.new()
			button.text = str(option_view.get("text", option_view.get("id", "")))
			button.disabled = not bool(option_view.get("is_available", false))
			button.pressed.connect(_on_event_option_pressed.bind(str(option_view.get("id", ""))))
			_actions_container.add_child(button)
		return

	for action_definition: Dictionary in visible_actions:
		var button: Button = Button.new()
		button.text = _format_action_button_text(action_definition)
		button.pressed.connect(_on_action_pressed.bind(str(action_definition.get("id", ""))))
		_actions_container.add_child(button)

func _on_action_pressed(action_id: String) -> void:
	RunController.perform_action(action_id)

func _on_event_option_pressed(option_id: String) -> void:
	RunController.choose_event_option(option_id)

func _on_restart_pressed() -> void:
	RunController.start_new_run()

func _format_action_button_text(action_definition: Dictionary) -> String:
	var lines: Array[String] = [
		str(action_definition.get("display_name", action_definition.get("id", ""))),
		str(action_definition.get("description", ""))
	]
	var feedback_parts: Array[String] = []
	for key: String in action_definition.get("base_costs", {}).get("resources", {}).keys():
		feedback_parts.append("%s -%d" % [_describe_key(key), int(action_definition.get("base_costs", {}).get("resources", {})[key])])
	for key: String in action_definition.get("base_rewards", {}).get("resources", {}).keys():
		feedback_parts.append("%s +%d" % [_describe_key(key), int(action_definition.get("base_rewards", {}).get("resources", {})[key])])
	for key: String in action_definition.get("base_rewards", {}).get("stats", {}).keys():
		feedback_parts.append("%s +%d" % [_describe_key(key), int(action_definition.get("base_rewards", {}).get("stats", {})[key])])
	if not feedback_parts.is_empty():
		lines.append("反馈: " + "，".join(feedback_parts))
	return "\n".join(lines)

func _describe_key(key: String) -> String:
	var labels: Dictionary = {
		"blood_qi": "血气",
		"spirit_stone": "灵石",
		"spirit_sense": "神识",
		"clue_fragments": "线索",
		"pollution": "污染",
		"exposure": "暴露",
		"physique": "体魄",
		"mind": "心智",
		"insight": "悟性",
		"occult": "诡感",
		"tact": "手腕"
	}
	return str(labels.get(key, key))
