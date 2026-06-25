## Why

当前对局里只有 Player 一个单位，`TurnController` 的 `ENEMY_PHASE` 是空壳，敌人阵营完全缺位 —— 玩家走来走去没有任何反应物，对局没有真正的对抗。要让对局成立，需要支持动态生成多个敌方单位、为它们建立行动回合、并加入基础 AI 行为。

## What Changes

- 新增 `$Enemies` 容器节点，作为所有动态生成敌人的父节点
- 新增 `EnemyDB`（数据驱动的兵种定义） + `conf/enemies.json`
- 新增 `EnemySpawner`，按规则在对局开始时生成若干敌人（数量 / 位置可含随机性）
- 给所有 `Unit` 在 `init_unit` 末尾加 group 标签：`units` + `<faction>`（如 `player` / `enemy`）
- 新增 unit 占格检查：`Pathfinder.is_walkable` 拒绝任何已被 unit 占据的格子；BFS / 路径搜索均尊重占格
- **BREAKING** `Unit.move_range` 重命名为 `Unit.ap_max`，含义从"移动距离上限"明确为"AP 上限"。`init_unit` 第三参数同步改名
- `TurnController` 真正实现 ENEMY_PHASE：`end_turn` 不再直接进入下一回合，而是切到 ENEMY_PHASE；增加 `phase_changed(phase)` 信号 与 `end_enemy_phase()` 方法
- 新增 `EnemyAI`：最小可用版本（朝最近 player 单位移动、AP 用尽即停）；支持"按键加速跳过"将 `move_interval` 临时降至 0
- `main.gd` 监听 `phase_changed`，在 ENEMY_PHASE 时依次驱动每个敌人 AI，全部结束后调用 `end_enemy_phase()`
- `main.gd._collect_targetable_cells()` 改为返回所有 enemy group 单位的 `{grid, level}`

## Capabilities

### New Capabilities
- `enemy-spawn`: 动态生成敌方单位 —— 兵种数据定义、生成规则（含随机）、`$Enemies` 容器与 group 标签管理
- `unit-occupation`: 单位占格规则 —— 任何 unit 占据的格子对所有 unit 视为不可走，影响 `is_walkable` 与寻路
- `enemy-ai`: 敌人在 ENEMY_PHASE 的行为决策与执行 —— 最小可用 AI（追击最近 player）、动画加速跳过机制

### Modified Capabilities
- `turn-controller`: ENEMY_PHASE 从空壳变为真实阶段，新增 `phase_changed` 信号与 `end_enemy_phase()` 方法，回合推进时机改变
- `action-points`: 字段 `move_range` 重命名为 `ap_max`，`init_unit` 参数名同步调整，spec 文本同步更新

## Impact

- **代码**: `Script/unit.gd`（改名 + group 标签）、`Script/pathfinder.gd`（占格检查）、`Script/turn_controller.gd`（阶段切换）、`Script/main.gd`（@onready 容器、阶段监听、敌人目标收集、HUD `ap_max`）
- **新增文件**: `Script/enemy_db.gd`、`Script/enemy_spawner.gd`、`Script/enemy_ai.gd`、`conf/enemies.json`
- **场景**: `main.tscn` 增加 `$Enemies` 空节点
- **依赖资源**: 至少 1 个敌人 `SpriteFrames`（可暂时复用 `player2_sprites.tres`，后续替换）
- **存档**: 当前 `PlayerSaveProvider` 只存玩家，敌人不入存档（每次开局重生），无破坏
- **测试**: 现有 `action-points` 场景需验证 `ap_max` 改名不破坏 BFS 与 HUD
