# 项目规范

## 1. 项目目标
本项目是一个 Godot 4.x + GDScript 开发的多周目、生存模拟、事件驱动独立游戏。
首要目标：
- 可扩展
- 可维护
- 数据驱动
- 可测试
- 可被 AI 协作持续开发

## 2. 分层约定
### 2.1 core
只放纯状态模型、值对象、规则接口。
禁止：
- 直接依赖具体 UI
- 直接依赖场景节点路径
- 混入表现逻辑

### 2.2 systems
负责流程、结算、触发、校验、存档等应用层逻辑。
要求：
- 使用 core 模型
- 尽量通过服务接口交互
- 不直接操作具体 UI 控件

### 2.3 content
存放事件、行动、NPC、状态、遗产等配置。
要求：
- 优先数据驱动
- 新增内容优先加配置，不改底层

### 2.4 ui / scenes
只处理展示、输入、动画、交互。
禁止：
- 直接修改核心状态
- 在按钮回调中堆积业务逻辑

## 3. 状态修改规则
所有对玩家、NPC、世界、局外进度的变更，都必须通过统一状态变更接口。
禁止：
- 直接在任意脚本里写 player.hp -= 10 这类代码
- UI 层越过系统层改值

## 4. 数据驱动约定
以下内容必须优先数据驱动：
- 行动定义
- 事件定义
- 状态定义
- NPC 初始数据
- 周目继承项
- 阶段节点

只有在通用配置无法表达时，才允许补少量专用逻辑。

## 5. 模块边界
### 允许依赖
- ui -> systems
- systems -> core
- systems -> content
- autoload -> systems/core

### 禁止依赖
- core -> ui
- core -> scenes
- content -> ui
- content -> gameplay-specific node path

## 6. 命名规范
- 文件名：snake_case
- 类名：PascalCase（有 class_name 时）
- 方法/变量：snake_case
- 常量：UPPER_SNAKE_CASE
- 资源 key / tag / id：统一 snake_case

## 7. GDScript 规范
- 默认使用静态类型
- 公共接口必须标注参数和返回类型
- 函数尽量短小，超过 40~60 行优先拆分
- 单个脚本职责单一
- 避免巨型脚本
- 优先组合而非继承滥用
- 使用 Godot 风格顺序组织代码：
  class_name / extends / signals / enums / const / @export / vars / 生命周期函数 / 公共方法 / 私有方法

## 8. 事件系统规范
事件定义至少包含：
- id
- title
- description
- trigger_conditions
- weight
- tags
- options
- effects
- repeatable
- priority

事件效果优先使用通用 effect executor。
禁止每个事件都写一份独立逻辑脚本，除非该事件明显超出通用框架。

## 9. 行动系统规范
行动定义至少包含：
- id
- display_name
- description
- availability_conditions
- base_costs
- base_rewards
- tags
- linked_event_pool

行动执行流程必须固定阶段化：
1. 校验
2. 扣消耗
3. 应用基础收益
4. 应用修正器
5. 检查附加触发
6. 记录日志
7. 推送后续事件

## 10. 存档规范
存档分为：
- run_save：单局状态
- meta_save：局外进度

要求：
- 可版本化
- 尽量可调试
- 字段新增不能轻易导致旧存档全废

## 11. 调试规范
必须保留开发调试入口，至少支持：
- 修改资源
- 添加状态
- 改天数
- 触发事件
- 修改 NPC 关系
- 强制死亡
- 重置周目

## 12. 提交规范
每次提交必须说明：
- 改动目标
- 涉及文件
- 设计理由
- 扩展方式
- 风险点

禁止“顺手把别的也改了”。