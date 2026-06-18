## Why

战棋游戏需要物品系统来支撑装备、消耗品、材料等玩法。当前项目没有物品系统，也没有启动流程（直接进入 Main 场景）。需要建立物品数据框架和启动场景，为后续装备、背包、商店等功能打基础。

## What Changes

- 新增物品配置系统：JSON 文件存储物品 const 数据（id、名称、类型、图标、描述、价格、堆叠、品质）
- 新增 ItemDB Autoload 单例：启动时加载物品配置，提供全局查询接口
- 新增物品运行时类层级：BaseItem（基类）、EquipItem（可装备）、UseItem（可使用）
- 新增 ItemFactory：根据物品类型创建对应运行时实例
- 新增 Boot 场景：游戏启动第一个场景，负责加载配置后跳转
- 新增 MainMenu 场景：简单主菜单，点击"开始游戏"进入 Main
- 修改 project.godot：main_scene 改为 Boot.tscn，注册 ItemDB Autoload

## Capabilities

### New Capabilities

- `item-config`: 物品配置数据管理，JSON 加载与查询
- `item-runtime`: 物品运行时类层级（BaseItem/EquipItem/UseItem）与工厂
- `boot-scene`: 启动场景与主菜单，配置加载与场景流转

### Modified Capabilities

（无现有 capability 需要修改）

## Impact

- `project.godot`: 新增 Autoload 注册，修改 main_scene
- 新增目录: `Data/`, `Items/icons/`
- 新增脚本: `item_db.gd`, `item_factory.gd`, `base_item.gd`, `equip_item.gd`, `use_item.gd`, `boot.gd`, `main_menu.gd`
- 新增场景: `Boot.tscn`, `MainMenu.tscn`
- 现有 `main.tscn` 和 `main.gd` 不需要修改
