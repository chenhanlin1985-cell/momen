# 当前工作区分组

这份清单只服务一个目的：

把当前仍未提交的改动，按功能块分清楚，方便继续收口或后续拆提交。

## 1. 路线图主系统

核心代码：

- [autoload/run_controller.gd](/e:/game/momen/autoload/run_controller.gd)
- [systems/route/route_map_service.gd](/e:/game/momen/systems/route/route_map_service.gd)
- [ui/components/route_map_panel.gd](/e:/game/momen/ui/components/route_map_panel.gd)
- [scenes/screens/main_game/main_game_screen.gd](/e:/game/momen/scenes/screens/main_game/main_game_screen.gd)
- [scenes/screens/main_game/main_game_screen.tscn](/e:/game/momen/scenes/screens/main_game/main_game_screen.tscn)
- [ui/view_models/main_game_view_model.gd](/e:/game/momen/ui/view_models/main_game_view_model.gd)

模板与文档：

- [content/story/act1/route_map/day_01.json](/e:/game/momen/content/story/act1/route_map/day_01.json)
- [content/story/act1/route_map/day_02.json](/e:/game/momen/content/story/act1/route_map/day_02.json)
- [content/story/act1/route_map/day_03.json](/e:/game/momen/content/story/act1/route_map/day_03.json)
- [content/story/act1/route_map/day_04.json](/e:/game/momen/content/story/act1/route_map/day_04.json)
- [content/story/act1/route_map/day_05.json](/e:/game/momen/content/story/act1/route_map/day_05.json)
- [content/story/act1/route_map/day_06.json](/e:/game/momen/content/story/act1/route_map/day_06.json)
- [docs/ROUTE_MAP_IMPLEMENTATION_PLAN.md](/e:/game/momen/docs/ROUTE_MAP_IMPLEMENTATION_PLAN.md)

## 2. 战斗系统与战斗 UI

核心代码：

- [systems/battle/battle_service.gd](/e:/game/momen/systems/battle/battle_service.gd)
- [systems/battle/battle_rule_service.gd](/e:/game/momen/systems/battle/battle_rule_service.gd)
- [core/models/battle_state.gd](/e:/game/momen/core/models/battle_state.gd)
- [ui/components/battle_panel.gd](/e:/game/momen/ui/components/battle_panel.gd)
- [ui/components/battle_panel.tscn](/e:/game/momen/ui/components/battle_panel.tscn)
- [ui/components/battle_card_slot.gd](/e:/game/momen/ui/components/battle_card_slot.gd)
- [ui/components/battle_hand_card.gd](/e:/game/momen/ui/components/battle_hand_card.gd)

规则与数值：

- [content/battle/card_definitions.json](/e:/game/momen/content/battle/card_definitions.json)
- [content/battle/enemy_mind_definitions.json](/e:/game/momen/content/battle/enemy_mind_definitions.json)
- [content/battle/pollution_profiles.json](/e:/game/momen/content/battle/pollution_profiles.json)
- [content/battle/battle_texts.json](/e:/game/momen/content/battle/battle_texts.json)
- [docs/BATTLE_CONTENT_CONSTRAINTS.md](/e:/game/momen/docs/BATTLE_CONTENT_CONSTRAINTS.md)

## 3. 事件/文本/作者链修正

- [systems/event/event_service.gd](/e:/game/momen/systems/event/event_service.gd)
- [content/story/act1/csv/events.csv](/e:/game/momen/content/story/act1/csv/events.csv)
- [content/story/act1/csv/localization.csv](/e:/game/momen/content/story/act1/csv/localization.csv)
- [content/dialogue/texts/outer_senior_texts.json](/e:/game/momen/content/dialogue/texts/outer_senior_texts.json)
- [content/story/act1/md/active/00/3401.md](/e:/game/momen/content/story/act1/md/active/00/3401.md)
- [content/story/act1/md/active/00/3402.md](/e:/game/momen/content/story/act1/md/active/00/3402.md)
- [tools/story_compiler/markdown_story_compiler.gd](/e:/game/momen/tools/story_compiler/markdown_story_compiler.gd)
- [tools/story_mount/story_event_builder.gd](/e:/game/momen/tools/story_mount/story_event_builder.gd)
- [tools/story_mount/story_mount_browser.gd](/e:/game/momen/tools/story_mount/story_mount_browser.gd)

## 4. 美术资源接入

- [content/npcs/npc_definitions.json](/e:/game/momen/content/npcs/npc_definitions.json)
- [assets/art/portraits/npcs/00/9501_default.png](/e:/game/momen/assets/art/portraits/npcs/00/9501_default.png)
- [assets/art/portraits/npcs/02/02_default.png](/e:/game/momen/assets/art/portraits/npcs/02/02_default.png)
- [assets/art/portraits/npcs/03/03_default.png](/e:/game/momen/assets/art/portraits/npcs/03/03_default.png)
- [assets/art/portraits/npcs/04/04_default.png](/e:/game/momen/assets/art/portraits/npcs/04/04_default.png)
- [assets/art/backgrounds/scenes/02/02_01.png](/e:/game/momen/assets/art/backgrounds/scenes/02/02_01.png)
- [assets/art/backgrounds/scenes/03/03_01.png](/e:/game/momen/assets/art/backgrounds/scenes/03/03_01.png)
- [assets/art/backgrounds/scenes/04/04_01.png](/e:/game/momen/assets/art/backgrounds/scenes/04/04_01.png)
- [assets/art/backgrounds/scenes/05/05_01.png](/e:/game/momen/assets/art/backgrounds/scenes/05/05_01.png)
- [assets/art/backgrounds/scenes/06/06_01.png](/e:/game/momen/assets/art/backgrounds/scenes/06/06_01.png)
- [assets/art/backgrounds/scenes/endings/ending_battle_deviation.png.png](/e:/game/momen/assets/art/backgrounds/scenes/endings/ending_battle_deviation.png.png)

## 5. 验证与维护入口

总入口：

- [docs/VALIDATION_QUICKSTART.md](/e:/game/momen/docs/VALIDATION_QUICKSTART.md)
- [tools/validation/run_route_map_validation_suite.ps1](/e:/game/momen/tools/validation/run_route_map_validation_suite.ps1)
- [tools/validation/run_battle_validation_suite.ps1](/e:/game/momen/tools/validation/run_battle_validation_suite.ps1)

路线图验证：

- [tools/validation/validate_route_map_graph_integrity_runner.gd](/e:/game/momen/tools/validation/validate_route_map_graph_integrity_runner.gd)
- [tools/validation/validate_route_map_runtime_runner.gd](/e:/game/momen/tools/validation/validate_route_map_runtime_runner.gd)
- [tools/validation/validate_route_map_action_determinism_runner.gd](/e:/game/momen/tools/validation/validate_route_map_action_determinism_runner.gd)
- [tools/validation/validate_route_map_regression_suite_runner.gd](/e:/game/momen/tools/validation/validate_route_map_regression_suite_runner.gd)
- [tools/validation/validate_route_map_long_chain_runner.gd](/e:/game/momen/tools/validation/validate_route_map_long_chain_runner.gd)
- [tools/validation/validate_route_map_ui_runner.gd](/e:/game/momen/tools/validation/validate_route_map_ui_runner.gd)
- [tools/validation/validate_route_map_copy_runner.gd](/e:/game/momen/tools/validation/validate_route_map_copy_runner.gd)

战斗验证：

- [tools/validation/validate_all_battle_integrity_runner.gd](/e:/game/momen/tools/validation/validate_all_battle_integrity_runner.gd)
- [tools/validation/validate_all_battle_failure_flow_runner.gd](/e:/game/momen/tools/validation/validate_all_battle_failure_flow_runner.gd)
- [tools/validation/validate_battle_softlock_runner.gd](/e:/game/momen/tools/validation/validate_battle_softlock_runner.gd)
- [tools/validation/validate_battle_end_to_end_runner.gd](/e:/game/momen/tools/validation/validate_battle_end_to_end_runner.gd)
- [tools/validation/validate_battle_result_state_cleanup_runner.gd](/e:/game/momen/tools/validation/validate_battle_result_state_cleanup_runner.gd)
- [tools/validation/validate_battle_save_restore_runner.gd](/e:/game/momen/tools/validation/validate_battle_save_restore_runner.gd)
- [tools/validation/validate_battle_view_sync_runner.gd](/e:/game/momen/tools/validation/validate_battle_view_sync_runner.gd)
- [tools/validation/validate_pollution_counterplay_runner.gd](/e:/game/momen/tools/validation/validate_pollution_counterplay_runner.gd)
- [tools/validation/validate_enemy_specific_card_bonus_runner.gd](/e:/game/momen/tools/validation/validate_enemy_specific_card_bonus_runner.gd)

补充审计：

- [tools/validation/estimate_battle_balance_runner.gd](/e:/game/momen/tools/validation/estimate_battle_balance_runner.gd)
- [tools/validation/validate_art_asset_bindings_runner.gd](/e:/game/momen/tools/validation/validate_art_asset_bindings_runner.gd)
- [tools/validation/validate_story_csv_alignment_runner.gd](/e:/game/momen/tools/validation/validate_story_csv_alignment_runner.gd)
- [tools/validation/validate_player_facing_text_integrity_runner.gd](/e:/game/momen/tools/validation/validate_player_facing_text_integrity_runner.gd)
- [tools/validation/validate_outer_senior_texts_runner.gd](/e:/game/momen/tools/validation/validate_outer_senior_texts_runner.gd)

## 6. 已知仍待提交的噪音

还有一批早期临时 `.uid` 删除记录仍留在工作区：

- `tmp_check_dialogue_events.gd`
- `tmp_check_dialogue_events.gd.uid`
- `tmp_check_option_texts.gd.uid`
- `tmp_dump_markdown_event.gd.uid`
- `tmp_list_markdown_events.gd.uid`
- `tmp_load_compiler.gd.uid`
- `tools/story_compiler/tmp_dump_roundtrip_diff_runner.gd.uid`
- `tools/story_compiler/tmp_export_conditional_dialogues_runner.gd.uid`
- `tools/story_compiler/tmp_export_other_dialogues_runner.gd.uid`
- `tools/story_compiler/tmp_list_active_md_runner.gd.uid`

这批本身不是功能改动，适合放到最后一次统一清理里处理。
