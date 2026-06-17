## ADDED Requirements

### Requirement: HUD 固定于窗口顶部
HUD SHALL 使用 CanvasLayer (layer=10) + Control 节点，锚定于窗口顶部全宽（anchors_preset = TOP_WIDE），不受 Camera2D 平移影响。

#### Scenario: 地图平移时 HUD 不动
- **WHEN** Camera2D 平移地图
- **THEN** HUD 始终固定在窗口顶部，位置不变

### Requirement: AP 显示
HUD SHALL 实时显示当前单位的剩余行动点。使用可视化方式（如圆点或数字）展示 `action_points` / `move_range`。

#### Scenario: 显示当前 AP
- **WHEN** 单位 `action_points = 3`，`move_range = 5`
- **THEN** HUD 显示 AP 为 3/5（或等效可视化）

#### Scenario: AP 变化时更新
- **WHEN** 单位移动消耗 2 AP
- **THEN** HUD 立即更新显示新 AP 值

### Requirement: 回合计数显示
HUD SHALL 显示当前回合数和最大回合数，格式为"回合 N/M"。

#### Scenario: 显示回合数
- **WHEN** `current_turn = 3`，`max_turns = 10`
- **THEN** HUD 显示"回合 3/10"

#### Scenario: 回合推进时更新
- **WHEN** 回合从 3 推进到 4
- **THEN** HUD 更新显示"回合 4/10"

### Requirement: 结束回合按钮
HUD SHALL 包含"结束回合"按钮，点击后触发 TurnController.end_turn()。游戏结束后按钮 SHALL 禁用。

#### Scenario: 点击结束回合
- **WHEN** 玩家点击"结束回合"按钮
- **THEN** 调用 `turn_controller.end_turn()`，推进到下一回合

#### Scenario: 游戏结束后按钮禁用
- **WHEN** `is_game_over = true`
- **THEN** "结束回合"按钮变为禁用状态，不可点击

### Requirement: 右键上下文菜单
右键点击时 SHALL 弹出 PopupMenu，根据当前状态显示不同选项：
- IDLE 状态（`player_selected = false`）：显示"结束回合"
- UNIT_SELECTED 状态（`player_selected = true`）：显示"取消选择"

#### Scenario: 空闲时右键弹出结束回合
- **WHEN** `player_selected = false`，右键点击
- **THEN** 弹出菜单显示"结束回合"选项

#### Scenario: 选中时右键弹出取消选择
- **WHEN** `player_selected = true`，右键点击
- **THEN** 弹出菜单显示"取消选择"选项

#### Scenario: 选择取消选择
- **WHEN** 右键菜单中选择"取消选择"
- **THEN** `player_selected = false`，清除所有可达范围高亮和路径

#### Scenario: 游戏结束后右键无响应
- **WHEN** `is_game_over = true`，右键点击
- **THEN** 不弹出任何菜单
