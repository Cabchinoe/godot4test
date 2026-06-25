## ADDED Requirements

### Requirement: 单位占格阻挡
任何 `units` group 中的 unit 所占格 `(grid_pos, current_level)` SHALL 对其他所有 unit 视为不可走。`Pathfinder.is_walkable(grid, level, exclude_unit)` SHALL 在原有地形与障碍判定通过后，额外遍历 `units` group：若存在非 `exclude_unit` 的 unit 占据 `(grid, level)`，返回 `false`。

#### Scenario: 敌人占格阻止玩家通行
- **WHEN** Enemy 处于 `(grid: (3,3), level: 1)`，调用 `pathfinder.is_walkable(Vector2i(3,3), 1, player)`
- **THEN** 返回 `false`

#### Scenario: 排除自身格不阻挡自己
- **WHEN** Player 处于 `(grid: (2,2), level: 1)`，调用 `pathfinder.is_walkable(Vector2i(2,2), 1, player)`
- **THEN** 返回 `true`（自己当前格对自己视为可走）

#### Scenario: 空格仍可走
- **WHEN** `(4,4) level 1` 无 unit 占据且地形可走，调用 `pathfinder.is_walkable(Vector2i(4,4), 1, player)`
- **THEN** 返回 `true`

### Requirement: 占格在寻路与可达计算中生效
`Pathfinder.bfs(start, level, max_steps, self_unit)` 与 `Pathfinder.find_path(from, fl, to, tl, self_unit)` SHALL 通过 `is_walkable(..., self_unit)` 排除被其他 unit 占据的格子，使 BFS 可达集与最短路径自然绕开占格。

#### Scenario: BFS 绕开敌人
- **WHEN** Player 在 `(0,0) lv1`，Enemy 在 `(1,0) lv1`，Player `action_points = 3`，BFS 结果
- **THEN** 可达集不包含 `(1,0) lv1`，但 `(0,1) lv1`、`(2,0) lv1`（经其他路径可达）若地形允许仍可达

#### Scenario: find_path 绕开敌人
- **WHEN** Player 在 `(0,0) lv1`，Enemy 在 `(1,0) lv1`，目标 `(2,0) lv1`，地形允许 `(0,1)→(1,1)→(2,1)→(2,0)` 路径
- **THEN** 返回的 path 不经过 `(1,0) lv1`

#### Scenario: 终点是敌人占格
- **WHEN** 调用 `find_path(player.grid_pos, player.current_level, enemy.grid_pos, enemy.current_level, player)`
- **THEN** 返回空数组（不可达）

### Requirement: 占格检查容错
若 `Pathfinder` 无法获取 `SceneTree`（如测试环境），SHALL 跳过 unit 占格检查并仅按地形/障碍判定，不抛异常。

#### Scenario: 无 SceneTree 环境
- **WHEN** `Engine.get_main_loop()` 返回 `null`，调用 `is_walkable(g, l)`
- **THEN** 仅按地形与障碍判定，正常返回 `true`/`false`，不崩溃
