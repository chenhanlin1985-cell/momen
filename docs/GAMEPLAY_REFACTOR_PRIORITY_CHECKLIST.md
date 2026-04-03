# 游戏逻辑整理优先级清单

本文档不是泛方案，而是基于当前实际运行版本得出的执行清单。

目标是：

1. 先消除最容易制造混乱的双轨逻辑
2. 再收紧现有节点流
3. 最后整理表现层与辅助系统

## 总原则

- 优先删残留，不优先加兼容
- 保留当前已经跑通的节点流和心战链
- 继续遵守数字编号、文本外置、少技术债的项目规范
- 每一步都以“减少系统分叉”为目标，而不是增加过渡层

## 第 1 优先级：统一对话入口逻辑

### 目标

把当前对话系统彻底收成：

- `观察`
- `入侵`

不再保留旧的第三入口残留。

### 当前问题

[event_service.gd](/C:/momen/systems/event/event_service.gd) 里仍然同时存在：

- `__talk__` 分支
- `_build_dialogue_intrusion_option_views()`
- 旧的 `talk` 语义代码残留

虽然运行时主视图已经只显示两项，但代码结构仍然是混杂的。

### 执行动作

1. 删除 `__talk__` 的旧分支
2. 删除 `_build_dialogue_intrusion_option_views()`
3. 明确 `intrude` 的唯一职责就是“若配置了 `battle_id`，则进入心战；否则报不可用或回退规则”
4. 重新检查 `dialogue_mode` 是否还需要保留 `talk`

### 涉及文件

- [event_service.gd](/C:/momen/systems/event/event_service.gd)

### 完成标准

- 对话枢纽只剩现行两项语义
- 代码里不再保留死分支
- 对话状态机与现行玩法一致

## 第 2 优先级：统一战斗语义，只保留心战主轨

### 目标

消除“旧 `combat_event`”与“新 `battle_id` 心战”并存的双轨问题。

### 当前问题

当前系统里仍然有旧战斗事件，例如：

- `act1_combat_blood_runner`

这会导致项目同时存在两套战斗模型：

- 旧数值检定式 `combat_event`
- 新卡牌心战式 `battle_event / dialogue_event + battle_id`

### 执行动作

1. 盘点所有现存 `combat_event`
2. 判断每个旧战斗是：
   - 改造成心战
   - 改成普通事件
   - 直接删除
3. 若保留该剧情价值，则优先迁移到 `battle_definitions.json + enemy_mind_definitions.json`
4. 最终让 Act 1 的战斗主轨只剩心战一套

### 涉及文件

- [events.csv](/C:/momen/content/story/act1/csv/events.csv)
- [event_options.csv](/C:/momen/content/story/act1/csv/event_options.csv)
- [option_effects.csv](/C:/momen/content/story/act1/csv/option_effects.csv)
- [battle_definitions.json](/C:/momen/content/battle/battle_definitions.json)
- [enemy_mind_definitions.json](/C:/momen/content/battle/enemy_mind_definitions.json)

### 完成标准

- Act 1 不再依赖旧 `combat_event`
- 所有战斗都走同一条心战逻辑

## 第 3 优先级：统一“白天节点”的真实定义

### 目标

把当前白天真正可发生的内容边界固定下来，避免继续混进旧地点思维。

### 当前问题

现在白天同时会被：

- 主线事件
- 条件事件
- 随机事件
- 3 选 1 行动候选

接管，这本身没问题，但“哪些内容应该是事件，哪些应该是行动”仍然不够统一。

### 执行动作

1. 给白天内容做明确分层：
   - 必然节点
   - 条件节点
   - 随机节点
   - 白天候选行动
2. 统一规则：
   - 能独立成完整剧情拍子的，优先做事件
   - 只是白天轻量推进的，留在行动候选池
3. 避免再把“应做成节点”的内容塞回 `action_definitions.json`

### 涉及文件

- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [content_repository.gd](/C:/momen/systems/content/content_repository.gd)
- [action_definitions.json](/C:/momen/content/actions/action_definitions.json)
- [events.csv](/C:/momen/content/story/act1/csv/events.csv)

### 完成标准

- 白天内容边界清楚
- 新增内容时不会再在事件和行动之间反复摇摆

## 第 4 优先级：整理地点层职责，只保留表现与挂载

### 目标

明确地点已经不是导航玩法，而是：

- 背景表现层
- 内容挂载层
- 事件过滤条件层

### 当前问题

地点系统虽然已经不再主导玩家操作，但在认知上仍然容易被误当成旧探索系统。

### 执行动作

1. 整理地点文档与注释表达
2. 检查 `location_definitions.json` 里是否还残留旧导航语义
3. 收口 `LocationService` 的职责说明

### 涉及文件

- [location_definitions.json](/C:/momen/content/locations/location_definitions.json)
- [location_service.gd](/C:/momen/systems/location/location_service.gd)
- 相关说明文档

### 完成标准

- 团队对地点层的理解一致
- 后续不会再把地点重新扩回自由导航玩法

## 第 5 优先级：整理心战数值与成长闭环

### 目标

让心战真正成为稳定主玩法，而不是“现在能跑的样板”。

### 当前问题

当前心战已可运行，但仍需要进一步明确：

- 卡牌成长节奏
- 杂兵战收益上限
- 关键 NPC 战的强度级差
- 理智消耗、抗性修正的统一尺度

### 执行动作

1. 按 [BATTLE_CONTENT_CONSTRAINTS.md](/C:/momen/docs/BATTLE_CONTENT_CONSTRAINTS.md) 持续收数值
2. 检查杂兵战是否过度刷收益
3. 检查奖励卡进入牌堆后的强度膨胀
4. 明确哪些卡是通用成长，哪些卡只能来自关键 NPC

### 涉及文件

- [card_definitions.json](/C:/momen/content/battle/card_definitions.json)
- [enemy_mind_definitions.json](/C:/momen/content/battle/enemy_mind_definitions.json)
- [battle_definitions.json](/C:/momen/content/battle/battle_definitions.json)
- [battle_rule_service.gd](/C:/momen/systems/battle/battle_rule_service.gd)

### 完成标准

- 数值扩展有边界
- 牌库成长可控
- 心战成为可持续扩充的主系统

## 第 6 优先级：整理主界面模式切换

### 目标

让主界面 5 种模式的职责边界更稳定：

- `location`
- `dialogue`
- `event`
- `battle`
- `ending`

### 当前问题

主界面虽然已经能切模式，但仍有一些“从旧结构改过来”的痕迹，例如：

- 某些栏位在不同模式下的显示理由不够纯粹
- 某些 UI 元素仍然带着旧场景交互思维

### 执行动作

1. 检查各模式哪些面板必须显示、哪些应完全隐藏
2. 把心战当成独立舞台继续整理
3. 确认牌库、日志、顶部信息在各模式中的边界

### 涉及文件

- [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)
- [main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)
- [main_game_view_model.gd](/C:/momen/ui/view_models/main_game_view_model.gd)
- [battle_panel.gd](/C:/momen/ui/components/battle_panel.gd)
- [battle_panel.tscn](/C:/momen/ui/components/battle_panel.tscn)

### 完成标准

- 各模式职责边界清楚
- 不再出现“看起来还能点，但其实没有意义”的 UI

## 第 7 优先级：内容层补链，而不是继续补散点

### 目标

后续内容扩写按“链路图”而不是“散事件”来做。

### 当前问题

当前虽然已有多条心战，但仍需要更多桥接节点把：

- 柳飞霞
- 王麻子
- 夜巡弟子
- 疯长老

真正串成有因果的内容图。

### 执行动作

1. 优先补桥接主线节点
2. 再补每条 NPC 线的二层分叉
3. 最后补随机扰动和杂兵心战

### 涉及文件

- [events.csv](/C:/momen/content/story/act1/csv/events.csv)
- [event_triggers.csv](/C:/momen/content/story/act1/csv/event_triggers.csv)
- [event_options.csv](/C:/momen/content/story/act1/csv/event_options.csv)
- [option_effects.csv](/C:/momen/content/story/act1/csv/option_effects.csv)
- [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)

### 完成标准

- Act 1 不是“几条孤立心战”
- 而是“有起点、有桥接、有收束”的完整链路图

## 推荐执行顺序

建议严格按下面顺序推进：

1. 收掉对话残留
2. 收掉旧 `combat_event`
3. 明确白天内容边界
4. 固定地点层职责
5. 继续收紧心战数值
6. 整理主界面模式
7. 在稳定结构上继续补内容

## 当前最适合立刻开做的一步

如果从“减少混乱”角度看，下一步最值当的是：

**先处理 [event_service.gd](/C:/momen/systems/event/event_service.gd) 的旧对话残留分支。**

原因是它现在已经不是功能缺失，而是“结构认知不一致”的主要来源：

- 设计上是两按钮
- 代码里还像三按钮

这会持续拖累后续所有对话节点和心战节点的维护。
