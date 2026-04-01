# Opening Sequence 规则

## 目标

开场序章用于承载：

- 必死教学
- 觉醒演出
- 正式开局前的分步文本流程

这层流程运行在主界面 `OpeningOverlay`，不直接污染正式 run 的日程、地点和事件循环。

## 配置位置

配置写在：

- `content/runs/run_definitions.json`

字段名：

- `opening_sequence`

## 单步结构

```json
{
  "id": "awakening_bind_1",
  "title": "天魔降临",
  "lines": [
    "第一段文字",
    "第二段文字"
  ],
  "goal_summary": "可选，仅在这一页显示",
  "buttons": [
    {
      "text": "继续",
      "action": "goto",
      "target_step_id": "awakening_bind_2"
    }
  ]
}
```

## 支持字段

- `id`
  - 当前步骤的唯一编号
- `title`
  - 标题
- `lines`
  - 正文数组，界面会按空段拼成多段文本
- `goal_summary`
  - 可选；只在这一页显示
- `buttons`
  - 当前页按钮列表

## 按钮动作

- `goto`
  - 跳到 `target_step_id`
- `start_run`
  - 结束序章并正式开始本轮 run

## 规范

- 用户可见文本只写在配置里，不写进代码
- `action`、`target_step_id` 这类技术字段可以保留英文技术键
- 若以后要扩展演出风格，优先加配置字段，不要把剧情正文写回脚本
