class_name DayFlowService
extends RefCounted

var _run_state_mutator: RunStateMutator

func _init(run_state_mutator: RunStateMutator) -> void:
	_run_state_mutator = run_state_mutator

func advance_after_action(run_state: RunState) -> void:
	if run_state.is_run_over:
		return
	if run_state.world_state.current_phase != "day":
		return
	if run_state.world_state.actions_remaining > 0:
		return
	_run_state_mutator.set_phase(run_state, "night")
	_run_state_mutator.append_log(run_state, "夜幕降临，别院的异常开始浮出水面。")

func advance_after_event(run_state: RunState) -> void:
	if run_state.is_run_over:
		return

	match run_state.world_state.current_phase:
		"morning":
			_run_state_mutator.set_phase(run_state, "day")
			_run_state_mutator.append_log(run_state, "白天开始，你需要选择今天要去的地点。")
		"day":
			_run_state_mutator.set_phase(run_state, "night")
			_run_state_mutator.append_log(run_state, "白天结束，夜间异常开始逼近。")
		"night":
			_run_state_mutator.set_phase(run_state, "closing")
			_run_state_mutator.append_log(run_state, "回到寝舍后，你开始整理今天的见闻与代价。")
		"closing":
			if run_state.world_state.day >= run_state.world_state.max_day:
				_run_state_mutator.finish_run(run_state, "survived_cycle")
				_run_state_mutator.append_log(run_state, "第七日结束，西井之事已逼到终局。")
				return
			_run_state_mutator.start_next_day(run_state)
			_run_state_mutator.append_log(run_state, "进入第 %d 天。" % run_state.world_state.day)
