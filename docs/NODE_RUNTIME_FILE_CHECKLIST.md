# 节点制改造文件清单

## 用途

这份清单是执行版，不再讨论方向，只回答三件事：

1. 先改哪些文件
2. 每个文件改什么
3. 哪些旧入口在对应阶段必须退役

执行时只按阶段推进，不插入额外兼容层。

## 阶段 1：去掉“结束白天”

### 目标

- 当前节点结算后自动推进下一节点。
- 玩家不再手动点“结束白天”。

### 需要改的文件

#### [autoload/run_controller.gd](/C:/momen/autoload/run_controller.gd)

处理内容：

1. 把 `end_day()` 从主流程里退役。
2. 把“节点结算后进入下一阶段”的逻辑收敛到统一推进函数。
3. `perform_action()` 和 `perform_npc_interaction()` 结束后，不再等玩家手动结束白天。
4. 把当前依赖 `_day_flow_service.advance_after_action()` 的推进逻辑改成节点推进逻辑。

必须退役：

- `end_day()` 作为主流程入口

#### [scenes/screens/main_game/main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)

处理内容：

1. 去掉 `_end_day_button` 的主流程绑定。
2. 删除 `_on_end_day_pressed()` 或改成废弃态。
3. 刷新逻辑里不再根据“是否还能结束白天”来驱动底栏。

必须退役：

- `EndDayButton` 的交互语义

#### [scenes/screens/main_game/main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)

处理内容：

1. 删除 `EndDayButton`。
2. 底栏布局改成不依赖“结束白天”。

必须退役：

- `EndDayButton` 节点

#### [systems/flow/day_flow_service.gd](/C:/momen/systems/flow/day_flow_service.gd)

处理内容：

1. 只保留“天数与阶段推进”的必要能力。
2. 去掉“白天结束由按钮触发”的假设。

必须退役：

- 为手动结束白天服务的入口假设

## 阶段 2：去掉“手动移动”

### 目标

- 地点只保留为节点背景和条件载体。
- 玩家不再手动切换地点。

### 需要改的文件

#### [autoload/run_controller.gd](/C:/momen/autoload/run_controller.gd)

处理内容：

1. 退役 `move_to_location()` 作为玩家主流程入口。
2. 保留“当前节点决定当前地点”的赋值能力。
3. `get_available_locations()` 不再驱动主界面交互。

必须退役：

- `move_to_location()`

#### [systems/location/location_service.gd](/C:/momen/systems/location/location_service.gd)

处理内容：

1. 保留地点定义读取、地点条件判断、地点展示数据整理。
2. 去掉自由移动语义：
   - `can_move_to_location`
   - `move_to_location`
3. 如果仍需保留函数，必须只作为内部节点切换使用，不再暴露给玩家交互。

必须退役：

- 自由移动能力

#### [scenes/screens/main_game/main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)

处理内容：

1. 去掉 `_location_menu_button` 的主流程作用。
2. 去掉 `_rebuild_location_buttons()` 的主入口语义。
3. 背景刷新改成完全由当前节点和当前地点状态驱动。

必须退役：

- 地点菜单弹窗作为主互动入口

#### [scenes/screens/main_game/main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)

处理内容：

1. 删除地点按钮和地点弹窗列。
2. 保留舞台背景显示节点。

必须退役：

- `LocationMenuButton`
- `LocationColumn`

#### [content/locations/location_definitions.json](/C:/momen/content/locations/location_definitions.json)

处理内容：

1. 继续保留：
   - 背景图
   - 场景标题
   - 场景注释
   - 条件标签
2. 不再把这里的数据当成“玩家可自由导航的地图菜单”。

## 阶段 3：把 NPC 互动改成节点直开

### 目标

- 主剧情不再依赖手动点 NPC。
- NPC 只作为节点内容来源和舞台表现来源。

### 需要改的文件

#### [autoload/run_controller.gd](/C:/momen/autoload/run_controller.gd)

处理内容：

1. 收紧 `perform_npc_interaction()`，避免它继续承担主剧情推进职责。
2. 主剧情节点统一通过“当前事件/当前节点”直开。
3. `get_available_npc_interactions()` 逐步退出主流程。

必须退役：

- 自由点击 NPC 进入主剧情

#### [systems/npc/npc_service.gd](/C:/momen/systems/npc/npc_service.gd)

处理内容：

1. 保留 NPC 定义读取、状态读取、立绘/出场信息。
2. 逐步去掉“依赖当前地点点击某个 NPC”这条主路径。
3. 主剧情人物进入方式改成节点绑定。

#### [content/npcs/npc_interactions.json](/C:/momen/content/npcs/npc_interactions.json)

处理内容：

1. 清理只为自由点击存在的互动定义。
2. 只保留仍然有独立价值的特殊入口。

#### [content/npcs/npc_definitions.json](/C:/momen/content/npcs/npc_definitions.json)

处理内容：

1. 保留 NPC 展示数据、状态事件、关联标签。
2. 不再把“玩家是否能点到他”当成主要设计点。

#### [content/story/act1/csv/events.csv](/C:/momen/content/story/act1/csv/events.csv)

处理内容：

1. 把柳飞霞、王麻子、疯长老、巡夜弟子等主剧情内容收成节点直开。
2. 彻底区分：
   - 主线节点
   - 条件节点
   - 随机节点
3. 不再依赖“玩家回到场景再点一次人”。

## 阶段 4：把行动改成随机三选一节点

### 目标

- 行动不再是底栏自由入口。
- 行动只保留为随机节点候选。

### 需要改的文件

#### [autoload/run_controller.gd](/C:/momen/autoload/run_controller.gd)

处理内容：

1. `perform_action()` 改为处理节点候选结果，而不是自由行动按钮。
2. `get_visible_actions()` 不再服务底栏。

#### [systems/action/action_service.gd](/C:/momen/systems/action/action_service.gd)

处理内容：

1. 去掉“行动点耗尽后不能继续”的自由行动语义。
2. 保留行动效果结算能力。
3. 让它服务于随机节点候选结算。

#### [content/actions/action_definitions.json](/C:/momen/content/actions/action_definitions.json)

处理内容：

1. 只保留能作为随机候选内容存在的动作。
2. 删除纯粹为了底栏自由行动而存在的动作定义。

#### [content/story/act1/csv/event_pools.csv](/C:/momen/content/story/act1/csv/event_pools.csv)

处理内容：

1. 明确哪些池是随机节点池。
2. 让系统能从池里给出 3 个候选，而不是“行动后附加抽事件”。

## 阶段 5：收口主界面

### 目标

- 主界面明确表现“节点推进叙事”，不再表现“轻度探索”。

### 需要改的文件

#### [scenes/screens/main_game/main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd)

处理内容：

1. 底栏只保留有价值入口。
2. 强化当前节点信息区。
3. 弹窗只保留仍然必要的模块。

最终建议保留：

- 线索
- 必要的状态概览
- 对话与事件面板

最终建议删除：

- 地点入口
- 行动入口
- 结束白天入口

#### [scenes/screens/main_game/main_game_screen.tscn](/C:/momen/scenes/screens/main_game/main_game_screen.tscn)

处理内容：

1. 删掉退役按钮和退役弹窗列。
2. 根据新底栏重新排版。

#### [ui/view_models/main_game_view_model.gd](/C:/momen/ui/view_models/main_game_view_model.gd)

处理内容：

1. 不再组织“可移动地点”“剩余行动”这种旧语义。
2. 新增或强化：
   - 当前节点标题
   - 当前节点层级
   - 当前节点摘要
   - 线索摘要

#### [content/text/ui_texts.json](/C:/momen/content/text/ui_texts.json)

处理内容：

1. 清理旧底栏文案。
2. 补齐节点制界面文案。
3. 所有新 UI 文案继续外置。

## 现状扫描出的旧入口

当前已经明确需要在后续阶段处理中断的入口有：

1. [autoload/run_controller.gd](/C:/momen/autoload/run_controller.gd) 中的 `move_to_location()`
2. [autoload/run_controller.gd](/C:/momen/autoload/run_controller.gd) 中的 `end_day()`
3. [systems/location/location_service.gd](/C:/momen/systems/location/location_service.gd) 中的自由移动函数
4. [systems/action/action_service.gd](/C:/momen/systems/action/action_service.gd) 中围绕 `actions_remaining` 的自由行动语义
5. [systems/npc/npc_service.gd](/C:/momen/systems/npc/npc_service.gd) 中基于地点点击的 NPC 主流程入口
6. [scenes/screens/main_game/main_game_screen.gd](/C:/momen/scenes/screens/main_game/main_game_screen.gd) 中的：
   - `_location_menu_button`
   - `_action_menu_button`
   - `_end_day_button`

## 执行要求

后续正式改代码时，严格按阶段推进：

1. 先切 `结束白天`
2. 再切 `手动移动`
3. 再切 `NPC 自由点击`
4. 再切 `自由行动`
5. 最后收口 UI

任何阶段都不要为了省事补一个新的兼容层。
