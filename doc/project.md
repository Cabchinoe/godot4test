# 战棋游戏项目文档

## 项目概述

基于 Godot 4 的回合制战棋游戏（SRPG），正交网格地图，支持多高度层级。

- **引擎**: Godot 4.6
- **渲染**: 2D 正交（Square TileMap）
- **网格尺寸**: 16×16 像素（逻辑），显示缩放 4 倍（64×64 视觉）

---

## 场景结构

```
Main (Node2D)                          ← 根节点, Y Sort Enabled
├── Ground10 (TileMapLayer)            ← 地面层, scale=(4,4)
│   └── TileSet: urban (custom_data: terrain, height)
── Ground11 (TileMapLayer)            ← 障碍/高度层, scale=(4,4), z_index=1
│   └── TileSet: indoor (custom_data: height)
── Cover1 (TileMapLayer)              ← 高亮覆盖层, scale=(4,4)
│   └── CoverSprite (Sprite2D)         ← 鼠标悬停指示器
└── Player (Node2D)                    ← 角色, scale=(4,4), z_index=1
    └── Sprite2D                       ← 角色贴图, offset=(8,8), region=16×16
```

---

## 脚本文件

### `main.gd` — 主场景控制

| 功能 | 说明 |
|------|------|
| `_ready()` | 初始化高亮层、悬停精灵 |
| `_process()` | 鼠标悬停检测，显示 CoverSprite |
| `_unhandled_input()` | 点击角色显示范围，点击目标格移动 |
| `_show_move_range()` | BFS 计算可走范围，在 Cover1 上绘制高亮 |
| `_bfs()` | 广度优先搜索，从角色位置扩散 max_steps 步 |
| `_is_walkable()` | 判断格子是否可走（terrain=0 且 height=0） |
| `_find_path()` | BFS 最短路径，返回路径数组 |

### `unit.gd` — 角色类（class_name: Unit）

| 属性 | 说明 |
|------|------|
| `move_range` | 可移动步数，默认 5 |
| `grid_pos` | 当前网格坐标 |
| `move_path` | 移动路径队列 |
| `move_interval` | 每格移动间隔，默认 0.15 秒 |

| 方法 | 说明 |
|------|------|
| `_process()` | 计时器驱动逐格移动 |
| `_step_to_next()` | 跳到路径下一个格子，修正 Sprite2D 偏移 |
| `set_move_path()` | 接收路径，开始移动 |

---

## 坐标系统

### 三层坐标

| 坐标 | 说明 | 转换 |
|------|------|------|
| **世界坐标** | `get_global_mouse_position()` 返回 | — |
| **TileMap 局部坐标** | `map_to_local()` / `local_to_map()` 使用 | `(world - layer.global_position) / layer.scale` |
| **网格坐标** | 逻辑坐标，如 `(3, 5)` | `local_to_map(local)` |

### 关键转换公式

```
世界 → 网格:
  local = (world - ground_layer.global_position) / ground_layer.scale
  grid = ground_layer.local_to_map(local)

网格 → 世界:
  local = ground_layer.map_to_local(grid)
  world = ground_layer.to_global(local)

角色位置修正:
  global_position = world_pos - sprite_offset
  sprite_offset = Vector2(8, 8) * player.scale  // = (32, 32)
```

### 为什么需要转换

- `Ground10` 的 `position = (0, 0)`，`scale = (4, 4)`
- `Player` 的 `scale = (4, 4)`，Sprite2D 的 `offset = (8, 8)`
- Sprite2D 在 Player 局部空间的偏移 `(8, 8)` 经 scale 放大后实际世界偏移为 `(32, 32)`
- 角色 `global_position` 必须减去这个偏移，视觉中心才能对准网格

---

## 地形数据

通过 TileSet 的 **Custom Data Layers** 存储：

| 层 | 名称 | 类型 | 含义 |
|----|------|------|------|
| custom_data_0 | `terrain` | int | 0=可走, 1=不可走（水/山等） |
| custom_data_1 | `height` | int | 0=地面, 1+=高地/障碍 |

### 行走判定逻辑

```
_is_walkable(grid):
  1. ground_layer 的 terrain != 0 → 不可走
  2. obstacle_layer 有格子且 height != 0 → 不可走
  3. 以上都通过 → 可走
```

---

## 核心玩法流程

```
1. 点击角色所在格子
   → player_selected = true
   → BFS 扩散 move_range 步
   → Cover1 绘制绿色高亮

2. 鼠标悬停高亮格子
   → CoverSprite 显示在该格子上（半透明）

3. 点击目标高亮格子
   → BFS 找最短路径
   → 角色沿路径逐格跳动（每格 0.15 秒）
   → 清除高亮，player_selected = false

4. 点击其他位置
   → 取消选择，清除高亮
```

---

## 素材来源

| 文件 | 来源 | 用途 |
|------|------|------|
| `urban.png` | Kenney RPG Urban Pack | 地面瓦片 |
| `indoor.png` | Kenney Roguelike Indoors | 障碍/室内瓦片 |
| `player.png` | 程序生成（Pillow） | 角色像素图 16×16 |
| `highlight.png` | 程序生成（Pillow） | 高亮/悬停 16×16 半透明绿 |

---

## 待开发

- [ ] 行动点（AP）系统
- [ ] 攻击/战斗系统
- [ ] 敌方 AI
- [ ] 回合管理（玩家回合 / 敌方回合）
- [ ] 多单位支持
- [ ] 高度层级移动规则（上下坡消耗）
- [ ] UI（血条、行动面板、回合提示）
- [ ] 存档系统
