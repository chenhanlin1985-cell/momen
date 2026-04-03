# 节点制改造执行顺序

## 执行原则

这次改造只允许一条主路径：把现有“伪自由行动”结构收成“节点推进”结构。

必须遵守下面 6 条：

1. 不为了“先跑起来”额外增加兼容层。
2. 不长期并存两套 runtime。
3. 不保留没有实际玩法价值的假入口。
4. 运行时主键继续优先使用数字命名。
5. 玩家可见文本继续全部外置。
6. 每一步完成后都要能明确退役一批旧能力，而不是继续拖着。

## 唯一主循环

改造完成后，运行时只允许这一条流程：

1. 当前节点结算完成。
2. 系统自动解析下一节点。
3. 解析顺序固定为：
   - 主线必然节点
   - 条件节点
   - 随机三选一节点
   - 结局节点
4. 玩家完成当前节点。
5. 系统继续自动推进，直到结局。

不再要求玩家手动移动、手动结束白天、手动寻找真正有效的互动入口。

## 明确保留

这些是现有系统里值得保留的部分：

1. `content/story/act1/csv/events.csv`
2. `content/story/act1/csv/event_triggers.csv`
3. `content/story/act1/csv/event_options.csv`
4. `content/story/act1/csv/option_effects.csv`
5. `content/story/act1/csv/localization.csv`
6. Markdown 编译链
7. 条件判断、事件效果执行、对话事件渲染、线索状态体系

保留它们，是因为它们本质上仍然服务“节点内容、条件检查、结果结算”。

## 明确退役

这些能力只要切完对应阶段，就不要再补：

1. 手动结束白天
2. 手动切换地点
3. 依赖自由点击 NPC 才能进入主剧情
4. 以行动点为核心的白天自由行动
5. 看起来能点、实际上没有独立价值的地点/行动入口

## 分阶段执行

### 第 1 步：切掉“结束白天”

目标：

- 节点完成后自动推进下一步。
- 不再需要玩家点“结束白天”。

必须处理的文件：

- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)
- [main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)
- [day_flow_service.gd](/C:/momen/systems/flow/day_flow_service.gd)

验收标准：

- 整个流程里没有手动结束白天按钮。
- 当前节点结算后会立即进入下一节点解析。

### 第 2 步：切掉“手动移动”

目标：

- 地点只保留为节点背景和条件载体。
- 玩家不再手动切换地点。

必须处理的文件：

- [location_service.gd](/C:/momen/systems/location/location_service.gd)
- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)
- [main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)
- [location_definitions.json](/C:/momen/content/locations/location_definitions.json)

验收标准：

- 玩家无法主动打开地点切换流程。
- 节点进入时自动切换背景和出场对象。

### 第 3 步：把 NPC 互动改成节点直开

目标：

- 主剧情不再依赖“点某个 NPC”。
- 有 NPC 的剧情节点，进入节点时直接开对话或事件。

必须处理的文件：

- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [npc_service.gd](/C:/momen/systems/npc/npc_service.gd)
- [content/story/act1/csv/events.csv](/C:/momen/content/story/act1/csv/events.csv)
- [npc_interactions.json](/C:/momen/content/npcs/npc_interactions.json)
- [npc_definitions.json](/C:/momen/content/npcs/npc_definitions.json)

验收标准：

- 柳飞霞、王麻子、疯长老、巡夜弟子等主剧情人物都能通过节点直接进入。
- 不再依赖“回到自由界面再点 NPC”。

### 第 4 步：把行动改成“随机三选一节点”

目标：

- 行动不再是底部自由操作栏。
- 行动只在随机节点阶段以三选一形式出现。

必须处理的文件：

- [run_controller.gd](/C:/momen/autoload/run_controller.gd)
- [action_service.gd](/C:/momen/systems/action/action_service.gd)
- [action_definitions.json](/C:/momen/content/actions/action_definitions.json)
- [event_pools.csv](/C:/momen/content/story/act1/csv/event_pools.csv)
- [events.csv](/C:/momen/content/story/act1/csv/events.csv)

验收标准：

- 没有主线节点、没有条件节点时，系统给玩家 3 个随机候选。
- 玩家选 1 个后立刻结算并进入下一节点。

### 第 5 步：收口主界面

目标：

- 主界面从“轻度探索界面”收成“节点叙事界面”。

必须处理的文件：

- [main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)
- [main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)
- [main_game_view_model.gd](/C:/momen/ui/view_models/main_game_view_model.gd)
- [ui_texts.json](/C:/momen/content/text/ui_texts.json)

验收标准：

- 底栏只保留仍然有真实价值的入口。
- 线索模块保留。
- 当前节点信息、对话区、资源与风险摘要能支撑完整游玩。

## 开发判断标准

每做一项改动，都问这 3 个问题：

1. 这个入口现在是否真的给玩家提供了有价值的选择？
2. 删掉它以后，剧情和交互会不会更直接？
3. 它是不是只是为了兼容旧结构而存在？

如果答案分别是：

- “没有真实选择价值”
- “删掉更直接”
- “只是兼容旧结构”

那就直接删，不补兼容。

## 当前结论

这次改造不是在“给自由行动做优化”，而是在正式放弃伪自由结构。

项目完成后的唯一定位应该是：

**节点推进叙事游戏，不再是假自由行动游戏。**
