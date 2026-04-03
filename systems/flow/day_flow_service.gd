class_name DayFlowService
extends RefCounted

const GAME_TEXT := preload("res://systems/content/game_text.gd")

var _run_state_mutator: RunStateMutator


func _init(run_state_mutator: RunStateMutator) -> void:
	_run_state_mutator = run_state_mutator


func advance_after_action(_run_state: RunState) -> void:
	advance_after_event(_run_state)


func advance_after_event(run_state: RunState) -> void:
	if run_state.is_run_over:
		return

	match run_state.world_state.current_phase:
		"morning":
			_run_state_mutator.set_phase(run_state, "day")
			_run_state_mutator.append_log(run_state, GAME_TEXT.text("day_flow_service.logs.day_start"))
		"day":
			_run_state_mutator.set_phase(run_state, "night")
			_run_state_mutator.append_log(run_state, GAME_TEXT.text("day_flow_service.logs.day_complete"))
		"night":
			_run_state_mutator.set_phase(run_state, "closing")
			_run_state_mutator.append_log(run_state, GAME_TEXT.text("day_flow_service.logs.night_end"))
		"closing":
			if run_state.world_state.day >= run_state.world_state.max_day:
				_run_state_mutator.finish_run(run_state, "survived_cycle")
				_run_state_mutator.append_log(run_state, GAME_TEXT.text("day_flow_service.logs.final_resolution"))
				return
			_run_state_mutator.start_next_day(run_state)
			_run_state_mutator.append_log(run_state, GAME_TEXT.format_text("day_flow_service.logs.next_day", [run_state.world_state.day]))
