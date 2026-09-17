# 《辉石之痕：黎明阵线》项目文档

> *Trace of Pyroxene: Dawn Frontline* —— 项目总览与工程索引。
> 本文记录**当前工程的真实状态**（场景、脚本、数据、资源）与专项文档的分工；玩法、数值与美术规范一律以专项文档为准。

---

## 一、 项目定位

| 项目 | 内容 |
|---|---|
| 名称 | 中文《辉石之痕：黎明阵线》／英文 *Trace of Pyroxene: Dawn Frontline* |
| 类型 | 二次元轻奇幻战棋（SRPG）+ 战区搜打撤（Extraction）+ 基地建设农耕 + 同级物资二合 + 居民援助订单 |
| 基调 | 战后废墟中的生机与救赎；明朗温暖、务实重建，拒绝晦涩谜语人叙事 |
| 主控 | 前哨站指挥官兼后勤长，自休眠舱苏醒后完全失忆，以「带大家活下去」为第一原则 |
| 核心循环 | 战区搜打撤 → 基地建设与生产 → 同级物资二合 → 居民援助订单 → 进入更高阶战区 |
| 引擎 | Godot 4.6（Mobile 渲染管线、Jolt Physics），GDScript |
| 显示 | 视口 1920×1080，`canvas_items` 拉伸；网格瓦片 64×64 像素 |

完整企划、世界观与玩法闭环见 [game_design.md](game_design.md)。

---

## 二、 文档索引

| 文档 | 内容 |
|---|---|
| [game_design.md](game_design.md) | 企划设计书：项目定位、世界观、核心玩法闭环、武器装备与改装系统 |
| [character_design.md](character_design.md) | 干员体系通用规则与核心干员档案（当前：贝妮），含星级/等级成长、武器数值与视觉资产规格 |
| [crafting_design.md](crafting_design.md) | 合成与生产表：Lv0~Lv8 二合树、战场物资包、工厂棋盘、居民订单、交易行 |
| [inventory_workbench_reuse_guide.md](inventory_workbench_reuse_guide.md) | 物品容器工作台的设计、服务层 API、复用路线图与风险点 |
| [battlefield_inventory_implementation_plan.md](battlefield_inventory_implementation_plan.md) | 战场角色面板与临时物资容器（`TemporaryContainer`）的接入方案 |
| [warehouse_art_manifest.md](warehouse_art_manifest.md) | 入仓物品清单、用途与图标目标路径 |
| [inventory_background_colors.md](inventory_background_colors.md) | 物品图标 Lv0~Lv8 背景色（tier）规范与处理流程 |
| `openspec/` | 能力规格（`specs/`）与历次变更归档（`changes/archive/`） |

改动上述任一规范时，需同步更新其声明依赖的文件（例如 tier 色卡对应 `apply_tier_backgrounds*.py` 的 `TIER_COLORS` 与 `doc/assets/tier_bg_palette.png`）。

---

## 三、 场景流程与入口

```
Boot.tscn ──► MainMenu.tscn ──► CommandCenter.tscn（前哨指挥台）
                                    ├── main.tscn          战场（搜打撤）
                                    ├── Warehouse.tscn     仓库工作台
                                    ├── TradingPost.tscn   交易行
                                    └── Base.tscn          旧版基地场景
```

| 场景 | 脚本 | 说明 |
|---|---|---|
| `Boot.tscn` | `Script/boot.gd` | 启动场景：加载 `ItemDB`（`conf/items`）与 `EnemyDB`（`conf/enemies.json`），再跳转主菜单 |
| `MainMenu.tscn` | `Script/main_menu.gd` | 主菜单：随机背景、开始新游戏、继续游戏、存读档界面 |
| `CommandCenter.tscn` | `Script/command_center.gd` | 前哨指挥台：本地时间、信用点/辉石碎片展示、卡片入口。战斗、仓库、交易行已接入；温室／工厂／特勤处卡片已预留但未接场景 |
| `main.tscn` | `Script/main.gd` | 战场场景：回合制战棋、行动点、敌方阶段、战术装备面板 |
| `Base.tscn` | `Script/base.gd` | 旧版基地场景，保留移动与存读档入口 |
| `Warehouse.tscn` | `Script/inventory/warehouse.gd` | 仓库工作台：容器拖拽、装备与武器配件 |
| `TradingPost.tscn` | `Script/trading_post.gd` | 交易行：仅售 Lv1 基础品，用于补缺防卡关 |

自动加载（`project.godot`）：`ItemDB`、`SaveManager`、`EnemyDB`。

---

## 四、 战场场景结构（`main.tscn`）

```
Main (Node2D, y_sort_enabled = true, Script/main.gd)
├── Camera2D                                  ← 拖拽平移
├── Ground10 (TileMapLayer)                   ← 1 层地面（terrain / wall_block）
│   ├── obstacle (TileMapLayer, z_index = 1)  ← 1 层障碍（can_walk / is_stairs）
│   └── HUD (TileMapLayer, z_index = 2)       ← 1 层高亮（moverange / attack_range）
├── Ground20 (TileMapLayer, z_index = 3)      ← 2 层地面（y = -16）
│   ├── obstacle (TileMapLayer, z_index = 4)
│   └── HUD (TileMapLayer, z_index = 5)
├── HUD (TileMapLayer, z_index = 10)          ← 全局高亮层
│   ├── CoverSprite (Line2D, 绿)              ← 移动路径预览
│   └── CoverSprite2 (Line2D, 红)             ← 射击瞄准线
├── Player (Benny, Script/benny.gd, conf/characters/benny.tres)
│   └── Sprite2D (AnimatedSprite2D, offset = (32, 40))
├── Enemies (Node2D)                          ← EnemySpawner 生成的敌方单位
└── UILayer (CanvasLayer, layer = 10)
    └── UIRoot (Control)
        ├── StatusBar            ← APLabel / HPLabel / TurnLabel / EndTurnButton
        ├── ContextMenu          ← 右键行动菜单（attack / end turn / properties）
        └── BattleLoadoutPanel   ← 运行时挂载的战术装备面板
```

- **高亮绘制**：移动范围写入各层 `HUD` 的 `moverange.png`（源 id 0）；攻击范围写入 `attack_range.png`（源 id 1，`(0,0)` 灰 = 范围内无可攻击目标，`(1,0)` 绿 = 可攻击）；路径预览与瞄准线由 `Line2D` 实时绘制。
- **楼层错位**：`LevelManager.add_level(level, ground, obstacle, hud, y_offset)` 注册楼层，1 层偏移 `0`、2 层偏移 `-16`。

---

## 五、 脚本架构

### 战场与单位

| 脚本 | 职责 |
|---|---|
| `Script/main.gd` | 战场主控：状态机、行动菜单、高亮与路径、AP 结算、存档同步、敌方阶段调度 |
| `Script/base.gd` | 旧版基地场景逻辑：选中/移动与存读档入口 |
| `Script/level_manager.gd` | 楼层图层注册与 `y_offset` 查询（ground / obstacle / hud） |
| `Script/pathfinder.gd` | 四向 BFS 与最短路；含墙体方向掩码与楼梯换层规则 |
| `Script/bullet_range.gd` | DDA 弹道检测与射程范围计算 |
| `Script/turn_controller.gd` | 回合与阶段（`PLAYER_PHASE` / `ENEMY_PHASE`）、回合上限与 `game_over` |
| `Script/unit.gd` | `Unit` 基类：动画装配、AP、逐格移动与 `movement_finished` 信号 |
| `Script/player.gd` | `Player`：干员等级、生命、装备与 `CharacterDefinition` 读取 |
| `Script/benny.gd` | 贝妮专属特性【兔步敏捷】的额外 AP 与冷却实现 |
| `Script/character_definition.gd` | 干员定义资源：稀有度、外观、允许武器、默认装备、Lv1~Lv60 逐级数值 |
| `Script/enemy_db.gd` / `Script/enemy_spawner.gd` / `Script/enemy_ai.gd` | 敌人数据加载、按规则生成、追击与近身寻路 |
| `Script/ui/battle_context_menu.gd` | 右键行动菜单（攻击 / 结束回合 / 属性） |

### 物品与容器

| 脚本 | 职责 |
|---|---|
| `Script/item/item_db.gd` | 物品总表（自动加载）：按类型读取 `conf/items/*.json` 并校验图标 |
| `Script/item/item_factory.gd` / `base_item.gd` / `equip_item.gd` / `use_item.gd` / `weapon.gd` / `weapon_attachment.gd` | 物品模型与实例化 |
| `Script/inventory/warehouse_service.gd` | **唯一物品入口**（静态 API）：查询、容器移动、装备与配件替换、临时容器、容量检查 |
| `Script/inventory/item_container.gd` / `item_location.gd` / `container_spec.gd` / `transfer_policy.gd` | 容器抽象、位置值对象、容器参数与双击/拖拽规则配置 |
| `Script/inventory/warehouse_container.gd` / `backpack_container.gd` / `equipment_container.gd` / `weapon_attachment_container.gd` / `temporary_container.gd` | 具体容器适配器（仓库 / 背包 / 装备 / 配件 / 战场临时） |
| `Script/inventory/inventory_index.gd` | `uid → item`、仓库格位与背包格位索引缓存 |
| `Script/inventory/ui/*` | 工作台 UI：`inventory_slot`、`inventory_grid`、`item_info_panel`、`operator_equipment_slot`、`weapon_attachment_slot`、`base_storage_screen`、`battle_loadout_panel` |

### 存档与场景

| 脚本 | 职责 |
|---|---|
| `Script/save/save_manager.gd` | 10 个存档槽位读写、版本迁移、当前存档缓存（自动加载） |
| `Script/save/save_data.gd` / `player_save_data.gd` / `inventory_save_data.gd` / `quest_save_data.gd` / `story_save_data.gd` / `save_provider.gd` | 存档数据模型与场景侧 Provider |
| `Script/boot.gd` / `main_menu.gd` / `command_center.gd` / `trading_post.gd` | 启动、主菜单、前哨指挥台、交易行 |

---

## 六、 网格、坐标与行走判定

### 1. 三级坐标

| 坐标 | 说明 | 转换 |
|---|---|---|
| 世界坐标 | `get_global_mouse_position()` 返回值 | — |
| TileMap 局部坐标 | `map_to_local()` / `local_to_map()` 使用 | `(world - layer.global_position) / layer.scale` |
| 网格坐标 | 逻辑坐标，如 `(3, 5)`，与楼层 `level` 成对使用 | `layer.local_to_map(local)` |

### 2. 关键转换公式（`Script/unit.gd::_step_to_next`）

```
网格 → 世界：
  local = ground.map_to_local(grid)
  world = ground.to_global(local)
  world.y += level_manager.get_offset(level)        # 楼层视觉错位（1 层 0、2 层 -16）

角色落位：
  global_position = world - sprite.offset * scale   # 贝妮 offset = (32, 40)，scale = 1

世界 → 网格（点击检测，逐楼层尝试后取 Y 距离最近者）：
  local = ground.to_local(mouse_world)
  grid  = ground.local_to_map(local)
```

### 3. 地形数据（TileSet Custom Data Layers）

| 图层 | 自定义数据 | 类型 | 含义 |
|---|---|---|---|
| 地面 `Ground1x` | `terrain` | int | `0` = 可走；非 `0` = 不可走（水面、山体等） |
| 地面 `Ground1x` | `wall_block` | int | 方向墙掩码：`1`=上、`2`=右、`4`=下、`8`=左；对应方向进出被阻挡 |
| 障碍 `Ground1x/obstacle` | `can_walk` | bool | 为 `false` 时该格不可通行（家具、掩体、结构） |
| 障碍 `Ground1x/obstacle` | `is_stairs` | bool | 为 `true` 时该格是楼梯，可通往上层 |

### 4. 行走与换层判定（`Script/pathfinder.gd`）

```
is_walkable(grid, level):
  1. 地面层必须有 tile，且 terrain == 0
  2. 障碍层若有 tile，则 can_walk 必须为 true
  3. 同层该格不得已被其他单位占用
can_move(from, to, level):
  在 is_walkable 基础上，检查 from 的 wall_block 是否挡住离开方向、to 的 wall_block 是否挡住进入方向
get_neighbors:
  四方向同层移动；当前格 is_stairs 时可向上一层相邻可走格；下层相邻格 is_stairs 时可下楼
```

---

## 七、 战斗流程与规则（当前实现）

状态机：`IDLE` → `MOVE_STATE` → `MENU_STATE` → `ATTACK_STATE`（`Script/main.gd::State`）。任何状态切换都会清空高亮、路径与悬停提示。

1. **选中**：左键点击主角 → 进入 `MOVE_STATE`；以当前 AP 为步数做 BFS，在 `HUD` 层铺出可达格。
2. **预览**：悬停可达格时实时 `find_path` 并以绿色 `Line2D` 绘制路径。
3. **移动**：点击可达格 → 按 `路径节点数 - 1` 扣除 AP → 角色逐格移动（默认 0.15 秒/格），移动结束后按剩余 AP 重算范围。
4. **行动菜单**：右键主角 → `MENU_STATE`，弹出「攻击 / 结束回合 / 属性」；攻击条目显示武器 AP 消耗，AP 不足时数字变红且不可点击。
5. **攻击**：进入 `ATTACK_STATE` 后由 `BulletRange` 计算射程内格子并绘制弹道，点击目标扣除武器 `attack_cost`。**当前仅完成弹道计算与打印，伤害与命中结算尚未接入。**
6. **敌方阶段**：结束回合按钮（或菜单项）→ `TurnController.end_turn()` → 敌方阶段对每个 `enemy` 单位调用 `start_turn()` 并由 `EnemyAI` 逐个追击、近身；敌方阶段按住空格键可加速移动动画。敌人由 `EnemySpawner` 在战场 `_ready` 时按规则生成。
7. **回合上限**：达到 `TurnController.max_turns`（当前 10）触发 `game_over`，冻结战斗输入。

### 行动点（AP）

- 单位回合开始时 `action_points` 重置为 `ap_max`；`ap_max` 由 `CharacterDefinition` 中当前等级的记录决定。
- 移动 1 格 = 1 AP；普通攻击 = 武器 `attack_cost`（贝妮三把武器均为 1 AP）。
- 贝妮【兔步敏捷】：回合开始时若特性不在冷却中，额外获得 1 点**兔步额外 AP**；该点数被实际消耗后进入 3 回合冷却，回合结束仍未消耗则清空且不触发冷却。

### 敌人

- 配置：`conf/enemies.json`（当前仅 `infantry`「鹰酱大兵」，`ap_max = 4`，外观 `Unit/eagle_soldier_sprites.tres`）。
- 行为：`EnemyAI` 选取最近玩家单位，寻路至其相邻格并按剩余 AP 移动，不进行攻击。

---

## 八、 物品、容器与存档

### 1. 物品配置（`conf/items/*.json`，共 8 类 29 条）

| 文件 | 条数 | 类型 | 类型专属字段 |
|---|---:|---|---|
| `weapon.json` | 3 | `WEAPON` | `subtype`、`range`、`attack_power`、`attack_cost`、`attachment_slots` |
| `weapon_attachment.json` | 4 | `WEAPON_ATTACHMENT` | `slot`、`compatible_weapon_ids`、`stat_modifiers` |
| `armor.json` | 3 | `ARMOR` | `defense`、`can_equip` |
| `helmet.json` | 8 | `HELMET` | `defense`、`can_equip` |
| `backpack.json` | 4 | `BACKPACK` | `battle_grid_width`、`battle_grid_height`、`can_equip` |
| `consumable.json` | 2 | `CONSUMABLE` | `battle_effect_id` |
| `material.json` | 4 | `MATERIAL` | `merge_level` |
| `collectible.json` | 1 | `COLLECTIBLE` | — |

公共字段：`id`、`name`、`type`、`icon`、`description`、`price`、`merge_level`。`merge_level` 与 [inventory_background_colors.md](inventory_background_colors.md) 的 tier 色卡一致（无后缀按 Lv0 处理）。

### 2. 容器与物品实例（详见 [inventory_workbench_reuse_guide.md](inventory_workbench_reuse_guide.md)）

- 物品实例由 `InventorySaveData.warehouse_items` 唯一持有，记录 `uid` / `id` / `position`；仓库默认 10×10（100 格）。
- `position >= 0` 表示物品位于仓库格；`position = -1` 表示物品由装备、背包或配件容器引用，归属必须查 `operator_loadouts`。
- 装备四槽为 `weapon` / `helmet` / `armor` / `backpack`；背包内容按 `backpack_items[backpack_uid][位置] = uid` 保存。
- 战场临时物资使用 `TemporaryContainer` 会话缓存，**不写入存档**，关闭搜索或战斗结束时丢弃未拾取实例。
- 所有写操作必须经过 `WarehouseService` 并递增 `runtime_revision`；UI 不得直接修改存档字典。
- 护甲与头盔带耐久：`max_armor` / `current_armor`，处于破损状态的装备不可参与二合（`can_merge_item`）。

### 3. 存档（`Script/save/`）

| 项 | 内容 |
|---|---|
| 存档位置 | `user://saves/save.res`，共 10 个槽位 |
| `SaveData`（version 5） | `slot_id`、`timestamp`、`days`、`player`、`inventory`、`quest`、`story` |
| `PlayerSaveData`（version 4） | `operator_id`、`operator_level`、`experience`、`credits`、`owned_item_ids`、`equipped_item_ids`、`unlocked_flags` |
| `InventorySaveData` | `warehouse_level`、`warehouse_items`、`operator_loadouts`、`initial_content_created`、`starter_content_version`、`runtime_revision` |
| 登记方式 | 场景通过 `SaveProvider`（如 `PlayerSaveProvider`）注册到 `SaveManager`，进入场景时 `reload_current()` |

> `starter_content_version` 是开发期的初始物资注入开关，正式版本应移入开发工具或显式 debug 项（见复用指南「当前实现的风险点」）。

---

## 九、 美术与资源配置

| 目录 | 内容 |
|---|---|
| `Art/backgrounds/` | 主菜单背景（`main_menu_pyroxene_dawn.jpg` 为贝妮形象的权威视觉基准） |
| `Art/characters/benny/` | 贝妮立绘 `benny_base_01.png`（896×1200）与战斗像素图 `benny_idle/walk/aim.png`（64×80/帧） |
| `Art/source/` | 绿幕母版与生成源素材 |
| `Art/tilesets/urban_night/` | 地面、结构、道具图集（atlas），附 `README.md` 说明 |
| `Art/ui/` | 界面素材 |
| `HUD/` | 范围高亮瓦片：`moverange.png`、`attack_range.png` |
| `MAP/` | 旧版瓦片图集 `urban.png`、`indoor.png` |
| `Items/icons/` | 9 个分类、95 张物品图标 PNG，背景色按 [inventory_background_colors.md](inventory_background_colors.md) 生成 |
| `doc/assets/` | 文档配图（如 `tier_bg_palette.png` 色板） |

- 战斗像素图目前按 [character_design.md](character_design.md)「3.3 战斗像素形象」属**待重制占位**，重制时须与立绘共用配色板与识别特征。
- 物品清单与图标目标路径以 [warehouse_art_manifest.md](warehouse_art_manifest.md) 为准。

---

## 十、 当前进度与后续开发

### 已完成

- 多楼层地图：渲染层级、`y_offset` 错位、楼层点击检测。
- 多楼层寻路：四向 BFS、墙体方向掩码、楼梯上下楼、单位占位。
- 行动点与回合控制：玩家/敌方阶段、回合上限、结束回合按钮、HUD 状态栏。
- 敌人阵营：`EnemyDB` / `EnemySpawner` / `EnemyAI`。
- 弹道与射程：`BulletRange` 的 DDA 检测与攻击范围高亮。
- 相机拖拽平移、移动路径预览、攻击瞄准线、敌方阶段加速。
- 物品系统：8 类配置、`ItemDB` 校验、图标 tier 背景色规范。
- 仓库工作台：容器抽象、拖拽/双击规则、装备与武器配件、背包网格、护甲耐久与破损状态。
- 存档系统：10 槽位、版本迁移、`SaveProvider` 机制。
- 场景与角色：主菜单、前哨指挥台、交易行；贝妮 `CharacterDefinition`（Lv1~Lv60）与【兔步敏捷】特性实现。

### 待开发

- **战区搜打撤**：撤离点与时限、战利品容器、战场结算（当前攻击仅算弹道，无伤害、命中与撤离判定）。
- **基地生产**：温室种植、工厂二合棋盘、居民援助订单、特勤处（`CommandCenter` 卡片已预留）。
- **战斗深化**：距离档位与命中率/伤害、护甲耐久消耗、战术道具 `battle_effect_id` 效果。
- **剧情与表现**：对话系统与立绘表情差分（`benny_face_<emotion>_01.png`）、贝妮战斗像素重制。
- **经济与抽卡**：辉石碎片与共鸣池、订单声望体系。
- **多干员支持**：`WarehouseService.OPERATOR_ID` 目前固定为 `benny`，需按当前选中干员参数化。
