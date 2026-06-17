## Why

当前地图系统只支持单层（Ground10 + Ground11）。需要支持多层地图，让人物可以通过楼梯在不同楼层之间移动，实现立体地图效果。

## What Changes

- 新增 LevelManager 独立类，管理多层 ground/obstacle layer 及 Y 偏移
- Pathfinder 泛化为多层寻路，支持 (grid, level) 空间搜索
- 楼梯 tile 放在 obstacle layer，custom_data 标记 `is_stairs`
- 寻路规则：楼梯格可上到周围上层可走格子；周围下层是楼梯可下
- Player 新增 `current_level` 变量，渲染时根据楼层应用 Y 偏移
- 点击检测支持多层，按视觉距离选择目标层

## Capabilities

### New Capabilities
- `level-manager`: 管理多层地图数据，提供 layer 访问和 Y 偏移
- `multi-floor-pathfinding`: 多层寻路，支持楼梯上下楼
- `multi-floor-rendering`: 根据楼层渲染人物位置，处理 Y 偏移
- `multi-floor-click-detection`: 多层点击检测，选择视觉最近的层

### Modified Capabilities

## Impact

- `Script/main.gd`: 集成 LevelManager，修改点击检测逻辑
- `Script/pathfinder.gd`: 泛化为多层寻路
- `Script/unit.gd`: 新增 current_level，修改渲染位置计算
- 新增 `Script/level_manager.gd`
- Tile 数据：楼梯 tile 需要 `is_stairs` custom_data
