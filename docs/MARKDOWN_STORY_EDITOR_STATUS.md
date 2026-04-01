# Markdown Story Editor Status

## 当前结论
`markdown_story_editor` 现在只服务一套模式：
- Markdown 是作者输入层
- 运行时只认当前主结构
- 编辑器负责把 md 写回 `CSV + encounters + texts`

项目不再保留第二套剧情运行模式。

## 当前主结构
运行时真实数据源：
- `content/story/act1/csv/*`
- `content/dialogue/encounters/*`
- `content/dialogue/texts/*`

作者层主入口：
- `content/story/act1/md/active/`

归档与参考：
- `content/story/act1/md/archive/`

## 当前作者层规范
作者层只允许：
- 数字目录
- 数字文件名
- 数字编号
- 中文说明

作者层不再暴露：
- 英文运行时 ID
- 英文 NPC 缩写目录
- 英文文件名前缀
- 英文选项 ID

## 当前活跃目录
活跃目录使用数字目录：
- `00/`：通用事件
- `01/`：柳飞霞
- `02/`：药房执事
- `03/`：巡夜弟子
- `04/`：外门师兄
- `05/`：疯长老
- `06/`：王麻子

目录说明表：
- [content/story/act1/md/active/_folder_map.json](C:/momen/content/story/act1/md/active/_folder_map.json)

## 当前已经在线的 md 拆分
柳飞霞线：
- `content/story/act1/md/active/01/2001.md`
- `content/story/act1/md/active/01/2002.md`
- `content/story/act1/md/active/01/2102.md`

药房执事：
- `content/story/act1/md/active/02/2004.md`

巡夜弟子：
- `content/story/act1/md/active/03/2005.md`
- `content/story/act1/md/active/03/2008.md`

外门师兄：
- `content/story/act1/md/active/04/2003.md`
- `content/story/act1/md/active/04/2007.md`

## 当前编辑器职责
编辑器和编译器现在负责：
- 扫描 `md/active/`
- 生成预览
- 一键编译当前主结构
- 写回 `encounters / texts`
- 写回 CSV

编辑器新建草稿时，也默认生成纯数字文件名，不再生成英文前缀名。

## 当前推荐流程
1. 只在 `md/active/` 下写小 md 文件。
2. 先看目录说明表，确认应该写进哪个数字目录。
3. 文件名用纯数字。
4. 头部只写 `@编号`，不用 `@运行时ID`、`@NPC`、`@参与者`。
5. 写完后执行一次编译。

编译入口：
```powershell
C:\momen\Godot\Godot_v4.6-stable_mono_win64\Godot_v4.6-stable_mono_win64_console.exe --headless --editor --path C:\momen -s res://tools/story_compiler/compile_current_markdown_runner.gd --quit
```

## 新增一个 NPC 流程时的理解方式
现在“加一个 NPC 流程”应该这样理解：
- 去对应数字目录新增一个 md 文件
- 用数字编号说明它是哪一段
- 用中文写内容和说明
- 编译器自己把这段编号映射到当前项目结构

作者第一步不再是去记英文事件名，而是：
- 先查目录号
- 再决定编号
- 最后写 md 并编译

选项层也一样：
- 作者只写中文选项文本
- 不再手写英文选项 ID
- 编译器会按“剧情编号 + 选项顺序”稳定生成底层选项编号

## 还保留但不再是主线的东西
这些现在只算参考或工具产物，不是作者主入口：
- `archive/` 里的旧稿
- 导出参考稿
- 反编译参考稿

它们不会参与主编译，也不应再被当成剧情真相源。
