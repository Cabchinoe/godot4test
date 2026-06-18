## Context

当前项目是 Godot 4.6 战棋游戏，入口场景为 `main.tscn`，直接进游戏。架构使用纯 GDScript，`class_name` 全局注册，手动 `new()` 实例化。没有物品系统，没有启动流程。

需要建立：
1. 物品配置 + 全局数据访问
2. 运行时物品类层级
3. Boot → MainMenu → Main 启动流程

## Goals / Non-Goals

**Goals:**
- JSON 配置驱动的物品数据管理
- Autoload 单例全局访问物品数据
- 运行时类层级支持装备/使用/普通物品
- 工厂模式根据类型创建实例
- Boot 场景加载配置后跳转主菜单
- 简单主菜单进入 Main

**Non-Goals:**
- 属性加成系统
- 装备槽位逻辑
- 使用效果实现
- 背包 UI
- 地图掉落物
- 存档/读档

## Decisions

### 1. 配置格式：JSON

**选择**: JSON 文件存储物品数据

**理由**: 
- 通用格式，后续可做工具导表（Excel → JSON）
- 易于手动编辑和版本控制
- Godot 内置 `JSON` 类解析

**替代方案**: Godot Resource (.tres) — 编辑器可视化但每个物品一个文件会多

### 2. 全局数据访问：Autoload

**选择**: ItemDB 注册为 Autoload 单例

**理由**:
- 引擎启动自动创建，任何场景直接访问
- 符合 Godot 惯用法
- 与现有 class_name 风格兼容

**替代方案**: 手动单例挂到 tree — 灵活但每个场景要手动获取引用

### 3. 运行时类层级：继承

**选择**: BaseItem → EquipItem / UseItem

```
BaseItem               ← 所有物品基类，持有 item_data + quantity
├── EquipItem          ← WEAPON/AMMO/HELMET/ARMOR/CHESTRIG/BACKPACK
│   └── equip/unequip 框架（无属性加成）
├── UseItem            ← CONSUMABLE
│   └── use 框架（无实际效果）
└── (BaseItem 直接用)   ← MATERIAL/COLLECTIBLE
```

**理由**:
- 类型安全，不同物品有不同行为接口
- 扩展性好，后续加属性加成只需改 EquipItem
- 工厂根据 JSON 的 type 字段创建对应类

### 4. 图标资源关联：路径字符串

**选择**: JSON 存 `res://` 路径字符串，代码 `load()` 获取 Texture2D

**理由**:
- JSON 不能直接引用 Godot 资源
- 路径字符串灵活，改图标只改 JSON
- `load()` 有缓存，不会重复加载

### 5. 品质颜色：低纯度 Color 常量

**选择**: 字典映射品质到 Color

```
S → Color(0.72, 0.28, 0.28)  暗红
A → Color(0.72, 0.58, 0.22)  暗金
B → Color(0.52, 0.28, 0.62)  暗紫
C → Color(0.28, 0.42, 0.68)  暗蓝
D → Color(0.28, 0.58, 0.32)  暗绿
```

**理由**: 纯度不高，做 icon 背景不刺眼，视觉舒适

### 6. 启动流程

**选择**: Boot.tscn → MainMenu.tscn → main.tscn

```
project.godot: run/main_scene = Boot.tscn
               [autoload] ItemDB=*res://Script/item_db.gd

Boot._ready():
  ItemDB.load_from_file("res://Data/items.json")
  get_tree().change_scene_to_file("res://MainMenu.tscn")

MainMenu: Button "开始游戏" → change_scene_to_file("res://main.tscn")
```

## Risks / Trade-offs

**[JSON 无类型]** → 代码里做字段校验，加载时打印错误
**[Autoload 全局状态]** → ItemDB 只读，不存运行时状态，避免污染
**[类层级扩展]** → 现在只搭框架，后续加功能时可能需要重构接口
