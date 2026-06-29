## Why

`conf/items.json` 是单个 37KB 的扁平数组，混杂 10 种物品类型（武器、弹药、护甲等），编辑时难以定位和维护。同时项目需在 mac 与 windows 间协作开发，路径大小写漂移会在导出/CI（大小写敏感环境）下导致资源加载失败，需提前约束并校验。

## What Changes

- 将 `conf/items.json` 按 `type` 拆分为 10 个文件，存于 `conf/items/` 目录（`weapon.json`、`ammo.json`、`helmet.json`、`armor.json`、`chestrig.json`、`backpack.json`、`material.json`、`collectible.json`、`consumable.json`、`weapon_attachment.json`）。每条记录保留 `type` 字段。
- 改造 `ItemDB.load_from_file`：由读取单文件改为按 `VALID_TYPES` 键驱动，逐个加载 `conf/items/<type_lower>.json` 并合并。文件缺失时跳过并告警，不崩溃。
- 更新 `boot.gd` 调用入口以适配新的加载方式。
- 新增启动期路径校验：遍历所有已加载物品的 `icon` 路径，校验文件真实存在（并可选做大小写精确匹配），缺失则打印清单以早暴露。
- 建立跨平台路径约定：仅用 `res://`/`user://`、路径分隔符统一 `/`、配置路径小写规范。
- **BREAKING**: 删除原 `conf/items.json`，加载契约从单文件改为目录约定。

## Capabilities

### New Capabilities
- `item-config-loading`: 物品配置的分文件组织、按类型驱动加载合并、以及跨平台资源路径约定与启动期校验。

### Modified Capabilities
<!-- 无既有 spec 的需求变更 -->

## Impact

- 配置：`conf/items.json` → `conf/items/*.json`（10 个文件）
- 代码：`Script/item/item_db.gd`（加载逻辑 + 路径校验）、`Script/boot.gd`（调用入口）
- 资源约定：`Items/icons/**` 路径大小写规范，影响后续新增图标
- 无 API 对外变更；`get_item` / `get_items_by_type` / `get_all_items` 行为保持不变
