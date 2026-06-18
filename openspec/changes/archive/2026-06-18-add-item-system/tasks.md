## 1. 目录与文件结构

- [x] 1.1 创建 `Data/` 目录
- [x] 1.2 创建 `Items/icons/` 目录
- [x] 1.3 创建 `Data/items.json` 示例配置文件（包含各类型示例物品）

## 2. ItemDB Autoload 单例

- [x] 2.1 创建 `Script/item_db.gd`，实现 class_name ItemDB
- [x] 2.2 实现 `load_from_file(path)` 方法：解析 JSON，校验字段，存入 Dictionary
- [x] 2.3 实现 `get_item(id)` 方法：返回物品数据或 null
- [x] 2.4 实现 `get_items_by_type(type)` 方法：返回指定类型物品数组
- [x] 2.5 实现 `get_quality_color(quality)` 方法：返回品质对应 Color
- [x] 2.6 在 `project.godot` 注册 ItemDB 为 Autoload

## 3. 物品运行时类

- [x] 3.1 创建 `Script/base_item.gd`，实现 BaseItem 类（持有 item_data + quantity，提供查询方法）
- [x] 3.2 创建 `Script/equip_item.gd`，实现 EquipItem 继承 BaseItem（equip/unequip 框架）
- [x] 3.3 创建 `Script/use_item.gd`，实现 UseItem 继承 BaseItem（use 框架）

## 4. ItemFactory

- [x] 4.1 创建 `Script/item_factory.gd`，实现 ItemFactory 类
- [x] 4.2 实现 `create(id, quantity)` 方法：根据 type 创建对应类实例
- [x] 4.3 实现堆叠数量限制逻辑

## 5. Boot 场景

- [x] 5.1 创建 `Script/boot.gd`，实现 _ready() 加载配置并跳转 MainMenu
- [x] 5.2 创建 `Boot.tscn` 场景（空节点 + boot.gd 脚本）

## 6. MainMenu 场景

- [x] 6.1 创建 `Script/main_menu.gd`，实现"开始游戏"按钮跳转 main.tscn
- [x] 6.2 创建 `MainMenu.tscn` 场景（Label 标题 + Button）

## 7. project.godot 配置

- [x] 7.1 修改 `run/main_scene` 为 Boot.tscn 的 uid
- [x] 7.2 确认 Autoload 注册正确

## 8. 验证

- [x] 8.1 运行游戏，验证 Boot → MainMenu → Main 流程正常
- [x] 8.2 验证 ItemDB 加载 JSON 成功，查询接口正常
- [x] 8.3 验证 ItemFactory 根据类型创建正确类实例
