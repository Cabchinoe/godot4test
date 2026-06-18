## ADDED Requirements

### Requirement: BaseItem runtime class
系统 SHALL 提供 BaseItem 类作为所有物品的运行时基类。持有 item_data (Dictionary 引用 ItemDB 数据) 和 quantity (int)。提供 get_name(), get_icon(), get_description(), get_price(), get_quality(), get_quality_color(), get_type() 等查询方法。

#### Scenario: 创建 BaseItem 实例
- **WHEN** 通过 ItemFactory 创建物品实例
- **THEN** 返回 BaseItem 或其子类，持有正确的 item_data 和 quantity

#### Scenario: 查询物品属性
- **WHEN** 调用 item.get_name()
- **THEN** 返回 item_data 中的 name 字段

#### Scenario: 获取品质颜色
- **WHEN** 调用 item.get_quality_color()
- **THEN** 返回 ItemDB 中对应品质的 Color

### Requirement: EquipItem class for equippable items
系统 SHALL 提供 EquipItem 类继承 BaseItem，用于 WEAPON/AMMO/HELMET/ARMOR/CHESTRIG/BACKPACK 类型。提供 equip(unit) 和 unequip(unit) 方法框架（当前无属性加成，仅预留接口）。

#### Scenario: 创建 EquipItem
- **WHEN** ItemFactory 创建 type 为 "WEAPON" 的物品
- **THEN** 返回 EquipItem 实例

#### Scenario: 装备物品
- **WHEN** 调用 equip_item.equip(unit)
- **THEN** 方法执行不报错（当前为空实现框架）

#### Scenario: 卸下物品
- **WHEN** 调用 equip_item.unequip(unit)
- **THEN** 方法执行不报错（当前为空实现框架）

### Requirement: UseItem class for consumable items
系统 SHALL 提供 UseItem 类继承 BaseItem，用于 CONSUMABLE 类型。提供 use(unit) 方法框架（当前无实际效果，仅预留接口）。

#### Scenario: 创建 UseItem
- **WHEN** ItemFactory 创建 type 为 "CONSUMABLE" 的物品
- **THEN** 返回 UseItem 实例

#### Scenario: 使用物品
- **WHEN** 调用 use_item.use(unit)
- **THEN** 方法执行不报错（当前为空实现框架）

### Requirement: ItemFactory creates correct class by type
系统 SHALL 提供 ItemFactory，根据物品 type 字段创建对应运行时类。WEAPON/AMMO/HELMET/ARMOR/CHESTRIG/BACKPACK → EquipItem，CONSUMABLE → UseItem，MATERIAL/COLLECTIBLE → BaseItem。

#### Scenario: 工厂创建装备类
- **WHEN** 调用 ItemFactory.create("weapon_pistol_01", 1)，该物品 type 为 "WEAPON"
- **THEN** 返回 EquipItem 实例

#### Scenario: 工厂创建消耗品类
- **WHEN** 调用 ItemFactory.create("medkit_01", 3)，该物品 type 为 "CONSUMABLE"
- **THEN** 返回 UseItem 实例，quantity 为 3

#### Scenario: 工厂创建普通物品
- **WHEN** 调用 ItemFactory.create("material_wood_01", 10)，该物品 type 为 "MATERIAL"
- **THEN** 返回 BaseItem 实例

#### Scenario: 工厂创建不存在的物品
- **WHEN** 调用 ItemFactory.create("nonexistent", 1)
- **THEN** 返回 null，打印错误

### Requirement: Stackable item quantity management
可堆叠物品 SHALL 支持数量管理。stackable 为 true 时，quantity 不超过 max_stack。stackable 为 false 时，quantity MUST 为 1。

#### Scenario: 堆叠物品数量限制
- **WHEN** 创建 max_stack=5 的物品，尝试设置 quantity=10
- **THEN** quantity 被限制为 max_stack (5)

#### Scenario: 非堆叠物品数量
- **WHEN** 创建 stackable=false 的物品
- **THEN** quantity 始终为 1
