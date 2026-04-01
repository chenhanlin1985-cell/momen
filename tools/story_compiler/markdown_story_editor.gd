@tool
extends Control

const COMPILER_SCRIPT := preload("res://tools/story_compiler/markdown_story_compiler.gd")

@onready var _compile_button: Button = %CompileButton
@onready var _validate_button: Button = %ValidateButton
@onready var _scan_button: Button = %ScanButton
@onready var _preview_diff_button: Button = %PreviewDiffButton
@onready var _refresh_button: Button = %RefreshButton
@onready var _open_output_button: Button = %OpenOutputButton
@onready var _export_writer_drafts_button: Button = %ExportWriterDraftsButton
@onready var _apply_dialogue_assets_button: Button = %ApplyDialogueAssetsButton
@onready var _apply_csv_assets_button: Button = %ApplyCsvAssetsButton
@onready var _apply_project_assets_button: Button = %ApplyProjectAssetsButton
@onready var _open_writer_drafts_button: Button = %OpenWriterDraftsButton
@onready var _open_syntax_button: Button = %OpenSyntaxButton
@onready var _open_event_map_button: Button = %OpenEventMapButton
@onready var _open_npc_map_button: Button = %OpenNpcMapButton
@onready var _open_location_map_button: Button = %OpenLocationMapButton
@onready var _open_status_map_button: Button = %OpenStatusMapButton
@onready var _source_list: ItemList = %SourceList
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _log_label: RichTextLabel = %LogLabel
@onready var _source_title_label: Label = $"MarginContainer/Root/Body/LeftPanel/LeftPadding/LeftContent/SourceTitle"
@onready var _source_hint_label: Label = $"MarginContainer/Root/Body/LeftPanel/LeftPadding/LeftContent/SourceHint"
@onready var _draft_title_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftTitle"
@onready var _draft_hint_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftHint"
@onready var _new_event_title_edit: LineEdit = %NewEventTitleEdit
@onready var _new_file_stem_edit: LineEdit = %NewFileStemEdit
@onready var _new_event_title_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/NewEventTitleLabel"
@onready var _new_file_stem_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/NewFileStemLabel"
@onready var _npc_selector_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/NpcSelectorLabel"
@onready var _location_selector_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/LocationSelectorLabel"
@onready var _class_selector_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/ClassSelectorLabel"
@onready var _stage_selector_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/StageSelectorLabel"
@onready var _time_selector_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/DraftGrid/TimeSelectorLabel"
@onready var _next_id_label: Label = %NextIdLabel
@onready var _npc_selector: OptionButton = %NpcSelector
@onready var _location_selector: OptionButton = %LocationSelector
@onready var _class_selector: OptionButton = %ClassSelector
@onready var _stage_selector: OptionButton = %StageSelector
@onready var _time_selector: OptionButton = %TimeSelector
@onready var _preview_button: Button = %PreviewButton
@onready var _copy_template_button: Button = %CopyTemplateButton
@onready var _create_draft_button: Button = %CreateDraftButton
@onready var _template_output: TextEdit = %TemplateOutput
@onready var _mapping_title_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/MappingTitle"
@onready var _mapping_hint_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/MappingHint"
@onready var _mapping_kind_selector: OptionButton = %MappingKindSelector
@onready var _mapping_scope_selector: OptionButton = %MappingScopeSelector
@onready var _mapping_kind_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/MappingGrid/MappingKindLabel"
@onready var _mapping_scope_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/MappingGrid/MappingScopeLabel"
@onready var _mapping_title_grid_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/MappingGrid/MappingTitleLabel"
@onready var _mapping_title_edit: LineEdit = %MappingTitleEdit
@onready var _mapping_key_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/MappingGrid/MappingKeyLabel"
@onready var _mapping_key_edit: LineEdit = %MappingKeyEdit
@onready var _add_mapping_button: Button = %AddMappingButton
@onready var _summary_title_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/SummaryTitle"
@onready var _log_title_label: Label = $"MarginContainer/Root/Body/RightPanel/RightPadding/RightContent/LogTitle"

var _compiler = null
var _event_map_entries: Array[Dictionary] = []
var _npc_entries: Array[Dictionary] = []
var _location_entries: Array[Dictionary] = []
var _status_entries: Array[Dictionary] = []


func _ready() -> void:
	_ensure_compiler()
	_apply_ui_texts()
	_apply_primary_button_texts()
	_compile_button.pressed.connect(_one_click_compile)
	_validate_button.pressed.connect(_validate_now)
	_scan_button.pressed.connect(_scan_issues)
	_preview_diff_button.pressed.connect(_preview_diff)
	_refresh_button.pressed.connect(_reload_view)
	_open_output_button.pressed.connect(_open_output_path)
	_export_writer_drafts_button.pressed.connect(_export_writer_drafts)
	_apply_dialogue_assets_button.pressed.connect(_apply_dialogue_assets)
	_apply_csv_assets_button.pressed.connect(_apply_csv_assets)
	_apply_project_assets_button.pressed.connect(_apply_project_assets)
	_open_writer_drafts_button.pressed.connect(_open_writer_drafts_path)
	_open_syntax_button.pressed.connect(_open_syntax_doc)
	_open_event_map_button.pressed.connect(_open_event_map)
	_open_npc_map_button.pressed.connect(_open_npc_map)
	_open_location_map_button.pressed.connect(_open_location_map)
	_open_status_map_button.pressed.connect(_open_status_map)
	_source_list.item_activated.connect(_open_selected_source)
	_source_list.item_selected.connect(_show_selected_source_hint)
	_preview_button.pressed.connect(_refresh_template_preview)
	_copy_template_button.pressed.connect(_copy_template)
	_create_draft_button.pressed.connect(_create_draft)
	_add_mapping_button.pressed.connect(_add_mapping)
	_mapping_kind_selector.item_selected.connect(_on_mapping_kind_changed)
	_new_event_title_edit.text_changed.connect(_on_new_event_title_changed)
	_reload_view()

func _apply_primary_button_texts() -> void:
	_compile_button.text = "一键编译"
	_apply_project_assets_button.text = "写回当前主结构"


func _apply_ui_texts() -> void:
	_compile_button.text = "编译草稿包"
	_validate_button.text = "仅校验"
	_scan_button.text = "扫描问题"
	_preview_diff_button.text = "预览草稿差异"
	_refresh_button.text = "刷新列表"
	_open_output_button.text = "定位草稿包"
	_export_writer_drafts_button.text = "导出草稿包"
	_open_writer_drafts_button.text = "打开草稿包"
	_apply_dialogue_assets_button.text = "写回对话资产"
	_apply_csv_assets_button.text = "鍐欏洖 CSV"
	_apply_project_assets_button.text = "一键写回当前结构"
	_open_syntax_button.text = "语法文档"
	_open_event_map_button.text = "事件编号表"
	_open_npc_map_button.text = "人物表"
	_open_location_map_button.text = "地点表"
	_open_status_map_button.text = "状态表"
	_preview_button.text = "刷新模板"
	_copy_template_button.text = "复制模板"
	_create_draft_button.text = "创建草稿并登记"
	_add_mapping_button.text = "新增映射"

	_source_title_label.text = "可编译 Markdown 源文件"
	_source_hint_label.text = "单击查看编译预览，双击在文件系统里定位源文件。"
	_draft_title_label.text = "新建事件草稿"
	_draft_hint_label.text = "先填事件名，再生成模板；当前工具优先服务现有三阶段对话。"
	_new_event_title_label.text = "中文事件名"
	_new_file_stem_label.text = "文件名"
	_npc_selector_label.text = "关联人物"
	_location_selector_label.text = "默认地点"
	_class_selector_label.text = "剧情分类"
	_stage_selector_label.text = "触发阶段"
	_time_selector_label.text = "触发时间"
	_mapping_title_label.text = "快速新增映射"
	_mapping_hint_label.text = "当编译提示缺映射时，可以直接在这里补事件、人物、地点或状态。"
	_mapping_kind_label.text = "映射类型"
	_mapping_scope_label.text = "状态范围"
	_mapping_title_grid_label.text = "中文名"
	_mapping_key_label.text = "内部值"
	_summary_title_label.text = "编译总览"
	_log_title_label.text = "当前预览 / 日志"

	_new_event_title_edit.placeholder_text = "例如：柳飞霞再次登门"
	_new_file_stem_edit.placeholder_text = "留空则自动生成"
	_mapping_title_edit.placeholder_text = "例如：已知王麻子杀人真相"
	_template_output.placeholder_text = "这里会生成新的 Markdown 模板。"


func _reload_view() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲锛岃閲嶆柊杞藉叆鎻掍欢銆俒/color]"
		return
	_load_mapping_data()
	_rebuild_selectors()
	_rebuild_source_list()
	_rebuild_summary()
	_refresh_template_preview()
	if _source_list.item_count > 0:
		_source_list.select(0)
		_show_selected_source_hint(0)
	else:
		_log_label.text = "[b]鏈壘鍒板彲缂栬瘧鐨?Markdown 鏂囦欢銆俒/b]"


func _rebuild_source_list() -> void:
	if not _ensure_compiler():
		return
	_source_list.clear()
	for path: String in _compiler.get_source_markdown_paths():
		var label: String = path.trim_prefix(_compiler.get_markdown_dir())
		_source_list.add_item(label)
		_source_list.set_item_metadata(_source_list.item_count - 1, path)


func _rebuild_summary(result: Dictionary = {}) -> void:
	if not _ensure_compiler():
		_summary_label.text = "[b]Markdown 鍓ф湰缂栬瘧鍣╗/b]\n缂栬瘧鍣ㄥ垵濮嬪寲澶辫触銆?
		return
	var mapping_paths: Dictionary = _compiler.get_mapping_paths()
	var lines: PackedStringArray = [
		"[b]Markdown 鍓ф湰缂栬瘧鍣╗/b]",
		"婧愭枃浠舵暟閲忥細%d" % _source_list.item_count,
		"涓嬩竴涓缓璁簨浠?ID锛?s" % _suggest_next_event_id(),
		"浣滆€呯洰褰曪細%s" % _compiler.get_markdown_authoring_dir(),
		"鑽夌鍖呰緭鍑猴細%s" % _compiler.get_writer_draft_output_path(),
		"浜嬩欢鏄犲皠锛?s" % str(mapping_paths.get("event_id_map", "")),
		"NPC 鏄犲皠锛?s" % str(mapping_paths.get("npc_name_map", "")),
		"鍦扮偣鏄犲皠锛?s" % str(mapping_paths.get("location_name_map", "")),
		"鐘舵€佹槧灏勶細%s" % str(mapping_paths.get("status_key_map", ""))
	]
	if not result.is_empty():
		lines.append("")
		lines.append("鏈€杩戜竴娆＄紪璇戯細%s" % ("鎴愬姛" if _to_bool(result.get("success", false)) else "澶辫触"))
		lines.append("缂栬瘧浜嬩欢鏁帮細%d" % int(result.get("event_count", 0)))
		lines.append("璀﹀憡鏁伴噺锛?d" % Array(result.get("warnings", [])).size())
		lines.append("閿欒鏁伴噺锛?d" % Array(result.get("errors", [])).size())
	_summary_label.text = "\n".join(lines)


func _one_click_compile() -> void:
	_apply_project_assets()


func _compile_now() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.compile_writer_drafts(true)
	_rebuild_source_list()
	_rebuild_summary(result)
	_log_label.text = _build_result_text(result)
	EditorInterface.get_resource_filesystem().scan()
	if _to_bool(result.get("success", false)):
		_navigate_to_path(str(result.get("writer_draft_output_path", _compiler.get_writer_draft_output_path())))


func _validate_now() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.compile_writer_drafts(false)
	_rebuild_summary(result)
	_log_label.text = _build_result_text(result, true)


func _scan_issues() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.compile_writer_drafts(false)
	_rebuild_summary(result)
	_log_label.text = _build_scan_text(result)


func _preview_diff() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.compile_writer_drafts(false)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var existing_text: String = ""
	var output_path: String = _compiler.get_writer_draft_output_path()
	if FileAccess.file_exists(output_path):
		var file: FileAccess = FileAccess.open(output_path, FileAccess.READ)
		if file != null:
			existing_text = file.get_as_text()
	var compiled_text: String = str(result.get("writer_draft_text", ""))
	_log_label.text = _build_text_diff_text(existing_text, compiled_text)


func _build_result_text(result: Dictionary, validate_only: bool = false) -> String:
	var lines: PackedStringArray = []
	if _to_bool(result.get("success", false)):
		lines.append("[b]%s鎴愬姛[/b]" % ("鏍￠獙" if validate_only else "缂栬瘧"))
	else:
		lines.append("[b]%s澶辫触[/b]" % ("鏍￠獙" if validate_only else "缂栬瘧"))
	if validate_only and _to_bool(result.get("success", false)):
		lines.append("褰撳墠 Markdown 涓庢槧灏勮〃鍙互閫氳繃缂栬瘧妫€鏌ャ€?)
	for warning_text: String in Array(result.get("warnings", []), TYPE_STRING, "", null):
		lines.append("[color=yellow]璀﹀憡锛?s[/color]" % warning_text)
	for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
		lines.append("[color=tomato]閿欒锛?s[/color]" % error_text)
	if lines.size() == 1 and _to_bool(result.get("success", false)):
		lines.append("娌℃湁棰濆璀﹀憡锛屼骇鐗╁凡鍒锋柊銆?)
	return "\n".join(lines)


func _build_selected_source_preview(path: String) -> String:
	if not _ensure_compiler():
		return "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
	var compile_result: Dictionary = _compiler.compile_markdown(false)
	if not _to_bool(compile_result.get("success", false)):
		return _build_result_text(compile_result, true)
	var events: Array = _compiler.parse_md_file(path)
	var lines: PackedStringArray = [
		"[b]褰撳墠婧愭枃浠禰/b]",
		path,
		"",
		"[b]缂栬瘧棰勮[/b]",
		"浜嬩欢鏁伴噺锛?d" % events.size()
	]
	if events.is_empty():
		lines.append("鏈В鏋愬埌浜嬩欢銆?)
		return "\n".join(lines)
	for event_variant: Variant in events:
		var event_definition: Dictionary = Dictionary(event_variant)
		lines.append("")
		lines.append_array(_build_event_preview_lines(event_definition))
	return "\n".join(lines)


func _build_event_preview_lines(event_definition: Dictionary) -> PackedStringArray:
	var event_id: String = _compiler._build_draft_event_id(event_definition)
	var title: String = str(event_definition.get("title", event_id))
	var opening_text: String = str(event_definition.get("opening_text", "")).strip_edges()
	var observation_text: String = str(event_definition.get("observation_text", "")).strip_edges()
	var options: Array = Array(event_definition.get("options", []))
	var intrusion_options: Dictionary = Dictionary(event_definition.get("intrusion_options", {}))
	var lines: PackedStringArray = [
		"[b]%s[/b]" % title,
		"project_event_id锛?s" % event_id,
		"鍒嗙被 / 鏃舵锛?s / %s" % [
			str(event_definition.get("content_category", "")),
			str(event_definition.get("time_slot", ""))
		]
	]
	if not opening_text.is_empty():
		lines.append("寮€鍦猴細%s" % _preview_snippet(opening_text))
	if not observation_text.is_empty():
		lines.append("瑙傚療锛?s" % _preview_snippet(observation_text))
	if not options.is_empty():
		lines.append("鍩虹瀵硅瘽锛?s" % _join_preview_items(_collect_option_texts(options)))
	if not intrusion_options.is_empty():
		lines.append("鍏ヤ镜鏀瑰啓锛?)
		for intrusion_id: String in ["greed", "wrath", "delusion"]:
			if not intrusion_options.has(intrusion_id):
				continue
			lines.append(_build_intrusion_preview_line(intrusion_id, Array(intrusion_options.get(intrusion_id, []))))
	return lines


func _build_intrusion_preview_line(intrusion_id: String, option_list: Array) -> String:
	var label_map := {
		"greed": "璐?,
		"wrath": "鍡?,
		"delusion": "鐥?
	}
	var parts: PackedStringArray = []
	for option_variant: Variant in option_list:
		var option_definition: Dictionary = Dictionary(option_variant)
		var text: String = str(option_definition.get("text", "")).strip_edges()
		var effects: Array = Array(option_definition.get("effects", []))
		var effect_summary: String = _summarize_effects(effects)
		if effect_summary.is_empty():
			parts.append(text)
		else:
			parts.append("%s -> %s" % [text, effect_summary])
	return "- %s锛?s" % [str(label_map.get(intrusion_id, intrusion_id)), _join_preview_items(parts)]


func _collect_option_texts(options: Array) -> PackedStringArray:
	var texts: PackedStringArray = []
	for option_variant: Variant in options:
		var option_definition: Dictionary = Dictionary(option_variant)
		var text: String = str(option_definition.get("text", "")).strip_edges()
		if not text.is_empty():
			texts.append(text)
	return texts


func _summarize_effects(effects: Array) -> String:
	var parts: PackedStringArray = []
	for effect_variant: Variant in effects:
		var effect: Dictionary = Dictionary(effect_variant)
		var effect_type: String = str(effect.get("type", ""))
		match effect_type:
			"set_flag":
				parts.append("flag:%s" % str(effect.get("key", "")))
			"clear_flag":
				parts.append("clear:%s" % str(effect.get("key", "")))
			"add_tag":
				parts.append("tag:%s" % str(effect.get("key", "")))
			"remove_tag":
				parts.append("untag:%s" % str(effect.get("key", "")))
			"add_npc_tag":
				parts.append("npc:%s=%s" % [str(effect.get("npc_id", "")), str(effect.get("key", ""))])
			"modify_resource":
				parts.append("resource:%s%+d" % [str(effect.get("key", "")), int(effect.get("delta", 0))])
			"finish_run":
				parts.append("gameover")
			_:
				if not effect_type.is_empty():
					parts.append(effect_type)
	return _join_preview_items(parts)


func _join_preview_items(items: Array) -> String:
	var parts: PackedStringArray = []
	for item_variant: Variant in items:
		var text: String = str(item_variant).strip_edges()
		if not text.is_empty():
			parts.append(text)
	return " | ".join(parts)


func _preview_snippet(text: String, max_length: int = 72) -> String:
	var single_line: String = text.replace("\r", " ").replace("\n", " ").strip_edges()
	if single_line.length() <= max_length:
		return single_line
	return "%s..." % single_line.substr(0, max_length)


func _build_scan_text(result: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]鎵弿缁撴灉[/b]")
	if _to_bool(result.get("success", false)):
		lines.append("缂栬瘧缁撴瀯鍙€氳繃妫€鏌ャ€?)
	else:
		lines.append("瀛樺湪闃诲閿欒锛岄渶瑕佸厛淇銆?)
	for error_text: String in Array(result.get("errors", []), TYPE_STRING, "", null):
		lines.append("[color=tomato]閿欒锛?s[/color]" % error_text)
	for warning_text: String in Array(result.get("warnings", []), TYPE_STRING, "", null):
		lines.append("[color=yellow]璀﹀憡锛?s[/color]" % warning_text)
	if Array(result.get("errors", [])).is_empty() and Array(result.get("warnings", [])).is_empty():
		lines.append("娌℃湁鍙戠幇缂哄け鏄犲皠鎴栧彲鐤戝啓娉曘€?)
	return "\n".join(lines)


func _build_diff_text(existing_events: Array[Dictionary], compiled_events: Array[Dictionary]) -> String:
	var old_by_id: Dictionary = {}
	for item: Dictionary in existing_events:
		old_by_id[str(item.get("id", ""))] = JSON.stringify(item)
	var new_by_id: Dictionary = {}
	var added: PackedStringArray = []
	var changed: PackedStringArray = []
	for item: Dictionary in compiled_events:
		var event_id: String = str(item.get("id", ""))
		new_by_id[event_id] = JSON.stringify(item)
		if not old_by_id.has(event_id):
			added.append("%s / %s" % [event_id, str(item.get("title", ""))])
		elif str(old_by_id[event_id]) != str(new_by_id[event_id]):
			changed.append("%s / %s" % [event_id, str(item.get("title", ""))])
	var removed: PackedStringArray = []
	for event_id: Variant in old_by_id.keys():
		if not new_by_id.has(str(event_id)):
			removed.append(str(event_id))
	var lines: PackedStringArray = [
		"[b]缂栬瘧鍙樺寲棰勮[/b]",
		"鏂板浜嬩欢锛?d" % added.size(),
		"鏀瑰姩浜嬩欢锛?d" % changed.size(),
		"灏嗚绉婚櫎锛?d" % removed.size()
	]
	if not added.is_empty():
		lines.append("")
		lines.append("[b]鏂板[/b]")
		for item: String in added:
			lines.append("- %s" % item)
	if not changed.is_empty():
		lines.append("")
		lines.append("[b]鏀瑰姩[/b]")
		for item: String in changed:
			lines.append("- %s" % item)
	if not removed.is_empty():
		lines.append("")
		lines.append("[b]绉婚櫎[/b]")
		for item: String in removed:
			lines.append("- %s" % item)
	if added.is_empty() and changed.is_empty() and removed.is_empty():
		lines.append("")
		lines.append("褰撳墠缂栬瘧缁撴灉涓庣幇鏈変骇鐗╀竴鑷淬€?)
	return "\n".join(lines)


func _build_text_diff_text(existing_text: String, compiled_text: String) -> String:
	var lines: PackedStringArray = ["[b]褰撳墠椤圭洰鑽夌鍖呴瑙圼/b]"]
	if existing_text == compiled_text:
		lines.append("褰撳墠瀵煎嚭缁撴灉涓庣幇鏈夎崏绋垮寘涓€鑷淬€?)
	else:
		lines.append("褰撳墠瀵煎嚭缁撴灉灏嗘洿鏂拌崏绋垮寘鍐呭銆?)
		lines.append("鐜版湁闀垮害锛?d" % existing_text.length())
		lines.append("鏂扮闀垮害锛?d" % compiled_text.length())
	return "\n".join(lines)


func _show_selected_source_hint(index: int) -> void:
	if index < 0 or index >= _source_list.item_count:
		return
	var path: String = str(_source_list.get_item_metadata(index))
	_log_label.text = _build_selected_source_preview(path)


func _open_selected_source(index: int) -> void:
	if index < 0 or index >= _source_list.item_count:
		return
	_navigate_to_path(str(_source_list.get_item_metadata(index)))


func _open_output_path() -> void:
	if not _ensure_compiler():
		return
	_navigate_to_path(_compiler.get_writer_draft_output_path())


func _export_writer_drafts() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.compile_writer_drafts(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var output_path: String = str(result.get("writer_draft_output_path", _compiler.get_writer_draft_output_path()))
	_log_label.text = "[b]宸插鍑哄綋鍓嶉」鐩崏绋垮寘[/b]\n%s" % output_path
	EditorInterface.get_resource_filesystem().scan()
	_navigate_to_path(output_path)


func _apply_dialogue_assets() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.apply_current_dialogue_assets(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var event_ids: Array = Array(result.get("dialogue_asset_event_ids", []))
	var file_paths: Array = Array(result.get("dialogue_asset_files", []))
	var lines: PackedStringArray = ["[b]宸插啓鍥炲綋鍓嶅璇濊祫浜/b]", "浜嬩欢鏁伴噺锛?d" % event_ids.size()]
	for event_id: String in event_ids:
		lines.append("- %s" % event_id)
	if not file_paths.is_empty():
		lines.append("")
		lines.append("[b]鏇存柊鏂囦欢[/b]")
		for path: String in file_paths:
			lines.append("- %s" % path)
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "\n".join(lines)


func _apply_csv_assets() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.apply_current_csv_assets(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var event_ids: Array = Array(result.get("csv_asset_event_ids", []))
	var file_paths: Array = Array(result.get("csv_asset_files", []))
	var lines: PackedStringArray = ["[b]宸插啓鍥炲綋鍓?CSV 璧勪骇[/b]", "浜嬩欢鏁伴噺锛?d" % event_ids.size()]
	for event_id: String in event_ids:
		lines.append("- %s" % event_id)
	if not file_paths.is_empty():
		lines.append("")
		lines.append("[b]鏇存柊鏂囦欢[/b]")
		for path: String in file_paths:
			lines.append("- %s" % path)
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "\n".join(lines)


func _apply_project_assets() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var result: Dictionary = _compiler.apply_current_project_assets(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var dialogue_files: Array = Array(result.get("dialogue_asset_files", []))
	var csv_files: Array = Array(result.get("csv_asset_files", []))
	var lines: PackedStringArray = ["[b]宸插啓鍥炲綋鍓嶄富缁撴瀯[/b]"]
	lines.append("瀵硅瘽璧勪骇鏂囦欢锛?d" % dialogue_files.size())
	lines.append("CSV 鏂囦欢锛?d" % csv_files.size())
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "\n".join(lines)


func _open_writer_drafts_path() -> void:
	if not _ensure_compiler():
		return
	_navigate_to_path(_compiler.get_writer_draft_output_path())


func _open_syntax_doc() -> void:
	_navigate_to_path("res://docs/MARKDOWN_SYNTAX.md")


func _open_event_map() -> void:
	_open_mapping_path("event_id_map")


func _open_npc_map() -> void:
	_open_mapping_path("npc_name_map")


func _open_location_map() -> void:
	_open_mapping_path("location_name_map")


func _open_status_map() -> void:
	_open_mapping_path("status_key_map")


func _open_mapping_path(key: String) -> void:
	if not _ensure_compiler():
		return
	var path: String = str(_compiler.get_mapping_paths().get(key, ""))
	if path.is_empty():
		_log_label.text = "[color=tomato]娌℃湁鎵惧埌鏄犲皠鏂囦欢锛?s[/color]" % key
		return
	_navigate_to_path(path)


func _navigate_to_path(path: String) -> void:
	if path.is_empty():
		_log_label.text = "[color=tomato]鐩爣璺緞涓虹┖銆俒/color]"
		return
	EditorInterface.get_resource_filesystem().scan()
	var dock := EditorInterface.get_file_system_dock()
	if dock != null and dock.has_method("navigate_to_path"):
		dock.call_deferred("navigate_to_path", path)
		_log_label.text = "[b]宸插畾浣嶆枃浠禰/b]\n%s" % path
		return
	var global_path: String = ProjectSettings.globalize_path(path)
	OS.shell_open(global_path)
	_log_label.text = "[b]宸插皾璇曟墦寮€鏂囦欢[/b]\n%s" % path


func _load_mapping_data() -> void:
	if not _ensure_compiler():
		return
	var mapping_paths: Dictionary = _compiler.get_mapping_paths()
	_event_map_entries = _load_array_file(str(mapping_paths.get("event_id_map", "")))
	_npc_entries = _load_array_file(str(mapping_paths.get("npc_name_map", "")))
	_location_entries = _load_array_file(str(mapping_paths.get("location_name_map", "")))
	_status_entries = _load_array_file(str(mapping_paths.get("status_key_map", "")))


func _load_array_file(path: String) -> Array[Dictionary]:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return []
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_ARRAY:
		return []
	var result: Array[Dictionary] = []
	for item: Variant in parsed:
		if item is Dictionary:
			result.append(Dictionary(item).duplicate(true))
	return result


func _rebuild_selectors() -> void:
	_populate_selector(_npc_selector, _npc_entries, "鏈寚瀹氫汉鐗?)
	_populate_selector(_location_selector, _location_entries, "鏈寚瀹氬湴鐐?)
	_populate_static_selector(_class_selector, [
		{"label": "鏉′欢鍓ф儏浜嬩欢", "value": "鏉′欢鍓ф儏浜嬩欢"},
		{"label": "鍥哄畾鍓ф儏浜嬩欢", "value": "鍥哄畾鍓ф儏浜嬩欢"},
		{"label": "闅忔満鎵板姩浜嬩欢", "value": "闅忔満鎵板姩浜嬩欢"}
	])
	_populate_static_selector(_stage_selector, [
		{"label": "琛屽姩鍚?, "value": "琛屽姩鍚?},
		{"label": "闃舵寮€濮嬫椂", "value": "闃舵寮€濮嬫椂"}
	])
	_populate_static_selector(_time_selector, [
		{"label": "鐧藉ぉ", "value": "鐧藉ぉ"},
		{"label": "鏅ㄩ棿", "value": "鏅ㄩ棿"},
		{"label": "澶滈棿", "value": "澶滈棿"}
	])
	_populate_static_selector(_mapping_kind_selector, [
		{"label": "浜嬩欢鏄犲皠", "value": "event"},
		{"label": "NPC 鏄犲皠", "value": "npc"},
		{"label": "鍦扮偣鏄犲皠", "value": "location"},
		{"label": "鐘舵€佹槧灏?, "value": "status"}
	])
	_populate_static_selector(_mapping_scope_selector, [
		{"label": "鍏ㄥ眬鐘舵€?, "value": "flag"},
		{"label": "鐜╁鏍囪", "value": "player_tag"},
		{"label": "浜虹墿鐘舵€?, "value": "npc_tag"}
	])
	_on_mapping_kind_changed(_mapping_kind_selector.selected)
	_next_id_label.text = "寤鸿鏂颁簨浠?ID锛?s" % _suggest_next_event_id()


func _populate_selector(selector: OptionButton, entries: Array[Dictionary], empty_label: String) -> void:
	selector.clear()
	selector.add_item(empty_label)
	selector.set_item_metadata(0, "")
	var sorted_entries: Array[Dictionary] = entries.duplicate(true)
	sorted_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return str(a.get("title", "")) < str(b.get("title", ""))
	)
	for entry: Dictionary in sorted_entries:
		var title: String = str(entry.get("title", ""))
		selector.add_item(title)
		selector.set_item_metadata(selector.item_count - 1, title)
	selector.select(0)


func _populate_static_selector(selector: OptionButton, items: Array[Dictionary]) -> void:
	selector.clear()
	for item: Dictionary in items:
		selector.add_item(str(item.get("label", "")))
		selector.set_item_metadata(selector.item_count - 1, str(item.get("value", "")))
	if selector.item_count > 0:
		selector.select(0)


func _on_new_event_title_changed(new_text: String) -> void:
	if _new_file_stem_edit.text.strip_edges().is_empty():
		_new_file_stem_edit.text = _suggest_short_file_stem(_suggest_next_event_id())
	_refresh_template_preview()


func _refresh_template_preview() -> void:
	_template_output.text = _build_template_text()
	_next_id_label.text = "寤鸿鏂颁簨浠?ID锛?s" % _suggest_next_event_id()


func _on_mapping_kind_changed(index: int) -> void:
	var kind: String = _selected_selector_value(_mapping_kind_selector)
	_mapping_scope_selector.visible = kind == "status"
	if kind == "event":
		_mapping_key_edit.placeholder_text = "鏁板瓧 ID"
	elif kind == "npc":
		_mapping_key_edit.placeholder_text = "浠呭簳灞傝繍琛屾椂浣跨敤"
	elif kind == "location":
		_mapping_key_edit.placeholder_text = "浠呭簳灞傝繍琛屾椂浣跨敤"
	else:
		_mapping_key_edit.placeholder_text = "浠呭簳灞傝繍琛屾椂浣跨敤"


func _build_template_text() -> String:
	var title: String = _new_event_title_edit.text.strip_edges()
	if title.is_empty():
		title = "鏂颁簨浠舵爣棰?
	var location_label: String = _selected_selector_value(_location_selector)
	var class_label: String = _selected_selector_value(_class_selector)
	var stage_label: String = _selected_selector_value(_stage_selector)
	var time_label: String = _selected_selector_value(_time_selector)
	var lines: PackedStringArray = [
		"# [浜嬩欢] %s" % title,
		"@鍓ф儏鍒嗙被: %s" % class_label,
		"@琛ㄧ幇褰㈠紡: 鏅€氫簨浠?,
		"@瑙﹀彂闃舵: %s" % stage_label,
		"@瑙﹀彂鏃堕棿: %s" % time_label
	]
	if not location_label.is_empty():
		lines.append("@鍦扮偣: %s" % location_label)
	lines.append("")
	lines.append("鍦ㄨ繖閲屽啓浜嬩欢姝ｆ枃銆?)
	lines.append("")
	lines.append("=> [閫夐」涓€]")
	lines.append("杩欓噷鍐欓€夐」涓€鐨勭粨鏋溿€?)
	lines.append("$ 澧炲姞鏍囪: 鏂扮姸鎬佸悕 $")
	lines.append("")
	lines.append("=> [閫夐」浜宂")
	lines.append("杩欓噷鍐欓€夐」浜岀殑缁撴灉銆?)
	return "\n".join(lines)


func _copy_template() -> void:
	DisplayServer.clipboard_set(_template_output.text)
	_log_label.text = "[b]宸插鍒舵ā鏉縖/b]\n浣犵幇鍦ㄥ彲浠ョ洿鎺ョ矘璐村埌鏂扮殑 Markdown 鏂囦欢銆?


func _create_draft() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return
	var title: String = _new_event_title_edit.text.strip_edges()
	if title.is_empty():
		_log_label.text = "[color=tomato]璇峰厛濉啓涓枃浜嬩欢鍚嶃€俒/color]"
		return
	var event_id: String = _suggest_next_event_id()
	var file_stem: String = _new_file_stem_edit.text.strip_edges()
	if file_stem.is_empty():
		file_stem = _suggest_short_file_stem(event_id)
		_new_file_stem_edit.text = file_stem
	var authoring_dir: String = _compiler.get_markdown_authoring_dir()
	var npc_slug: String = _selected_npc_folder_prefix()
	if npc_slug.is_empty() or npc_slug == _suggest_file_stem("鏈寚瀹氫汉鐗?):
		npc_slug = "ev"
	var target_dir: String = "%s%s" % [authoring_dir, npc_slug]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))
	var target_path: String = "%s/%s.md" % [target_dir, file_stem]
	if FileAccess.file_exists(target_path):
		_log_label.text = "[color=tomato]鐩爣鏂囦欢宸插瓨鍦細%s[/color]" % target_path
		return
	if not _append_event_mapping(title, event_id):
		return
	var file: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		_log_label.text = "[color=tomato]鏃犳硶鍒涘缓 Markdown 鏂囦欢锛?s[/color]" % target_path
		return
	file.store_string(_template_output.text)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	_load_mapping_data()
	_rebuild_selectors()
	_rebuild_source_list()
	_rebuild_summary()
	_log_label.text = "[b]宸插垱寤烘柊鑽夌[/b]\n浜嬩欢鍚嶏細%s\n浜嬩欢 ID锛?s\n鏂囦欢锛?s" % [title, event_id, target_path]
	_navigate_to_path(target_path)


func _append_event_mapping(title: String, event_id: String) -> bool:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return false
	for entry: Dictionary in _event_map_entries:
		if str(entry.get("title", "")) == title:
			_log_label.text = "[color=tomato]浜嬩欢鍚嶅凡瀛樺湪鏄犲皠锛?s[/color]" % title
			return false
		if str(entry.get("id", "")) == event_id:
			_log_label.text = "[color=tomato]寤鸿 ID 宸茶鍗犵敤锛岃鍒锋柊鍚庨噸璇曪細%s[/color]" % event_id
			return false
	var updated_entries: Array = []
	for entry: Dictionary in _event_map_entries:
		updated_entries.append(entry)
	updated_entries.append({"id": event_id, "title": title})
	var path: String = str(_compiler.get_mapping_paths().get("event_id_map", ""))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_log_label.text = "[color=tomato]鏃犳硶鍐欏叆浜嬩欢鏄犲皠琛細%s[/color]" % path
		return false
	file.store_string(JSON.stringify(updated_entries, "\t"))
	file.close()
	return true


func _add_mapping() -> void:
	var kind: String = _selected_selector_value(_mapping_kind_selector)
	var title: String = _mapping_title_edit.text.strip_edges()
	var key_text: String = _mapping_key_edit.text.strip_edges()
	if title.is_empty() or key_text.is_empty():
		_log_label.text = "[color=tomato]璇峰厛濉啓涓枃鍚嶅拰鍐呴儴鍊笺€俒/color]"
		return
	match kind:
		"event":
			if not _append_event_mapping(title, key_text):
				return
		"npc":
			if not _append_mapping_entry("npc_name_map", _npc_entries, {"id": key_text, "title": title}):
				return
		"location":
			if not _append_mapping_entry("location_name_map", _location_entries, {"id": key_text, "title": title}):
				return
		"status":
			var scope: String = _selected_selector_value(_mapping_scope_selector)
			if not _append_mapping_entry("status_key_map", _status_entries, {"scope": scope, "key": key_text, "title": title}):
				return
		_:
			_log_label.text = "[color=tomato]鏈瘑鍒槧灏勭被鍨嬨€俒/color]"
			return
	EditorInterface.get_resource_filesystem().scan()
	_load_mapping_data()
	_rebuild_selectors()
	_rebuild_summary()
	_mapping_title_edit.clear()
	_mapping_key_edit.clear()
	_log_label.text = "[b]宸叉柊澧炴槧灏刐/b]\n绫诲瀷锛?s\n涓枃鍚嶏細%s\n鍐呴儴鍊硷細%s" % [kind, title, key_text]


func _append_mapping_entry(mapping_key: String, existing_entries: Array[Dictionary], new_entry: Dictionary) -> bool:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]缂栬瘧鍣ㄨ剼鏈湭鑳藉垵濮嬪寲銆俒/color]"
		return false
	for entry: Dictionary in existing_entries:
		if str(entry.get("title", "")) == str(new_entry.get("title", "")):
			_log_label.text = "[color=tomato]涓枃鍚嶅凡瀛樺湪鏄犲皠锛?s[/color]" % str(new_entry.get("title", ""))
			return false
		var compare_key_name: String = "id" if new_entry.has("id") else "key"
		if str(entry.get(compare_key_name, "")) == str(new_entry.get(compare_key_name, "")):
			_log_label.text = "[color=tomato]鍐呴儴鍊煎凡瀛樺湪鏄犲皠锛?s[/color]" % str(new_entry.get(compare_key_name, ""))
			return false
	var updated_entries: Array = []
	for entry: Dictionary in existing_entries:
		updated_entries.append(entry)
	updated_entries.append(new_entry)
	var path: String = str(_compiler.get_mapping_paths().get(mapping_key, ""))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_log_label.text = "[color=tomato]鏃犳硶鍐欏叆鏄犲皠琛細%s[/color]" % path
		return false
	file.store_string(JSON.stringify(updated_entries, "\t"))
	file.close()
	return true


func _suggest_next_event_id() -> String:
	var max_id: int = 999
	for entry: Dictionary in _event_map_entries:
		var value: int = str(entry.get("id", "0")).to_int()
		if value > max_id:
			max_id = value
	return str(max_id + 1)


func _suggest_file_stem(title: String) -> String:
	var lower: String = title.to_snake_case().strip_edges().to_lower()
	var cleaned := ""
	for i: int in lower.length():
		var char := lower[i]
		if (char >= "a" and char <= "z") or (char >= "0" and char <= "9") or char == "_":
			cleaned += char
	if cleaned.is_empty():
		return "event_%s" % _suggest_next_event_id()
	return cleaned

func _suggest_short_file_stem(event_id: String) -> String:
	return event_id

func _selected_npc_folder_prefix() -> String:
	var npc_id: String = _selected_selector_value(_npc_selector)
	match npc_id:
		"friendly_peer":
			return "01"
		"herb_steward":
			return "02"
		"night_patrol_disciple":
			return "03"
		"outer_senior_brother":
			return "04"
		"mad_elder":
			return "05"
		"wang_deacon":
			return "06"
		"":
			return "00"
		_:
			return "00"

func _selected_npc_file_prefix() -> String:
	var npc_id: String = _selected_selector_value(_npc_selector)
	match npc_id:
		"friendly_peer":
			return "fp"
		"herb_steward":
			return "hs"
		"night_patrol_disciple":
			return "np"
		"outer_senior_brother":
			return "os"
		"mad_elder":
			return "me"
		"wang_deacon":
			return "wd"
		"":
			return "ev"
		_:
			var compact: String = ""
			for part: String in npc_id.split("_", false):
				if not part.is_empty():
					compact += part.left(1)
			if compact.length() >= 2:
				return compact.left(2)
			if compact.length() == 1:
				return "%se" % compact
			return "ev"


func _selected_selector_value(selector: OptionButton) -> String:
	if selector.selected < 0:
		return ""
	return str(selector.get_item_metadata(selector.selected))


func _ensure_compiler() -> bool:
	if _compiler != null:
		return true
	if COMPILER_SCRIPT == null:
		return false
	_compiler = COMPILER_SCRIPT.new()
	return _compiler != null


func _to_bool(value: Variant) -> bool:
	match typeof(value):
		TYPE_BOOL:
			return value
		TYPE_INT, TYPE_FLOAT:
			return value != 0
		TYPE_STRING:
			var text: String = String(value).strip_edges().to_lower()
			return text == "true" or text == "1" or text == "yes"
		_:
			return value != null
