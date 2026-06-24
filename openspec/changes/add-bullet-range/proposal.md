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

## Impact

- 新增文件: `Script/bullet_range.gd`
- 不修改 `Pathfinder`，但复用其 `LevelManager` 和 `wall_block` 位掩码定义
- `main.gd` 后续可用于高亮子弹射程（不在本次变更范围内，由后续 UI 集成处理）
