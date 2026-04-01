# 对话配置参考

这份文档对应当前项目里已经接通的对话系统实现，重点说明：

- `content/dialogue/encounters/*.json` 中的对话逻辑层
- `content/dialogue/texts/*_texts.json` 中的文本层
- `content/story/act1/csv/*.csv` 中的事件入口、触发条件、基础选项与基础效果
- 三阶段对话流程：`观察 -> 入侵 -> 对话`
- 跨轮状态机如何通过 `flag` 驱动下一轮对话

对应代码入口：

- [event_service.gd](/C:/momen/systems/event/event_service.gd)
- [event_effect_executor.gd](/C:/momen/systems/event/event_effect_executor.gd)
- [condition_evaluator.gd](/C:/momen/systems/condition/condition_evaluator.gd)
- [content_repository.gd](/C:/momen/systems/content/content_repository.gd)
- [dialogue_event_panel.gd](/C:/momen/ui/components/dialogue_event_panel.gd)
- [friendly_peer_logic.json](/C:/momen/content/dialogue/encounters/friendly_peer_logic.json)
- [friendly_peer_texts.json](/C:/momen/content/dialogue/texts/friendly_peer_texts.json)

## 1. 当前系统模型

当前对话系统分成三层：

1. `story csv`
   负责定义这个对话事件何时出现、基础选项有哪些、默认效果是什么。

2. `dialogue encounter logic`
   负责定义这个事件的三阶段结构、可植入魔念、以及魔念命中后如何改写选项。

3. `dialogue texts`
   只放文案，不放逻辑。

也就是说：

- `events.csv` / `event_triggers.csv` 决定“这轮对话会不会出现”
- `event_options.csv` / `option_effects.csv` 决定“默认对话长什么样”
- `encounters/*.json` 决定“植入魔念后怎么改写”
- `texts/*.json` 决定“显示给玩家的文字”

## 2. 对话展示规则

当前 UI 有两种模式：

1. `CSV / encounter` 对话
   只要事件有 `options`，就走当前主系统，也就是现在这套三阶段对话。

2. `DialogueManager` 回退模式
   只有当事件没有 `options`、但有 `.dialogue` 资源路径、且运行环境存在 `DialogueManager` 时，才会走 DialogueManager。

这意味着当前 Act1 里大多数主用对话事件都应按 `CSV + encounter` 理解，而不是按 `.dialogue` 写状态。

## 3. 三阶段流程

当前 `dialogue_event` 在有 `dialogue_encounter` 定义时，不会一进入就直接显示对话选项，而是先进入三阶段流程：

1. `观察`
   显示 `observation_text`

2. `入侵`
   从 `intrusions` 里选择一个魔念
   一轮对话只能植入一次

3. `对话`
   进入正式选项
   如果已经植入魔念，会优先尝试命中该魔念的 `option_overrides`

运行时状态存放在 [run_state.gd](/C:/momen/core/models/run_state.gd)：

- `current_dialogue_mode`
- `current_dialogue_intrusion_tag`
- `current_dialogue_intrusion_used`

这些状态会在切换事件或清空当前事件时，由 [run_state_mutator.gd](/C:/momen/systems/state/run_state_mutator.gd) 自动重置。

## 4. 结算顺序

玩家点击一个真正的对话选项后，系统按下面顺序执行：

1. 读取当前事件定义与当前魔念状态
2. 如果当前魔念对该选项有 `option_overrides`，先覆盖原选项
3. 检查 `conditions`
4. 如果有 `check`，执行判定，得到 `success / failure / always`
5. 解析结果文本：
   - 先取 `success_result_text` / `failure_result_text`
   - 否则回退到 `result_text`
6. 执行 `effects`
7. 如果有结果文本，则把文本留在当前事件面板中，进入“等待继续”
8. 玩家点继续后，事件才真正结束
9. 如果这期间已经 `finish_run`，则在继续后进入结局页

这也是为什么死亡分支现在可以做到：

- 先显示死亡结果文本
- 再点继续
- 再进入轮回/结局

## 5. 文件结构

### 5.1 逻辑层

位置：

- `content/dialogue/encounters/*.json`

载入方式：

- 由 [content_repository.gd](/C:/momen/systems/content/content_repository.gd) 读取
- 入口 manifest 在 [content/dialogue/encounters/_manifest.json](/C:/momen/content/dialogue/encounters/_manifest.json)

每个 NPC 一份逻辑文件，例如：

- [friendly_peer_logic.json](/C:/momen/content/dialogue/encounters/friendly_peer_logic.json)

### 5.2 文本层

位置：

- `content/dialogue/texts/*_texts.json`

每个 NPC 一份文本文件，例如：

- [friendly_peer_texts.json](/C:/momen/content/dialogue/texts/friendly_peer_texts.json)

逻辑层通过 `*_id` 字段引用文本层，仓库加载时会自动把：

- `opening_text_id`
- `observation_text_id`
- `selected_hint_text_id`
- `label_id`
- `domain_label_id`
- `description_id`
- `text_id`
- `result_text_id`

解析成最终字符串。

## 6. 逻辑层结构

一个 `dialogue encounter` 的当前推荐结构：

```json
{
  "event_id": "dlg_friendly_peer_well_warning",
  "opening_text_id": "friendly_peer_well_warning.opening",
  "observation_text_id": "friendly_peer_well_warning.observe",
  "intrusions": [
    {
      "id": "wrath",
      "label_id": "friendly_peer_well_warning.wrath.label",
      "domain_label_id": "friendly_peer_well_warning.wrath.domain",
      "description_id": "friendly_peer_well_warning.wrath.desc",
      "selected_hint_text_id": "friendly_peer_well_warning.wrath.hint",
      "apply_log_text_id": "friendly_peer_well_warning.wrath.log",
      "option_overrides": {
        "ask_what_heard": {
          "text_id": "friendly_peer_well_warning.wrath.ask_what_heard.text",
          "result_text_id": "friendly_peer_well_warning.wrath.ask_what_heard.result",
          "effects": []
        }
      },
      "fallback_option_override": {
        "result_text_id": "some.fallback.result",
        "effects": []
      }
    }
  ]
}
```

字段含义：

- `event_id`
  关联哪个 `dialogue_event`

- `opening_text_id`
  进入对话后默认显示的正文

- `observation_text_id`
  玩家点击“观察”后显示的正文

- `intrusions`
  本轮可植入的魔念列表

### `intrusions[]` 内部字段

- `id`
  魔念内部 id，例如 `greed` / `wrath` / `delusion`

- `label_id`
  UI 按钮显示名称

- `domain_label_id`
  UI 小标签，当前一般就是“魔念”

- `description_id`
  在“入侵”阶段显示的说明

- `selected_hint_text_id`
  已植入这个魔念后，在正文里追加的提示

- `apply_log_text_id`
  植入时写入日志的文字

- `option_overrides`
  命中某个具体选项 id 时的改写

- `fallback_option_override`
  没命中专属 override 时的兜底改写

## 7. 文本 ID 命名规则

当前推荐使用“局部短 ID”，不要再回到过去那种超长路径式命名。

推荐风格：

- `friendly_peer_well_warning.opening`
- `friendly_peer_well_warning.wrath.label`
- `friendly_peer_well_warning.wrath.ask_what_heard.result`
- `friendly_peer_shadow_contact.wrath.press_loyalty.result`

不推荐把整条数据路径都拼进 key 里。

## 8. 选项字段说明

这里说的是事件选项最终参与结算时会用到的字段，不论它来自 CSV 默认选项，还是来自魔念 override。

### `text`

- 玩家点击的选项文本

### `result_text`

- 选中后显示在当前面板里的结果文本
- 不是右下角日志
- 非空时，会停留在当前事件里等待继续

### `success_result_text` / `failure_result_text`

- 只在该选项带 `check` 时有意义
- 优先级高于 `result_text`

### `conditions`

- 控制选项是否可点
- 不满足时，选项仍显示，但会禁用并显示 unmet 提示

### `check`

当前支持：

- `d20`
- `d100`

`source` 当前支持：

- `stat`
- `resource`
- `npc_relation`

### `effects`

- 真正修改运行时状态的地方
- 这是“规则层”，不是“文案层”

### `outcome`

- 写在单条 effect 上
- 可选：
  - `always`
  - `success`
  - `failure`

## 9. 当前支持的 effect 类型

以下内容以 [event_effect_executor.gd](/C:/momen/systems/event/event_effect_executor.gd) 为准。

### 玩家/世界

- `modify_resource`
- `modify_stat`
- `add_tag`
- `remove_tag`
- `set_flag`
- `clear_flag`
- `modify_world_value`
- `add_knowledge`

### NPC

- `modify_npc_relation`
- `add_npc_tag`
- `remove_npc_tag`
- `set_npc_available`

### 地点/流程

- `unlock_location`
- `block_location`
- `unblock_location`
- `add_followup_event`
- `finish_run`

常见例子：

```json
{ "type": "set_flag", "key": "liu_suspicion_seeded", "value": true }
{ "type": "clear_flag", "key": "liu_suspicion_seeded" }
{ "type": "modify_npc_relation", "npc_id": "friendly_peer", "field": "favor", "delta": 2 }
{ "type": "finish_run", "reason_id": "death_used_by_liu" }
```

注意：

- `set_flag.value` 统一写 `true/false`
- 不要再写字符串自引用

## 10. 当前支持的 condition 类型

以 [condition_evaluator.gd](/C:/momen/systems/condition/condition_evaluator.gd) 为准。

### 数值

- `stat_gte`
- `resource_gte`
- `resource_lte`
- `world_value_gte`

### tag / flag / knowledge

- `tag_present`
- `flag_present`
- `flag_not_present`
- `knowledge_present`

### 时间/流程

- `day_range`
- `day_gte`
- `phase_is`
- `last_action_is`
- `last_action_category_is`
- `current_location_is`

### 地点

- `location_unlocked`
- `location_blocked`
- `location_tag_present`
- `location_value_gte`

### NPC

- `npc_relation_gte`
- `npc_available`
- `npc_at_location`
- `npc_tag_present`

### 组合

- `all_of`
- `any_of`

## 11. 跨轮状态机

当前设计里，“跨轮对话状态机”不是靠 `current_dialogue_*` 这些临时变量实现的，而是靠可持久化的 `flag`。

也就是：

- 当轮对话内的阶段切换，用 `current_dialogue_mode / intrusion_tag`
- 跨天、跨轮、跨事件的状态推进，用 `flag`

### 柳飞霞当前示例

第一轮事件：

- `dlg_friendly_peer_well_warning`

如果第一轮命中 `wrath`，则会写入：

- `liu_suspicion_seeded = true`

第二轮事件：

- `dlg_friendly_peer_shadow_contact`

它的出现条件来自 CSV：

- `events.csv` 里 `req_flags = liu_suspicion_seeded`
- `event_triggers.csv` 里要求 `phase_is = day`
- `event_triggers.csv` 里要求 `day_gte = 2`

所以它表达的就是：

- 只有上一轮柳被成功引向“猜忌王麻子”
- 并且时间到了第二天白天
- 第二轮暗线接触才会出现

第二轮结算后会进一步写入例如：

- `liu_contact_established`
- `liu_betrayal_risk`
- `liu_informant_active`
- `liu_against_wang`

这套 flag 才是后续第三轮、背叛线、反制线应该继续读取的真相源。

## 12. 事件入口如何挂到 NPC 上

一个 NPC 对话真正出现，需要两层都接好：

1. 故事事件存在
   也就是 `events.csv` + `event_triggers.csv` + `event_options.csv`

2. NPC 有入口
   当前通常通过 [npc_interactions.json](/C:/momen/content/npcs/npc_interactions.json) 的 `dialogue_event_id` 挂上

另外，NPC 自身的 [npc_definitions.json](/C:/momen/content/npcs/npc_definitions.json) 里的 `state_event_ids` 也应该包含这个事件，方便状态追踪和调试视图统一理解这个 NPC 当前有哪些状态事件。

## 13. 推荐模板

### 13.1 普通线索推进

```json
"effects": [
  { "type": "set_flag", "key": "knows_cousin_secret", "value": true },
  { "type": "modify_resource", "scope": "player", "key": "clue_fragments", "delta": 2 }
]
```

### 13.2 推进下一轮对话状态机

```json
"effects": [
  { "type": "set_flag", "key": "liu_suspicion_seeded", "value": true },
  { "type": "modify_npc_relation", "npc_id": "friendly_peer", "field": "favor", "delta": 1 }
]
```

### 13.3 消耗旧状态，进入新阶段

```json
"effects": [
  { "type": "clear_flag", "key": "liu_suspicion_seeded" },
  { "type": "set_flag", "key": "liu_contact_established", "value": true },
  { "type": "set_flag", "key": "liu_betrayal_risk", "value": true }
]
```

### 13.4 先显示结果，再 GAME OVER

```json
"result_text": "她忽然出手，你当场毙命。黑暗再次降临。",
"effects": [
  { "type": "set_flag", "key": "death_used_by_liu", "value": true },
  { "type": "finish_run", "reason_id": "death_used_by_liu" }
]
```

## 14. 当前文档结论

当前系统和之前相比，最重要的变化是：

- 已经没有 `soul_power` 消耗
- 当前主用对话不是“直接进选项”，而是三阶段流程
- 文本与逻辑已经拆文件
- 跨轮推进已经开始按 `flag` 做状态机
- 柳飞霞已经有“第一轮命中猜忌 -> 第二轮暗线接触”的实际样板

如果后面继续扩展新的 NPC，对齐这份文档最重要的不是照抄文案，而是保持下面这条分工：

- `CSV` 管入口和基础选项
- `encounter logic` 管魔念改写
- `text` 管文案
- `flag` 管跨轮状态
