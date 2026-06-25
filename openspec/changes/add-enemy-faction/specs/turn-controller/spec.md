## MODIFIED Requirements

### Requirement: 回合计数与阶段管理
TurnController SHALL 管理当前回合数 `current_turn`、最大回合数 `max_turns`、当前阶段 `current_phase`（PLAYER_PHASE / ENEMY_PHASE）。初始化时接收 `max_turns` 参数，`current_turn` 从 1 开始。

`end_turn()` SHALL 仅由 `PLAYER_PHASE` 触发，调用后将 `current_phase` 切换为 `ENEMY_PHASE`，并发出 `phase_changed(ENEMY_PHASE)` 信号。`current_turn` 在此阶段不变；回合数推进发生在 `end_enemy_phase()` 中。

#### Scenario: 初始化回合控制器
- **WHEN** TurnController 以 `max_turns = 10` 初始化
- **THEN** `current_turn = 1`，`current_phase = PLAYER_PHASE`，`is_game_over = false`

#### Scenario: 结束玩家回合进入敌方阶段
- **WHEN** 当前 `current_turn = 3`，`current_phase = PLAYER_PHASE`，调用 `end_turn()`
- **THEN** `current_turn` 仍为 3，`current_phase = ENEMY_PHASE`，发出 `phase_changed(ENEMY_PHASE)` 信号

#### Scenario: ENEMY_PHASE 期间调用 end_turn 无效
- **WHEN** `current_phase = ENEMY_PHASE`，调用 `end_turn()`
- **THEN** 不执行任何操作，`current_phase` 不变，不发出信号

### Requirement: 敌方回合预留
`ENEMY_PHASE` 阶段 SHALL 由 TurnController 经 `phase_changed(ENEMY_PHASE)` 信号通知外部协调者。该阶段的具体行为（AI 执行、动画等）由外部完成；外部完成后 MUST 调用 `end_enemy_phase()` 显式结束本阶段，推进回合计数并切回 `PLAYER_PHASE`。

#### Scenario: 敌方阶段由外部推进
- **WHEN** `current_phase` 切换为 `ENEMY_PHASE`，外部 AI 协调者完成所有敌人行动后调用 `end_enemy_phase()`
- **THEN** `current_turn += 1`（若未达 `max_turns`），`current_phase = PLAYER_PHASE`，发出 `phase_changed(PLAYER_PHASE)` 与 `turn_started(current_turn)` 信号

#### Scenario: 敌方阶段达到最大回合
- **WHEN** `max_turns = 10`，`current_turn = 10`，`current_phase = ENEMY_PHASE`，调用 `end_enemy_phase()`
- **THEN** `is_game_over = true`，发出 `game_over` 信号，`current_phase` 不切回 PLAYER_PHASE

## ADDED Requirements

### Requirement: 阶段切换信号
TurnController SHALL 暴露 `phase_changed(phase: Phase)` 信号。该信号在每次 `current_phase` 变化时（PLAYER_PHASE → ENEMY_PHASE 或 ENEMY_PHASE → PLAYER_PHASE）发出。首回合 `start_game()` SHALL 不发出 `phase_changed`（因首次就是 PLAYER_PHASE，没有"变化"），但仍发出 `turn_started(1)` 保持原行为。

#### Scenario: 玩家阶段切到敌方阶段
- **WHEN** 调用 `end_turn()`
- **THEN** 发出 `phase_changed(ENEMY_PHASE)` 信号

#### Scenario: 敌方阶段切回玩家阶段
- **WHEN** 调用 `end_enemy_phase()` 且未达最大回合
- **THEN** 发出 `phase_changed(PLAYER_PHASE)` 信号

#### Scenario: 首回合不发 phase_changed
- **WHEN** 调用 `start_game()`
- **THEN** 发出 `turn_started(1)`，但不发出 `phase_changed` 信号

### Requirement: end_enemy_phase 方法
TurnController SHALL 提供 `end_enemy_phase()` 公开方法，用于由外部 AI 协调者显式结束敌方阶段。该方法 SHALL：
1. 若 `is_game_over` 为 true，立即返回不执行任何操作
2. 若 `current_phase` 不是 `ENEMY_PHASE`，立即返回不执行任何操作
3. 否则推进 `current_turn`，进行 `game_over` 判定，切回 `PLAYER_PHASE`，并依次发出 `phase_changed(PLAYER_PHASE)` 与 `turn_started(current_turn)` 信号

#### Scenario: 正常结束敌方阶段
- **WHEN** `current_turn = 3`，`current_phase = ENEMY_PHASE`，`is_game_over = false`，调用 `end_enemy_phase()`
- **THEN** `current_turn = 4`，`current_phase = PLAYER_PHASE`，依次发出 `phase_changed(PLAYER_PHASE)` 与 `turn_started(4)` 信号

#### Scenario: 非 ENEMY_PHASE 调用无效
- **WHEN** `current_phase = PLAYER_PHASE`，调用 `end_enemy_phase()`
- **THEN** 不执行任何操作，`current_turn` 不变

#### Scenario: 游戏结束后调用无效
- **WHEN** `is_game_over = true`，调用 `end_enemy_phase()`
- **THEN** 不执行任何操作
