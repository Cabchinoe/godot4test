## 1. LevelManager 实现

- [x] 1.1 创建 `Script/level_manager.gd`，定义 LevelManager 类
- [x] 1.2 实现 levels Dictionary 存储每层 ground/obstacle layer 和 y_offset
- [x] 1.3 实现 `get_layer(level, type)` 方法返回对应 TileMapLayer
- [x] 1.4 实现 `get_offset(level)` 方法返回 Y 偏移
- [x] 1.5 实现 `get_all_levels()` 和 `get_max_level()` 方法

## 2. Pathfinder 泛化

- [x] 2.1 修改 Pathfinder 构造函数，接收 LevelManager 替代单个 layer
- [x] 2.2 修改 `is_walkable(grid, level)` 方法，根据 level 查询对应 layer
- [x] 2.3 修改 `can_move(from, to, level)` 方法，添加 level 参数
- [x] 2.4 实现 `is_stairs(grid, level)` 方法，检查 obstacle layer 的 is_stairs custom_data
- [x] 2.5 实现 `get_neighbors(grid, level)` 方法，返回同层四方向 + 楼梯上下邻居
- [x] 2.6 修改 `bfs(start_grid, start_level, max_steps)` 方法，支持多层搜索
- [x] 2.7 修改 `find_path(from_grid, from_level, to_grid, to_level)` 方法，支持多层搜索

## 3. Player 多层支持

- [x] 3.1 在 Unit 类添加 `current_level: int = 1` 变量
- [x] 3.2 修改 `init_unit` 方法，接收 LevelManager 并初始化 pathfinder
- [x] 3.3 修改 `_step_to_next` 方法，处理 level 变化时更新 current_level
- [x] 3.4 修改渲染位置计算，应用 level 对应的 Y 偏移

## 4. Main 集成

- [x] 4.1 在 main.gd 创建 LevelManager 实例，配置 level 1 和 level 2 的 layers
- [x] 4.2 修改 `_ready` 方法，传递 LevelManager 给 player
- [x] 4.3 修改 `_process` 方法，鼠标 grid 转换支持多层
- [x] 4.4 修改 `_unhandled_input` 方法，点击检测遍历所有层选视觉最近
- [x] 4.5 修改 `_show_move_range` 方法，高亮显示对应层的 reachable cells
- [x] 4.6 修改 `_draw_path` 方法，路径绘制支持多层坐标转换

## 5. Tile 数据配置（需手动配置）

- [ ] 5.1 在 TileSet 中为楼梯 tile 添加 `is_stairs` custom_data
- [ ] 5.2 创建 Ground20 和 Ground21 TileMapLayer 节点
- [ ] 5.3 配置 Ground20 的 y_offset 为 -32

## 6. 测试验证（需手动测试）

- [ ] 6.1 测试同层寻路正常
- [ ] 6.2 测试上楼梯寻路（L1 → L2）
- [ ] 6.3 测试下楼梯寻路（L2 → L1）
- [ ] 6.4 测试点击检测在多层场景下正确选择层
- [ ] 6.5 测试人物渲染在楼层切换时 Y 偏移正确
