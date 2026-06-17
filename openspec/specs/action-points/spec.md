## ADDED Requirements

### Requirement: 行动点初始化与重置
Unit SHALL 拥有 `action_points` 属性，初始值等于 `move_range`。每回合开始时通过 `start_turn()` 方法将 `action_points` 重置为 `move_range`。

#### Scenario: 单位初始化
- **WHEN** Unit 以 `move_range = 5` 初始化
- **THEN** `action_points = 5`

#### Scenario: 回合开始重置 AP
- **WHEN** 单位当前 `action_points = 2`，调用 `start_turn()`
- **THEN** `action_points` 重置为 `move_range`（5）

### Requirement: 移动扣除行动点
Unit 移动时 SHALL 按实际步数扣除 `action_points`。每走 1 格扣 1 点。若 AP 不足则拒绝移动。

#### Scenario: 正常移动扣 AP
- **WHEN** `action_points = 5`，移动 3 步
- **THEN** `action_points = 2`

#### Scenario: AP 不足拒绝移动
- **WHEN** `action_points = 1`，尝试移动 3 步
- **THEN** 移动被拒绝，`action_points` 不变

### Requirement: 连续移动
当 `action_points > 0` 且移动动画结束后，Unit SHALL 保持选中状态，从新位置重新计算可达范围（BFS，`max_steps = action_points`），允许玩家继续点击可达格移动。

#### Scenario: 移动后保持选中
- **WHEN** `action_points = 5`，移动 3 步，动画结束
- **THEN** `action_points = 2`，保持 `player_selected = true`，可达范围从新位置以 `max_steps = 2` 重新计算

#### Scenario: AP 耗尽自动取消选中
- **WHEN** `action_points = 2`，移动 2 步，动画结束
- **THEN** `action_points = 0`，`player_selected = false`，清除所有可达范围和高亮路径

### Requirement: spend_ap 返回值
`spend_ap(cost: int)` SHALL 在 AP 充足时扣除并返回 `true`，AP 不足时返回 `false`。

#### Scenario: 扣除成功
- **WHEN** `action_points = 3`，调用 `spend_ap(2)`
- **THEN** 返回 `true`，`action_points = 1`

#### Scenario: 扣除失败
- **WHEN** `action_points = 1`，调用 `spend_ap(3)`
- **THEN** 返回 `false`，`action_points` 保持 1
