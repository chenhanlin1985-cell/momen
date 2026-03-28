# CONTENT_SCHEMA

## 1. 目标

本文档定义项目中的内容数据结构约定，用于指导：

- 行动定义
- 事件定义
- NPC 初始配置
- 状态定义
- 遗产定义
- 主目标定义
- 周目配置

目标：
1. 保持内容结构统一
2. 让 Codex 和人工都能稳定扩展
3. 避免“每加一种内容就改系统”
4. 尽量支持声明式配置

---

## 2. 通用约定

## 2.1 ID 规范
所有内容 ID 统一使用：

- snake_case
- 全项目唯一
- 一经发布尽量不改

示例：
- `cultivate`
- `black_market_trade`
- `injured`
- `outer_senior_brother`
- `day_7_patrol_lockdown`

---

## 2.2 标签规范
标签统一使用：

- snake_case
- 表意清晰
- 尽量短
- 用于条件系统，不用于展示文案

示例：
- `outer_disciple`
- `blood_path`
- `suspected`
- `night_only`
- `high_risk`
- `can_betray`
- `pollution_sensitive`

---

## 2.3 数值字段
统一约定：
- 明确单位
- 明确范围
- 有默认值
- 允许未来扩展

例如：
- `duration_days`
- `weight`
- `priority`
- `favor_delta`
- `alert_delta`

---

## 2.4 文本字段
统一约定：
- 展示文本和逻辑字段分离
- 逻辑永远不要依赖中文展示文本

建议区分：
- `id`
- `display_name`
- `description`
- `flavor_text`

---

## 2.5 条件与效果
条件和效果都采用结构化定义。

原则：
- 不用自然语言表示规则
- 不在内容里直接写任意代码
- 复杂逻辑优先拆成通用条件 / 通用效果

---

## 3. 行动定义 Schema

## 3.1 ActionDefinition

```yaml
id: cultivate
display_name: 修炼
description: 消耗精力与资源提升自身能力。
tags:
  - growth
  - cultivation

availability_conditions:
  - type: resource_gte
    key: blood_qi
    value: 1

base_costs:
  resources:
    blood_qi: 1
  stats: {}
  tags: []

base_rewards:
  resources:
    spirit_sense: 1
  stats:
    insight: 1
  tags: []

linked_event_pool:
  - cultivate_common
  - cultivate_risk

risk_weight: 10
sort_order: 100
is_visible: true