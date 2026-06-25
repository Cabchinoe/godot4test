## ADDED Requirements

### Requirement: 敌人回合行为执行
`EnemyAI` SHALL 提供 `run_turn(enemy: Unit) -> void` 方法（可 `await`）。执行流程：
1. 在 `player` group 中找曼哈顿距离最近的 player faction unit；若不存在，立即返回。
2. 调用 `enemy.pathfinder.find_path(enemy.grid_pos, enemy.current_level, target.grid_pos, target.current_level, enemy)` 求路径。
3. 若路径为空（不可达），立即返回。
4. 截取路径前 `enemy.action_points + 1` 个节点（含起点，即可走 `action_points` 步），调用 `enemy.spend_ap(steps)` 与 `enemy.set_move_path(truncated_path)`。
5. `await enemy.movement_finished`。

#### Scenario: 追击玩家
- **WHEN** Enemy 在 `(5,5) lv1`，`action_points = 4`，Player 在 `(0,0) lv1`，地形可走
- **THEN** Enemy 沿最短路径向 Player 方向移动恰好 4 步（耗尽 AP），动画结束后 `run_turn` 返回

#### Scenario: 无可达玩家时短路
- **WHEN** Enemy 与所有 player 单位之间无路径（被完全堵死）
- **THEN** `run_turn` 立即返回，不抛异常，`action_points` 不变

#### Scenario: 不存在 player 单位
- **WHEN** `get_tree().get_nodes_in_group("player")` 为空
- **THEN** `run_turn` 立即返回

#### Scenario: AP 不足以走完整路径
- **WHEN** Enemy 到 Player 的最短路径为 10 步，Enemy `action_points = 3`
- **THEN** Enemy 仅前进 3 步并停下，`action_points = 0`

### Requirement: 移动完成信号
`Unit` SHALL 暴露 `movement_finished` 信号，在 `_step_to_next` 走到 `is_moving = false`（无论是路径走完还是路径为空）的瞬间发出。

#### Scenario: 路径走完发信号
- **WHEN** Unit 通过 `set_move_path` 接到 3 步路径，依次执行到 `is_moving = false`
- **THEN** 发出 `movement_finished` 信号一次

#### Scenario: 空路径立即发信号
- **WHEN** Unit 通过 `set_move_path([])` 接到空路径
- **THEN** `is_moving = false`，发出 `movement_finished` 信号

### Requirement: 动画跳过加速
当玩家按住指定键（`KEY_SPACE`）时，`main.gd` SHALL 将所有 `units` group 内 unit 的 `move_interval` 临时设为 `0.01`；松开后恢复默认 `0.15`。该机制 SHALL 仅在 `ENEMY_PHASE` 期间生效，不影响 `PLAYER_PHASE` 下玩家的操作。

#### Scenario: 按键加速敌人动画
- **WHEN** 处于 `ENEMY_PHASE`，玩家按住 `KEY_SPACE`
- **THEN** 所有 unit 的 `move_interval == 0.01`，敌人移动视觉显著加速

#### Scenario: 松开恢复默认速度
- **WHEN** 松开 `KEY_SPACE`
- **THEN** 所有 unit 的 `move_interval` 恢复为 `0.15`

#### Scenario: 玩家回合按键无效
- **WHEN** 处于 `PLAYER_PHASE`，玩家按住 `KEY_SPACE`
- **THEN** `move_interval` 不变（仍为 `0.15`），不影响玩家移动节奏
