# 对话立绘表情规则

这份规则只说明一件事：作者如何从 Markdown 出发，控制对话中的立绘表情。

## 原则

- 作者只改 `content/story/act1/md/active/` 里的 Markdown。
- 作者稿里不写图片路径。
- 作者稿里不写英文表情名。
- 作者稿里只写中文表情标签。
- 真正的图片路径只放在 NPC 配置里。

## 资源放置

立绘资源统一放在：

- `res://assets/art/portraits/npcs/<数字目录>/`

例如柳飞霞是 `01`，所以她的资源放在：

- `res://assets/art/portraits/npcs/01/`

当前你已经有：

- `01_default.png`
- `01_ang.png`
- `01_sad.png`

## NPC 配置

NPC 配置里保留一张默认图，再增加一个“表情标签 -> 图片路径”的表。

示例：

```json
{
  "portrait_path": "res://assets/art/portraits/npcs/01/01_default.png",
  "portrait_variants": {
    "生气": "res://assets/art/portraits/npcs/01/01_ang.png",
    "悲伤": "res://assets/art/portraits/npcs/01/01_sad.png"
  }
}
```

含义是：

- 不写表情时，用默认图。
- Markdown 写 `生气`，就切到 `01_ang.png`。
- Markdown 写 `悲伤`，就切到 `01_sad.png`。

## Markdown 写法

当前支持 4 类表情控制。

### 1. 开场表情

```md
[开场表情: 悲伤]
```

进入对话时，先用这张表情。

### 2. 观察表情

```md
[观察表情: 悲伤]
```

点“观察”后切到这张表情。

### 3. 入侵表情

```md
[入侵表情: 贪 = 生气]
[入侵表情: 嗔 = 生气]
[入侵表情: 痴 = 悲伤]
```

含义是：

- 当玩家选了某一种魔念，
- 显示该次入侵反馈时，
- 自动切到对应表情。

而且当前实现里，这张表情会继续沿用到紧接着的“对话”阶段，除非你后面显式改掉。

### 4. 对话表情

```md
[对话表情: 悲伤]
```

如果你希望正式交锋阶段统一使用一张表情，可以写这一条。

它的优先级低于“刚刚选中的入侵表情”。

也就是说当前顺序是：

1. 入侵后的即时表情
2. 对话阶段专门指定的表情
3. 开场默认图

## 推荐写法

柳飞霞这类角色，比较适合这样配：

```md
[开场表情: 悲伤]
[观察表情: 悲伤]
[入侵表情: 贪 = 生气]
[入侵表情: 嗔 = 生气]
[入侵表情: 痴 = 悲伤]
```

这样效果会是：

- 刚出现时带一点伪装的哀伤
- 观察时继续保持悲伤外壳
- 贪或嗔被点中时，立刻切到更危险的“生气”
- 痴仍保留“悲伤”这层伪装

## 编译流程

写完 Markdown 后，照常一键编译即可。

```powershell
C:\momen\Godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe --headless --editor --path C:\momen -s res://tools/story_compiler/compile_current_markdown_runner.gd --quit
```

## 当前边界

当前这版已经支持：

- 开场切表情
- 观察切表情
- 入侵即时反馈切表情
- 入侵后进入对话时继续沿用这张表情

还没单独支持的，是“同一个对话选项 A 和选项 B 各自再切不同表情”。

如果后面你需要这一层，我们再加“选项结果表情”规则，但先不把作者稿语法做复杂。
