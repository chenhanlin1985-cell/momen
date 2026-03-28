extends Node

signal run_state_changed(run_state: RunState)
signal meta_progress_changed(meta_progress: MetaProgress)
signal run_started(run_state: RunState)
signal run_ended(run_state: RunState)
signal error_raised(message: String)

var current_run_state: RunState
var meta_progress: MetaProgress = MetaProgress.new()

func set_run_state(run_state: RunState) -> void:
	current_run_state = run_state
	run_state_changed.emit(current_run_state)
	if current_run_state.is_run_over:
		run_ended.emit(current_run_state)

func set_meta_progress(value: MetaProgress) -> void:
	meta_progress = value
	meta_progress_changed.emit(meta_progress)

func emit_run_started(run_state: RunState) -> void:
	run_started.emit(run_state)

func raise_error(message: String) -> void:
	error_raised.emit(message)
