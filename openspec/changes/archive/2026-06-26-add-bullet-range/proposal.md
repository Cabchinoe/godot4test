## Why

当前 `Pathfinder` 用 BFS 计算角色可移动范围，但无法判断角色子弹能打到哪些格子。子弹是直线弹道，受墙体 `wall_block`、放置层 `obstacle` 阻挡，还要考虑跨 level 的高低差规则。BFS 不适合这个场景，需要独立的射线检测系统。

## What Changes

- 新增 `BulletRange` 类，独立于 `Pathfinder`，专门计算子弹可达格子
- 使用 DDA (Digital Differential Analyzer) 射线算法逐格追踪子弹弹道
- 支持任意射程参数（从武器或角色属性传入）
- 支持跨 level 规则:
  - 平射（同 level）：标准 DDA
  - 高打低：路径上所有格 level ≤ 目标 level，子弹"穿过"虚空格子
  - 低打高：目标必须在起点相邻格（距离 1）
- 阻挡检测:
  - 离开和进入格子时按 DDA 实际跨越的边检查 `wall_block` 方向位
  - 进入格子时检查 `obstacle.can_walk`
  - 路径上 level 高于子弹旅行 level 的格子视为阻挡

## Capabilities

### New Capabilities
- `bullet-range`: 计算角色子弹从指定起点可命中的所有格子，处理墙体阻挡、放置物阻挡及多 level 地图规则

### Modified Capabilities
（无，BFS 寻路逻辑不变）

## Phase 2 改进（全射程可视化）

- 翻 Decision 8：候选目标重新由 bbox fan-out 生成，而非外部 unit 列表
- 重命名主入口 `get_targetable_cells` → `get_reachable_cells`
- 参数 `targetable_cells` → `unit_cells`，仅承担"动态阻挡 + 自身可命中"语义，不再充当候选源
- 返回值包含全部射程内可命中格（空地 + unit 所在格）
- main.gd 攻击模式渲染两种底色：
  - 灰色 = 子弹能到的空地
  - 浅绿 = 上面站着 unit 的格
  - hover 浅绿格时显示枪线，hover 灰格不显示

## Impact

- 新增文件: `Script/bullet_range.gd`
- 不修改 `Pathfinder`，但复用其 `LevelManager` 和 `wall_block` 位掩码定义
- `main.gd` 攻击模式 HUD 渲染逻辑变更，hover 行为变更
- HUD tileset 新增第二个 atlas tile（浅绿底）；纹理拼成 2×1 PNG，atlas (0,0) = 灰、(1,0) = 浅绿
