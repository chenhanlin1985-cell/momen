# 心理战模块安全实装方案

## 目的

本方案用于把 [battle.md](/C:/momen/docs/battle.md) 实装进当前项目，同时尽量避免新增兼容层和技术债。

当前项目已经切到“节点推进”主循环，因此战斗不能再按旧的 `combat_event + 事件选项检定` 继续扩写。  
最安全的方式是：

- 主流程仍然是节点流
- 心理战是独立模块
- 事件系统只负责进入战斗与接收战斗结果

## 结论

必须重写，不做硬兼容的部分：

- 战斗状态模型
- 战斗流程控制
- 战斗专用 UI
- 战斗数据格式

只做桥接，不承担战斗细节的部分：

- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [event_service.gd](/C:/momen/systems/event/event_service.gd)
- [content_repository.gd](/C:/momen/systems/content/content_repository.gd)
- [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)
- [main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)

## 为什么不能直接改现有 combat_event

当前现状：

- [events.csv](/C:/momen/content/story/act1/csv/events.csv) 里的 `combat_event` 只是一种事件表现类型
- [event_options.csv](/C:/momen/content/story/act1/csv/event_options.csv) 里的战斗仍然是普通选项检定
- [event_service.gd](/C:/momen/systems/event/event_service.gd) 只会把敌人基础数值挂到事件定义上
- [enemy_definitions.json](/C:/momen/content/enemies/enemy_definitions.json) 只有简单敌人数值

而 [battle.md](/C:/momen/docs/battle.md) 要求的是：

- 手牌
- 抽牌与重抽
- 认知插槽
- 理智消耗
- 敌方心防
- 破绽与抗性
- 敌方反制回合
- 战后奖励卡牌

这已经不是“给 combat_event 多加几个字段”能解决的事。  
如果继续塞进旧事件选项流，会把事件系统、对话系统、主界面三边都污染掉。

## 目标结构

### 1. 主流程层

继续沿用当前节点流：

- 必然节点
- 条件节点
- 随机节点

当节点是“心理战入口”时：

1. 主流程暂停在当前事件
2. 切入心理战模块
3. 心理战模块独立完成整个回合流程
4. 战斗结果回写到 `RunState`
5. 返回节点流，进入战后收束节点

### 2. 心理战模块层

新增独立模块，不复用旧对话面板：

- 战斗状态
- 战斗服务
- 战斗界面
- 战斗数据

### 3. 内容层

继续外置，继续数字命名，不把玩家文本塞回脚本。

## 新增文件

### 核心脚本

- [battle_state.gd](/C:/momen/core/models/battle_state.gd)
- [battle_service.gd](/C:/momen/systems/battle/battle_service.gd)
- [battle_rule_service.gd](/C:/momen/systems/battle/battle_rule_service.gd)
- [battle_reward_service.gd](/C:/momen/systems/battle/battle_reward_service.gd)

### UI

- [battle_panel.tscn](/C:/momen/ui/components/battle_panel.tscn)
- [battle_panel.gd](/C:/momen/ui/components/battle_panel.gd)

### 内容数据

- [card_definitions.json](/C:/momen/content/battle/card_definitions.json)
- [enemy_mind_definitions.json](/C:/momen/content/battle/enemy_mind_definitions.json)
- [battle_definitions.json](/C:/momen/content/battle/battle_definitions.json)
- [battle_texts.json](/C:/momen/content/battle/battle_texts.json)

## 只改桥接的现有文件

### [run_controller.gd](/C:/momen/autoload/run_controller.gd)

处理内容：

- 增加“当前是否处于战斗中”的入口
- 增加“开始战斗”
- 增加“提交战斗操作”
- 增加“结束战斗并回写结果”

不要继续让它承担：

- 手牌逻辑
- 回合逻辑
- 敌方反制逻辑

### [event_service.gd](/C:/momen/systems/event/event_service.gd)

处理内容：

- 新增一种明确的事件表现类型，例如 `battle_event`
- 读到 `battle_event` 时，只返回战斗入口所需的基础信息
- 不在这里做战斗过程结算

不要继续让它承担：

- 卡牌算分
- 重抽
- 插槽组合
- 战斗胜负判断

### [content_repository.gd](/C:/momen/systems/content/content_repository.gd)

处理内容：

- 新增 battle 内容读取入口
- 按数字 id 提供卡牌、敌方心防、战斗定义

不要做：

- 临时把战斗字段混进旧 `enemy_definitions.json`
- 临时把整场战斗定义硬塞进 `events.csv`

### [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)

处理内容：

- 根据 `scene_mode` 切换到心理战面板
- 战斗中隐藏普通事件和普通节点选项
- 战斗结束后回到现有节点流界面

不要做：

- 把战斗界面直接塞进 `dialogue_event_panel.gd`
- 把事件按钮容器继续扩成战斗按钮容器

### [main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)

处理内容：

- 增加一个独立的 BattlePanel 容器

不要做：

- 继续在现有 EventPanel 上层层嵌套战斗控件

## 数据结构规范

全部数字命名。

### 1. 卡牌定义 `card_definitions.json`

建议字段：

- `id`
- `story_id`
- `display_name`
- `card_group`
- `card_type`
- `base_score`
- `multiplier_tags`
- `cost_sanity`
- `draw_weight`
- `text_key`
- `notes`

约束：

- `card_group` 只分“线索卡”“情绪卡”
- `card_type` 继续用项目内术语，不回到英文枚举暴露给玩家
- 玩家可见名称和说明继续外置

### 2. 敌方心防定义 `enemy_mind_definitions.json`

建议字段：

- `id`
- `npc_id`
- `story_id`
- `display_name`
- `max_hp`
- `start_hp`
- `start_sanity_pressure`
- `slot_count`
- `vulnerability_tags`
- `resistance_tags`
- `counter_profile_id`
- `victory_rewards`

说明：

- 这里定义的是“心理战版本的敌人”
- 不和旧 `enemy_definitions.json` 混写

### 3. 战斗定义 `battle_definitions.json`

建议字段：

- `id`
- `story_id`
- `entry_event_id`
- `result_event_id_success`
- `result_event_id_failure`
- `enemy_mind_id`
- `starter_deck`
- `initial_hand_size`
- `redraw_cost`
- `end_turn_recoil`
- `max_sanity`
- `exp_reward`
- `reward_card_ids`
- `ui_style`

说明：

- 每一场战斗是一个独立定义
- 用 `entry_event_id` 绑定主流程节点
- 用 `result_event_id_success / failure` 回到节点流

### 4. 文本 `battle_texts.json`

外置内容包括：

- 卡牌说明
- 敌方破绽说明
- 敌方抗性说明
- 回合按钮文案
- 战斗日志文案
- 胜利/失败总结文案

## 第一场样板战斗

按 [battle.md](/C:/momen/docs/battle.md) 原需求，第一场直接做柳飞霞。

### 建议编号

- 战斗定义：`9101`
- 敌方心防：`9101`
- 线索卡：`9111` `9112` `9113`
- 情绪卡：`9121` `9122` `9123`
- 奖励卡：`9131` `9132`

### 对应关系

- `9101` 心理战入口节点挂在柳飞霞对应剧情事件之后
- 成功后进入新的战后收束节点
- 失败后进入失败收束节点或直接坏结局节点

## 第一阶段必须实现的 battle.md 需求

第一版必须完整实现：

- 理智值
- 2 个认知插槽
- 手牌
- 抽牌
- 重抽
- 出牌消耗理智
- 回合结束反噬
- 敌方 HP
- 破绽倍率
- 抗性修正
- 胜利奖励
- 返回剧情节点

第一版可以先固定，但不能偷掉：

- 敌方反制
- 奖励卡获得
- 战后经验回写

第一版可以先做成单场样板，后续再通用化：

- 只先支持柳飞霞一场
- 只先支持 2 插槽
- 只先支持一套新手牌组

## 明确重写边界

下面这些部分如果不顺手，不要兼容，直接重写：

### 必须重写

- 战斗状态容器
- 战斗流程控制器
- 战斗专用 UI
- 战斗内容数据文件

### 严禁继续兼容扩写

- [dialogue_event_panel.gd](/C:/momen/ui/components/dialogue_event_panel.gd)
- 旧 `combat_event` 的普通选项式结算
- [enemy_definitions.json](/C:/momen/content/enemies/enemy_definitions.json) 的旧简单敌人数值结构

## 实施顺序

### 阶段 1：建独立骨架

先做：

- `battle_state.gd`
- `battle_service.gd`
- `battle_panel.tscn/.gd`
- `content/battle/*.json`

这一步不接主流程，只保证模块自洽。

### 阶段 2：接入入口事件

改：

- `events.csv`
- `event_service.gd`
- `content_repository.gd`
- `run_controller.gd`

目标：

- 读到 `battle_event`
- 正确进入 `BattlePanel`

### 阶段 3：接入柳飞霞首战

补：

- `9101` 战斗定义
- 柳飞霞敌方心防定义
- 新手牌组
- 成功/失败收束节点

目标：

- 第一场完整打通

### 阶段 4：战后回写

补：

- EXP
- 奖励卡
- 状态标签
- 战后剧情节点

目标：

- 能从战斗返回节点流并继续推进

## 当前不做的事

为了避免技术债，当前阶段不做：

- 把所有 NPC 对话都立刻改成心理战
- 在旧战斗和新战斗之间做双轨长期兼容
- 把卡牌逻辑混进现有事件选项 CSV
- 把战斗文本塞回脚本常量

## 验收标准

第一阶段完成后，至少满足：

1. 进入柳飞霞节点后能切到独立心理战面板
2. 玩家能抽牌、重抽、放入 2 个插槽并结算
3. 理智、敌方 HP、破绽、抗性能实际生效
4. 失败会触发反噬或失败收束
5. 胜利会回写 EXP、奖励卡和剧情结果
6. 战斗结束后能回到节点流，不残留旧事件状态

## 结论

这次实装的安全原则只有一条：

心理战模块独立重写，节点流只做入口和回写。  
凡是会把战斗细节塞回旧事件系统、旧对话面板、旧敌人结构的做法，都不要采用。
