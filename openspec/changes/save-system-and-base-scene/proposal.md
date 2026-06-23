## Why

游戏缺少存档系统，无法持久化玩家进度。同时缺少基地场景作为对局外的中枢，当前主菜单直接进入对局（main），没有中间过渡场景来管理存档、仓库、任务等功能。

## What Changes

- 新增 **SaveManager**（Autoload），提供多槽位（10个）存档/读档/删除能力
- 新增 **SaveProvider 注册机制**，各系统通过 Provider 模式注册自己的序列化逻辑，SaveManager 不硬编码依赖
- 新增 **SaveData Resource** 体系，包含 PlayerSaveData 及未来可扩展的 InventorySaveData、QuestSaveData、StorySaveData 等
- 新增 **存档 UI**，支持槽位选择、保存、读取、删除操作，显示槽位摘要信息
- 新增 **Base 场景**（基地），作为默认入口场景，复制 main 的地图和玩家，提供自由移动（AP=50）+ 寻路高亮，不含回合控制
- 修改 **project.godot**，主场景改为 Base.tscn，注册 SaveManager autoload
- 修改 **main.gd**，支持从 SaveManager 读取玩家初始状态

## Capabilities

### New Capabilities
- `save-manager`: 存档管理核心，包含多槽位存取删、Provider 注册机制、版本迁移入口
- `save-data-model`: SaveData Resource 及子数据容器定义（PlayerSaveData 等）
- `save-ui`: 存档/读档界面，槽位列表、保存/读取/删除操作
- `base-scene`: 基地场景，自由移动 + 寻路高亮 + 存档 UI 入口 + 进入对局入口

### Modified Capabilities
- `action-points`: Base 场景中 AP 设为 50（无限制），main 场景行为不变
- `turn-controller`: main 场景保留回合控制，Base 场景不使用 TurnController

## Impact

- **新增文件**: `Script/save/` 目录下约 10 个文件，`Base.tscn` + `base.gd`
- **修改文件**: `project.godot`（主场景 + autoload），`main.gd`（支持从存档初始化）
- **依赖**: 无外部依赖，纯 GDScript + Godot Resource 系统
- **现有系统**: Unit、LevelManager、Pathfinder 保持不变，仅 main.gd 增加存档初始化逻辑
