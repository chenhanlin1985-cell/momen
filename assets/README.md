# 资源目录

项目中的美术、音频、字体、图标等二进制资源统一放在 `res://assets/`。

约定：

- `res://assets/art/`：立绘、背景、UI 图像、特效图
- `res://assets/audio/`：音乐、环境音、音效
- `res://assets/fonts/`：字体资源
- `res://assets/icons/`：图标与小尺寸符号资源

补充规则：

- `res://content/` 只存放配置、文本、剧情结构、CSV、Markdown、JSON 等内容数据。
- 不要把图片、音频、字体再放回 `res://content/`。
- 角色立绘统一放在 `res://assets/art/portraits/npcs/` 下。
- `npcs/` 的子目录只使用数字编号，不直接暴露有含义的英文命名。
- 目录含义统一查看 `res://assets/art/portraits/npcs/_folder_map.json`。

示例：

- `res://assets/art/portraits/npcs/01/01_default.png`
- `res://assets/art/portraits/npcs/01/01_panic.png`
- `res://assets/art/portraits/npcs/06/06_default.png`
