# 当前游戏历程与游戏逻辑总梳理

本文档描述的是当前项目里“实际正在运行”的游戏结构，而不是早期方案或历史草稿。

目标有 3 个：

1. 统一团队对当前游戏历程的理解
2. 明确现行运行时到底由哪些系统驱动
3. 标出仍然存在的遗留结构与后续整理方向

## 1. 当前游戏的核心形态

项目已经不再是“自由移动 + 自由点 NPC + 手动结束白天”的旧结构。

当前版本的核心形态是：

- 开场序章
- 进入 7 天循环
- 每天按阶段自动推进
- 每个阶段优先检查事件
- 若白天没有必然或条件事件，则给出 3 个随机行动候选
- 某些 NPC 对话节点可以进入“入侵式心战”
- 心战胜负再把玩家带回对应的后续对话或收束事件
- 最后进入第 7 天结局检查

也就是说，当前项目的真实结构更接近：

`序章 -> 节点流 -> 对话/心战分支 -> 结局`

而不是：

`地图探索 -> 行动点管理 -> 自由式日程模拟`

## 2. 玩家实际游戏历程

### 2.1 开场序章

开场数据来自 [run_definitions.json](/C:/momen/content/runs/run_definitions.json)。

现行 `default_run` 的序章流程是：

- 凡人视角的两次死亡分支
- 天魔绑定
- 回到正式 Act 1 开场

这一段是演出序章，不属于正式 7 天循环内部节点。

### 2.2 正式主循环

正式主循环的初始状态同样来自 [run_definitions.json](/C:/momen/content/runs/run_definitions.json)：

- `starting_day = 1`
- `max_day = 7`
- `actions_per_day = 1`
- 初始地点 `01`
- 初始解锁地点 `01/02/03`
- 初始 NPC `01/02/03/04`

玩家进入正式流程后，世界按 4 个阶段推进：

- `morning`
- `day`
- `night`
- `closing`

阶段推进逻辑在 [day_flow_service.gd](/C:/momen/systems/flow/day_flow_service.gd)。

当前推进规则是：

- `morning -> day`
- `day -> night`
- `night -> closing`
- `closing -> next day`
- 第 7 天 `closing` 后若未提前结束，则直接收束本轮

玩家不再手动点击“结束白天”。

### 2.3 白天节点

白天是当前项目最重要的玩家操作阶段。

白天的实际规则是：

1. 先检查是否有必然事件
2. 没有则检查条件事件
3. 再没有则检查随机事件
4. 如果事件仍然没有接管，则给玩家 3 个随机行动候选

当前这套调度由：

- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [event_service.gd](/C:/momen/systems/event/event_service.gd)
- [story_event_scheduler.gd](/C:/momen/systems/event/story_event_scheduler.gd)

共同完成。

### 2.4 夜间与收束

夜间不再让玩家自由行动，而是自动进入事件读取和阶段收束。

因此当前体验上：

- 白天负责“选”
- 夜间负责“收”

这和项目现在的叙事目标是对齐的。

## 3. 当前事件体系

### 3.1 三层事件结构仍然存在

当前运行时仍然保留 3 层事件结构，核心数据在 [events.csv](/C:/momen/content/story/act1/csv/events.csv)。

#### 第一层：必然主线

对应：

- `event_class = fixed_story`
- `event_class = ending_check`

现行主线骨架是：

- `1001`
- `1002`
- `1003`
- `1004`
- `1005`
- `1006`

这些事件构成 Act 1 的日程骨架。

#### 第二层：条件触发事件

对应：

- `event_class = conditional_story`

这层包含：

- 地点调查事件
- NPC 状态事件
- 特定后果事件
- 心战后的收束事件

例如：

- `2001` 柳飞霞首轮
- `2002` 柳飞霞后续接触
- `2003` 疯长老首轮
- `2004` 王麻子首轮
- `2005` 夜巡弟子首轮
- `9102/9103` 柳飞霞心战收束
- `9202/9203` 王麻子心战收束
- `9302/9303` 夜巡心战收束
- `9402/9403` 疯长老心战收束

#### 第三层：随机事件

对应：

- `event_class = random_filler`

当前既包括：

- 普通资源/关系/风险扰动
- 也包括可重复的杂兵心战 `9501`

### 3.2 当前调度顺序

当前 [story_event_scheduler.gd](/C:/momen/systems/event/story_event_scheduler.gd) 的调度顺序是：

白天：

1. `ending_check`
2. `fixed_story`
3. `conditional_story`
4. `random_filler`

非白天：

1. `ending_check`
2. `fixed_story`
3. `conditional_story`
4. `random_filler`

这意味着现在白天和夜间都会读取随机事件，只是白天还会在无事件时继续落到 3 个随机行动候选。

## 4. 当前玩家操作结构

### 4.1 已被移除的旧操作

下面这些旧结构已经不再是主循环核心：

- 手动结束白天
- 手动移动地点
- 点击场景内 NPC 开主剧情
- 从动作菜单里挑一长串地点动作

### 4.2 当前保留的玩家操作

当前玩家实际会做的事只有 4 类：

- 推进开场序章按钮
- 在白天 3 选 1 的候选行动里做选择
- 在事件面板里做选项
- 在对话里选择 `观察 / 入侵`

其中：

- `观察` 仍然是对话观察
- `入侵` 会在有配置时直接进入心战

## 5. 对话系统当前逻辑

### 5.1 当前对话不是旧版三按钮了

现行对话阶段控制在 [event_service.gd](/C:/momen/systems/event/event_service.gd)。

当前对话枢纽真实可见的是：

- `观察`
- `入侵`

而不是旧的：

- `观察`
- `侵入`
- `对话`

当前代码里 `__talk__` 仍然有遗留分支，但现行枢纽视图已经提前返回，只展示两项。这说明“旧三段式”在运行上已被压缩，但代码层仍有未完全清理的残留。

### 5.2 对话的几种状态

当前对话状态概念上仍有：

- `hub`
- `observe`
- `intrude`
- `talk`

但实际主用的是：

- `hub`
- `observe`
- `入侵后直接切战斗`

### 5.3 对话结束后的推进

对话完成后：

- 事件被标记已触发
- 当前事件被清掉
- 再进入统一的阶段推进逻辑

这一点由 [run_controller.gd](/C:/momen/autoload/run_controller.gd) 的 `complete_current_dialogue_event()` 驱动。

## 6. 心战系统当前逻辑

### 6.1 心战如何进入

当前心战有两种入口：

- `dialogue_event` 上挂 `battle_id`
- 直接 `battle_event`

当前主用的是第一种，也就是“对话中点击入侵 -> 进入心战”。

### 6.2 心战的核心规则

当前心战由：

- [battle_service.gd](/C:/momen/systems/battle/battle_service.gd)
- [battle_rule_service.gd](/C:/momen/systems/battle/battle_rule_service.gd)

负责。

现行规则是：

- 固定 2 槽
- 左槽 `BASE`
- 右槽 `MULTI`
- 必须两槽都放满才能结算

结算公式是：

`基础值 x 倍率 x 破绽倍率 + 抗性修正`

同时还会结算：

- 槽位卡的理智消耗
- 抗性带来的额外理智消耗
- 回合结束反噬

### 6.3 心战资源与结果

当前心战的直接结果有：

- 敌方心防值降低
- 玩家理智降低
- 战斗胜利或失败

战斗胜利后由 [run_controller.gd](/C:/momen/autoload/run_controller.gd) 的 `_complete_current_battle()` 回写：

- 经验
- 新卡牌
- 战斗日志
- 战后摘要文本
- 对应的成功结果事件

失败后则：

- 写失败摘要
- 进入失败结果事件
- 某些战斗会直接结束本轮

### 6.4 牌库与成长

当前牌库系统本质上是“心战卡收藏与可用牌堆摘要”。

现行牌库会显示：

- 战斗定义的基础起始牌堆
- 已经通过心战奖励获得的卡

而且现在这些奖励卡不只是展示，还会并入后续战斗的起始牌堆。

## 7. 当前 Act 1 的主要心战内容

当前已经实装的主要心战链有：

- `2001 -> 9101 -> 9102/9103` 柳飞霞
- `2004 -> 9201 -> 9202/9203` 王麻子
- `2005 -> 9301 -> 9302/9303` 夜巡弟子
- `2003 -> 9401 -> 9402/9403` 疯长老
- `9501 -> 9502/9503` 外门低级弟子随机杂兵

其中：

- 前四条是关键 NPC 链
- `9501` 是可重复经验与练手来源

## 8. 当前行动系统的真实位置

虽然“自由行动制”已经被砍掉，但项目仍然保留了 `ActionService` 和行动定义。

当前这层的真实作用已经变成：

- 作为白天无事件时的 3 选 1 候选项来源

也就是说，现在的行动不再是“地图探索动作”，而更像“节点之间的白天抉择包”。

这层逻辑主要在 [run_controller.gd](/C:/momen/autoload/run_controller.gd) 的：

- `get_visible_actions()`
- `_get_or_create_current_action_candidates()`

## 9. 当前 UI 呈现模式

主界面当前有 5 种场景模式，由 [main_game_view_model.gd](/C:/momen/ui/view_models/main_game_view_model.gd) 生成，再由 [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd) 渲染：

- `location`
- `dialogue`
- `event`
- `battle`
- `ending`

### 9.1 各模式含义

- `location`：白天节点与动作展示
- `dialogue`：人物对话
- `event`：普通事件或非对话事件
- `battle`：全屏心战
- `ending`：本局收束

### 9.2 当前牌库入口

牌库按钮现在有两处：

- 场景交互栏
- 顶部常驻按钮

这样即使在对话或心战中，也仍然可以打开牌库。

## 10. 当前主要资源与进度项

### 10.1 玩家资源

当前 HUD 主显示资源包括：

- `blood_qi`
- `spirit_stone`
- `spirit_sense`
- `clue_fragments`
- `pollution`
- `exposure`

### 10.2 玩家属性

当前玩家属性包括：

- `physique`
- `mind`
- `insight`
- `occult`
- `tact`

### 10.3 世界推进值

当前世界推进值主要有：

- `investigation_progress`
- `anomaly_progress`
- `patrol_level`

这些值会继续影响条件事件与结局条件。

## 11. 数据文件分层

### 11.1 运行定义层

- [run_definitions.json](/C:/momen/content/runs/run_definitions.json)

负责：

- 开场
- 初始状态
- 初始 NPC / 地点 / 资源 / 目标

### 11.2 事件层

- [events.csv](/C:/momen/content/story/act1/csv/events.csv)
- [event_triggers.csv](/C:/momen/content/story/act1/csv/event_triggers.csv)
- [event_options.csv](/C:/momen/content/story/act1/csv/event_options.csv)
- [option_effects.csv](/C:/momen/content/story/act1/csv/option_effects.csv)
- [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)

负责：

- 事件定义
- 触发条件
- 选项
- 效果
- 文本

### 11.3 心战层

- [card_definitions.json](/C:/momen/content/battle/card_definitions.json)
- [enemy_mind_definitions.json](/C:/momen/content/battle/enemy_mind_definitions.json)
- [battle_definitions.json](/C:/momen/content/battle/battle_definitions.json)
- [battle_texts.json](/C:/momen/content/battle/battle_texts.json)

负责：

- 卡牌
- 敌方心防
- 战斗定义
- 心战 UI 文本

### 11.4 UI 文本层

- [ui_texts.json](/C:/momen/content/text/ui_texts.json)
- [dialogue_ui_texts.json](/C:/momen/content/text/dialogue_ui_texts.json)
- [opening_ui_texts.json](/C:/momen/content/text/opening_ui_texts.json)

## 12. 目前仍然存在的遗留与混乱点

这部分是当前最重要的“认知警告”。

### 12.1 代码层仍有旧对话残留

[event_service.gd](/C:/momen/systems/event/event_service.gd) 里仍然保留了：

- `__talk__` 的旧分支
- `_build_dialogue_intrusion_option_views()` 的旧实现

但现行枢纽逻辑已经提前返回，运行时主用的是“观察 / 入侵直开战斗”。

也就是说：

- 设计上已经切到新逻辑
- 代码上还没有彻底清尸

### 12.2 仍有旧 `combat_event`

[events.csv](/C:/momen/content/story/act1/csv/events.csv) 里仍有旧式 `combat_event`，例如 `act1_combat_blood_runner`。

这说明当前项目存在两套战斗语义：

- 旧的数值型 `combat_event`
- 新的卡牌心战 `battle_id`

这是后续必须继续收口的地方。

### 12.3 地点仍保留表现层意义

虽然地点导航已不再是主玩法，但地点仍然影响：

- 背景图
- 当前出场 NPC
- 某些事件的可触发位置
- 杂兵/调查/异常事件的地点过滤

所以地点现在不是“删除对象”，而是“表现与挂载层”。

### 12.4 行动系统已降级，但未完全退役

行动系统现在已经不再是旧日程模拟，但底层文件和服务仍然存在。

这说明当前项目还处在：

- 结构方向已切换
- 底层技术债尚未完全收尾

的阶段。

## 13. 当前可以用来指导后续开发的统一心智模型

如果要一句话概括当前项目，最准确的说法是：

**一个由 7 天阶段推进驱动的节点叙事游戏，白天以主线/条件/随机节点和 3 选 1 抉择推进，关键 NPC 对话则通过“观察 / 入侵”切入心战，再把胜负结果回写回剧情链。**

后续新增内容时，应优先问自己：

1. 这是一条主线节点、条件节点，还是随机节点？
2. 它是普通事件，还是应该做成“对话 -> 入侵心战 -> 收束事件”？
3. 它会回写哪些状态、资源、关系和卡牌？
4. 它属于哪一段编号，是否符合当前心战与事件约束？

## 14. 后续最值得继续整理的方向

按优先级建议如下：

1. 彻底清掉 `EventService` 里旧对话残留分支
2. 把旧 `combat_event` 统一收进心战或正式退役
3. 继续把 Act 1 关键 NPC 节点补成完整链路图
4. 统一梳理“地点作为表现层”的职责边界
5. 给当前心战、事件、编号规则继续补文档，减少后续散改
