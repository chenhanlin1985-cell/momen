# 提交分批方案

这份文档的目的很简单：

把当前工作区按“最适合拆提交”的方式先定下来，等确认稳定后可以直接照着分批提交。

## 批次 1：路线图主系统

目标：

把连续路线图、路线图节点执行、路线图 UI 与路线图模板作为一个完整功能集提交。

建议包含：

- [autoload/run_controller.gd](/e:/game/momen/autoload/run_controller.gd)
- [scenes/screens/main_game/main_game_screen.gd](/e:/game/momen/scenes/screens/main_game/main_game_screen.gd)
- [scenes/screens/main_game/main_game_screen.tscn](/e:/game/momen/scenes/screens/main_game/main_game_screen.tscn)
- [ui/view_models/main_game_view_model.gd](/e:/game/momen/ui/view_models/main_game_view_model.gd)
- [systems/route/route_map_service.gd](/e:/game/momen/systems/route/route_map_service.gd)
- [ui/components/route_map_panel.gd](/e:/game/momen/ui/components/route_map_panel.gd)
- [content/story/act1/route_map/day_01.json](/e:/game/momen/content/story/act1/route_map/day_01.json)
- [content/story/act1/route_map/day_02.json](/e:/game/momen/content/story/act1/route_map/day_02.json)
- [content/story/act1/route_map/day_03.json](/e:/game/momen/content/story/act1/route_map/day_03.json)
- [content/story/act1/route_map/day_04.json](/e:/game/momen/content/story/act1/route_map/day_04.json)
- [content/story/act1/route_map/day_05.json](/e:/game/momen/content/story/act1/route_map/day_05.json)
- [content/story/act1/route_map/day_06.json](/e:/game/momen/content/story/act1/route_map/day_06.json)
- [docs/ROUTE_MAP_IMPLEMENTATION_PLAN.md](/e:/game/momen/docs/ROUTE_MAP_IMPLEMENTATION_PLAN.md)

建议提交信息方向：

`feat: land continuous route map progression for act 1`

## 批次 2：路线图验证与维护入口

目标：

把路线图护栏、快速入口和维护文档独立成一批，后面回看历史更清楚。

建议包含：

- [docs/VALIDATION_QUICKSTART.md](/e:/game/momen/docs/VALIDATION_QUICKSTART.md)
- [docs/WORKTREE_GROUPING.md](/e:/game/momen/docs/WORKTREE_GROUPING.md)
- [tools/validation/run_route_map_validation_suite.ps1](/e:/game/momen/tools/validation/run_route_map_validation_suite.ps1)
- [tools/validation/validate_route_map_graph_integrity_runner.gd](/e:/game/momen/tools/validation/validate_route_map_graph_integrity_runner.gd)
- [tools/validation/validate_route_map_runtime_runner.gd](/e:/game/momen/tools/validation/validate_route_map_runtime_runner.gd)
- [tools/validation/validate_route_map_action_determinism_runner.gd](/e:/game/momen/tools/validation/validate_route_map_action_determinism_runner.gd)
- [tools/validation/validate_route_map_regression_suite_runner.gd](/e:/game/momen/tools/validation/validate_route_map_regression_suite_runner.gd)
- [tools/validation/validate_route_map_long_chain_runner.gd](/e:/game/momen/tools/validation/validate_route_map_long_chain_runner.gd)
- [tools/validation/validate_route_map_ui_runner.gd](/e:/game/momen/tools/validation/validate_route_map_ui_runner.gd)
- [tools/validation/validate_route_map_copy_runner.gd](/e:/game/momen/tools/validation/validate_route_map_copy_runner.gd)
- [tools/validation/validate_route_map_edge_flow_runner.gd](/e:/game/momen/tools/validation/validate_route_map_edge_flow_runner.gd)
- [tools/validation/validate_route_map_reachability_runner.gd](/e:/game/momen/tools/validation/validate_route_map_reachability_runner.gd)
- [tools/validation/validate_route_map_no_dead_ends_runner.gd](/e:/game/momen/tools/validation/validate_route_map_no_dead_ends_runner.gd)
- [tools/validation/validate_route_map_targets_runner.gd](/e:/game/momen/tools/validation/validate_route_map_targets_runner.gd)
- [tools/validation/validate_route_map_density_runner.gd](/e:/game/momen/tools/validation/validate_route_map_density_runner.gd)
- [tools/validation/validate_route_map_forced_entry_alignment_runner.gd](/e:/game/momen/tools/validation/validate_route_map_forced_entry_alignment_runner.gd)
- [tools/validation/validate_route_map_morning_entry_runner.gd](/e:/game/momen/tools/validation/validate_route_map_morning_entry_runner.gd)
- [tools/validation/validate_day1_route_chain_runner.gd](/e:/game/momen/tools/validation/validate_day1_route_chain_runner.gd)
- [tools/validation/validate_route_map_after_battle_runner.gd](/e:/game/momen/tools/validation/validate_route_map_after_battle_runner.gd)

建议提交信息方向：

`test: add route map validation suite and maintenance docs`

## 批次 3：战斗系统与战斗 UI

目标：

把战斗软锁修复、卡牌实例化、布局重构、UI 可读性和定向倍率规则作为一批提交。

建议包含：

- [systems/battle/battle_service.gd](/e:/game/momen/systems/battle/battle_service.gd)
- [systems/battle/battle_rule_service.gd](/e:/game/momen/systems/battle/battle_rule_service.gd)
- [core/models/battle_state.gd](/e:/game/momen/core/models/battle_state.gd)
- [ui/components/battle_panel.gd](/e:/game/momen/ui/components/battle_panel.gd)
- [ui/components/battle_panel.tscn](/e:/game/momen/ui/components/battle_panel.tscn)
- [ui/components/battle_card_slot.gd](/e:/game/momen/ui/components/battle_card_slot.gd)
- [ui/components/battle_hand_card.gd](/e:/game/momen/ui/components/battle_hand_card.gd)
- [content/battle/card_definitions.json](/e:/game/momen/content/battle/card_definitions.json)
- [content/battle/enemy_mind_definitions.json](/e:/game/momen/content/battle/enemy_mind_definitions.json)
- [content/battle/pollution_profiles.json](/e:/game/momen/content/battle/pollution_profiles.json)
- [content/battle/battle_texts.json](/e:/game/momen/content/battle/battle_texts.json)
- [docs/BATTLE_CONTENT_CONSTRAINTS.md](/e:/game/momen/docs/BATTLE_CONTENT_CONSTRAINTS.md)

建议提交信息方向：

`fix: stabilize battle flow and rebuild battle panel layout`

## 批次 4：战斗验证与平衡审计

目标：

把战斗一键验证、战斗回归、平衡/规则专项检查单独留痕。

建议包含：

- [tools/validation/run_battle_validation_suite.ps1](/e:/game/momen/tools/validation/run_battle_validation_suite.ps1)
- [tools/validation/validate_all_battle_integrity_runner.gd](/e:/game/momen/tools/validation/validate_all_battle_integrity_runner.gd)
- [tools/validation/validate_all_battle_failure_flow_runner.gd](/e:/game/momen/tools/validation/validate_all_battle_failure_flow_runner.gd)
- [tools/validation/validate_battle_softlock_runner.gd](/e:/game/momen/tools/validation/validate_battle_softlock_runner.gd)
- [tools/validation/validate_battle_end_to_end_runner.gd](/e:/game/momen/tools/validation/validate_battle_end_to_end_runner.gd)
- [tools/validation/validate_battle_result_state_cleanup_runner.gd](/e:/game/momen/tools/validation/validate_battle_result_state_cleanup_runner.gd)
- [tools/validation/validate_battle_save_restore_runner.gd](/e:/game/momen/tools/validation/validate_battle_save_restore_runner.gd)
- [tools/validation/validate_battle_view_sync_runner.gd](/e:/game/momen/tools/validation/validate_battle_view_sync_runner.gd)
- [tools/validation/validate_pollution_counterplay_runner.gd](/e:/game/momen/tools/validation/validate_pollution_counterplay_runner.gd)
- [tools/validation/validate_enemy_specific_card_bonus_runner.gd](/e:/game/momen/tools/validation/validate_enemy_specific_card_bonus_runner.gd)
- [tools/validation/estimate_battle_balance_runner.gd](/e:/game/momen/tools/validation/estimate_battle_balance_runner.gd)

建议提交信息方向：

`test: add battle validation suite and balance audit helpers`

## 批次 5：事件链、文本与作者链修正

目标：

把灰市分类修正、外门长老文本修复、CSV/本地化一致性收成一批。

建议包含：

- [systems/event/event_service.gd](/e:/game/momen/systems/event/event_service.gd)
- [content/story/act1/csv/events.csv](/e:/game/momen/content/story/act1/csv/events.csv)
- [content/story/act1/csv/localization.csv](/e:/game/momen/content/story/act1/csv/localization.csv)
- [content/dialogue/texts/outer_senior_texts.json](/e:/game/momen/content/dialogue/texts/outer_senior_texts.json)
- [content/story/act1/md/active/00/3401.md](/e:/game/momen/content/story/act1/md/active/00/3401.md)
- [content/story/act1/md/active/00/3402.md](/e:/game/momen/content/story/act1/md/active/00/3402.md)
- [tools/story_compiler/markdown_story_compiler.gd](/e:/game/momen/tools/story_compiler/markdown_story_compiler.gd)
- [tools/story_mount/story_event_builder.gd](/e:/game/momen/tools/story_mount/story_event_builder.gd)
- [tools/story_mount/story_mount_browser.gd](/e:/game/momen/tools/story_mount/story_mount_browser.gd)
- [tools/validation/validate_story_csv_alignment_runner.gd](/e:/game/momen/tools/validation/validate_story_csv_alignment_runner.gd)
- [tools/validation/validate_player_facing_text_integrity_runner.gd](/e:/game/momen/tools/validation/validate_player_facing_text_integrity_runner.gd)
- [tools/validation/validate_outer_senior_texts_runner.gd](/e:/game/momen/tools/validation/validate_outer_senior_texts_runner.gd)

建议提交信息方向：

`fix: align story content metadata and player-facing text data`

## 批次 6：美术资源接入

目标：

把新背景、立绘、结局图接线独立出去，方便以后单独回看资源接入历史。

建议包含：

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
- [tools/validation/validate_art_asset_bindings_runner.gd](/e:/game/momen/tools/validation/validate_art_asset_bindings_runner.gd)

建议提交信息方向：

`feat: integrate new act 1 art assets into runtime presentation`

## 批次 7：最后的噪音清理

目标：

把历史临时探针删除记录单独放到最后，避免和功能改动混在一起。

建议包含：

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

建议提交信息方向：

`chore: remove obsolete temporary probes and uid leftovers`

## 建议顺序

如果后面确认这批内容稳定，建议顺序是：

1. 路线图主系统
2. 路线图验证与维护入口
3. 战斗系统与战斗 UI
4. 战斗验证与平衡审计
5. 事件链、文本与作者链修正
6. 美术资源接入
7. 最后的噪音清理

这样每一批的语义都比较单纯，也更方便后面回看历史。
