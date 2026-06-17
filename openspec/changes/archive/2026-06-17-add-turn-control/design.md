## Context

当前战棋原型架构：
- `main.gd`：场景根脚本，处理所有输入、状态管理、渲染逻辑
- `Unit`：单位类，含 `move_range`、寻路、移动动画
- `Pathfinder`：BFS 可达范围 + A* 寻路，cost 为 1/步
- `LevelManager`：多层地图管理

问题：单位移动一次性用完、无回合概念、地图超出窗口无法查看、无 UI 层。

## Goals / Non-Goals

**Goals:**
- 实现回合计数与游戏结束判定
- 实现行动点（AP）系统，支持连续移动
- 实现 Camera2D 地图拖拽平移
- 实现固定 HUD 界面（AP、回合数、结束回合按钮、右键菜单）

**Non-Goals:**
- 敌方 AI 回合（仅预留 ENEMY_PHASE 空壳）
- 多单位管理（当前只有 1 个 Player）
- 镜头缩放、边界限制、跟随 unit 等高级摄像机功能
- AP 消耗差异化（所有移动 cost = 1/步）

## Decisions

### 1. TurnController 作为独立类

**选择**: `class_name TurnController`，独立于 main.gd

**理由**: 回合逻辑与场景输入解耦，便于测试和未来扩展（如加入敌方回合、回合事件回调）。

**替代方案**: 写在 main.gd 中 → 会导致 main.gd 职责过重。

### 2. AP 挂在 Unit 上

**选择**: `Unit` 新增 `action_points` 属性 + `start_turn()` / `spend_ap()` 方法

**理由**: AP 是单位属性，与 move_range 绑定。未来多单位时每个 unit 独立管理自己的 AP。

**替代方案**: 在 main.gd 中管理 AP → 违反数据归属原则。

### 3. 点击 vs 拖拽：阈值判断

**选择**: 左键按下记录位置，鼠标移动超过 5px 视为拖拽，释放时若未超过阈值视为点击

**理由**: 战棋/RTS 标准做法，用户体验自然。

**替代方案**: 右键拖拽 → 与右键取消/结束回合冲突；中键拖拽 → 不够直觉。

### 4. Camera2D 平移地图

**选择**: 在场景中添加 Camera2D 节点，拖拽时修改 `camera.position`

**理由**: Godot 原生方案，子节点自动跟随，`get_global_mouse_position()` 自动处理坐标转换，现有代码无需改动。

**替代方案**: 手动偏移所有节点 position → 工作量大且易出错。

### 5. HUD 使用 CanvasLayer + Control

**选择**: 新建 CanvasLayer (layer=10) + Control 节点，锚定顶部全宽

**理由**: CanvasLayer 独立于 Camera2D，UI 永远固定于屏幕。与 TileMap 的 HUD 层（格子高亮）互不干扰。

### 6. 右键上下文菜单

**选择**: 使用 Godot `PopupMenu` 节点，根据当前状态显示不同选项
- IDLE 状态：显示"结束回合"
- UNIT_SELECTED 状态：显示"取消选择"

**理由**: 方案C（混合）—— 结束回合按钮同时常驻 + 右键可触发，取消选择仅右键触发。

### 7. 动画期间锁定输入

**选择**: `is_moving == true` 时忽略所有点击输入

**理由**: 简单可靠，避免动画中途改变路径导致的 bug。连续移动需等当前动画结束。

## Risks / Trade-offs

- **[拖拽阈值误判]** → 5px 阈值在大多数场景合理，触屏设备可能需要调整，当前仅支持鼠标。
- **[动画等待感]** → 连续移动需等每段动画结束，可能略有延迟感。未来可改为路径队列化（方案B）优化。
- **[PopupMenu 与右键冲突]** → 需确保 PopupMenu 弹出时不触发其他右键逻辑，用 `event.handled = true` 阻断。
- **[Camera2D 与 TileMap 坐标]** → `get_global_mouse_position()` 在 Camera2D 移动后仍返回正确世界坐标，已验证无需额外转换。
