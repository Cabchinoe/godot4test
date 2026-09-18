## Why

战场容器目前建立在“一格最多一个可交互容器”的隐含假设上，但敌人战利品箱可以在同一格堆叠：

- 敌人死亡时 `_on_unit_defeated()` 先把它移出 `units` / `enemy` 分组再 `queue_free()`（`Script/main.gd:824`），该格立刻空出，后续敌人可以走上来死在同一格。
- 敌人掉落箱固定 `can_walk = true`（`Script/battle_container_spawner.gd:61`），丢弃物堆同样 `can_walk = true`（`Script/battle_container_spawner.gd:79`），路边垃圾桶也是 `can_walk: true`（`Script/main.gd:797`）。这些格子都允许再站一个敌人并死在那里。

同格出现 2 个以上容器后，现有搜索链路只能命中其中一个，另一个的战利品事实上永久拿不到：

- 右键拾取 `_get_container_at()`（`Script/main.gd:603`）按“到鼠标距离最近”选择，且判定是严格小于（`Script/main.gd:611`）。同格容器的 `global_position` 完全相同 → 距离相等 → 永远是 `battle_containers` 分组里最先生成的那个胜出，后生成的无法被右键选中。
- 站立菜单 `_get_container_at_grid()`（`Script/main.gd:617`）遇到第一个匹配就 `return`，同样只有一个候选。
- 视觉上没有任何堆叠表现：所有容器挂在同一层 `obstacle` 下、`z_index` 相同（`Script/battle_container_spawner.gd:35`），同 z 的兄弟节点按树序绘制 → 后生成的盖住先生成的。玩家看到的是最新那个箱子，右键打开的却是最早那个箱子。
- 容器搜空后只 `set_depleted(true)`、节点保留（`Script/main.gd:753`）。于是“已空的箱子”盖在“还有货的箱子”上面，站立菜单也只提示“容器已搜空”（`Script/main.gd:519`）。

顺带暴露一个已存在、但堆叠后会高频触发的缺陷：`_search_container()` 播种掉落时忽略 `add_search_item()` 的返回值，随后无条件 `mark_loot_seeded()`（`Script/main.gd:682`）。容量不足时物品既进不了临时容器、又被标记为已播种 → 静默丢失。

## What Changes

**Step 1 查询一对多 + 优先级 + 绘制顺序同步（正确性修复）**

- 新增 `_get_containers_at_grid()` 返回同格全部容器；两个入口共用 `_pick_container()`，按两档“没搜过 > 搜过”排序（丢弃物恒定第 0 档），同档取绘制最上层者。
- 同格容器的兄弟顺序随优先级重排（`move_child()` 到父节点末尾），让绘制最上层始终等于默认目标；不用 `z_index` 分层，因为单位占用 `obstacle.z_index + 1`（`Script/unit.gd:134`）。
- `_get_container_at()` 距离相等时用同一套优先级打破平局，保证“看到的”就是“点到的”。

**Step 2 同格 ≥2 个目标时的列表菜单（交互修复）**

- `BattleContainerActionMenu` 增加列表模式：标题 `同格 N 个目标`，每个候选一行按钮，按优先级从上到下排列，行内显示名称、状态动词与 AP 成本，逐行独立判定可用性并给出禁用原因。
- 右键地图容器：候选 1 个走现状单按钮；候选 ≥2 个走列表模式。
- 右键角色（站在容器格上）：`BattleContextMenu` 的搜索项文案改为 `搜索…（同格 N 个）`，点击后关闭行动菜单并弹出同一个列表菜单，两个入口收敛到同一套选择 UI。
- 0 AP 目标（搜过的容器、丢弃物）即使已搜空也可打开面板查看，不扣 AP；只有“不同层”“超出 1 格攻击射线”“AP 不足”会禁用行动项。
- 行动菜单跳转列表菜单时用 `call_deferred` 延迟到本帧末尾，否则同帧 hide + popup 会被窗口失焦逻辑关掉。
- 不做“搜完自动切下一个”的隐式轮转：搜索会扣 AP，目标必须可预期。

**Step 3 播种失败不再静默丢物品**

- `_search_container()` 检查 `add_search_item()` 返回值；失败的物品留在待播种队列，下一次搜索继续尝试，并在状态栏提示剩余未取出的数量。

**Step 4 搜索必须同层 + 成本文案统一 + 菜单自适应宽度**

- `BattleContainer.can_be_searched_by()` 增加同层前置条件：`actor.current_level != current_level` 直接返回 false。此前 `BulletRange` 的“低打高”规则会把邻层格子算进 1 格射程，导致站在二层能搜一层的容器。
- `_describe_container()` 对跨层目标给出独立原因“需要与角色位于同一层。”，与射程不足、AP 不足区分开。
- 成本文案统一为 `N AP`，不再出现“免费”（0 AP 就写 0 AP）；涉及容器菜单、行动菜单与搜索状态栏提示。
- 两个菜单的 `min_size` 改为按最宽一行动态计算，并对中日韩字符做兜底估算（字体缺字形时 `get_string_size` 会返回 0），长名称如 `掠夺兵战利品箱 ×2 · 查看（已空）` 不再被截断。容器菜单下限 260 / 列表 320、上限 560；行动菜单下限 186、上限 420。

**不在本次范围**

- **同格敌人掉落合并：已明确放弃（2026-09-18 决策变更）。** 同格允许存在任意数量的容器，全部通过 Step 1 的优先级查询与 Step 2 的列表菜单暴露给玩家。
- 同格容器的像素偏移 / `×N` 角标等美术表现：列表菜单已能表达数量与名称，暂不做。
- 战术面板内的“上一个 / 下一个目标”切换，面板仍一次只展示一个临时容器。

## Capabilities

### New Capabilities
- `battle-container-stacking`: 同格同层多容器共存时的查询优先级、视觉一致性、合并规则与掉落播种保证

### Modified Capabilities
（无。现有 openspec capability 未覆盖容器搜索；现行规则记录在 `doc/battlefield_inventory_implementation_plan.md`，本次同步更新其第 1、2、4 节）

## Impact

- `Script/battle_container.gd`：`get_search_priority()` 两档优先级、`can_be_searched_by()` 同层前置条件；Step 3 待补的待播种队列与 `take_pending_loot()`
- `Script/main.gd`：新增 `_get_containers_at_grid()` / `_get_containers_near()` / `_sorted_containers()` / `_pick_container()` / `_reorder_containers_at_grid()` / `_describe_container()`，`_search_container()` 允许打开已搜空容器，两个右键入口按候选数分支
- `Script/ui/battle_container_action_menu.gd`：列表模式（行数可变）、`get_selected_index()`、`show_search()` 改收 `verb`、`min_size` 按内容自适应、成本文案 `N AP`
- `Script/ui/battle_context_menu.gd`：搜索项文案支持 `搜索…（同格 N 个）`、`min_size` 按内容自适应、成本文案 `N AP`，信号与按钮结构不变
- `Script/battle_container_spawner.gd`：本次不改（合并方案已取消）
- `doc/battlefield_inventory_implementation_plan.md`：补充同格堆叠规则
- 不改 `WarehouseService` 临时容器接口，不改存档结构（容器与临时物资本就只存在于当前战局，`Script/main.gd:130`）
- 兼容性：一局内已存在的同格多容器在 Step 1 后立即全部可达；Step 3 只影响之后新生成的掉落，不追溯合并
