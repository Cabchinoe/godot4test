# 战场角色面板与物资交互方案

本轮遵循 `inventory_workbench_reuse_guide.md` 的容器约定：物品实例继续由 `InventorySaveData.warehouse_items` 唯一持有，装备、背包和配件只保存 `uid` 引用；临时物资存放在战场运行时会话缓存，不写入 `InventorySaveData`。

## 已接入

- 顶部状态栏：左侧显示 AP 与生命值；回合数固定在顶部中间，结束回合按钮位于其右侧。
- 右键行动菜单：攻击条目显示武器的 AP 消耗；行动点不足时，消耗数字为红色且攻击不可点击。
- 干员选择：点击干员进入移动选择状态时打开战术面板；面板含角色生命、装备栏、武器配件栏、背包与临时物资栏。
- 存档加载：战场进入后调用 `WarehouseService.ensure_data()`，再同步 `PlayerSaveData.equipped_item_ids`；仓库中调整的装备、配件和背包内容会直接带入战场。
- 拖拽：背包内部、临时物资内部可交换；装备、配件、背包和临时物资之间通过 `WarehouseService.transfer_item()` 原子移动或替换。
- 双击：临时物资按“空装备栏 → 背包”的优先级转移；背包、装备和配件优先移入临时物资栏。

## 临时物资容器

`TemporaryContainer` 是非持久化容器，生命周期仅覆盖当前战场搜索交互：

1. 搜索目标时调用：
   `battle_loadout_panel.open_search_container("<目标唯一ID>", "医疗柜", 16, 4)`。
2. 将搜索结果加入面板：
   `battle_loadout_panel.add_search_item("consumable_medkit_01")`。
3. 关闭搜索窗口或战斗结束时调用：
   `battle_loadout_panel.close_temporary_container()`。

未被拿走的临时实例会在关闭时丢弃；转移到装备或背包的实例仍由存档持有，并会在正常存档流程中保存。

## 本轮限制

- 战斗中不允许替换装有物资的背包，避免旧背包内容无处回填；背包为空时可正常替换。
- 当前战场尚未实现可搜索目标，因此临时面板 API 已就绪，等待搜索交互接入时调用。
- 后续多干员接入时，应把 `WarehouseService.OPERATOR_ID` 的默认值改为当前选中干员 ID，并让战场面板按队伍逐个配置。
