## 1. TurnController 核心

- [x] 1.1 创建 `Script/turn_controller.gd`，实现 `class_name TurnController`，含 `current_turn`、`max_turns`、`current_phase`、`is_game_over` 属性
- [x] 1.2 实现 `start_game()` 方法：初始化首回合，发出 `turn_started` 信号
- [x] 1.3 实现 `end_turn()` 方法：推进回合、阶段切换（PLAYER→ENEMY自动跳过→PLAYER）、达到 max_turns 后设 `is_game_over=true` 并发出 `game_over` 信号
- [x] 1.4 定义信号：`turn_started(turn: int)`、`turn_ended(turn: int)`、`game_over()`

## 2. Unit 行动点系统

- [x] 2.1 `unit.gd` 新增 `action_points: int` 属性，`init_unit` 中初始化为 `move_range`
- [x] 2.2 实现 `start_turn()` 方法：重置 `action_points = move_range`
- [x] 2.3 实现 `spend_ap(cost: int) -> bool` 方法：AP 充足时扣除返回 true，不足返回 false

## 3. 场景结构改造

- [x] 3.1 `main.tscn` 添加 Camera2D 节点（不改原有层级，Camera2D 自动影响视口）
- [x] 3.2 添加 CanvasLayer (layer=10) + Control 节点（锚定 TOP_WIDE），包含 HBoxContainer（AP 显示、回合标签、结束回合按钮）和 PopupMenu 节点

## 4. main.gd 状态机重构

- [x] 4.1 新增 `turn_controller: TurnController` 实例，`_ready()` 中初始化并调用 `start_game()`
- [x] 4.2 新增拖拽状态变量：`is_dragging`、`press_pos`、`last_mouse_pos`，拖拽阈值常量 `DRAG_THRESHOLD = 5`
- [x] 4.3 重构 `_unhandled_input()`：左键按下记录 `press_pos`，左键释放时根据拖拽阈值判断点击/拖拽
- [x] 4.4 实现拖拽逻辑：`is_dragging = true` 时，每帧 `camera.position -= (current_mouse - last_mouse)`
- [x] 4.5 重构左键点击逻辑：选中 unit 后保持 `player_selected`，移动后根据剩余 AP 决定是否保持选中并重算可达范围
- [x] 4.6 实现右键逻辑：`player_selected = true` 时取消选择并清除高亮；`player_selected = false` 时弹出结束回合菜单
- [x] 4.7 实现游戏结束锁定：`is_game_over = true` 时忽略所有输入，`_process()` 跳过 hover 逻辑
- [x] 4.8 实现动画锁：`player.is_moving == true` 时忽略点击输入

## 5. HUD 交互

- [x] 5.1 连接结束回合按钮 `pressed` 信号 → `turn_controller.end_turn()`
- [x] 5.2 连接 PopupMenu 选项：结束回合 / 取消选择，根据状态动态显示
- [x] 5.3 监听 `turn_started` 信号更新 HUD（AP 重置、回合数更新）
- [x] 5.4 监听 AP 变化实时更新 HUD 显示
- [x] 5.5 游戏结束时禁用结束回合按钮

## 6. 集成验证

- [x] 6.1 验证完整流程：选 unit → 移动扣 AP → 连续移动 → AP 耗尽自动取消 → 结束回合 → 新回合 AP 重置
- [x] 6.2 验证达到最大回合后 console 输出"对局结束"，所有输入被锁定
- [x] 6.3 验证 Camera2D 拖拽平移不影响点击选中和 HUD 位置
- [x] 6.4 验证右键菜单在 IDLE/SELECTED 状态下正确切换选项
