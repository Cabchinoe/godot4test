## 1. 类骨架与初始化

- [x] 1.1 创建 `Script/bullet_range.gd`，声明 `class_name BulletRange`
- [x] 1.2 定义常量 `DIR_MASK`（与 `Pathfinder` 一致：N=1, E=2, S=4, W=8）和 `EPSILON`
- [x] 1.3 添加 `level_manager: LevelManager` 字段，实现 `_init(p_level_manager)` 构造器

## 2. 辅助方法

- [x] 2.1 实现 `get_level_at(grid: Vector2i) -> int`：遍历所有 level 查 `ground.get_cell_tile_data(grid)`，返回有 tile 的 level，否则 -1
- [x] 2.2 实现 `_has_wall(grid, dir, level) -> bool`：检查 `ground.get_cell_tile_data(grid)` 的 `wall_block` 中 `dir` 对应位是否置位
- [x] 2.3 实现 `_has_obstacle_block(grid, level) -> bool`：检查 `obstacle.get_cell_tile_data(grid)` 的 `can_walk` 是否为 false

## 3. DDA 射线追踪

- [x] 3.1 实现 `_dda_path(origin: Vector2i, target: Vector2i) -> Array`：返回有序步骤列表，每步含 `{from, to, cross_v, cross_h}`，其中 `cross_v` / `cross_h` 标记本步是否跨越垂直 / 水平边
- [x] 3.2 处理 `dir.x == 0` 或 `dir.y == 0` 的纯垂直/水平射线（用 `INF` 表示对应方向 t 值）
- [x] 3.3 处理 `abs(t_max_x - t_max_y) < EPSILON` 的跨角情况：同步推进 x、y，标记 `cross_v == true` 且 `cross_h == true`
- [x] 3.4 步进直到 `current == target`，返回路径列表

## 4. 路径阻挡检测

- [x] 4.1 实现 `_is_path_clear(path, origin_level, travel_level) -> bool`，对每步执行 4.2-4.5
- [x] 4.2 跨垂直边时：检查 `from` 的 E/W 墙（依 `step_x` 符号）和 `to` 的反方向墙，任一置位返回 false
- [x] 4.3 跨水平边时：检查 `from` 的 S/N 墙（依 `step_y` 符号）和 `to` 的反方向墙
- [x] 4.4 跨角时：同时执行 4.2 + 4.3 两套检查
- [x] 4.5 检查 `to` 格的 level 约束（`get_level_at(to) > travel_level` 且不等于 -1 → 阻挡）和 `_has_obstacle_block(to, travel_level)`（仅当该格 level ≤ travel_level 时）

## 5. 主入口

- [x] 5.1 实现 `get_reachable_cells(origin: Vector2i, origin_level: int, range: int) -> Array[Dictionary]`
- [x] 5.2 生成 bounding box 内候选格列表，排除起点
- [x] 5.3 对每个候选格调用 `get_level_at` 取 `target_level`，跳过 `target_level == -1`
- [x] 5.4 分支处理三种 level 关系：
  - 平射 / 高打低：跑 DDA + `_is_path_clear`
  - 低打高：仅当切比雪夫距离 ≤ 1（8 邻域）时检查相邻格 wall_block + obstacle；对角方向用跨角规则检查两条边的墙
- [x] 5.5 通过检查的候选格加入结果 `[{grid, level}]`

## 6. 验证与边界用例

- [ ] 6.1 手测：起点 (10,10) lv=1，射程 5，目标 (13,12) lv=1，路径中 (12,11) 北墙 → 应阻挡
- [ ] 6.2 手测：起点 lv=2，目标 lv=1，路径经过 lv=2 地板 → 应阻挡
- [ ] 6.3 手测：起点 lv=1，目标 lv=2 切比雪夫距离 > 1 → 应排除
- [ ] 6.4 手测：起点 lv=1，目标 lv=2 切比雪夫距离 == 1（4 正向或 4 对角）→ 应可达（若无墙阻挡）
- [ ] 6.5 手测：DDA 路径穿过无地面格子 → 子弹应穿过
- [ ] 6.6 手测：起点东墙存在，目标在东侧 → 应阻挡
- [ ] 6.7 手测：射线穿格子角，角两侧任一有墙 → 应阻挡

## 7. 集成 Smoke Test

- [x] 7.1 在 `main.gd` 临时加调试调用 `BulletRange.new(level_manager).get_reachable_cells(player.grid_pos, player.current_level, 5)`，`print` 结果
- [ ] 7.2 Godot 运行 main 场景，检查输出格子数和分布是否合理
- [ ] 7.3 移除临时调试代码
