## ADDED Requirements

### Requirement: 兵种数据定义与加载
系统 SHALL 通过 `conf/enemies.json` 与 `Script/enemy_db.gd` 提供数据驱动的兵种定义。`EnemyDB` SHALL 在首次访问时自动加载 JSON，并按 `id` 暴露兵种数据字典（包含至少 `name`、`ap_max`、`sprite_frames_path` 字段）。

#### Scenario: 加载已定义兵种
- **WHEN** `conf/enemies.json` 中定义 `goblin` 包含 `name="Goblin"`, `ap_max=4`, `sprite_frames_path="res://Unit/player2_sprites.tres"`，调用 `EnemyDB.get("goblin")`
- **THEN** 返回字典 `{name: "Goblin", ap_max: 4, sprite_frames_path: "res://Unit/player2_sprites.tres"}`

#### Scenario: 访问未定义兵种
- **WHEN** 调用 `EnemyDB.get("not_exist")`
- **THEN** 返回 `null` 或空字典，并输出 warning，不抛异常

### Requirement: 敌人节点容器
`main.tscn` SHALL 包含一个名为 `Enemies` 的 `Node2D` 子节点，作为所有动态生成敌人的父节点。该节点在编辑器中为空。

#### Scenario: 容器节点存在
- **WHEN** 加载 `main.tscn`
- **THEN** 场景树中存在 `Main/Enemies` 节点，类型为 `Node2D`，无子节点

### Requirement: 动态生成敌人
`EnemySpawner` SHALL 提供 `spawn(id: String, grid: Vector2i, level: int) -> Unit` 方法，根据 `EnemyDB` 查得的数据动态创建 `Unit` 节点：包含一个名为 `Sprite2D` 的 `AnimatedSprite2D` 子节点（`offset = Vector2(32, 32)`，`animation = "walk"`），并自动 `add_child` 到 `$Enemies` 容器，调用 `init_unit(name, "enemy", ap_max, level_manager, level)`，设置 `grid_pos` 并将 `global_position` 对齐到对应格的世界坐标。

#### Scenario: 生成单个 goblin
- **WHEN** 调用 `EnemySpawner.spawn("goblin", Vector2i(3, 5), 1)`
- **THEN** `$Enemies` 下新增一个 `Unit` 子节点，`faction == "enemy"`，`ap_max == 4`，`grid_pos == Vector2i(3, 5)`，`current_level == 1`，`global_position` 对齐到 (3,5) 格中心

#### Scenario: 生成的敌人加入 group
- **WHEN** 通过 `EnemySpawner.spawn(...)` 创建敌人
- **THEN** 该 unit 处于 `units` group 与 `enemy` group 中

### Requirement: 阵营 Group 标签
`Unit.init_unit` SHALL 在末尾自动将自己加入 `units` group 与 `<faction>` group（如 `player` 或 `enemy`）。

#### Scenario: Player 加入 group
- **WHEN** Player unit 调用 `init_unit("Player", "player", 5, ...)`
- **THEN** 该 unit 处于 `units` group 与 `player` group 中

#### Scenario: Enemy 加入 group
- **WHEN** Enemy unit 调用 `init_unit("Goblin", "enemy", 4, ...)`
- **THEN** 该 unit 处于 `units` group 与 `enemy` group 中

### Requirement: 对局开始时按规则生成敌人
对局进入 `main.tscn` 的 `_ready` 阶段时，系统 SHALL 调用 `EnemySpawner` 根据生成规则创建一批敌人。生成规则 MAY 包含随机数量与随机位置，但 MUST 保证：所有生成位置 walkable（地形 + 障碍）、不与 Player 重合、不与已生成的其他敌人重合。

#### Scenario: 对局开始有敌人
- **WHEN** 进入 `main.tscn` 完成 `_ready`
- **THEN** `$Enemies` 下至少有 1 个子节点，`enemy` group 中至少有 1 个 unit

#### Scenario: 生成位置不冲突
- **WHEN** 生成 N 个敌人
- **THEN** 任意两个敌人 `(grid_pos, current_level)` 不相同，且都不等于 Player 的 `(grid_pos, current_level)`
