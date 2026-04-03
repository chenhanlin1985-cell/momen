# 对话事件接手清单

本文档已更新为当前状态版本。

## 1. 当前结论

当前项目里的 `dialogue_event` 已经完成第一轮收口：

- `dialogue_event` 只保留给会导向心战的入口节点
- 非心战 NPC 对话已经迁到 `standard_event`
- 旧 `talk` 运行时回退已经移除

因此接手时，不应再按“存在一批无 battle 的 dialogue_event”来理解系统。

## 2. 当前保留的 dialogue_event

当前仅剩 4 个 battle 入口型 `dialogue_event`：

- `2001` -> `9101`
- `2004` -> `9201`
- `2005` -> `9301`
- `2003` -> `9401`

这些节点保留：

- `观察`
- `入侵`
- 进入心战

## 3. 已迁移的非心战 NPC 对话

以下节点现在都已经是 `standard_event`：

- `2002`
- `2102`
- `2201`
- `2202`
- `2203`
- `2008`
- `2007`

它们仍然可以走人物对话表现，但不再依赖旧对话状态机。

## 4. 当前真实规则

- `dialogue_event` = battle-entry conversation
- `standard_event` = non-battle NPC conversation with speaker/portrait presentation
- `compact_choice_event` = compact reward/choice style presentation

另外，Markdown 编译器现在也会强制执行这条规则：

- 如果内容写成 `dialogue_event` 但没有 `battle_id`，会自动降级为 `standard_event`

## 5. 接手建议

后续开发时，优先参考下面两份当前文档：

- `docs/DIALOGUE_EVENT_RUNTIME_STATUS.md`
- `docs/EVENT_TYPE_MAPPING_CURRENT.md`

如果要继续收口，下一步应针对“battle 入口型 dialogue_event”的契约继续做约束，而不是回到旧 talk 体系。
