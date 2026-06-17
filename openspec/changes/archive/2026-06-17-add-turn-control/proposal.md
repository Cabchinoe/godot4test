## Why

当前战棋原型缺少回合制核心机制：单位移动力一次性用完、无回合计数、无行动点系统、地图超出窗口无法拖拽查看。需要实现回合控制系统和摄像机平移，使游戏具备基本战棋交互框架。

## What Changes

- 新增 `TurnController` 独立类：管理回合计数、阶段切换（PLAYER_PHASE / ENEMY_PHASE）、最大回合限制、游戏结束判定
- `Unit` 新增行动点（AP）系统：`action_points` 每回合重置为 `move_range`，移动时按步数扣除，支持连续移动（AP未耗尽时保持选中状态并重新计算可达范围）
- 重构 `main.gd` 输入状态机：区分点击与拖拽（阈值判断）、右键上下文操作（选中时取消选择、空闲时弹出结束回合）、游戏结束后锁定所有输入
- 新增 Camera2D 地图平移：左键拖拽移动地图视口
- 新增 HUD UI 层（CanvasLayer + Control）：常驻显示 AP 剩余、回合计数、结束回合按钮，固定于窗口顶部

## Capabilities

### New Capabilities
- `turn-controller`: 回合计数、阶段管理、最大回合限制与游戏结束判定
- `action-points`: 单位行动点系统，每回合重置，移动按步扣除，支持连续移动
- `camera-pan`: Camera2D 地图拖拽平移，左键点击与拖拽阈值区分
- `hud-ui`: 固定于窗口顶部的 HUD 界面，显示 AP、回合数、结束回合按钮，右键上下文菜单

### Modified Capabilities
<!-- 无需修改现有 spec，本次为全新功能 -->

## Impact

- **新增文件**: `Script/turn_controller.gd`
- **修改文件**: `Script/unit.gd`（+AP 逻辑）、`Script/main.gd`（状态机重构 + Camera2D + 输入处理）
- **场景变更**: `main.tscn` 新增 Camera2D 节点、CanvasLayer + Control UI 节点
- **依赖**: 无外部依赖，纯 Godot 内置节点
