## 1. 存档数据模型

- [x] 1.1 创建 `Script/save/save_data.gd`：SaveData Resource（version, slot_id, timestamp, days, player/inventory/quest/story 子数据引用）
- [x] 1.2 创建 `Script/save/player_save_data.gd`：PlayerSaveData Resource（level, move_range）
- [x] 1.3 创建预留的空 Resource：InventorySaveData、QuestSaveData、StorySaveData
- [x] 1.4 创建 `Script/save/slot_info.gd`：SlotInfo RefCounted（slot_id, exists, timestamp, days, summary）

## 2. SaveProvider 基类

- [x] 2.1 创建 `Script/save/save_provider.gd`：SaveProvider RefCounted 基类，定义 write_to/read_from/get_provider_name 虚方法

## 3. SaveManager Autoload

- [x] 3.1 创建 `Script/save/save_manager.gd`：实现 SLOT_COUNT=10、save/load/delete_slot/list_slots/slot_exists/register_provider
- [x] 3.2 实现 Resource 文件读写逻辑（user://saves/slot_<id>/save.res）
- [x] 3.3 实现版本检查与 _migrate() 预留入口
- [x] 3.4 在 project.godot 注册 SaveManager 为 Autoload

## 4. PlayerSaveProvider

- [x] 4.1 创建 `Script/save/providers/player_save_provider.gd`：实现 write_to（从 Unit 读数据写入 PlayerSaveData）和 read_from（从 PlayerSaveData 写回 Unit）

## 5. 基地场景

- [x] 5.1 创建 `Base.tscn`：复制 main.tscn 的地图结构（Ground10/Ground20 + obstacle + HUD）、玩家、Camera2D
- [x] 5.2 创建 `Script/base.gd`：初始化 LevelManager + Player（AP=50），实现移动/寻路高亮/相机拖拽逻辑（从 main.gd 复制，去掉回合控制）
- [x] 5.3 添加 UILayer：TopBar（玩家信息）、ActionButtons（存档/读档/进入战斗/返回主菜单）
- [x] 5.4 实现"进入战斗"按钮 → change_scene_to_file("res://main.tscn")
- [x] 5.5 实现"返回主菜单"按钮 → change_scene_to_file("res://MainMenu.tscn")
- [x] 5.6 修改 main_menu.gd：新游戏跳转改为 Base.tscn（Boot 保持为 main_scene）

## 6. 存档 UI

- [x] 6.1 创建 `Script/save/ui/save_slot_item.tscn` + `save_slot_item.gd`：单槽位 UI 组件（槽位编号、摘要、保存/读取/删除按钮）
- [x] 6.2 创建 `Script/save/ui/save_load_ui.tscn` + `save_load_ui.gd`：存档面板，包含 10 个槽位列表 + 返回按钮
- [x] 6.3 实现保存逻辑：调用 SaveManager.save(slot_id)，刷新 UI
- [x] 6.4 实现读取逻辑：调用 SaveManager.load(slot_id)，关闭 UI
- [x] 6.5 实现删除逻辑：确认提示 → SaveManager.delete_slot(slot_id)，刷新 UI
- [x] 6.6 将存档 UI 集成到 Base.tscn 的 UILayer 中

## 7. Main 场景适配

- [x] 7.1 修改 `Script/main.gd`：_ready() 中检查 SaveManager 是否有当前数据，有则从存档初始化玩家状态
