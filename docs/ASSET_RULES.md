# 资源规范

## 1. 总原则

所有美术、音频、字体、图标等资源统一放在 `res://assets/`。

`res://content/` 只保留内容配置与文本数据，不再存放图片、音频、字体等资源文件。

## 2. 目录约定

- `res://assets/art/`
- `res://assets/audio/`
- `res://assets/fonts/`
- `res://assets/icons/`

人物立绘统一放在：

- `res://assets/art/portraits/npcs/<folder>/`

其中 `<folder>` 只使用数字编号，不使用有含义的英文目录名。

目录含义统一查看：

- `res://assets/art/portraits/npcs/_folder_map.json`

示例：

- `res://assets/art/portraits/npcs/01/01_default.png`
- `res://assets/art/portraits/npcs/01/01_smile.png`
- `res://assets/art/portraits/npcs/01/01_panic.png`

## 3. 内容层与资源层分离

以下内容放在 `res://content/`：

- Markdown 剧情稿
- CSV 配置
- JSON 配置
- 本地化文本
- encounter 逻辑与 texts 数据

以下内容放在 `res://assets/`：

- NPC 立绘
- 场景背景
- UI 贴图
- 特效图
- BGM 与音效
- 字体文件

## 4. 路径写法

配置里引用资源时，统一写 `res://assets/...` 路径。

例如 `content/npcs/npc_definitions.json` 中的 `portrait_path`：

```json
"portrait_path": "res://assets/art/portraits/npcs/01/01_default.png"
```

## 5. 新资源接入流程

1. 先在 `assets/` 下找到对应类别目录。
2. 如果是 NPC 立绘，先查 `_folder_map.json` 找到对应数字目录。
3. 把资源文件放进对应数字目录。
4. 文件名也优先使用数字前缀，不使用带含义的英文名。
5. 再去配置文件里填写 `res://assets/...` 路径。

## 6. 强规则

- 不要把新图片放进 `res://content/`
- 不要把新音频放进 `res://content/`
- 不要在多个目录重复存放同一资源
- 资源路径必须稳定，避免频繁改名导致配置失效
- `npcs/` 子目录不允许直接使用 `friendly_peer`、`herb_steward` 这类有含义的英文命名
- 如果目录或文件名必须解释含义，就通过对照表说明，不把含义直接写进名字里
