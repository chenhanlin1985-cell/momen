# 验证快速入口

这份文档只回答一件事：

当前仓库里，改完内容或系统后，应该先跑哪套验证。

## 一键入口

路线图验证：

```powershell
& 'e:\game\momen\tools\validation\run_route_map_validation_suite.ps1'
```

战斗验证：

```powershell
& 'e:\game\momen\tools\validation\run_battle_validation_suite.ps1'
```

## 什么时候跑路线图套件

只要改了下面任意一类内容，就先跑路线图套件：

- `content/story/act1/route_map/*.json`
- `systems/route/*.gd`
- `ui/components/route_map_panel.gd`
- `autoload/run_controller.gd` 里和路线图推进有关的逻辑
- 路线图 action 反馈事件、路线图 UI 类型、路线图文案

路线图套件主要防这些问题：

- 节点能看到但实际走不到
- 边回列、同列推进、看起来像断链
- action 节点又被旧随机事件调度改写
- 灰市/奖励/对话节点跑成错误事件类型
- Day 1 到 Day 6 的关键路径前沿错位

## 什么时候跑战斗套件

只要改了下面任意一类内容，就先跑战斗套件：

- `content/battle/*.json`
- `systems/battle/*.gd`
- 战斗结果事件链
- 战斗 UI 与战斗状态同步逻辑
- 污染牌、敌人特攻、数值平衡相关逻辑

战斗套件主要防这些问题：

- 软锁
- 失败后断链
- 存档恢复错位
- UI 看起来还能点，但状态其实已经结束
- 文案写了特殊效果，但规则层没生效

## 建议顺序

如果一次改动同时碰了路线图和战斗，建议顺序是：

1. 先跑路线图套件
2. 再跑战斗套件
3. 最后再做实机手测

## 相关文档

- [ROUTE_MAP_IMPLEMENTATION_PLAN.md](/e:/game/momen/docs/ROUTE_MAP_IMPLEMENTATION_PLAN.md)
- [BATTLE_CONTENT_CONSTRAINTS.md](/e:/game/momen/docs/BATTLE_CONTENT_CONSTRAINTS.md)
