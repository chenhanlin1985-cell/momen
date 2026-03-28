extends Node

func build_run_save_payload() -> Dictionary:
	if AppState.current_run_state == null:
		return {}
	return {
		"schema_version": 1,
		"run_state": AppState.current_run_state.to_dict()
	}

func build_meta_save_payload() -> Dictionary:
	return {
		"schema_version": 1,
		"meta_progress": AppState.meta_progress.to_dict()
	}

func restore_run_state(payload: Dictionary) -> void:
	var run_data: Dictionary = payload.get("run_state", {})
	if run_data.is_empty():
		return
	AppState.set_run_state(RunState.from_dict(run_data))

func restore_meta_progress(payload: Dictionary) -> void:
	var meta_data: Dictionary = payload.get("meta_progress", {})
	if meta_data.is_empty():
		return
	AppState.set_meta_progress(MetaProgress.from_dict(meta_data))
