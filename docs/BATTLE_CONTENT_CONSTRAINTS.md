# 心战内容约束

本文档用于约束当前心战内容的编号、数值和配置方式，避免后续继续把数值推回“首回合秒杀”或“纯粹坐牢”。

## 编号段

- `91xx`：主线关键人物心战与收束节点
- `92xx`：王麻子线心战与收束节点
- `93xx`：夜巡线心战与收束节点
- `94xx`：疯长老线心战与收束节点
- `95xx`：可重复杂兵心战与收束节点
- `911x-919x`：Act 1 心战卡牌
- `961x-969x`：Act 1 污染牌

## 事件结构

所有心战统一走同一条链：

1. `dialogue_event` 或 `battle_event` 作为入口事件
2. 入口事件写入 `battle_id`
3. `content/battle/battle_definitions.json` 用同编号段定义心战
4. 心战结束后落到 `result_event_id_success / result_event_id_failure`
5. 收束事件只负责叙事反馈与状态回写，不再额外套第二套入口

## 配置原则

- 插槽固定两格：左槽 `BASE`，右槽 `MULTI`
- `card_group = "02"` 只用于 `BASE`
- `card_group = "01"` 只用于 `MULTI`
- 不再为某个 NPC 在代码里硬写弱点判定
- 所有弱点、抗性、额外理智消耗、分值修正都写进 `enemy_mind_definitions.json`
- 污染牌优先做成可利用资源，不做纯粹废牌

## 敌方心防数值

- 杂兵：`max_hp 20-24`，`exp_reward 1`
- 精英：`max_hp 32-38`，`exp_reward 2-3`
- BOSS：`max_hp 40-46`，`exp_reward 3`

目标回合数：

- 杂兵：`3-4` 回合
- 精英：`4-5` 回合
- BOSS：`5-6` 回合

## 我方理智与反噬

- 所有战斗配置只保留统一的基础理智：`max_sanity 12`
- 实际进入战斗时使用：`基础理智 12 + 等级奖励`
- 当前最小可执行版的等级奖励为：每提升 `1` 级，心战理智上限 `+1`
- 后续若接入正式属性升级，沿用同一入口，把等级奖励替换成属性奖励，不再回到“每场战斗单独配上限”
- 常规 `end_turn_recoil` 以 `1` 为基准
- 污染额外扣理智优先通过污染牌自身承担，不再用基础回合反噬硬压玩家

## 卡牌数值

- 通用基础牌：`base_score 5`
- 强化基础牌：`base_score 6-7`
- 高强度奖励基础牌：`base_score 7` 封顶
- 常规倍率牌：`1.1-1.5`
- 强力倍率牌：`1.6` 左右，只给少量关键牌
- 污染逆转倍率：首批控制在 `1.6-2.4`，不要直接回到 `x3.0` 泛滥

## 抗性与破绽

- `vulnerability_base_type_multipliers`：按 `BASE` 的 `card_type` 放大
- `vulnerability_multi_tag_multipliers`：按 `MULTI` 的 `effect_tags` 放大
- 单项弱点倍率优先控制在 `1.3-1.6`
- 不再同时给同一敌人叠两层 `2.0` 级放大
- `resistance_extra_cost_by_base_type`：额外理智消耗，优先控制在 `+1`
- `resistance_score_delta_by_base_type`：最终伤害修正，优先控制在 `-1 ~ -2`
- 禁止再出现 `-999` 这类硬锁死分支的临时值

## 污染牌原则

- 首批只做三类：
  - `reverse_multi`
  - `hand_aura`
  - `locked_conscience`
- 当前已实装的最小可执行版只启用：
  - `reverse_multi`
  - `hand_aura`
- 每个敌人每回合最多塞 `1` 张污染
- 触发来源先只用：
  - 回合意图
  - 血量阈值

## 奖励原则

- 每场关键 NPC 心战结算给 `2` 张奖励卡以内
- 杂兵心战最多给 `1` 张奖励卡
- 奖励卡必须直接进入后续战斗牌堆，不允许只显示在牌库里

## 文本原则

- 玩家可见文本继续全部外置
- `battle_texts.json` 负责卡牌说明、敌方意图、HUD 文案、污染提示

## 验证入口

战斗系统现在已经提供了一条一键验证入口：

- [run_battle_validation_suite.ps1](/e:/game/momen/tools/validation/run_battle_validation_suite.ps1)

执行方式：

```powershell
& 'e:\game\momen\tools\validation\run_battle_validation_suite.ps1'
```

这条入口会顺序跑完当前最关键的战斗验证：

- 战斗定义完整性
- 失败链是否都能进入失败收束
- 软锁与无解终局
- 端到端胜负链
- 结果事件后的状态清理
- 存档 / 读档恢复
- 视图同步
- 污染牌反制窗口
- 指定敌人额外倍率
- 粗略平衡估计

## 验证分层建议

后续如果继续调整战斗系统，建议按下面三层来跑，而不是只靠实机打一两场。

### 1. 改内容或事件链接时

至少运行：

- [validate_all_battle_integrity_runner.gd](/e:/game/momen/tools/validation/validate_all_battle_integrity_runner.gd)
- [validate_all_battle_failure_flow_runner.gd](/e:/game/momen/tools/validation/validate_all_battle_failure_flow_runner.gd)
- [validate_battle_end_to_end_runner.gd](/e:/game/momen/tools/validation/validate_battle_end_to_end_runner.gd)

这一层主要防：

- `battle_id`、敌方定义、结果事件缺失
- 失败后无法进入失败收束
- 胜负结果链断掉

### 2. 改规则或状态机时

至少运行：

- [validate_battle_softlock_runner.gd](/e:/game/momen/tools/validation/validate_battle_softlock_runner.gd)
- [validate_battle_result_state_cleanup_runner.gd](/e:/game/momen/tools/validation/validate_battle_result_state_cleanup_runner.gd)
- [validate_battle_save_restore_runner.gd](/e:/game/momen/tools/validation/validate_battle_save_restore_runner.gd)
- [validate_battle_view_sync_runner.gd](/e:/game/momen/tools/validation/validate_battle_view_sync_runner.gd)

这一层主要防：

- 理智耗尽/局面无解后的软锁
- 失败结局后的状态残留
- 战斗中存档恢复错位
- UI 和真实状态不同步

### 3. 改卡牌平衡或特殊规则时

至少运行：

- [validate_pollution_counterplay_runner.gd](/e:/game/momen/tools/validation/validate_pollution_counterplay_runner.gd)
- [validate_enemy_specific_card_bonus_runner.gd](/e:/game/momen/tools/validation/validate_enemy_specific_card_bonus_runner.gd)
- [estimate_battle_balance_runner.gd](/e:/game/momen/tools/validation/estimate_battle_balance_runner.gd)

这一层主要防：

- 污染牌重新变回无反制窗口
- 文案写了特殊加成但规则层没生效
- 某一场战斗重新冒出独一档尖刺难度

## 维护建议

后续只要改了以下任意一类内容：

- `content/battle/*.json`
- `systems/battle/*.gd`
- 战斗结果事件链
- 战斗面板与状态同步逻辑

就不建议只靠手打一两场确认。至少先跑一遍：

```powershell
& 'e:\game\momen\tools\validation\run_battle_validation_suite.ps1'
```

因为战斗系统现在最容易重新回来的问题，不是“某张牌数字差一点”，而是：

- 软锁
- 失败链断掉
- 存档恢复错位
- UI 看起来还能点，但状态其实已经终结
- `localization.csv` 负责入口事件与收束事件正文
