# 当前项目状态

本文档用于在聊天上下文丢失后，快速恢复当前项目的开发状态。

最后更新关注点：

- Act 1 主循环与主线收束
- Markdown 作为剧情主配置源
- 三阶段对话系统
- 立绘 / 场景背景资源接入
- 开场序章演出

## 1. 当前核心方向

项目当前不是传统固定线性剧情，而是：

- 白天自由行动
- 夜间 / 固定节点收束
- 对话采用 `观察 / 入侵 / 对话` 三阶段
- 通过线索、flags、NPC 关系、结局条件推进主线

作者层的目标已经明确：

- Markdown 是剧情配置主入口
- 资源统一放 `assets/`
- 面向玩家的文字不写进代码
- 新内容优先写配置，不优先写脚本特判

## 2. 当前运行时主结构

### 2.1 主循环

核心 run 定义：

- [content/runs/run_definitions.json](C:/momen/content/runs/run_definitions.json)

当前默认 run：

- `default_run`

它负责：

- 开场序章 `opening_sequence`
- 玩家初始属性 / 资源 / flags
- 起始地点与开放地点
- 起始 NPC
- 主线 flow 路径
- 初始目标池

### 2.2 主线收束

主线 flow：

- [content/story/act1/main_story_flow.json](C:/momen/content/story/act1/main_story_flow.json)

当前已经接上：

- day1 到 day7 的主线锚点
- gate check
- resolution checks
- fallback ending

### 2.3 内容真相源

运行时当前真正使用的是：

- [content/story/act1/csv](C:/momen/content/story/act1/csv)
- [content/dialogue/encounters](C:/momen/content/dialogue/encounters)
- [content/dialogue/texts](C:/momen/content/dialogue/texts)

不再保留第二套运行时剧情模式。

## 3. Markdown 作者链

当前作者层入口：

- [content/story/act1/md/active](C:/momen/content/story/act1/md/active)

规则：

- 目录只用数字
- 文件名优先短编号
- 作者层不暴露英文运行时 ID
- 写完后统一编译进当前主结构

相关文档：

- [docs/MARKDOWN_SYNTAX.md](C:/momen/docs/MARKDOWN_SYNTAX.md)
- [docs/MARKDOWN_STORY_EDITOR_STATUS.md](C:/momen/docs/MARKDOWN_STORY_EDITOR_STATUS.md)
- [docs/PROJECT_RULES.md](C:/momen/docs/PROJECT_RULES.md)

当前已经落地的作者链能力：

- Markdown 写三阶段对话
- 一键编译
- 写回 `encounters / texts / csv`
- 数字目录映射

## 4. 对话系统当前状态

### 4.1 玩法结构

当前对话系统核心在：

- [systems/event/event_service.gd](C:/momen/systems/event/event_service.gd)
- [ui/components/dialogue_event_panel.gd](C:/momen/ui/components/dialogue_event_panel.gd)

当前流程：

1. 进入对话显示开场
2. 点 `观察` 显示观察文本
3. 点 `入侵` 选择一次魔念
4. 入侵后自动回主菜单，但正文显示本次植入反馈
5. 进入 `对话` 后显示正式回应
6. 所有结果文本在当前面板内结算，不依赖右下角日志

### 4.2 状态来源

当前已经统一为：

- `CSV + EventService + encounter`

不再让 `DialogueManager + bridge` 直接承担状态写入真相源。

### 4.3 立绘表情

当前支持：

- 默认立绘
- 观察表情
- 入侵后表情
- 对话阶段表情

作者配置从 md 出发，规则见：

- [docs/DIALOGUE_PORTRAIT_RULES.md](C:/momen/docs/DIALOGUE_PORTRAIT_RULES.md)

柳飞霞已经接通：

- 默认
- 生气
- 悲伤

## 5. 开场序章当前状态

这是最近新增的重要结构。

### 5.1 数据位置

- [content/runs/run_definitions.json](C:/momen/content/runs/run_definitions.json)

字段：

- `opening_sequence`

### 5.2 当前已实现的最小序章

已经接上的流程：

- 第零世必死教学
- 两种凡人选择
- 死亡页面
- 天魔降临
- 绑定完成
- 回到正式开局

这条链运行在主界面的 OpeningOverlay，不直接污染正式 7 天主循环。

相关文档：

- [docs/OPENING_SEQUENCE_RULES.md](C:/momen/docs/OPENING_SEQUENCE_RULES.md)

### 5.3 当前视觉支持

开场序章已经支持按步骤 `style` 切换视觉风格：

- `intro`
- `choice`
- `death`
- `awakening`
- `opening`

并且已经有：

- 覆盖色层切换
- 强弱不同的装饰条
- 轻量 pulse / 标题放大

## 6. 场景表现当前状态

### 6.1 场景背景

当前背景资源根目录：

- [assets/art/backgrounds/scenes](C:/momen/assets/art/backgrounds/scenes)

目前已经接通宿舍背景：

- `res://assets/art/backgrounds/scenes/01/01_01.png`

主场景层新增了真实背景图层：

- `SceneBackgroundTexture`

说明：

- 普通地点显示背景图
- 事件 / 对话 / 结局会回到纯色气氛层
- 现在宿舍已接入，后续其他地点建议转入 location 配置层，不要继续写死在代码里

### 6.2 场景 NPC

最近已经从“文字热点卡片”改成：

- 半身像贴左下底边
- 多个 NPC 从左到右排开
- 鼠标悬停轻微上浮
- 无立绘时显示统一剪影式占位牌

### 6.3 场景 NPC 交互

最近已经去掉了点击 NPC 后那层意味不明的中间弹窗。

当前行为：

- 点击场景内 NPC
- 在 NPC 身边直接展开一个小交互面板
- 当前只有 `对话`
- 未来可以扩 `赠送 / 切磋 / 其他`

这层是为未来扩展预留的，但目前已经是场景内展开，不再打断沉浸感。

## 7. 资源目录规则

当前项目已经明确：

- 二进制资源统一放 `assets/`
- `content/` 只放配置、文本、Markdown、CSV、JSON

立绘目录当前规则：

- [assets/art/portraits/npcs](C:/momen/assets/art/portraits/npcs)

其下子目录使用数字编号，对照表说明含义。

相关文档：

- [docs/ASSET_RULES.md](C:/momen/docs/ASSET_RULES.md)

## 8. 编码与文本规则

这是当前项目非常重要的一条硬规范。

### 必须遵守

- `.gd / .tscn / .json / .csv / .md` 统一 UTF-8
- 默认使用 UTF-8 without BOM
- 不允许在 GBK / ANSI / UTF-8 之间来回转码
- 代码里不允许写剧情正文、玩家文案、长说明
- 所有玩家可见文本都要外置

原因：

- 这个项目曾经多次被转码污染
- 一旦在乱码文件上继续改，会把上下文和配置一起污染掉

## 9. 最近这段开发主要完成了什么

这次开发阶段，重点完成的是：

1. 把剧情作者链统一到 Markdown 主入口
2. 把对话系统收成三阶段玩法
3. 把立绘表情接进 md -> encounter -> runtime
4. 把主场景改成“背景图 + 贴底 NPC 半身像 + 就地交互”
5. 把开场序章做成数据驱动的独立流程

## 10. 当前已知的下一步优先项

如果下次继续，最推荐的工作顺序是：

1. 把场景背景图从 `main_game_screen.gd` 的临时硬编码，下放到地点配置
2. 继续补主场景背景资源
3. 继续补主要 NPC 立绘资源
4. 优化场景内 NPC 小交互面板，让它更像气泡操作条
5. 继续把 `act.md` 想表达的“天魔身份感”补进正式体验

## 11. 接手时优先看什么

下次如果聊天上下文没了，优先看这些文件：

- [docs/CURRENT_PROJECT_STATUS.md](C:/momen/docs/CURRENT_PROJECT_STATUS.md)
- [docs/PROJECT_RULES.md](C:/momen/docs/PROJECT_RULES.md)
- [docs/MARKDOWN_STORY_EDITOR_STATUS.md](C:/momen/docs/MARKDOWN_STORY_EDITOR_STATUS.md)
- [docs/MARKDOWN_SYNTAX.md](C:/momen/docs/MARKDOWN_SYNTAX.md)
- [docs/OPENING_SEQUENCE_RULES.md](C:/momen/docs/OPENING_SEQUENCE_RULES.md)
- [docs/DIALOGUE_PORTRAIT_RULES.md](C:/momen/docs/DIALOGUE_PORTRAIT_RULES.md)

如果要直接看代码主入口：

- [autoload/run_controller.gd](C:/momen/autoload/run_controller.gd)
- [scenes/screens/main_game/main_game_screen.gd](C:/momen/scenes/screens/main_game/main_game_screen.gd)
- [systems/event/event_service.gd](C:/momen/systems/event/event_service.gd)
- [tools/story_compiler/markdown_story_compiler.gd](C:/momen/tools/story_compiler/markdown_story_compiler.gd)
