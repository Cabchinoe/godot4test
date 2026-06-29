## 1. 拆分配置文件

- [x] 1.1 在 `conf/items/` 下创建 10 个类型文件（`weapon.json`、`ammo.json`、`helmet.json`、`armor.json`、`chestrig.json`、`backpack.json`、`material.json`、`collectible.json`、`consumable.json`、`weapon_attachment.json`），沿用原 Tab 缩进风格
- [x] 1.2 将 `conf/items.json` 各条记录按 `type` 搬运到对应文件，保留每条的 `type` 字段
- [x] 1.3 核对：各文件记录数之和等于原 `items.json` 总数；`weapon_attachment.json` 当前无数据可为空数组 `[]` 或暂不创建

## 2. 改造加载器

- [x] 2.1 在 `Script/item/item_db.gd` 改造加载入口为按 `VALID_TYPES` 键驱动：遍历键，拼 `res://conf/items/<key.to_lower()>.json` 逐个加载
- [x] 2.2 复用现有解析逻辑：文件缺失跳过 + 打印告警；JSON 解析失败或根非数组时打印错误并跳过该文件，不中断整体流程
- [x] 2.3 将各文件解析出的记录经 `_validate_entry` 校验后合并入 `_items`；保持 `get_item`/`get_items_by_type`/`get_all_items` 行为不变
- [x] 2.4 加载结束打印物品总数

## 3. 启动期路径校验

- [x] 3.1 在 `item_db.gd` 新增 icon 路径校验：遍历所有已加载物品的 `icon`，用 `FileAccess.file_exists` 检查存在性
- [x] 3.2 收集缺失项并打印包含物品 id 与缺失路径的清单；校验不阻断启动

## 4. 接入与清理

- [x] 4.1 更新 `Script/boot.gd`：将 `ItemDB.load_from_file("res://conf/items.json")` 改为新的目录加载入口调用
- [x] 4.2 运行启动验证：日志物品总数与拆分前一致，无意外缺失告警
- [x] 4.3 验证通过后删除原 `conf/items.json`

## 5. 跨平台路径约定

- [x] 5.1 确认全部新增路径仅用 `res://`/`user://`、分隔符为 `/`、配置文件名小写
- [x] 5.2 核对 `icon` 路径大小写与磁盘真实文件名精确匹配（参照 `Items/icons/` 实际目录）
