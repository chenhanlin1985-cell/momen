# 文本清理事件清单

本文档用于清理当前项目中“旧设定文本混入当前剧情”的问题。

目标不是逐句修补，而是先确定：

- 哪些运行时事件应该保留
- 哪些事件需要重写
- 哪些旧事件应该删除
- 哪些重复事件应该合并到唯一运行时 ID

---

## 1. 当前判断

项目当前同时存在两套叙事骨架：

- 新骨架：开场序章 + 天魔绑定 + 柳飞霞 / 王麻子 / 疯长老 / 外门考核
- 旧骨架：`act1_well_whisper` / 西井 / 外门师兄 / 井下低语

真正的问题不是“几句文案没换”，而是：

- 主循环事件仍大量使用旧骨架文本
- 地点、NPC、状态标签仍在暴露旧骨架术语
- 同一剧情节点存在多套事件 ID 和多套文本资产

---

## 2. 分类标准

### `保留`

已经与当前剧情方向一致，只需微调文案，不需要结构性删除。

### `重写`

这个事件在运行时结构上还需要，但正文、标题、选项和结果必须整体改成当前剧情。

### `删除`

与当前剧情方向不一致，或者只是旧骨架残留，不应再出现在运行时。

### `合并`

同一剧情节点存在多套 ID 或多份文本，需要收敛成唯一来源。

---

## 3. 主线固定事件

### `act1_day1_arrival`

- 标题：`初入外门`
- 当前状态：`重写`
- 原因：
  - 这是 day1 主锚点，必须保留结构位置
  - 但当前正文明显还是旧“初入外门 / 西井警告”开局，不是“天魔重开后的正式日间开局”
- 当前文本来源：
  - [events.csv](/C:/momen/content/story/act1/csv/events.csv)
  - [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
  - [main_story_flow.json](/C:/momen/content/story/act1/main_story_flow.json)
- 建议改成：
  - 第一天白天正式开局说明
  - 明确你已不是第一次死在这里
  - 当前任务应围绕“借柳飞霞、王麻子、疯长老三条线拿到第一条可用线索”

### `act1_day2_missing_rumor`

- 标题：`失踪传闻`
- 当前状态：`重写`
- 原因：
  - 结构位置可保留
  - 但“西井失踪传闻”属于旧骨架
  - 当前剧情应该更偏向“王麻子摊派、试药、灭口、传话暗线”等现实压迫
- 当前文本来源：
  - [events.csv](/C:/momen/content/story/act1/csv/events.csv)
  - [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
  - [main_story_flow.json](/C:/momen/content/story/act1/main_story_flow.json)
- 建议改成：
  - 王麻子开始摊派、勒索、盘人
  - 玩家第一次意识到“活路”和“真相”被同一套秩序绑住

### `act1_day4_first_choice`

- 标题：`第一次重大选择`
- 当前状态：`重写`
- 原因：
  - 流程节点描述已经部分偏向当前剧情
  - 但运行时文本仍混有“西井 / 旧井”语义
- 当前文本来源：
  - [events.csv](/C:/momen/content/story/act1/csv/events.csv)
  - [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
  - [main_story_flow.json](/C:/momen/content/story/act1/main_story_flow.json)
- 建议改成：
  - 第一次真正选边
  - 选择先靠柳飞霞线、王麻子线还是疯长老线推进

### `act1_day5_lockdown`

- 标题：`封锁与盘查`
- 当前状态：`重写`
- 原因：
  - flow 文档里实际想表达的是“疯长老试药 / 丹房生死关”
  - 但现运行时文本还是“西井封锁”
- 当前文本来源：
  - [events.csv](/C:/momen/content/story/act1/csv/events.csv)
  - [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
  - [main_story_flow.json](/C:/momen/content/story/act1/main_story_flow.json)
- 建议改成：
  - 疯长老开始正式试药
  - 你被盯上、被筛选、或被迫拿秘密换命

### `act1_day6_truth_reversal`

- 标题：`真相或误判回收`
- 当前状态：`重写`
- 原因：
  - 结构可保留
  - 当前文本仍带“井下低语 / 异变接受度”残留
  - 应改为月考前夜的路线收束
- 当前文本来源：
  - [events.csv](/C:/momen/content/story/act1/csv/events.csv)
  - [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
  - [main_story_flow.json](/C:/momen/content/story/act1/main_story_flow.json)

### `act1_day7_final_judgement`

- 标题：`结算夜验证`
- 当前状态：`重写`
- 原因：
  - 必须保留作为 day7 收束事件
  - 当前文本还是旧“第七夜 / 西井结果”框架
  - 应改为正式“外门月考 / 最终路线结算”
- 当前文本来源：
  - [events.csv](/C:/momen/content/story/act1/csv/events.csv)
  - [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
  - [main_story_flow.json](/C:/momen/content/story/act1/main_story_flow.json)

---

## 4. 条件剧情事件

### `conditional_record_discovery`

- 标题：`旧账册的缺页`
- 当前状态：`保留，重写轻度`
- 原因：
  - “账册缺页 / 被人为处理的痕迹”与当前剧情兼容
  - 但文案应从“西井封存记录”改成“族兄、血神阵图、试药记录、丹房账册”方向

### `conditional_whisper_deepens`

- 标题：`低语加深`
- 当前状态：`删除或彻底改造`
- 原因：
  - 这是典型旧骨架事件，围绕井下低语展开
  - 如果当前剧情决定保留“天魔耳语 / 异常感知”，也必须换成新设定，不应再挂在西井体系下

### `conditional_wrong_trust_payoff`

- 标题：`误信的代价`
- 当前状态：`保留，重写`
- 原因：
  - “误信”主题和柳飞霞线高度兼容
  - 当前可改成“你误以为她会站在你这边，结果只是互相利用”

### `conditional_patrol_interrogation`

- 标题：`夜巡盘问`
- 当前状态：`保留，重写轻度`
- 原因：
  - 巡夜盘问在当前剧情中仍可成立
  - 只需从“异常 / 西井”导向改成“灭口、丹房、后墙传话、夜里出没”

### `conditional_senior_test`

- 标题：`师兄的试探`
- 当前状态：`保留，重写为疯长老试探`
- 原因：
  - 结构已经接近疯长老线
  - 但标题和部分文本仍暴露旧“外门师兄”遗留命名

---

## 5. 地点/随机/扰动事件

### 资源类

- `act1_res_leftover_medicine`
  - 状态：`保留，轻改`
  - 原因：药房残药与当前剧情兼容

- `act1_res_hidden_stash`
  - 状态：`保留，轻改`
  - 原因：寝舍旧物与当前剧情兼容

- `act1_res_food_shortage`
  - 状态：`保留，轻改`
  - 原因：外门底层生存压力仍需要

### 关系类

- `act1_rel_peer_small_talk`
  - 状态：`重写`
  - 原因：当前是旧“别院里越来越不对劲”的泛西井氛围，建议改为外门流言、月考、试药、王麻子动作

- `act1_rel_steward_cold_gaze`
  - 状态：`保留，轻改`
  - 原因：执事盯上你和当前剧情一致

- `act1_rel_false_friendliness`
  - 状态：`保留，轻改`
  - 原因：外门有人来套话在当前剧情里成立

### 异常类

- `act1_ano_hear_well_echo`
  - 状态：`删除或彻底改造`
  - 原因：明显属于西井线

- `act1_ano_wrong_name_whisper`
  - 状态：`改造后保留`
  - 原因：如果保留“天魔感知 / 残响 / 被害者回音”可转成新异常来源，不应继续挂靠西井

- `act1_ano_mark_on_wall`
  - 状态：`改造后保留`
  - 原因：可转成茅草屋、丹房或化骨池相关异常痕迹

### 风险类

- `act1_risk_followed_in_dark`
  - 状态：`保留，轻改`
  - 原因：夜里被盯梢很适合当前剧情

- `act1_risk_patrol_question`
  - 状态：`保留，轻改`
  - 原因：巡夜压力仍成立

- `act1_risk_wrong_time_wrong_place`
  - 状态：`保留，轻改`
  - 原因：在不该出现的地方被撞见与当前剧情一致

### 战斗类

- `act1_combat_blood_runner`
  - 状态：`保留`
  - 原因：血役堵路、立威、打压，与当前外门血雾设定兼容

---

## 6. NPC 对话事件

这一层是当前最混乱的部分，因为同一剧情节点同时存在：

- CSV 事件
- encounter 逻辑
- texts 文本
- Markdown 编译产物
- 旧 `.dialogue` 文件

### 柳飞霞首轮

相关 ID：

- `dlg_friendly_peer_well_warning`
- `2001`
- `friendly_peer_md_2101`

当前状态：`合并`

建议：

- 只保留一套运行时事件 ID
- 推荐保留 Markdown 产物路线：
  - `friendly_peer_md_2101`
  - 或者统一改成一个更语义化的新 ID
- 删除/停用：
  - `dlg_friendly_peer_well_warning`
  - `2001`

原因：

- 三套内容都在写“柳飞霞第一次试探遗物”
- 文案高度重复
- 会导致之后按钮、结果、状态很容易串线

文本来源：

- [friendly_peer_logic.json](/C:/momen/content/dialogue/encounters/friendly_peer_logic.json)
- [friendly_peer_texts.json](/C:/momen/content/dialogue/texts/friendly_peer_texts.json)
- [localization.csv](/C:/momen/content/story/act1/csv/localization.csv)
- [2001.md](/C:/momen/content/story/act1/md/active/01/2001.md)

### 柳飞霞第二轮

相关 ID：

- `dlg_friendly_peer_shadow_contact`
- `friendly_peer_md_2102`

当前状态：`合并`

建议：

- 如果 `friendly_peer_md_2102` 已经是当前认可版本，就保留它
- `dlg_friendly_peer_shadow_contact` 的逻辑和文本要么并入，要么退役

原因：

- 都在承担“柳飞霞开始递暗线 / 试图交易 / 被逼选边”的功能

### 疯长老第一轮

相关 ID：

- `dlg_outer_senior_guidance`
- `2003`

当前状态：`合并`

建议：

- 这条线保留一个明确名称，如“疯长老的第一次注视”
- 删除 `2003` 这套重复 Markdown 运行时资产，或把 `dlg_outer_senior_guidance` 全部改为 Markdown 主源

### 疯长老第二轮

相关 ID：

- `conditional_senior_test`
- `2007`

当前状态：`合并`

建议：

- 保留一套
- 文案统一成“疯长老试探你是否值得留下”

### 王麻子对话

相关 ID：

- `dlg_herb_steward_probe`
- `2004`

当前状态：`合并`

建议：

- 保留一套
- 结构上可继续作为“账册 / 利益 / 盘剥”线核心事件

### 巡夜弟子对话

相关 ID：

- `dlg_patrol_report_anomaly`
- `2005`
- `conditional_patrol_interrogation`
- `2008`

当前状态：`部分保留，部分合并`

建议：

- 保留两类功能事件：
  - 交情报
  - 被盘问
- 删除单纯重复的 Markdown 运行时副本：
  - `2005`
  - `2008`

---

## 7. 明显旧骨架术语，需要全局替换

以下内容应被视为“旧设定暴露点”：

- `act1_well_whisper`
- 西井
- 旧井
- 井下低语
- 外门师兄
- `outer_senior_brother`
- `met_outer_senior`
- `trusted_outer_senior`
- `west_well_outer`
- `west_well_inner`

主要暴露文件：

- [location_definitions.json](/C:/momen/content/locations/location_definitions.json)
- [npc_definitions.json](/C:/momen/content/npcs/npc_definitions.json)
- [npc_interactions.json](/C:/momen/content/npcs/npc_interactions.json)
- [ui_texts.json](/C:/momen/content/text/ui_texts.json)
- [status_key_map.json](/C:/momen/content/story/act1/status_key_map.json)
- [npc_name_map.json](/C:/momen/content/story/act1/npc_name_map.json)
- [location_name_map.json](/C:/momen/content/story/act1/location_name_map.json)

---

## 8. 建议执行顺序

### 第一批：先清骨架

1. 重写 day1-day7 主线事件文本
2. 决定异常系统是否保留“超自然耳语”，若保留则改成天魔相关来源
3. 停止再使用 `act1_well_whisper` 作为对外叙事标签

### 第二批：清对话重复资产

1. 柳飞霞线只留一套运行时事件 ID
2. 疯长老线只留一套运行时事件 ID
3. 王麻子线只留一套运行时事件 ID
4. 巡夜线按“上报 / 盘问”两类保留，其余重复项清掉

### 第三批：清 UI 与地点/NPC 文案

1. 地点描述
2. NPC 互动按钮
3. 状态标签
4. 条件提示与日志标签

---

## 9. 推荐下一步

下一步直接做两件事：

1. 先列一张“最终保留事件 ID 名单”
2. 然后从 [localization.csv](/C:/momen/content/story/act1/csv/localization.csv) 开始，按保留名单重写 day1-day7 与 NPC 对话按钮文案

