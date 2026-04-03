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

@onready var _source_title_label: Label = %SourceTitle
@onready var _source_hint_label: Label = %SourceHint
@onready var _source_list: ItemList = %SourceList

@onready var _draft_title_label: Label = %DraftTitle
@onready var _draft_hint_label: Label = %DraftHint
@onready var _new_event_title_label: Label = %NewEventTitleLabel
@onready var _new_file_stem_label: Label = %NewFileStemLabel
@onready var _npc_selector_label: Label = %NpcSelectorLabel
@onready var _location_selector_label: Label = %LocationSelectorLabel
@onready var _class_selector_label: Label = %ClassSelectorLabel
@onready var _stage_selector_label: Label = %StageSelectorLabel
@onready var _time_selector_label: Label = %TimeSelectorLabel
@onready var _new_event_title_edit: LineEdit = %NewEventTitleEdit
@onready var _new_file_stem_edit: LineEdit = %NewFileStemEdit
@onready var _npc_selector: OptionButton = %NpcSelector
@onready var _location_selector: OptionButton = %LocationSelector
@onready var _class_selector: OptionButton = %ClassSelector
@onready var _stage_selector: OptionButton = %StageSelector
@onready var _time_selector: OptionButton = %TimeSelector
@onready var _next_id_label: Label = %NextIdLabel
@onready var _preview_button: Button = %PreviewButton
@onready var _copy_template_button: Button = %CopyTemplateButton
@onready var _create_draft_button: Button = %CreateDraftButton
@onready var _template_output: TextEdit = %TemplateOutput

@onready var _mapping_title_label: Label = %MappingTitle
@onready var _mapping_hint_label: Label = %MappingHint
@onready var _mapping_kind_label: Label = %MappingKindLabel
@onready var _mapping_scope_label: Label = %MappingScopeLabel
@onready var _mapping_title_grid_label: Label = %MappingTitleLabel
@onready var _mapping_key_label: Label = %MappingKeyLabel
@onready var _mapping_kind_selector: OptionButton = %MappingKindSelector
@onready var _mapping_scope_selector: OptionButton = %MappingScopeSelector
@onready var _mapping_title_edit: LineEdit = %MappingTitleEdit
@onready var _mapping_key_edit: LineEdit = %MappingKeyEdit
@onready var _add_mapping_button: Button = %AddMappingButton

@onready var _summary_title_label: Label = %SummaryTitle
@onready var _summary_label: RichTextLabel = %SummaryLabel
@onready var _log_title_label: Label = %LogTitle
@onready var _log_label: RichTextLabel = %LogLabel

var _compiler = null
var _event_map_entries: Array[Dictionary] = []
var _npc_entries: Array[Dictionary] = []
var _location_entries: Array[Dictionary] = []
var _status_entries: Array[Dictionary] = []


func _ready() -> void:
	_apply_ui_texts()
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]编译器脚本初始化失败，请检查 markdown_story_compiler.gd。[/color]"
		return
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
	_source_list.item_selected.connect(_show_selected_source_hint)
	_source_list.item_activated.connect(_open_selected_source)
	_preview_button.pressed.connect(_refresh_template_preview)
	_copy_template_button.pressed.connect(_copy_template)
	_create_draft_button.pressed.connect(_create_draft)
	_add_mapping_button.pressed.connect(_add_mapping)
	_mapping_kind_selector.item_selected.connect(_on_mapping_kind_changed)
	_new_event_title_edit.text_changed.connect(_on_new_event_title_changed)
	_reload_view()


func _apply_ui_texts() -> void:
	_compile_button.text = "一键编译"
	_validate_button.text = "仅校验"
	_scan_button.text = "扫描问题"
	_preview_diff_button.text = "预览草稿差异"
	_refresh_button.text = "刷新列表"
	_open_output_button.text = "定位草稿包"
	_export_writer_drafts_button.text = "导出草稿包"
	_open_writer_drafts_button.text = "打开草稿包"
	_apply_dialogue_assets_button.text = "写回对话资产"
	_apply_csv_assets_button.text = "写回 CSV"
	_apply_project_assets_button.text = "写回当前主结构"
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
	_source_hint_label.text = "单击查看解析预览，双击在文件系统里定位源文件。"
	_draft_title_label.text = "新建事件草稿"
	_draft_hint_label.text = "作者层只使用数字编号、数字文件名和中文说明。"
	_new_event_title_label.text = "中文事件名"
	_new_file_stem_label.text = "文件名"
	_npc_selector_label.text = "关联人物"
	_location_selector_label.text = "默认地点"
	_class_selector_label.text = "剧情分类"
	_stage_selector_label.text = "触发阶段"
	_time_selector_label.text = "触发时间"
	_mapping_title_label.text = "快速新增映射"
	_mapping_hint_label.text = "编译提示缺映射时，可以直接在这里补事件、人物、地点或状态。"
	_mapping_kind_label.text = "映射类型"
	_mapping_scope_label.text = "状态范围"
	_mapping_title_grid_label.text = "中文名"
	_mapping_key_label.text = "内部值"
	_summary_title_label.text = "编译总览"
	_log_title_label.text = "当前预览 / 日志"

	_new_event_title_edit.placeholder_text = "例如：柳飞霞再次登门"
	_new_file_stem_edit.placeholder_text = "留空则自动使用数字编号"
	_mapping_title_edit.placeholder_text = "例如：已知王麻子杀人真相"
	_mapping_key_edit.placeholder_text = "内部值"
	_template_output.placeholder_text = "这里会生成新的 Markdown 模板。"


func _reload_view() -> void:
	if not _ensure_compiler():
		_log_label.text = "[color=tomato]编译器脚本初始化失败。[/color]"
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
		_log_label.text = "[b]未找到可编译的 Markdown 文件。[/b]"


func _rebuild_source_list() -> void:
	_source_list.clear()
	for path: String in _compiler.get_source_markdown_paths():
		var label := path.trim_prefix(_compiler.get_markdown_dir())
		_source_list.add_item(label)
		_source_list.set_item_metadata(_source_list.item_count - 1, path)


func _rebuild_summary(result: Dictionary = {}) -> void:
	var lines: PackedStringArray = [
		"[b]Markdown 剧本编译器[/b]",
		"源文件数量：%d" % _source_list.item_count,
		"下一建议事件 ID：%s" % _suggest_next_event_id(),
		"作者目录：%s" % _compiler.get_markdown_authoring_dir(),
		"草稿包输出：%s" % _compiler.get_writer_draft_output_path()
	]
	var mapping_paths: Dictionary = _compiler.get_mapping_paths()
	lines.append("事件映射：%s" % str(mapping_paths.get("event_id_map", "")))
	lines.append("人物映射：%s" % str(mapping_paths.get("npc_name_map", "")))
	lines.append("地点映射：%s" % str(mapping_paths.get("location_name_map", "")))
	lines.append("状态映射：%s" % str(mapping_paths.get("status_key_map", "")))
	if not result.is_empty():
		lines.append("")
		lines.append("最近一次结果：%s" % ("成功" if _to_bool(result.get("success", false)) else "失败"))
		lines.append("事件数量：%d" % int(result.get("event_count", 0)))
		lines.append("警告数量：%d" % Array(result.get("warnings", [])).size())
		lines.append("错误数量：%d" % Array(result.get("errors", [])).size())
	_summary_label.text = "\n".join(lines)


func _one_click_compile() -> void:
	_apply_project_assets()


func _validate_now() -> void:
	var result: Dictionary = _compiler.compile_writer_drafts(false)
	_rebuild_summary(result)
	_log_label.text = _build_result_text(result, true)


func _scan_issues() -> void:
	var result: Dictionary = _compiler.compile_writer_drafts(false)
	_rebuild_summary(result)
	_log_label.text = _build_scan_text(result)


func _preview_diff() -> void:
	var result: Dictionary = _compiler.compile_writer_drafts(false)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var output_path: String = str(result.get("writer_draft_output_path", _compiler.get_writer_draft_output_path()))
	var existing_text := ""
	if FileAccess.file_exists(output_path):
		var file := FileAccess.open(output_path, FileAccess.READ)
		if file != null:
			existing_text = file.get_as_text()
	var compiled_text: String = str(result.get("writer_draft_text", ""))
	_log_label.text = _build_text_diff_text(existing_text, compiled_text)


func _export_writer_drafts() -> void:
	var result: Dictionary = _compiler.compile_writer_drafts(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var output_path: String = str(result.get("writer_draft_output_path", _compiler.get_writer_draft_output_path()))
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "[b]已导出当前草稿包[/b]\n%s" % output_path
	_navigate_to_path(output_path)


func _apply_dialogue_assets() -> void:
	var result: Dictionary = _compiler.apply_current_dialogue_assets(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var lines: PackedStringArray = ["[b]已写回对话资产[/b]"]
	lines.append("事件数量：%d" % Array(result.get("dialogue_asset_event_ids", [])).size())
	for path: Variant in Array(result.get("dialogue_asset_files", [])):
		lines.append("- %s" % str(path))
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "\n".join(lines)


func _apply_csv_assets() -> void:
	var result: Dictionary = _compiler.apply_current_csv_assets(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var lines: PackedStringArray = ["[b]已写回 CSV 资产[/b]"]
	lines.append("事件数量：%d" % Array(result.get("csv_asset_event_ids", [])).size())
	for path: Variant in Array(result.get("csv_asset_files", [])):
		lines.append("- %s" % str(path))
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "\n".join(lines)


func _apply_project_assets() -> void:
	var result: Dictionary = _compiler.apply_current_project_assets(true)
	_rebuild_summary(result)
	if not _to_bool(result.get("success", false)):
		_log_label.text = _build_result_text(result, true)
		return
	var lines: PackedStringArray = ["[b]已写回当前主结构[/b]"]
	lines.append("对话资产文件：%d" % Array(result.get("dialogue_asset_files", [])).size())
	lines.append("CSV 文件：%d" % Array(result.get("csv_asset_files", [])).size())
	EditorInterface.get_resource_filesystem().scan()
	_log_label.text = "\n".join(lines)


func _open_output_path() -> void:
	_navigate_to_path(_compiler.get_writer_draft_output_path())


func _open_writer_drafts_path() -> void:
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
	var path: String = str(_compiler.get_mapping_paths().get(key, ""))
	if path.is_empty():
		_log_label.text = "[color=tomato]没有找到映射文件：%s[/color]" % key
		return
	_navigate_to_path(path)


func _navigate_to_path(path: String) -> void:
	if path.is_empty():
		_log_label.text = "[color=tomato]目标路径为空。[/color]"
		return
	EditorInterface.get_resource_filesystem().scan()
	var dock := EditorInterface.get_file_system_dock()
	if dock != null and dock.has_method("navigate_to_path"):
		dock.call_deferred("navigate_to_path", path)
		_log_label.text = "[b]已定位文件[/b]\n%s" % path
		return
	OS.shell_open(ProjectSettings.globalize_path(path))
	_log_label.text = "[b]已尝试打开文件[/b]\n%s" % path


func _show_selected_source_hint(index: int) -> void:
	if index < 0 or index >= _source_list.item_count:
		return
	var path: String = str(_source_list.get_item_metadata(index))
	_log_label.text = _build_selected_source_preview(path)


func _open_selected_source(index: int) -> void:
	if index < 0 or index >= _source_list.item_count:
		return
	_navigate_to_path(str(_source_list.get_item_metadata(index)))


func _build_selected_source_preview(path: String) -> String:
	var result: Dictionary = _compiler.compile_markdown(false)
	if not _to_bool(result.get("success", false)):
		return _build_result_text(result, true)
	var events: Array = _compiler.parse_md_file(path)
	var lines: PackedStringArray = [
		"[b]当前源文件[/b]",
		path,
		"",
		"[b]解析预览[/b]",
		"事件数量：%d" % events.size()
	]
	if events.is_empty():
		lines.append("当前文件没有解析出事件。")
		return "\n".join(lines)
	for event_variant: Variant in events:
		var event_definition: Dictionary = Dictionary(event_variant)
		lines.append("")
		lines.append("[b]%s[/b]" % str(event_definition.get("title", "未命名事件")))
		if event_definition.has("id"):
			lines.append("编号：%s" % str(event_definition.get("id", "")))
		lines.append("分类 / 时段：%s / %s" % [
			str(event_definition.get("content_category", "")),
			str(event_definition.get("time_slot", ""))
		])
		var opening_text: String = str(event_definition.get("opening_text", "")).strip_edges()
		if not opening_text.is_empty():
			lines.append("开场：%s" % _preview_snippet(opening_text))
		var observation_text: String = str(event_definition.get("observation_text", "")).strip_edges()
		if not observation_text.is_empty():
			lines.append("观察：%s" % _preview_snippet(observation_text))
		var options: Array = Array(event_definition.get("options", []))
		if not options.is_empty():
			lines.append("对话选项：%d" % options.size())
	return "\n".join(lines)


func _build_result_text(result: Dictionary, validate_only: bool = false) -> String:
	var lines: PackedStringArray = []
	lines.append("[b]%s%s[/b]" % ["校验" if validate_only else "编译", "成功" if _to_bool(result.get("success", false)) else "失败"])
	if validate_only and _to_bool(result.get("success", false)):
		lines.append("当前 Markdown 与映射表通过校验。")
	for warning_text: Variant in Array(result.get("warnings", [])):
		lines.append("[color=yellow]警告：%s[/color]" % str(warning_text))
	for error_text: Variant in Array(result.get("errors", [])):
		lines.append("[color=tomato]错误：%s[/color]" % str(error_text))
	if lines.size() == 1 and _to_bool(result.get("success", false)):
		lines.append("没有额外警告，结果已刷新。")
	return "\n".join(lines)


func _build_scan_text(result: Dictionary) -> String:
	var lines: PackedStringArray = ["[b]扫描结果[/b]"]
	lines.append("状态：%s" % ("通过" if _to_bool(result.get("success", false)) else "存在错误"))
	for error_text: Variant in Array(result.get("errors", [])):
		lines.append("[color=tomato]错误：%s[/color]" % str(error_text))
	for warning_text: Variant in Array(result.get("warnings", [])):
		lines.append("[color=yellow]警告：%s[/color]" % str(warning_text))
	if Array(result.get("errors", [])).is_empty() and Array(result.get("warnings", [])).is_empty():
		lines.append("没有发现缺失映射或可疑写法。")
	return "\n".join(lines)


func _build_text_diff_text(existing_text: String, compiled_text: String) -> String:
	var lines: PackedStringArray = ["[b]当前项目草稿包预览[/b]"]
	if existing_text == compiled_text:
		lines.append("当前导出结果与现有草稿包一致。")
	else:
		lines.append("当前导出结果将更新草稿包内容。")
		lines.append("现有长度：%d" % existing_text.length())
		lines.append("新稿长度：%d" % compiled_text.length())
	return "\n".join(lines)


func _preview_snippet(text: String, max_length: int = 72) -> String:
	var single_line: String = text.replace("\r", " ").replace("\n", " ").strip_edges()
	if single_line.length() <= max_length:
		return single_line
	return "%s..." % single_line.substr(0, max_length)


func _load_mapping_data() -> void:
	var mapping_paths: Dictionary = _compiler.get_mapping_paths()
	_event_map_entries = _load_array_file(str(mapping_paths.get("event_id_map", "")))
	_npc_entries = _load_array_file(str(mapping_paths.get("npc_name_map", "")))
	_location_entries = _load_array_file(str(mapping_paths.get("location_name_map", "")))
	_status_entries = _load_array_file(str(mapping_paths.get("status_key_map", "")))


func _load_array_file(path: String) -> Array[Dictionary]:
	if path.is_empty():
		return []
	var file := FileAccess.open(path, FileAccess.READ)
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
	_populate_selector(_npc_selector, _npc_entries, "title", "id", "未指定人物")
	_populate_selector(_location_selector, _location_entries, "title", "id", "未指定地点")
	_populate_static_selector(_class_selector, [
		{"label": "条件剧情事件", "value": "条件剧情事件"},
		{"label": "固定剧情事件", "value": "固定剧情事件"},
		{"label": "随机扰动事件", "value": "随机扰动事件"}
	])
	_populate_static_selector(_stage_selector, [
		{"label": "行动后", "value": "行动后"},
		{"label": "阶段开始时", "value": "阶段开始时"}
	])
	_populate_static_selector(_time_selector, [
		{"label": "白天", "value": "白天"},
		{"label": "晨间", "value": "晨间"},
		{"label": "午后", "value": "午后"},
		{"label": "夜间", "value": "夜间"}
	])
	_populate_static_selector(_mapping_kind_selector, [
		{"label": "事件映射", "value": "event"},
		{"label": "人物映射", "value": "npc"},
		{"label": "地点映射", "value": "location"},
		{"label": "状态映射", "value": "status"}
	])
	_populate_static_selector(_mapping_scope_selector, [
		{"label": "全局状态", "value": "flag"},
		{"label": "玩家标记", "value": "player_tag"},
		{"label": "人物状态", "value": "npc_tag"}
	])
	_on_mapping_kind_changed(_mapping_kind_selector.selected)
	_next_id_label.text = "建议新事件 ID：%s" % _suggest_next_event_id()


func _populate_selector(selector: OptionButton, entries: Array[Dictionary], label_key: String, value_key: String, empty_label: String) -> void:
	selector.clear()
	selector.add_item(empty_label)
	selector.set_item_metadata(0, "")
	for entry: Dictionary in entries:
		var label := str(entry.get(label_key, ""))
		var value := str(entry.get(value_key, ""))
		if label.is_empty():
			continue
		selector.add_item(label)
		selector.set_item_metadata(selector.item_count - 1, value)
	selector.select(0)


func _populate_static_selector(selector: OptionButton, items: Array[Dictionary]) -> void:
	selector.clear()
	for item: Dictionary in items:
		selector.add_item(str(item.get("label", "")))
		selector.set_item_metadata(selector.item_count - 1, str(item.get("value", "")))
	if selector.item_count > 0:
		selector.select(0)


func _on_new_event_title_changed(_new_text: String) -> void:
	if _new_file_stem_edit.text.strip_edges().is_empty():
		_new_file_stem_edit.text = _suggest_next_event_id()
	_refresh_template_preview()


func _on_mapping_kind_changed(_index: int) -> void:
	var kind := _selected_selector_value(_mapping_kind_selector)
	_mapping_scope_selector.visible = kind == "status"
	_mapping_scope_label.visible = kind == "status"
	match kind:
		"event":
			_mapping_key_edit.placeholder_text = "数字 ID"
		"npc", "location":
			_mapping_key_edit.placeholder_text = "数字 ID"
		_:
			_mapping_key_edit.placeholder_text = "内部值"


func _refresh_template_preview() -> void:
	_template_output.text = _build_template_text()
	_next_id_label.text = "建议新事件 ID：%s" % _suggest_next_event_id()


func _build_template_text() -> String:
	var title := _new_event_title_edit.text.strip_edges()
	if title.is_empty():
		title = "新事件标题"
	var lines: PackedStringArray = [
		"# [事件] %s" % title,
		"@编号: %s" % _suggest_next_event_id(),
		"@剧情分类: %s" % _selected_selector_value(_class_selector),
		"@触发阶段: %s" % _selected_selector_value(_stage_selector),
		"@触发时间: %s" % _selected_selector_value(_time_selector)
	]
	var location_id := _selected_selector_value(_location_selector)
	if not location_id.is_empty():
		lines.append("@地点: %s" % _selected_selector_text(_location_selector))
	lines.append("")
	lines.append("[开场]")
	lines.append("在这里写事件正文。")
	lines.append("")
	lines.append("=> [选项一]")
	lines.append("这里写选项一的结果。")
	lines.append("$获得状态: 新状态名$")
	lines.append("")
	lines.append("=> [选项二]")
	lines.append("这里写选项二的结果。")
	return "\n".join(lines)


func _copy_template() -> void:
	DisplayServer.clipboard_set(_template_output.text)
	_log_label.text = "[b]已复制模板[/b]\n现在可以直接粘贴到新的 Markdown 文件。"


func _create_draft() -> void:
	var title := _new_event_title_edit.text.strip_edges()
	if title.is_empty():
		_log_label.text = "[color=tomato]请先填写中文事件名。[/color]"
		return
	var event_id := _suggest_next_event_id()
	var file_stem := _new_file_stem_edit.text.strip_edges()
	if file_stem.is_empty():
		file_stem = event_id
		_new_file_stem_edit.text = file_stem
	if not _append_event_mapping(title, event_id):
		return
	var folder_code := _selected_npc_folder_prefix()
	var target_dir := "%s%s" % [_compiler.get_markdown_authoring_dir(), folder_code]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))
	var target_path := "%s/%s.md" % [target_dir, file_stem]
	if FileAccess.file_exists(target_path):
		_log_label.text = "[color=tomato]目标文件已存在：%s[/color]" % target_path
		return
	var file := FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		_log_label.text = "[color=tomato]无法创建 Markdown 文件：%s[/color]" % target_path
		return
	file.store_string(_template_output.text)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	_load_mapping_data()
	_rebuild_selectors()
	_rebuild_source_list()
	_rebuild_summary()
	_log_label.text = "[b]已创建新草稿[/b]\n事件名：%s\n事件 ID：%s\n文件：%s" % [title, event_id, target_path]
	_navigate_to_path(target_path)


func _append_event_mapping(title: String, event_id: String) -> bool:
	for entry: Dictionary in _event_map_entries:
		if str(entry.get("title", "")) == title:
			_log_label.text = "[color=tomato]事件名已存在映射：%s[/color]" % title
			return false
		if str(entry.get("id", "")) == event_id:
			_log_label.text = "[color=tomato]事件 ID 已存在：%s[/color]" % event_id
			return false
	var updated_entries: Array = []
	for entry: Dictionary in _event_map_entries:
		updated_entries.append(entry)
	updated_entries.append({"id": event_id, "title": title})
	var path: String = str(_compiler.get_mapping_paths().get("event_id_map", ""))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_log_label.text = "[color=tomato]无法写入事件映射：%s[/color]" % path
		return false
	file.store_string(JSON.stringify(updated_entries, "\t"))
	file.close()
	return true


func _add_mapping() -> void:
	var kind := _selected_selector_value(_mapping_kind_selector)
	var title := _mapping_title_edit.text.strip_edges()
	var key_text := _mapping_key_edit.text.strip_edges()
	if title.is_empty() or key_text.is_empty():
		_log_label.text = "[color=tomato]请先填写中文名和内部值。[/color]"
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
			var scope := _selected_selector_value(_mapping_scope_selector)
			if not _append_mapping_entry("status_key_map", _status_entries, {"scope": scope, "key": key_text, "title": title}):
				return
		_:
			_log_label.text = "[color=tomato]未知映射类型。[/color]"
			return
	EditorInterface.get_resource_filesystem().scan()
	_load_mapping_data()
	_rebuild_selectors()
	_rebuild_summary()
	_mapping_title_edit.clear()
	_mapping_key_edit.clear()
	_log_label.text = "[b]已新增映射[/b]\n类型：%s\n中文名：%s\n内部值：%s" % [kind, title, key_text]


func _append_mapping_entry(mapping_key: String, existing_entries: Array[Dictionary], new_entry: Dictionary) -> bool:
	for entry: Dictionary in existing_entries:
		if str(entry.get("title", "")) == str(new_entry.get("title", "")):
			_log_label.text = "[color=tomato]中文名已存在映射：%s[/color]" % str(new_entry.get("title", ""))
			return false
		var compare_key_name := "id" if new_entry.has("id") else "key"
		if str(entry.get(compare_key_name, "")) == str(new_entry.get(compare_key_name, "")):
			_log_label.text = "[color=tomato]内部值已存在映射：%s[/color]" % str(new_entry.get(compare_key_name, ""))
			return false
	var updated_entries: Array = []
	for entry: Dictionary in existing_entries:
		updated_entries.append(entry)
	updated_entries.append(new_entry)
	var path: String = str(_compiler.get_mapping_paths().get(mapping_key, ""))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_log_label.text = "[color=tomato]无法写入映射文件：%s[/color]" % path
		return false
	file.store_string(JSON.stringify(updated_entries, "\t"))
	file.close()
	return true


func _suggest_next_event_id() -> String:
	var max_id := 999
	for entry: Dictionary in _event_map_entries:
		var value := str(entry.get("id", "0")).to_int()
		if value > max_id:
			max_id = value
	return str(max_id + 1)


func _selected_npc_folder_prefix() -> String:
	var npc_id := _selected_selector_value(_npc_selector)
	if npc_id.is_empty():
		return "00"
	if ["00", "01", "02", "03", "04", "05", "06"].has(npc_id):
		return npc_id
	return "00"


func _selected_selector_value(selector: OptionButton) -> String:
	if selector.selected < 0:
		return ""
	return str(selector.get_item_metadata(selector.selected))


func _selected_selector_text(selector: OptionButton) -> String:
	if selector.selected < 0:
		return ""
	return selector.get_item_text(selector.selected)


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
