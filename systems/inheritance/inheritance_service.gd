class_name InheritanceService
extends RefCounted

func generate_options(run_state: RunState) -> Array[Dictionary]:
	if not run_state.is_run_over:
		return []
	return [
		{
			"id": "fragmented_memory_placeholder",
			"display_name": "残缺记忆",
			"description": "这是周目继承系统的占位实现，用于后续接入正式遗产数据。"
		}
	]
