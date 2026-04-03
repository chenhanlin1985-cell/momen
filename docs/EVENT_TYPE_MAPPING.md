# 事件类型映射表

本文档已更新为当前状态版本。

项目里现在仍然有两层事件类型：

- 底层运行时类型：`presentation_type`
- UI / 玩法标签：`event_type_key`

这两层不能混用。

## 1. 当前关键映射

### 1.1 心战入口节点

- `2001` -> `dialogue_event` / `boss_battle`
- `2004` -> `dialogue_event` / `elite_battle`
- `2005` -> `dialogue_event` / `elite_battle`
- `2003` -> `dialogue_event` / `elite_battle`

### 1.2 非心战 NPC 对话

- `2002` -> `standard_event` / `reward`
- `2102` -> `standard_event` / `reward`
- `2201` -> `standard_event` / `reward`
- `2202` -> `standard_event` / `reward`
- `2203` -> `standard_event` / `reward`
- `2007` -> `standard_event` / `reward`
- `2008` -> `standard_event` / `dialogue`

### 1.3 其他常见类型

- `1301-1303` -> `compact_choice_event` / `reward`
- `2301-2303` -> `compact_choice_event` / `reward`
- `2401-2403` -> `compact_choice_event` / `reward`
- `3301-3302` -> `standard_event` / `review`
- `3401-3402` -> `standard_event` / `shop`
- `9501` -> `battle_event` / `normal_battle`

## 2. 当前最重要的理解

现在最需要记住的是：

- 不是所有“人物对话表现”都是 `dialogue_event`
- 非心战 NPC 对话已经可以是 `standard_event + dialogue scene`
- `dialogue_event` 的语义已经被收紧为“会进入心战的对话入口”

## 3. 实际开发规则

- 需要 `观察 / 入侵 / battle` 的节点，用 `dialogue_event`
- 需要人物立绘/说话人表现，但不会进心战的节点，用 `standard_event`
- 需要紧凑奖励/回顾式展示的节点，用 `compact_choice_event` 或对应普通事件

更完整的当前说明，优先参考：

- `docs/EVENT_TYPE_MAPPING_CURRENT.md`
- `docs/DIALOGUE_EVENT_RUNTIME_STATUS.md`
