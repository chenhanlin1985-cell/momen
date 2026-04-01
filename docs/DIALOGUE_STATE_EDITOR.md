# Dialogue State Editor

场景文件：
- [dialogue_state_editor.tscn](/C:/momen/tools/dialogue/dialogue_state_editor.tscn)

脚本：
- [dialogue_state_editor.gd](/C:/momen/tools/dialogue/dialogue_state_editor.gd)

## 目标
这个工具现在的定位不是“直接手改 CSV/JSON”，而是让作者先按写作直觉写一段场景，再由编辑器把它拆成：
- 文本层草稿
- 逻辑层草稿
- CSV 草稿
- 最后还需要补线的挂接提醒

## 当前能做什么
- 选择 `Run` 和 `NPC`
- 查看这个 NPC 现有的 `dialogue_event`
- 可视化每段对话：
  - 需要哪些 flag
  - 会设置哪些 flag
  - 会清除哪些 flag
  - 已经占用了哪些 intrusion override
- 在右侧直接写下一段剧情的作者草稿：
  - Opening
  - Observe
  - 两个基础对话选项
  - 贪 / 嗔 / 痴 的诱导思路
- 自动生成一份 `Writer Draft` 输出包，里面包含：
  - 作者视角摘要
  - 文本文件草稿
  - 逻辑文件草稿
  - CSV 草稿
  - wiring reminder

## 推荐工作流
1. 先在右侧用自然语言写这一段剧情。
2. 确认这段剧情依赖哪些旧 flag，又会产出哪些新 flag。
3. 看工具生成的 `Writer Draft` 输出包。
4. 把输出包分发到对应文件：
   - `content/dialogue/texts/*`
   - `content/dialogue/encounters/*`
   - `content/story/act1/csv/*.csv`
   - `content/npcs/npc_interactions.json`
   - `content/npcs/npc_definitions.json`
5. 再把自动生成的 TODO effect 替换成真正的状态变化。

## 现在还没做的部分
- 还不能直接写回文件
- 还不能拖拽改状态图
- 还不能自动补完整的 option_overrides / effects
- 还没有把 CSV 写回和 JSON 写回做成一步完成

## 为什么这样做
当前项目的复杂度不在“写一句文案”，而在“一段剧情要同时改多个地方”。这个工具先解决的是表达方式问题：
- 作者按剧情来写
- 编辑器按系统要求来拆

这样后面即使继续做自动写回，也会建立在作者能看懂、能掌控的输入模型上，而不是继续让人直接操作一堆分散配置。
