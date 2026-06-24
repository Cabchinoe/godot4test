## ADDED Requirements

### Requirement: BulletRange 类独立计算子弹可达格子

系统 SHALL 提供独立的 `BulletRange` 类，与 `Pathfinder` 解耦，专门计算从指定起点和 level 出发的子弹可命中格子集合。类 MUST 接受 `LevelManager` 实例以查询地图层信息。

#### Scenario: 创建 BulletRange 实例
- **WHEN** 调用方使用 `LevelManager` 实例构造 `BulletRange`
- **THEN** 实例成功创建，且能基于该 `LevelManager` 查询任意 level 的 `ground` 和 `obstacle` 层

#### Scenario: 计算可达格子集合
- **WHEN** 调用方提供起点格子、起点 level、射程参数
- **THEN** 返回 `Array[Dictionary]`，每项包含 `grid: Vector2i` 和 `level: int`，表示子弹可命中的格子及其所在 level
- **AND** 结果不包含起点本身

### Requirement: 射程边界约束

子弹可达格子 MUST 限制在以起点为中心、边长为 `2 * range + 1` 的正方形包围盒内。

#### Scenario: 射程为 5，起点 (10,10)
- **WHEN** 计算可达格子
- **THEN** 候选格子范围为 x ∈ [5, 15] 且 y ∈ [5, 15]
- **AND** 起点 (10,10) 不在结果中

### Requirement: Level 关系决定子弹弹道规则

子弹的目标 level 与起点 level 的关系 MUST 决定弹道处理方式。

#### Scenario: 平射（目标 level 等于起点 level）
- **WHEN** 目标格 level 等于起点 level
- **THEN** 子弹旅行 level 设为起点 level
- **AND** 使用 DDA 算法计算路径并按标准规则检查阻挡

#### Scenario: 高打低（目标 level 小于起点 level）
- **WHEN** 目标格 level 小于起点 level
- **THEN** 子弹旅行 level 设为目标 level
- **AND** DDA 路径上任何格子 level 大于目标 level 即视为阻挡
- **AND** DDA 路径上 level 等于 -1（无地面）的格子允许子弹穿过

#### Scenario: 低打高（目标 level 大于起点 level）
- **WHEN** 目标格 level 大于起点 level
- **THEN** 目标格 MUST 与起点格在 8 邻域内（切比雪夫距离为 1，包含 4 正向 + 4 对角）
- **AND** 距离大于 1 的高层格子 MUST 排除在结果之外
- **AND** 正交方向目标：检查起点离开方向墙和目标进入方向墙
- **AND** 对角方向目标：检查起点对应两条边的墙（水平 + 垂直）和目标对应两条边的墙，任一墙存在即阻挡（跨角规则）
- **AND** 所有方向都需要检查目标格的 obstacle

### Requirement: DDA 射线追踪子弹路径

系统 SHALL 使用 DDA (Digital Differential Analyzer) 算法在格子坐标系上追踪子弹弹道，记录每次跨越格子边界的顺序与方向。

#### Scenario: 计算 DDA 路径
- **WHEN** 提供起点和终点格子坐标（视为格子中心）
- **THEN** 返回有序格子列表，从起点开始按射线穿越顺序排列
- **AND** 每两个相邻格子之间标识跨越的边界类型（垂直边 / 水平边 / 角落）

#### Scenario: 射线穿过格子角落（t_max_x == t_max_y）
- **WHEN** DDA 步进时垂直边界与水平边界的 t 值相等
- **THEN** 同时跨越垂直边和水平边
- **AND** 任一方向有墙体阻挡即视为路径阻断

### Requirement: 按 DDA 跨越边方向检查 wall_block

每次 DDA 路径跨越格子边界时，系统 MUST 检查实际跨越的那条边是否被 `wall_block` 阻挡，包括离开格的出口边和进入格的入口边。墙体检查 MUST 包含对偶等效：物理同一面墙可设置在任一边的格子上，查询 `(grid, dir)` 的墙时，若邻格 `(grid + dir)` 的反方向位被置位也视为该墙存在。

#### Scenario: 跨垂直边向右
- **WHEN** DDA 从格子 A 跨右边进入格子 B
- **THEN** 检查 A 的东墙位（bit 2）以及 B 的西墙位（bit 8，A 的东墙对偶）
- **AND** 同时检查 B 的西墙位以及 A 的东墙位（B 的西墙对偶）
- **AND** 任一位被置位即视为阻挡

#### Scenario: 跨水平边向下
- **WHEN** DDA 从格子 A 跨下边进入格子 B
- **THEN** 检查 A 的南墙位（bit 4）以及 B 的北墙位（bit 1，对偶）
- **AND** 任一位被置位即视为阻挡

#### Scenario: 起点的离开方向有墙
- **WHEN** 子弹从起点向某方向射出，起点对应方向有 wall_block 或邻格反方向有对偶 wall_block
- **THEN** 该方向上的弹道立即阻断，目标不可命中

#### Scenario: 跨角射线穿过墙体仅设在对角格上
- **WHEN** DDA 跨角从 A 进入 D（A、D 为对角），构成角点的相邻两格 B、C 上设有指向角点的 wall_block
- **THEN** 跨垂直边检查 A 的水平离开方向墙时，命中 B 上的对偶墙
- **AND** 跨水平边检查时类似命中 C 上的对偶墙
- **AND** 任一墙存在即阻断弹道

### Requirement: 进入格子的 obstacle 阻挡检测

系统 MUST 在子弹进入每个格子时检查该格子对应 level 的 `obstacle` 层 `can_walk` 自定义数据。

#### Scenario: 进入格子有不可走 obstacle
- **WHEN** DDA 路径进入格子 G，G 的 obstacle 层数据存在且 `can_walk` 为 false
- **THEN** 路径在 G 处阻断
- **AND** G 不会加入可达结果（除非 G 本身是目标且 obstacle 为可命中体）

#### Scenario: 进入格子的 obstacle 可走或无 obstacle
- **WHEN** DDA 路径进入格子 G，G 无 obstacle 或 `can_walk` 为 true
- **THEN** 子弹可继续前进

### Requirement: 格子 level 自动解析

系统 MUST 提供工具方法 `get_level_at(grid)`，遍历所有已注册 level 的 `ground` 层，返回该格子所属 level。若无任何 level 有该格地面，返回 -1。

#### Scenario: 格子在 level 1 有地面
- **WHEN** 查询 (5,5) 的 level，仅 level 1 的 ground 层在 (5,5) 有 tile
- **THEN** 返回 1

#### Scenario: 格子无任何 level 有地面
- **WHEN** 查询 (20,20) 的 level，所有 level 的 ground 层在 (20,20) 均无 tile
- **THEN** 返回 -1

### Requirement: 路径终点判定

子弹的目标格 MUST 是 DDA 路径终点，且必须能完整通过所有阻挡检查才视为可命中。

#### Scenario: 路径完整通过
- **WHEN** DDA 从起点到目标格的每一步均通过 wall_block、obstacle、level 约束检查
- **THEN** 目标格加入可达结果

#### Scenario: 路径中途阻断
- **WHEN** DDA 从起点向目标格前进过程中任一格未通过检查
- **THEN** 目标格不加入可达结果
- **AND** 中途已通过的格子也不自动加入（每个目标格独立判定）
