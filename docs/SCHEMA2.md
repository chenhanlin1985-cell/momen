3.2 字段说明
id：行动唯一标识
display_name：界面展示名
description：说明文本
tags：行动标签
availability_conditions：行动可用条件
base_costs：基础消耗
base_rewards：基础收益
linked_event_pool：关联事件池
risk_weight：风险权重，可用于附加事件判定
sort_order：UI 排序
is_visible：是否显示在行动列表中
4. 事件定义 Schema
4.1 EventDefinition
id: market_patrol_questioning
title: 夜市盘查
description: 你刚离开黑市巷口，夜巡弟子拦住了你，似乎察觉到了什么。
tags:
  - black_market
  - patrol
  - suspicion

trigger_conditions:
  - type: tag_present
    scope: player
    key: visited_black_market

weight: 15
priority: 50
repeatable: true
once_per_run: false
cooldown_days: 2

options:
  - id: bribe
    text: 塞给对方几枚灵石
    conditions:
      - type: resource_gte
        key: spirit_stone
        value: 3
    effects:
      - type: modify_resource
        scope: player
        key: spirit_stone
        delta: -3
      - type: modify_npc_relation
        npc_id: night_patrol_disciple
        field: favor
        delta: 1
      - type: modify_npc_relation
        npc_id: night_patrol_disciple
        field: alert
        delta: -1

  - id: argue
    text: 强行辩解
    conditions: []
    effects:
      - type: modify_resource
        scope: player
        key: exposure
        delta: 2
      - type: add_tag
        scope: player
        key: suspected

  - id: flee
    text: 转身就跑
    conditions:
      - type: stat_gte
        key: physique
        value: 2
    effects:
      - type: modify_resource
        scope: player
        key: blood_qi
        delta: -1
      - type: add_followup_event
        key: patrol_chase
4.2 字段说明
id：事件唯一 ID
title：标题
description：正文
tags：事件标签
trigger_conditions：触发条件
weight：权重
priority：优先级
repeatable：是否可重复
once_per_run：是否单局仅一次
cooldown_days：冷却天数
options：选项列表
5. 事件选项 Schema
5.1 EventOptionDefinition
id: bribe
text: 塞给对方几枚灵石
conditions:
  - type: resource_gte
    key: spirit_stone
    value: 3
effects:
  - type: modify_resource
    scope: player
    key: spirit_stone
    delta: -3
result_text: 对方掂了掂灵石，脸色缓和了几分。
5.2 字段说明
id：选项唯一 ID（在事件内唯一）
text：选项文案
conditions：该选项自身可见 / 可选条件
effects：效果列表
result_text：结算反馈文本
6. 条件 Schema
6.1 基本结构
type: resource_gte
scope: player
key: spirit_stone
value: 3
6.2 MVP 必须支持的条件类型
属性条件
type: stat_gte
scope: player
key: physique
value: 2
资源条件
type: resource_lte
scope: player
key: pollution
value: 3
标签条件
type: tag_present
scope: world
key: market_open
状态条件
type: status_present
scope: player
key: injured
天数条件
type: day_range
min: 5
max: 10
世界状态条件
type: world_value_gte
key: patrol_level
value: 2
NPC 关系条件
type: npc_relation_gte
npc_id: herb_steward
field: favor
value: 3
6.3 组合条件

MVP 推荐支持：

type: all_of
conditions:
  - type: tag_present
    scope: player
    key: suspected
  - type: resource_gte
    scope: player
    key: spirit_sense
    value: 2

以及：

type: any_of
conditions:
  - type: stat_gte
    scope: player
    key: tact
    value: 3
  - type: npc_relation_gte
    npc_id: outer_senior_brother
    field: favor
    value: 4
7. 效果 Schema
7.1 基本结构
type: modify_resource
scope: player
key: spirit_stone
delta: -3
7.2 MVP 必须支持的效果类型
修改资源
type: modify_resource
scope: player
key: blood_qi
delta: -1
修改属性
type: modify_stat
scope: player
key: insight
delta: 1
添加状态
type: add_status
scope: player
key: injured
duration_days: 2
stacks: 1
移除状态
type: remove_status
scope: player
key: injured
添加标签
type: add_tag
scope: world
key: market_locked
移除标签
type: remove_tag
scope: player
key: suspected
修改 NPC 关系
type: modify_npc_relation
npc_id: suspicious_elder
field: alert
delta: 2
修改世界值
type: modify_world_value
key: patrol_level
delta: 1
触发后续事件
type: add_followup_event
key: patrol_chase
记录情报
type: add_knowledge
key: west_well_is_not_safe
直接失败
type: fail_run
reason_id: executed_by_patrol
8. NPC 配置 Schema
8.1 NpcDefinition
id: herb_steward
display_name: 药房执事
role: steward
faction_id: herb_house
tags:
  - greedy
  - resource_gatekeeper

initial_relation:
  favor: 0
  alert: 0

initial_status_tags: []
initial_flags:
  alive: true
  interactable: true

secrets:
  - hidden_side_trade

preferred_actions:
  - work
  - trade
8.2 字段说明
id：唯一标识
display_name：展示名称
role：身份
faction_id：派系
tags：行为标签
initial_relation：初始关系
initial_status_tags：初始状态标签
initial_flags：基础状态
secrets：可被事件利用的信息标签
preferred_actions：容易与哪些行动产生联动
9. 状态定义 Schema
9.1 StatusDefinition
id: injured
display_name: 受伤
description: 你的身体还未恢复，行动效率下降。
tags:
  - negative
  - body

duration_days: 2
max_stacks: 3
stacking_rule: refresh_duration

timing_effects:
  - trigger: on_action_before
    effects:
      - type: modify_action_cost_multiplier
        value: 1.2

removal_conditions:
  - type: action_completed
    key: rest
9.2 MVP 简化建议

MVP 可先不支持特别复杂的 timing_effects，但字段保留，后面不用重构 schema。

10. 遗产定义 Schema
10.1 InheritanceDefinition
id: fragmented_memory_patrol_route
display_name: 巡逻记忆残片
description: 你记起了夜巡弟子的巡逻规律。
inheritance_type: knowledge
tags:
  - patrol
  - route_memory

effects:
  - type: add_tag
    scope: player
    key: knows_patrol_route

unlock_tags:
  - inheritance_knowledge
rarity: common
10.2 字段说明
id：唯一标识
display_name：展示名
description：说明
inheritance_type：类型，如 knowledge / trait / manual
tags：分类标签
effects：新局应用效果
unlock_tags：解锁标记
rarity：稀有度
11. 主目标定义 Schema
11.1 GoalDefinition
id: survive_21_days
display_name: 活过 21 天
description: 在别院中撑到最后一天。
completion_conditions:
  - type: day_gte
    value: 21
failure_conditions: []
reward_tags:
  - goal_survival_complete
priority: 10

另一个例子：

id: investigate_anomaly_source
display_name: 找出异常源头
description: 找出别院中的一个异常来源，并保留相关情报。
completion_conditions:
  - type: knowledge_present
    key: anomaly_source_identified
reward_tags:
  - goal_investigation_complete
priority: 20
12. 周目配置 Schema
12.1 RunConfig
id: default_run
display_name: 默认开局

starting_day: 1
max_day: 21
actions_per_day: 2

player_init:
  stats:
    physique: 2
    mind: 2
    insight: 1
    occult: 1
    tact: 1
  resources:
    blood_qi: 3
    spirit_stone: 5
    spirit_sense: 1
    pollution: 0
    exposure: 0
  tags:
    - outer_disciple

world_init:
  values:
    patrol_level: 1
  tags:
    - market_open

starting_npcs:
  - outer_senior_brother
  - herb_steward
  - black_market_broker
  - friendly_peer
  - suspicious_elder
  - night_patrol_disciple

starting_goal_pool:
  - survive_21_days
  - investigate_anomaly_source
13. 命名与组织建议
13.1 内容文件组织

建议按内容类型分目录：

content/
  actions/
    cultivate.tres
    work.tres
    explore.tres

  events/
    common/
    stage/
    death/

  npcs/
  statuses/
  inheritance/
  goals/
  runs/
13.2 一次只加一类内容

新增内容时优先顺序：

先写 schema 对应数据
再接系统读取
再接 UI 展示
最后补专用逻辑
14. MVP 当前支持边界

MVP 阶段 schema 必须做到：

字段可扩展
通用效果够用
通用条件够用
不追求一次覆盖所有复杂内容

MVP 阶段可暂时不做：

脚本表达式型条件
自定义任意逻辑回调
嵌套过深的效果树
复杂概率树

原则：

先用 80% 通用 schema 覆盖 80% 内容，再为少数复杂内容留扩展点。

15. 结论

内容 schema 的目标不是“把所有未来玩法一次设计完”，而是：

让行动、事件、NPC、状态、遗产用统一方式表达
让 Codex 能稳定按同一模式继续扩展
让后续新增内容时尽量只加数据，不改底层

这份 schema 是当前 MVP 阶段的唯一内容结构基准。


---

### 这 3 份文档建议你接下来这样用

先把它们放进 `docs/`，然后把下面这段作为 Codex 的项目启动前置提示：

```text
请先阅读并遵守以下文档：
- docs/PROJECT_RULES.md
- docs/ARCHITECTURE.md
- docs/MVP_SCOPE.md
- docs/CONTENT_SCHEMA.md
- docs/CODING_STYLE.md

工作要求：
1. 先遵守文档中的分层与扩展约定
2. 如果实现方案与文档冲突，先指出冲突，不要直接忽略
3. 新增同类内容优先通过配置扩展
4. 不要把业务逻辑写进 UI
5. 除非我明确要求，否则不要顺手重构无关代码
6. 每次输出必须说明：
   - 改了哪些文件
   - 为什么这样设计
   - 后续如何扩展
   - 有哪些风险点