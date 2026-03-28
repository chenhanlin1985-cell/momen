# Architecture

# ARCHITECTURE

## 1. 项目目标

本项目是一个使用 Godot 4.x + GDScript 开发的独立游戏原型，类型为：

- 多周目
- 生存模拟
- 事件驱动
- 轻演出、重系统
- 单局 20~40 分钟
- 优先 PC / Steam

架构首要目标：

1. 支持 MVP 快速落地
2. 支持后续扩展而不大规模重构
3. 支持 Codex 持续协作开发
4. 内容优先数据驱动
5. 核心逻辑与 UI 解耦
6. 单局状态与元进度分离
7. 尽量可测试、可调试、可存档

---

## 2. 架构原则

### 2.1 分层明确
项目采用以下分层：

- `core`：纯状态模型、值对象、基础契约
- `systems`：规则执行、流程结算、存档、条件判断
- `content`：行动、事件、NPC、状态、继承项等内容定义
- `ui` / `scenes`：展示层、输入层、弹窗、界面组合
- `autoload`：全局生命周期服务入口，不放业务细节

### 2.2 数据驱动优先
以下内容默认必须数据驱动：

- 行动定义
- 事件定义
- 状态定义
- NPC 初始配置
- 周目继承项
- 阶段节点
- 主目标定义

原则：
> 新增同类内容时，应优先“加数据”，而不是“改底层”。

### 2.3 统一状态修改
所有核心状态变更必须通过统一接口进行。

禁止：
- UI 直接修改玩家、NPC、世界状态
- 任意脚本随处改核心资源值
- 事件脚本直接越层改状态而不经过系统

### 2.4 流程阶段化
每日流程、行动结算、事件结算必须分阶段处理，避免超长函数和硬编码流程。

### 2.5 尽量组合，不堆 God Object
禁止把所有职责集中到一个 `GameManager` 中。

---

## 3. 目录结构

建议目录结构如下：

```text
res://
  addons/

  autoload/
    app_state.gd
    run_controller.gd
    save_service.gd

  core/
    models/
      player_state.gd
      npc_state.gd
      world_state.gd
      run_state.gd
      meta_progress.gd
    value_objects/
    enums/
    contracts/

  systems/
    flow/
      day_flow_state_machine.gd
    action/
      action_service.gd
      action_validator.gd
      action_executor.gd
    event/
      event_service.gd
      event_trigger_service.gd
      event_effect_executor.gd
    condition/
      condition_evaluator.gd
    status/
      status_service.gd
    inheritance/
      inheritance_service.gd
    save/
      save_repository.gd
      save_serializer.gd
    debug/
      debug_command_service.gd

  content/
    actions/
    events/
      common/
      stage/
      death/
    npcs/
    statuses/
    inheritance/
    goals/
    runs/

  scenes/
    app/
    screens/
      main_game/
      run_summary/
    widgets/
    popups/

  ui/
    presenters/
    view_models/
    bindings/

  assets/
    art/
    audio/
    fonts/
    icons/

  tools/
    debug/
    validation/

  tests/
    unit/
    integration/

  docs/