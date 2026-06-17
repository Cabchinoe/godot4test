## ADDED Requirements

### Requirement: 回合计数与阶段管理
TurnController SHALL 管理当前回合数 `current_turn`、最大回合数 `max_turns`、当前阶段 `current_phase`（PLAYER_PHASE / ENEMY_PHASE）。初始化时接收 `max_turns` 参数，`current_turn` 从 1 开始。

#### Scenario: 初始化回合控制器
- **WHEN** TurnController 以 `max_turns = 10` 初始化
- **THEN** `current_turn = 1`，`current_phase = PLAYER_PHASE`，`is_game_over = false`

#### Scenario: 结束回合推进
- **WHEN** 当前 `current_turn = 3`，调用 `end_turn()`
- **THEN** `current_turn` 变为 4，`current_phase` 回到 `PLAYER_PHASE`

### Requirement: 游戏结束判定
当 `current_turn` 超过 `max_turns` 时，TurnController SHALL 将 `is_game_over` 设为 `true`，并通过信号通知。游戏结束后 SHALL 不再接受任何回合操作。

#### Scenario: 达到最大回合后结束
- **WHEN** `max_turns = 10`，`current_turn = 10`，调用 `end_turn()`
- **THEN** `is_game_over = true`，发出 `game_over` 信号，console 输出"对局结束"

#### Scenario: 游戏结束后拒绝操作
- **WHEN** `is_game_over = true`，调用 `end_turn()`
- **THEN** 不执行任何操作，`current_turn` 不变

### Requirement: 回合开始信号
每回合开始时（包括首回合和后续回合），TurnController SHALL 发出 `turn_started(turn: int)` 信号，用于触发单位 AP 重置等逻辑。

#### Scenario: 首回合开始
- **WHEN** 调用 `start_game()`
- **THEN** 发出 `turn_started(1)` 信号

#### Scenario: 新回合开始
- **WHEN** 结束第 3 回合（未达最大回合）
- **THEN** 发出 `turn_started(4)` 信号

### Requirement: 敌方回合预留
ENEMY_PHASE 阶段 SHALL 存在但为空实现，直接自动跳过回到 PLAYER_PHASE。

#### Scenario: 敌方回合自动跳过
- **WHEN** `current_phase` 切换为 `ENEMY_PHASE`
- **THEN** 立即自动切换回 `PLAYER_PHASE` 并推进回合
