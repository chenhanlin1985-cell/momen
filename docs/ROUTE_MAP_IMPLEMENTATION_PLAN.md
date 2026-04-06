# 路线图系统落地方案

本文档用于把“像杀戮尖塔那样可视化选择路线”的想法，收敛成一个可以在当前项目里直接执行的工程方案。

目标不是把项目改造成爬塔 Roguelike，而是：

1. 让玩家在每次关键事件后都清楚知道自己接下来能走什么
2. 把当前已经存在的“路线经营”体验，变成真正可见、可选择、可预判的线路图
3. 在尽量不推翻现有 7 天叙事骨架的前提下完成接入

## 1. 设计结论

当前项目最适合做的不是“整局长竖图”，而是：

- 外层保留现有 `Day 1 -> Day 7` 叙事推进
- 内层在“白天可选阶段”展示一张小型路线图
- 玩家通过路线图选择下一个节点
- 节点最终仍然走现有 `action / event / battle` 运行时

一句话概括：

`7天叙事骨架 + 白天路线图选点 + 夜间自动收束`

这比完整照搬《杀戮尖塔》更适合现在的项目节奏。

## 2. 为什么当前项目适合这样接

现有系统已经具备 3 个关键前提：

- [run_controller.gd](/e:/game/momen/autoload/run_controller.gd) 已经把白天“无强制事件时的下一步选择”集中到了一个入口
- [main_game_view_model.gd](/e:/game/momen/ui/view_models/main_game_view_model.gd) 已经有稳定的 `event_type_key` 语义，可直接用于路线节点分类
- Act 1 已经存在明确路线 flag：
  - `route_records`
  - `route_seek_senior`
  - `route_well`
  - `route_lie_low`

也就是说，当前问题不是“系统里没有路线”，而是：

- 路线已存在
- 路线推进已存在
- 但玩家缺少一个清晰的可视化选择界面

## 3. 第一版范围

第一版只做“可执行 MVP”，不做复杂程序化生成。

### 3.1 第一版必须完成

- 新增 `route_map` 场景模式
- 白天无强制事件时，显示路线图而不是纯按钮列表
- 玩家可从路线图选择下一个节点
- 节点点击后复用现有执行链：
  - `perform_action(action_id)`
  - 或直接打开 `current_event`
  - 或直接进入 `battle`
- 节点类型可视化
- 当前节点、已选路径、可达节点有清晰视觉状态

### 3.2 第一版不要做

- 不做全局随机图生成
- 不做十几层长路线图
- 不做复杂地图种子系统
- 不做跨天地图持久路径规划
- 不做节点动画演出优先级过高的包装

第一版重点是“清晰”，不是“炫”。

## 4. 推荐交互形态

### 4.1 总体结构

路线图建议做成“日内小图”：

- 左侧为起点或当前进度
- 中间到右侧为 2 到 3 列可达节点
- 每列 2 到 4 个节点
- 玩家只能选择当前可达列中的一个节点
- 选中后立即执行该节点对应内容

### 4.2 节点类型

第一版建议使用这 7 类：

- `story`
- `dialogue`
- `reward`
- `shop`
- `review`
- `battle`
- `risk`

这些类型应直接映射现有 UI 语义，而不是再发明一套新分类。

### 4.3 节点显示信息

每个节点第一版显示：

- 图标或徽记
- 类型短标签
- 一句短提示
- 可选的风险/收益提示

例如：

- `对话` 柳飞霞递来暗报
- `战斗` 王麻子的盘问
- `奖励` 后墙灰市
- `风险` 夜巡盯梢

不要在第一版把节点内容完全剧透。

## 5. 与当前运行时的关系

### 5.1 不替代事件系统

路线图只是“下一步入口层”，不是新的剧情执行器。

节点点击后最终仍走现有系统：

- `story_event_scheduler`
- `event_service`
- `battle_service`
- `option_effects`

所以路线图本质上是：

`可视化选择器`

而不是：

`新剧情内核`

### 5.2 白天调度的新顺序

当前白天大致是：

1. 强制事件
2. 条件事件
3. 随机事件
4. 如果没有事件，则给 3 个行动候选

建议改成：

1. `ending_check`
2. `fixed_story`
3. 必须立即接管的 `conditional_story`
4. 若无强制接管，则打开路线图
5. 玩家在线路图上选一个节点
6. 节点再触发 `action / event / battle`

这样能保住主线强制收束，又让“白天的主动选择”变成清晰的地图行为。

## 6. 数据方案

第一版建议使用“模板图 + 运行时过滤”的方案。

### 6.1 新增数据文件

建议新增目录：

- `content/story/act1/route_map/`

建议按天拆模板：

- `day_01.json`
- `day_02.json`
- `day_03.json`
- `day_04.json`
- `day_05.json`
- `day_06.json`

第 7 天主要是收束与结局检查，可不需要白天路线图。

### 6.2 节点结构建议

```json
{
  "day": 3,
  "nodes": [
    {
      "node_id": "d3_records_probe",
      "column": 1,
      "lane": 0,
      "node_type": "dialogue",
      "title": "账册线",
      "hint": "顺着药房旧账继续往里探",
      "target_kind": "event",
      "target_id": "2004",
      "requires": ["global.route_records == true"],
      "blocks": [],
      "priority": 100,
      "once": true
    }
  ],
  "edges": [
    { "from": "start", "to": "d3_records_probe" }
  ]
}
```

### 6.3 字段说明

- `node_id`
  - 路线图内部节点 id
- `column`
  - 所在列
- `lane`
  - 同列中的竖向位置
- `node_type`
  - 节点展示类型
- `title`
  - 节点标题
- `hint`
  - 节点短说明
- `target_kind`
  - `action` / `event` / `battle`
- `target_id`
  - 运行时真实目标 id
- `requires`
  - 出现条件
- `blocks`
  - 屏蔽条件
- `priority`
  - 同类候选排序
- `once`
  - 是否每日只出现一次

### 6.4 第一版的简化策略

第一版不做复杂动态建图，只做：

- 先读当天模板
- 根据当前状态过滤不可用节点
- 对同列同类型节点按 `priority` 截取
- 生成可视化结果

这样足够稳定，也便于作者后续手工控制节奏。

## 7. 系统设计

### 7.1 新增服务

建议新增：

- [route_map_service.gd](/e:/game/momen/systems/route/route_map_service.gd)

职责：

- 读取当日路线模板
- 过滤不满足条件的节点
- 构建路线图视图数据
- 校验节点可达性
- 处理节点点击后的目标派发

### 7.2 新增 UI 组件

建议新增：

- [route_map_panel.gd](/e:/game/momen/ui/components/route_map_panel.gd)
- [route_map_panel.tscn](/e:/game/momen/ui/components/route_map_panel.tscn)

职责：

- 渲染节点
- 渲染连线
- 高亮当前可选节点
- 发出 `node_selected(node_id)` 信号

### 7.3 RunController 接入点

[run_controller.gd](/e:/game/momen/autoload/run_controller.gd) 需要新增：

- `get_current_route_map_view()`
- `select_route_map_node(node_id)`
- 白天路线图是否可打开的判断

原则是：

- 路线图由 `RunController` 对外提供视图
- 具体生成逻辑下沉给 `RouteMapService`

### 7.4 ViewModel 接入点

[main_game_view_model.gd](/e:/game/momen/ui/view_models/main_game_view_model.gd) 需要新增：

- `scene_mode = "route_map"`
- 路线图标题/说明文本
- 当前路线选择提示文本

### 7.5 MainGameScreen 接入点

[main_game_screen.gd](/e:/game/momen/scenes/screens/main_game/main_game_screen.gd) 需要新增：

- 路线图面板容器
- `scene_mode == route_map` 的显示逻辑
- 路线图节点点击后的回调

## 8. 当前内容如何映射到路线图

### 8.1 已有路线 flag 可直接映射

当前可先把 4 条主路线当成线路图主脉络：

- `route_records` 账册线
- `route_seek_senior` 疯长老线
- `route_well` 化骨池线
- `route_lie_low` 暂避锋芒线

### 8.2 已有事件类型可直接映射

可先直接映射这些内容：

- `2004 / 2401 / 2402 / 2403` -> 账册线节点
- `2003 / 2301 / 2302 / 2303` -> 疯长老线节点
- `2005 / 1301 / 1302 / 1303` -> 化骨池线节点
- `2002 / 2102 / 2201 / 2202 / 2203` -> 柳飞霞对话/奖励节点
- `3401 / 3402` -> 灰市/交易节点
- `9501` -> 风险战斗节点

### 8.3 夜间桥接节点的作用

像 `1101 / 1102 / 1103 / 1104 / 1005` 这类桥接节点，不一定要出现在白天路线图里。

它们更适合作为：

- 白天路线选择后的总结
- 夜间收束提示
- 路线意义的重新命名和强化

## 9. 状态流转

### 9.1 白天路线图状态

建议新增一个轻量运行时状态：

- `run_state.world_state.current_route_map_day`
- `run_state.world_state.current_route_map_node_id`
- `run_state.world_state.route_map_completed_for_phase`

第一版也可以不持久化完整路径，只记录：

- 当前是否已经完成本次白天路线选择
- 本次选择了哪个节点

### 9.2 推荐状态顺序

```text
白天开始
-> 检查强制事件
-> 无强制事件
-> 打开路线图
-> 选择节点
-> 执行节点目标
-> 后处理 follow-up
-> 进入 night / closing
```

## 10. UI 方案

### 10.1 第一版布局建议

在现有主舞台区域加入路线图层，不要另开全屏复杂界面。

推荐布局：

- 顶部：第几天 / 当前阶段 / 路线提示
- 中部：路线图节点与连线
- 底部：当前选中节点说明
- 右侧或下方：确认进入按钮

### 10.2 节点表现建议

- `story` 用现有剧情棕色系
- `dialogue` 用现有对话蓝灰系
- `reward` 用绿色系
- `shop` 用金棕系
- `battle` 用红色系
- `risk` 用偏暗黄或灰红系

直接复用 [main_game_screen.gd](/e:/game/momen/scenes/screens/main_game/main_game_screen.gd) 里现成的 `EVENT_TYPE_THEME` 视觉语言，避免新旧 UI 割裂。

### 10.3 节点信息密度

第一版每个节点建议只显示：

- 节点名
- 类型标签
- 一句 hint

不要把完整剧情描述塞进节点本体。

## 11. 开发拆分

### Phase 1：UI 原型

目标：

- 新增 `route_map_panel`
- 支持节点和连线显示
- 支持选择/高亮
- 使用假数据演示

完成标志：

- 能在主界面里看到一张静态小图
- 能点击节点

### Phase 2：运行时接线

目标：

- `RunController` 暴露路线图视图
- `MainGameViewModel` 新增 `route_map` 模式
- `MainGameScreen` 正式渲染路线图

完成标志：

- 白天无强制事件时能打开真实路线图

### Phase 3：节点执行

目标：

- 节点点击后能触发 `action / event / battle`
- 保证原有 follow-up 和 phase progression 不断

完成标志：

- 选节点后能正常进入剧情、战斗、奖励

### Phase 4：Act 1 模板接入

目标：

- 至少给 Day 2 到 Day 6 配一版真实模板
- 把现有路线节点映射进去

完成标志：

- 玩家能在 Act 1 主要白天阶段通过路线图选线

### Phase 5：校验与优化

目标：

- 校验无不可达节点
- 校验无死边
- 校验节点目标存在
- 校验强制事件优先级不被路线图覆盖

## 12. 第一批要改的文件

核心新增：

- [route_map_service.gd](/e:/game/momen/systems/route/route_map_service.gd)
- [route_map_panel.gd](/e:/game/momen/ui/components/route_map_panel.gd)
- [route_map_panel.tscn](/e:/game/momen/ui/components/route_map_panel.tscn)
- `content/story/act1/route_map/day_02.json`
- `content/story/act1/route_map/day_03.json`
- `content/story/act1/route_map/day_04.json`
- `content/story/act1/route_map/day_05.json`
- `content/story/act1/route_map/day_06.json`

核心修改：

- [run_controller.gd](/e:/game/momen/autoload/run_controller.gd)
- [main_game_view_model.gd](/e:/game/momen/ui/view_models/main_game_view_model.gd)
- [main_game_screen.gd](/e:/game/momen/scenes/screens/main_game/main_game_screen.gd)
- [main_game_screen.tscn](/e:/game/momen/scenes/screens/main_game/main_game_screen.tscn)

建议补校验：

- `tools/validation/validate_route_map_targets_runner.gd`
- `tools/validation/validate_route_map_reachability_runner.gd`

## 13. 风险与规避

### 风险 1：路线图和强制剧情抢控制权

规避：

- 强制事件永远先于路线图
- 路线图只负责“无强制接管时的主动选择”

### 风险 2：线路图太复杂，反而更看不懂

规避：

- 第一版只做 2 到 3 列
- 节点少而明确
- 强提示类型，不强提示全部剧情内容

### 风险 3：内容作者负担过重

规避：

- 第一版使用手工模板图
- 仅给关键天数配模板
- 节点直接映射已有事件，不要求重写内容

### 风险 4：路线图只换了展示，没有真的提升理解

规避：

- 每个节点必须有“类型 + 路线意义 + 下一步风险感”
- 夜间桥接文本要呼应玩家当天选择

## 14. 最推荐的开工顺序

建议严格按这个顺序做：

1. 路线图组件假数据原型
2. `route_map` 场景模式接进主界面
3. 白天选择入口从按钮切到路线图
4. 接入 Day 2 到 Day 3 的真实模板
5. 验证主线、战斗、奖励节点都能正确跳转
6. 再补 Day 4 到 Day 6

## 15. 决策建议

如果现在正式开做，建议第一轮只追求这件事：

**把“白天 3 选 1 的抽象按钮”升级成“Day 2 到 Day 3 可视化路线图选点”。**

这是最小、最稳、感知提升最大的一刀。

做完这一轮之后，再决定要不要继续扩成更完整的 Act 1 路线图系统。

## 16. 当前落地状态

路线图系统现在已经不是原型，而是一套正在使用中的主串联层。

当前已落地：

- Day 1 到 Day 6 的连续总路线图
- 路线图 `action` 节点的专用执行链
- `action` 节点的反馈事件面板
- Day 2 到 Day 6 的主要路线模板
- 图结构校验、关键路径回归、UI 类型回归

当前运行语义已经明确：

- 路线图是 `下一步入口层`
- 真正执行仍然走现有 `event / battle / option_effects`
- 有些节点是“当前可走前沿”
- 有些节点是“保留在图上的预览分支”，这类节点显示在图上但会带锁定原因

这意味着后续调整时，不能再把“图上存在但当前锁住”的节点一律当成坏链。

## 17. 路线图不变量

路线图模板现在必须满足以下不变量，这些规则已经和验证脚本绑定。

### 17.1 图结构不变量

- 每个节点 `node_id` 必须唯一且非空
- 每条边的起点和终点都必须存在
- 每个节点都必须能从 `start` 到达
- 每个非终点节点都必须有后继
- 每个非终点节点最终都必须能走到某个 `transition` 终点
- 每条非 `start` 的边都必须严格向右推进

最后一条尤其重要：

- 不允许回列
- 不允许同列推进

因为这两种结构虽然在 JSON 上“合法”，但放到连续路线图里会直接制造“像断链一样”的体验问题。

### 17.2 运行时不变量

- 路线图 `action` 节点不再走旧的随机 `post_action` 扰动调度
- 路线图 `action` 节点执行后，必须先进入反馈事件，再回到路线图
- 有模板的天数，一旦进入路线图主线，就不能悄悄掉回旧 `transition_preview`
- 强制入口事件必须在模板里占据真实前沿位置

## 18. 锁定预览分支语义

路线图里并不是所有可见节点都代表“下一步一定可点”。

当前系统里有两种都合法的节点：

- `当前前沿节点`
  - 本轮真的可以点
- `锁定预览节点`
  - 仍然显示在图上，但用来表达另一条线的压力、机会或未来入口
  - 会带明确的锁定原因

Day 6 的疯长老线就是一个典型例子：

- 玩家若先把白天推进压到账册线
- `day6_records_event` 会成为当前可走前沿
- `day6_elder_event` 会继续保留在图上
- 但它此时应该显示为“你当前主押的不是疯长老线”的锁定预览节点

这不是断链，也不是模板坏了，而是路线图在表达：

`另一条活路还在，但你这一步已经没押在它身上`

后续维护模板时，必须保留这种语义，不要把所有锁定节点都误判成 bug。

## 19. 当前验证护栏

路线图系统现在至少有三层护栏：

- 图结构护栏
  - [validate_route_map_graph_integrity_runner.gd](/e:/game/momen/tools/validation/validate_route_map_graph_integrity_runner.gd)
- 关键路径护栏
  - [validate_route_map_regression_suite_runner.gd](/e:/game/momen/tools/validation/validate_route_map_regression_suite_runner.gd)
  - [validate_route_map_long_chain_runner.gd](/e:/game/momen/tools/validation/validate_route_map_long_chain_runner.gd)
- UI 与文案护栏
  - [validate_route_map_ui_runner.gd](/e:/game/momen/tools/validation/validate_route_map_ui_runner.gd)
  - [validate_route_map_copy_runner.gd](/e:/game/momen/tools/validation/validate_route_map_copy_runner.gd)

### 19.1 当前关键路径套件已覆盖

- Day 1 开场主链
- Day 2 低调线
- Day 3 低调线
- Day 4 疯长老线
- Day 5 账册线
- Day 5 柳飞霞线
- Day 5 灰市节点
- Day 6 账册线到灰市
- Day 6 化骨池入口
- Day 6 疯长老压力预览语义

## 20. 后续修改规则

后续任何人再改路线图模板时，建议遵守这条顺序：

1. 先改模板
2. 先跑图结构校验
3. 再跑关键路径套件
4. 最后才手测 UI

不要再采用：

- 先靠实机点出断链
- 再回头修单个节点

因为路线图真正的根因层在：

- 模板图结构
- 强制入口语义
- 当前前沿 vs 锁定预览分支

只有这三层一起看，路线图系统才会稳定。

## 21. 一键验证入口

路线图系统现在已经提供了一个一键验证入口：

- [run_route_map_validation_suite.ps1](/e:/game/momen/tools/validation/run_route_map_validation_suite.ps1)

执行方式：

```powershell
& 'e:\game\momen\tools\validation\run_route_map_validation_suite.ps1'
```

这条入口会顺序跑完当前最关键的路线图验证：

- 图结构完整性
- 节点文案基础巡检
- UI 类型映射
- 运行时主状态
- action 节点确定性
- 关键路径回归
- 长链路线回归

如果只是改了路线图模板、节点标题、节点提示，建议至少跑这一条总入口。

## 22. 验证分层建议

为了避免以后再次出现“先实机点断，再回头补单点”的情况，路线图验证建议按下面三层使用。

### 22.1 改模板结构时

至少运行：

- [validate_route_map_graph_integrity_runner.gd](/e:/game/momen/tools/validation/validate_route_map_graph_integrity_runner.gd)
- [validate_route_map_regression_suite_runner.gd](/e:/game/momen/tools/validation/validate_route_map_regression_suite_runner.gd)

这一层主要防：

- 节点不可达
- 回列 / 同列推进
- 非终点无后继
- 主链断掉

### 22.2 改运行时逻辑时

至少运行：

- [validate_route_map_runtime_runner.gd](/e:/game/momen/tools/validation/validate_route_map_runtime_runner.gd)
- [validate_route_map_action_determinism_runner.gd](/e:/game/momen/tools/validation/validate_route_map_action_determinism_runner.gd)
- [validate_route_map_long_chain_runner.gd](/e:/game/momen/tools/validation/validate_route_map_long_chain_runner.gd)

这一层主要防：

- action 节点掉回旧随机调度
- 强制入口和路线图前沿打架
- 夜段 / 跨天桥接后丢链

### 22.3 改 UI 或文案时

至少运行：

- [validate_route_map_ui_runner.gd](/e:/game/momen/tools/validation/validate_route_map_ui_runner.gd)
- [validate_route_map_copy_runner.gd](/e:/game/momen/tools/validation/validate_route_map_copy_runner.gd)

这一层主要防：

- 类型显示错位
- 奖励/对话/商店节点显示成错误主题
- 节点提示重新退回占位词或泛化文案

## 23. 维护建议

后续如果路线图继续扩展到更多天数或更多分支，建议保持这条原则：

- 先把新分支加进模板
- 再把新分支加进关键路径套件
- 最后才认为它已经“正式落地”

也就是说：

`模板接入` 不等于 `系统已稳定`

只有当一条路线同时满足：

- 图结构合法
- 关键路径回归已覆盖
- UI 类型与文案显示正常

它才算真正进入可维护状态。
