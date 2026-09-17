# 物品容器工作台：设计与复用指南

## 目标

本轮实现把仓库、干员装备、武器配件槽与战场背包接入同一份物品实例存档。所有可移动物品都有稳定 `uid`；仓库格、背包格、装备栏和配件槽只保存对该实例的引用与位置。

本文既记录当前仓库功能，也作为战场、温室、工厂、特勤处接入物品容器能力的开发约定。

## 当前功能

- 仓库：固定 10×10、筛选、自动整理、拖拽交换、物品详情和存档。
- 装备：武器、头盔、护甲、背包四槽；仓库/背包物品可装配，装备可回仓或进入背包。
- 武器配件：仓库、背包、武器槽、已装备武器和背包内武器之间可移动；替换时旧配件回到来源位置。
- 背包：按装备定义的 `battle_grid_width × battle_grid_height` 展示，内容与坐标保存到 `operator_loadouts.backpack_items`。
- 双击：由 `TransferPolicy` 的 `source → target` 规则决定，而不是散落在各 UI 回调中。
- 面板：武器配件与背包面板并列常驻；没有对应装备时显示占位内容，不改变另一面板尺寸。

## 仓库场景交互规则

### 单击与面板

- 点击任意物品只更新信息面板的唯一选中对象。
- 点击另一把武器才切换武器配件面板。
- 背包面板跟随当前已装备背包；点击普通物品、筛选或整理不会关闭它。
- 拖拽高亮只更新当前有效落点与上一个落点，不重建网格。

### 双击规则

| 来源 | 物品类型 | 目标优先级 |
| --- | --- | --- |
| 仓库 | 武器 / 头盔 / 护甲 / 背包 | 对应空装备栏 |
| 仓库 | 其他物品 | 已装备背包的第一个空格 |
| 背包 | 任意物品 | 仓库第一个空格 |
| 装备栏 | 任意物品 | 仓库第一个空格 |
| 武器配件槽 | 配件 | 仓库第一个空格 |

### 拖拽与替换规则

| 来源 | 目标 | 结果 |
| --- | --- | --- |
| 仓库格 ↔ 背包格 | 任意有效格 | 空格移动；两个已占用格交换 |
| 仓库武器 → 武器栏 | 已有武器 | 新武器装备，旧武器回到新武器原仓库格 |
| 背包武器 → 武器栏 | 已有武器 | 新武器装备，旧武器回到新武器原背包格 |
| 仓库配件 → 武器 | 已有同槽配件 | 新配件装备，旧配件回到新配件原仓库格 |
| 背包配件 → 武器 | 已有同槽配件 | 新配件装备，旧配件回到新配件原背包格 |
| 配件槽 A → 配件槽 B | 已有同槽配件 | 两个配件在来源槽与目标槽之间交换 |

替换必须是原子操作：无法满足兼容性、容量或目标位置要求时，不修改任何容器。

## 持久化模型

`InventorySaveData` 是唯一持久化入口：

- `warehouse_items`: 物品实例数组，包含 `uid`、`id`、`position`。
- `operator_loadouts`: 干员装备、武器配件、背包内容。
- `runtime_revision`: 运行时索引失效版本；每次服务层写入后递增。

`position >= 0` 表示物品位于仓库，`position = -1` 表示物品由装备、背包或配件容器引用。容器归属必须通过 `operator_loadouts` 判断，不能仅依赖 `position`。

背包内容采用位置到实例的映射：

```gdscript
operator_loadouts[operator_id]["backpack_items"][backpack_uid] = {
    0: "item_uid_a",
    5: "item_uid_b",
}
```

卸下背包前，调用方必须基于仓库的 `capacity - occupied_count` 预检 `背包内容数 + 背包自身`；不足时禁止卸下，避免中途丢失物品。

## 可复用层

### UI 组件

- `InventorySlot`: 通用物品格，负责 hover、拖拽预览、双击与高亮。
- `InventoryGrid`: 通用网格缝隙拖放接收器。
- `ItemInfoPanel`: 按物品类型展示差异化信息。
- `OperatorEquipmentSlot` / `WeaponAttachmentSlot`: 特殊目标格；其他场景可新增同模式组件。

### 服务层

`WarehouseService` 当前提供实例查找、仓库/背包移动、装备替换、配件替换和容量检查。新场景应调用服务操作，不应直接写 `warehouse_items` 或 `operator_loadouts`。

常用操作按用途分组：

- 查询：`get_item_by_uid`、`get_item_at_position`、`get_backpack_items`。
- 容器移动：`move_warehouse_item_to_backpack`、`move_backpack_item_to_warehouse`、`swap_warehouse_and_backpack_item`。
- 装备：`equip_item`、`equip_backpack_item`、`replace_equipped_item_from_warehouse`、`replace_equipped_item_from_backpack`。
- 配件：`attach_item`、`attach_backpack_item_to_weapon`、`move_attachment`、`detach_attachment`。

新增容器时，优先在服务层新增原子操作；UI 只负责将拖拽来源、目标与规则转换为服务调用。

### 规则与容器参数

`TransferPolicy` 使用数据配置双击目的地与容器参数：

```gdscript
policy.configure({
    "source_container": {
        "ITEM_TYPE": [{"target": "target_container", "slot": "optional_slot"}],
        "*": [{"target": "fallback_container"}],
    },
}, {
    "target_container": {"columns": 8, "capacity": 64, "allows_swap": true},
})
```

`container_settings` 用于传递同一模板在不同场景的差异参数；`ContainerSpec` 可作为资源承载这些参数。

| 参数 | 用途 | 示例 |
| --- | --- | --- |
| `columns` | 网格列数 | 工厂 8、仓库 10 |
| `capacity` | 最大格数 | 战场投放箱 16 |
| `accepted_item_types` | 可接受物品类别 | 温室种植槽仅 `MATERIAL` |
| `allows_swap` | 是否允许两格互换 | 工厂棋盘 true、任务栏 false |
| `drag_enabled` | 是否允许从该容器拖出 | 奖励预览 false |

## 其他场景接入

### 战场

复用背包网格与 `TransferPolicy`；规则可设为“背包双击 → 战术快捷栏 → 战场地面容器”。战场容器只需提供容量、接受类型和是否允许交换。

### 温室

把种子槽、作物格、产出格做成容器。规则示例：种子从仓库拖入种植槽；成熟产物双击回仓；不可接受装备类型。

### 工厂

把二合棋盘和输入/输出格做成容器。规则示例：只接受可合成谱系；拖拽交换允许；合成成功后由服务层替换两个来源实例。

### 特勤处

把任务物资栏、队员装备栏和奖励缓存做成容器。规则示例：任务栏从已装备背包装载物品，并受容量和场景专属限制约束；结束时奖励缓存批量转入仓库。

## 性能实现与约束

- `InventoryIndex` 缓存 `uid → item`、`uid → 数组索引`、`warehouse_position → uid` 与 `backpack_position → uid`，避免高频线性扫描。
- 所有写操作必须经过服务层并递增 `runtime_revision`。
- 普通仓库交换只刷新仓库格与头部；装备/配件变化才刷新相应面板。
- 鼠标移动时不重建节点；拖拽高亮只更新上一个与当前目标格。

### 索引失效约定

1. 服务层改变 `warehouse_items`、物品 `position`、背包映射、装备映射或配件映射后调用 `_touch(inventory)`。
2. 下次查询通过 `InventoryIndex.ensure()` 自动重建缓存。
3. UI 不能绕过服务层直接修改存档字典；否则必须显式增加 `runtime_revision`，但不推荐这样做。

## 开发与提交检查清单

- 新物品配置具有 `id`、`type`、`icon`，装备还需提供可展示的战场属性。
- 新容器先定义 `ContainerSpec` 与 `TransferPolicy` 规则，再实现 UI。
- 每条移动/替换路径验证：成功、目标满、来源为空、物品类型不兼容、存档重载。
- 验证背包卸下的容量预检与配件替换的来源位置回填。
- 提交前运行 JSON 校验、`git diff --check`、目标场景加载；若 Godot 会格式化无关场景，先保护或还原该文件。

## 下一阶段

下一阶段应从 `WarehouseService` 中抽出 `ItemContainer` 接口：`can_accept`、`insert`、`remove`、`swap`、`capacity`。届时仓库、背包、工厂棋盘、温室槽位和战场地面容器可完全参数化，而 `WarehouseScreen` 仅保留布局与展示职责。

### 新会话开发路线图

按以下顺序实施，避免先做场景 UI 后再重写数据层：

#### 阶段 1：容器抽象（优先）

1. 新增 `ItemLocation` 值对象，统一描述 `container_id`、`owner_id`、`position`、`slot_id`。
2. 新增 `ItemContainer` 接口或基类，最少包含：
   - `get_item(position)`
   - `get_capacity()` / `get_columns()`
   - `can_accept(item_uid, position)`
   - `insert(item_uid, position)`
   - `remove(position)`
   - `swap(source_position, target_position)`
3. 实现第一批容器适配器：`WarehouseContainer`、`BackpackContainer`、`EquipmentContainer`、`WeaponAttachmentContainer`。
4. 将 `WarehouseService` 中现有的仓库/背包/装备/配件移动函数改为组合容器操作，不改变现有 UI 行为。

**验收条件**：同一条“仓库武器替换装备武器”流程不再需要按来源写多套分支；只由来源容器、目标容器和规则决定。

#### 阶段 2：通用转移执行器

1. 新增 `ItemTransferExecutor`，输入为 `source_location`、`target_location`、`TransferPolicy`。
2. 执行器负责统一处理：有效性校验、容量预检、替换回填、交换、失败回滚、revision 更新。
3. `TransferPolicy` 从当前的“双击规则”扩展为：
   - 允许的来源/目标容器组合；
   - 同类型物品是否允许交换；
   - 替换物回填策略（来源位置 / 仓库空位 / 禁止替换）；
   - 双击目标优先级；
   - 场景专属过滤条件。

**验收条件**：`WarehouseScreen` 的拖放回调只负责构造位置和调用执行器，不直接调用多种 `WarehouseService.move_*` 方法。

#### 阶段 3：通用工作台 UI 模板

1. 新建 `InventoryWorkbench` 场景或基类，接收：
   - 容器列表；
   - `TransferPolicy`；
   - 面板布局参数；
   - 信息面板字段策略。
2. 将当前的仓库网格、背包网格、装备栏和配件槽包装成可注册的容器视图。
3. 让温室、工厂、特勤处只配置容器及规则，不复制拖拽状态机、悬停高亮、双击逻辑和持久化流程。

**验收条件**：新增一个 4×4 的测试容器只需要创建 `ContainerSpec + TransferPolicy`，不需要复制 `InventorySlot` 或 `WarehouseScreen` 的事件代码。

#### 阶段 4：接入后续场景

| 场景 | 首批容器 | 特有规则 |
| --- | --- | --- |
| 战场 | 背包、战术栏、地面战利品 | 背包容量、回合内使用与撤离结算 |
| 温室 | 种子槽、作物槽、收获缓存 | 仅接受种子/肥料；成熟后回仓 |
| 工厂 | 二合棋盘、输入、输出 | 同谱系同等级合成；输出格不可交换 |
| 特勤处 | 任务物资、干员装备、奖励缓存 | 任务限制、队伍配置、结算批量入仓 |

### 当前实现的风险点

1. **`position = -1` 语义过载**：装备、背包、配件都使用该值，必须依赖 `operator_loadouts` 区分位置；在新增容器前应先引入 `ItemLocation`。
2. **索引失效遗漏风险**：目前部分装备/配件映射通过字典写入；新增写路径必须调用 `_touch(inventory)`，否则 `InventoryIndex` 可能读取旧位置。
3. **`WarehouseService` 仍包含场景语义**：`OPERATOR_ID = "benny"`、固定 10×10、测试物资注入均不应进入未来通用服务。
4. **测试物资迁移逻辑**：`starter_content_version` 用于当前开发测试；正式版本需移到开发工具、测试存档或显式 debug 开关，不能继续自动污染老存档。
5. **运行时 revision 被持久化**：目前为实现简单而导出到存档资源；后续可改为非持久的会话缓存版本，或在读取时重置为 0。
6. **UI 仍有整体刷新**：装备、配件和背包变化会重建部分面板；通用工作台完成前不要继续向 `WarehouseScreen` 堆叠大型功能。
7. **物品归属校验不足**：当前武器兼容性主要按配件配置校验；多干员版本需要为装备增加 `allowed_operator_ids` 或由角色定义提供校验器。
8. **事务缺少统一回滚**：现有高频路径已做来源位置回填，但新容器加入时必须由 `ItemTransferExecutor` 统一提交或回滚，不能只依赖 UI 顺序调用。

### 下一阶段测试矩阵

在开始战场/温室/工厂前，至少补齐以下自动或手工回归：

| 测试 | 断言 |
| --- | --- |
| 索引刷新 | 每种服务层移动后，`uid` 与格位索引立刻一致 |
| 容量边界 | 仓库/背包满时，移动和替换不改变任何来源数据 |
| 替换回填 | 仓库、背包、配件槽三种来源都回填到正确来源位置 |
| 存档重载 | 仓库、装备、配件、背包坐标重载后完全一致 |
| 规则差异 | 同一物品在仓库/战场/工厂的双击结果由不同策略正确决定 |
| UI 刷新 | 只刷新受影响容器；拖拽移动不重建整个工作台 |
