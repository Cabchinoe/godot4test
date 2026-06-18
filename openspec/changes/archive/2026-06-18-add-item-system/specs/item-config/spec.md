## ADDED Requirements

### Requirement: Item JSON configuration file
系统 SHALL 提供 `res://Data/items.json` 文件存储所有物品 const 数据。JSON 格式为数组，每个元素包含字段：id (string), name (string), type (string 枚举), icon (string res:// 路径), description (string), price (int), stackable (bool), max_stack (int), quality (string "S"/"A"/"B"/"C"/"D")。

#### Scenario: JSON 文件存在且格式正确
- **WHEN** 系统启动并加载 `res://Data/items.json`
- **THEN** JSON 解析成功，返回物品数据数组

#### Scenario: JSON 文件缺失
- **WHEN** `res://Data/items.json` 不存在
- **THEN** 系统打印错误信息，不崩溃，ItemDB 保持空

### Requirement: Item type enumeration
物品类型 SHALL 为枚举：WEAPON, AMMO, HELMET, ARMOR, CHESTRIG, BACKPACK, MATERIAL, COLLECTIBLE, CONSUMABLE。JSON 中 type 字段 MUST 使用这些字符串值。

#### Scenario: 有效类型值
- **WHEN** JSON 中 type 为 "WEAPON"
- **THEN** 系统识别为武器类型

#### Scenario: 无效类型值
- **WHEN** JSON 中 type 为 "INVALID_TYPE"
- **THEN** 系统打印警告，跳过该物品

### Requirement: ItemDB Autoload singleton
系统 SHALL 提供 ItemDB 作为 Autoload 单例，启动时加载物品配置，提供全局查询接口。

#### Scenario: 启动时加载配置
- **WHEN** 游戏启动，Boot 场景调用 `ItemDB.load_from_file(path)`
- **THEN** 所有物品数据加载到内存，可通过 `get_item(id)` 查询

#### Scenario: 查询存在的物品
- **WHEN** 调用 `ItemDB.get_item("weapon_pistol_01")`
- **THEN** 返回该物品的 Dictionary 数据

#### Scenario: 查询不存在的物品
- **WHEN** 调用 `ItemDB.get_item("nonexistent")`
- **THEN** 返回 null

#### Scenario: 按类型查询物品
- **WHEN** 调用 `ItemDB.get_items_by_type("WEAPON")`
- **THEN** 返回所有武器类型物品的数组

### Requirement: Quality color mapping
系统 SHALL 提供品质到颜色的映射，用于 UI 显示。S=暗红, A=暗金, B=暗紫, C=暗蓝, D=暗绿，颜色纯度不高。

#### Scenario: 获取品质颜色
- **WHEN** 调用 `ItemDB.get_quality_color("S")`
- **THEN** 返回 Color(0.72, 0.28, 0.28)

#### Scenario: 无效品质值
- **WHEN** 调用 `ItemDB.get_quality_color("X")`
- **THEN** 返回默认灰色
