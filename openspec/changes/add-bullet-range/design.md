## Context

当前项目 `Pathfinder` 用 BFS 计算角色移动范围，复用 `wall_block` 位掩码（北=1, 东=2, 南=4, 西=8）和 `obstacle` 层的 `can_walk` 自定义数据判断格子可走性。`LevelManager` 管理多层地图（每层有 `ground` / `obstacle` / `hud` TileMapLayer，已知约束：每个 2D 格子只属于一个 level）。

子弹射程是直线弹道问题，性质与 BFS 寻路不同：
- 任意角度射线，跨格的方向不固定（不像 BFS 只有四正方向）
- 高低差规则不同（子弹"穿过"虚空，BFS 必须有地面）
- 不需要"到达"，只需"打到"

需独立类 `BulletRange` 处理。

## Goals / Non-Goals

**Goals:**
- 提供独立 `BulletRange` 类，不修改 `Pathfinder`
- 使用 DDA 算法精确追踪射线穿越的格子边
- 复用 `LevelManager` 和 `wall_block` 位掩码语义
- 支持任意射程参数
- 处理 3 种 level 关系：平射 / 高打低 / 低打高

**Non-Goals:**
- 不处理弹道命中目标后的伤害逻辑
- 不处理子弹动画 / 渲染
- 不处理射程内的 UI 高亮（由 main.gd 后续集成）
- 不修改 BFS 寻路或现有移动系统
- 不考虑动态遮挡（如其他单位站位阻挡子弹，本次不实现）

## Decisions

### Decision 1: 使用 DDA 而非 Bresenham 或视线 (LOS) 算法

**选择**: DDA (Digital Differential Analyzer)

**理由**:
- 精确追踪射线跨越每条格子边的顺序，能区分"先跨垂直边"还是"先跨水平边"
- 复用现有 `wall_block` 方向位语义自然
- 简单可控，~80 行 GDScript

**替代方案**:
- *Bresenham 直线算法*: 只输出经过的格子，无法精确告知跨越的是哪条边，对 `wall_block` 检查不友好
- *Shadowcasting / 八分体阴影投射*: roguelike 经典 FOV 算法，更精确但实现复杂，对当前需求过度设计

### Decision 2: 格子坐标系统在格子中心做 DDA

**选择**: 把每个格子视为 1×1 正方形，中心为整数坐标 `(x, y)`，边界在 `x ± 0.5`、`y ± 0.5`

**理由**:
- 算法与渲染像素（16×16）解耦，缩放无关
- 边界 t 计算简化：从中心到下一垂直边的初始距离始终为 `0.5 / |dir.x|`
- 与项目其他地方使用 `Vector2i` 格子坐标一致

### Decision 3: Level 旅行规则

**选择**: 子弹的 `travel_level = target_level`（目标所在 level）

**理由**:
- 高打低：子弹"穿过"虚空往下打，旅行 level = 目标 level，路径上 level 高于 travel_level 的格子（高层地板）形成阻挡，符合视觉直觉
- 平射：travel_level == origin_level，路径上其他 level 的格子有地板自然挡住
- 低打高：单独规则（只能打相邻格），无 DDA

**替代方案**:
- *travel_level 始终 = origin_level*：会导致高打低时被高层地板挡住自己，不合理
- *DDA 中逐步切换 level*：复杂、容易出 bug，且和"每格只属于一个 level"的设定不匹配

### Decision 4: 低打高限制为 8 邻域

**选择**: `target_level > origin_level` 时，目标 MUST 与起点切比雪夫距离 ≤ 1（即起点周围 8 格：4 正向 + 4 对角）

**理由**:
- 视觉合理：从低处向上打只能打到正上方紧邻的高处（贴墙射击），含对角
- 简化算法：避免在 DDA 中跨 level 切换
- 对角情况按跨角规则检查两条边的墙体（起点 origin_level 上的两条出口边 + 目标 target_level 上的两条入口边）

### Decision 5: 虚空格子（无任何 level 有地面）允许子弹穿过

**选择**: `get_level_at(grid) == -1` 时子弹直接穿过该格

**理由**:
- 用户明确指定为方案 B
- 视觉合理：没有地板 = 没有阻挡物
- 简化判断：不需要在虚空格做 wall_block / obstacle 检查（虚空格本就没有这些数据）

### Decision 6: 起点跳过 obstacle/level 检查，但仍检查离开方向的 wall_block

**选择**: 
- 起点 obstacle.can_walk 不检查（角色站这就是可走的）
- 起点 level 不参与"路径 level ≤ travel_level"约束
- 起点的离开方向 wall_block MUST 检查（角色可能贴墙，墙挡子弹离开）

**理由**:
- 用户明确："2.4.1 离开 grid 和进入 grid 要考虑墙体阻挡 wall_block"
- 符合现有 `Pathfinder.can_move()` 对起始格 wall_block 的检查方式

### Decision 7: 跨角处理（t_max_x == t_max_y）

**选择**: 同时跨越垂直边和水平边，两条边的 wall_block 任一被置位即阻挡。墙体查询采用对偶等效：`_has_wall(grid, dir, level)` 同时查 `grid` 自身 `dir` 位和邻格 `grid+dir` 的反方向位。

**理由**:
- 严格的角落穿透检查（避免对角线"漏射"穿墙）
- 与 roguelike FOV 的常见做法一致
- 对偶等效让跨角穿越能正确命中"仅设在对角格上"的墙体（如 (6,6).E 等价于 (7,6).W，无论设在哪边都生效）
- 实现简单：在 DDA 步进时检测 `abs(t_x - t_y) < EPSILON` 单独处理，墙查询统一走 `_has_wall`

**替代方案**:
- *只检查其中一条边*：会出现明显穿墙 bug
- *把跨角拆成两次单边跨越*：增加路径长度且语义不清
- *要求墙体必须双向对偶设置*：制作负担大，对外不友好

### Decision 8: 候选目标由外部传入而非全格枚举

**选择**: `get_targetable_cells(origin, origin_level, max_range, targetable_cells)` 接收外部传入的候选目标列表（通常是其他 unit 所在格），返回其中可被命中的子集。不再做 bounding box 全格 fan-out。

**理由**:
- 实战只需要知道"能打到哪些敌人"，不需要枚举所有空地
- targetable_cells 同时充当"动态阻挡"列表，统一概念
- 性能更好：候选规模 = unit 数（小），而非 (2*range+1)^2
- API 更简洁、语义更清

**替代方案**:
- *fan-out + 单独 occupied 参数*：候选 = 全格、阻挡 = unit 列表，两套概念，复杂
- *拆成两个 API*：维护成本高，UI 层也用不到全格 fan-out

### Decision 9: 动态目标格阻挡只在平射启用

**选择**:
- 平射（同 level）：路径中间在 `targetable_cells` 内 → 阻挡（打到中间的人）
- 高打低：路径中间忽略 `targetable_cells` → 不阻挡
- 低打高：只有 1 步相邻，无中间格，无意义

**理由**:
- 视觉直觉：从高处俯射，前方矮个不挡视线；平视则会被前面的人挡住
- 用户明确诉求
- 简化逻辑：`block_on_unit = (target_level == origin_level)` 一行判断

**实现**:
- `_is_path_clear` 加 `targetable_cells` 和 `block_on_unit` 参数
- 仅对非最后一步 `to_grid` 在 `targetable_cells` 中且 `block_on_unit == true` 时返回 false

### Decision 10: 候选目标自身永远不阻挡自己

**选择**: `_is_path_clear` 中通过 `is_last = (i == path.size() - 1)` 区分目标格与中间格，目标格即使在 `targetable_cells` 中也不阻挡。

**理由**:
- 目标格就是命中对象，把"自己挡住自己"是悖论
- 实现简洁：单个布尔标记区分

## Risks / Trade-offs

| 风险 | 缓解 |
|------|------|
| DDA 在垂直/水平射线（dir.x==0 或 dir.y==0）时除零 | 用 `INF` 表示无穷 t，DDA 步进自然只跨另一方向边 |
| 跨角浮点误差导致跨垂直边/水平边判定不稳定 | 用 `abs(t_x - t_y) < EPSILON` 显式判跨角 |
| 起点对自身格的离开方向检查与角色站立的"先离开再到达"语义冲突 | DDA 步进首步即处理起点离开 wall_block |
| Bounding box 包含很多明显被墙挡的格 | 不优化（射程通常 ≤10，总格数有限） |
| 多 level 楼板规则与未来楼层洞口 / 跳跃打击需求可能冲突 | 当前作用域仅"打到地板"，洞口规则不实现 |
| `get_level_at` 每次遍历所有 level 性能 | level 数量小（当前 2 层），可接受；若扩展可加缓存 |

## Migration Plan

无迁移需求（新增独立类，不修改现有 API）。

部署：
1. 添加 `Script/bullet_range.gd`
2. 由调用方（武器系统 / UI 高亮）按需 `BulletRange.new(level_manager)` 实例化
3. 现有 `Pathfinder` 和 `main.gd` 移动逻辑不变

回滚：删除 `Script/bullet_range.gd`，无外部依赖。

## Open Questions

- **射程是否要按曼哈顿距离 vs 欧氏距离 vs 切比雪夫距离限制？** 当前按切比雪夫（bounding box）截断，子弹的实际"步数"由 DDA 路径长度决定。是否需要额外按欧氏射程裁剪？（暂按 bounding box 实现，后续可加）
- **子弹能否穿过角色 / 单位？** 当前不考虑动态遮挡，未来若需考虑可在 `is_grid_blocked` 中加单位查询。
- **武器是否影响射程曲线？**（如散弹枪近距离命中率高、远距离衰减）本次只关注"能否打到"，不处理命中率。
