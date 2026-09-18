## 1. Step 1：同格查询一对多 + 优先级 + 绘制顺序

- [x] 1.1 `Script/battle_container.gd` 新增 `get_search_priority() -> int`：两档——`is_ground_pile` 或 `is_opened == false` → 0（没搜过 / 丢弃物），`is_opened == true` → 1（搜过，含已搜空）
- [x] 1.2 `Script/main.gd` 新增 `_get_containers_at_grid(grid, level) -> Array[BattleContainer]`，遍历 `battle_containers` 分组收集全部匹配项
- [x] 1.3 `Script/main.gd` 新增 `_pick_container(candidates) -> BattleContainer`：按 `get_search_priority()` 升序，同档取数组末位（绘制最上层）（实现为 `_sorted_containers()` + `_pick_container()` 取首元素）
- [x] 1.4 `_get_container_at_grid()` 改为 `_pick_container(_get_containers_at_grid(...))`（`_get_container_at_grid()` 已移除，调用点直接用 `_pick_container(_get_containers_at_grid(...))`）
- [x] 1.5 `_get_container_at()` 改为收集 `interaction_radius` 内全部候选 → 取最小距离 → 同距离候选交给 `_pick_container()` 打破平局（`_get_container_at()` 改名为 `_get_containers_near()`，返回最近距离组的全部候选）
- [x] 1.6 新增 `_reorder_containers_at_grid(grid, level)`：把同格候选按优先级用 `move_child()` 排到父节点末尾，优先级最高者最后（绘制在最上层）
- [x] 1.7 在四个状态变化点调用 1.6：容器生成后、`begin_search()` 首次打开后、`set_depleted(true)` 后、`append_loot()` 后（`append_loot()` 触发点待 Step 4）
- [x] 1.8 验证：同格“1 个 closed + 1 个 opened 有货”，closed 绘制在上层，右键与站立菜单默认目标都是它（headless 测试场景验证，已清理）
- [x] 1.9 验证：把上层容器搜过后，绘制顺序与默认目标同步切到没搜过的那个；已搜空者降到末档但仍可点开（headless 测试场景验证，已清理）

## 2. Step 2：容器菜单列表模式

- [x] 2.1 `Script/ui/battle_container_action_menu.gd` 新增 `show_search_list(entries: Array[Dictionary], screen_position: Vector2i)`，`entries` 每项含 `name` / `verb` / `ap_cost` / `enabled` / `reason`
- [x] 2.2 列表模式动态重建行按钮，`min_size` 随行数增长；样式复用现有 `_make_style()`，不新增第二套视觉
- [x] 2.3 保留 `show_search()` 单按钮模式，候选数为 1 时行为与文案完全不变
- [x] 2.4 选中行 → `hide()` → 把选中容器写入 main.gd 的 `_pending_container` → 发 `search_requested`（信号签名不变）（菜单暴露 `get_selected_index()`，由 main.gd 映射回 `_pending_containers`）
- [x] 2.5 禁用行显示原因 tooltip，且点击无副作用（不扣 AP、不开面板）
- [ ] 2.6 验证：点空白处左键仍能关闭列表菜单（沿用 `Script/main.gd:388` 路径）——需真机 GUI 确认

## 3. Step 2：两个右键入口按候选数分支

- [x] 3.1 `_handle_right_click()`（`Script/main.gd:481`）：候选 1 个走 `show_search()`，≥2 个走 `show_search_list()`，0 个保持现有后续分支
- [x] 3.2 `_show_context_menu()`（`Script/main.gd:500`）：候选 ≥2 个时 `search_label = "搜索…（同格 N 个）"`，`search_enabled` = 至少一个候选可搜，`search_reason` 取默认目标的不可用原因
- [x] 3.3 行动菜单的搜索项在候选 ≥2 个时不直接搜索，改为关闭行动菜单并在鼠标位置弹出 3.1 的列表菜单
- [x] 3.4 列表菜单标题统一为 `同格 N 个目标`，行序与 `_pick_container()` 优先级一致（第一行 = 默认目标 = 绘制最上层）
- [x] 3.5 验证：站在“战利品箱 + 丢弃物堆”同格上右键角色 → 搜索项显示 `搜索…（同格 2 个）` → 弹出列表 → 两行分别显示各自 AP 成本，选择后进入对应临时容器面板（headless 验证文案与跳转，视觉待真机确认）
- [x] 3.6 验证：同格 3 个目标（没搜过 / 已搜空 / 丢弃物）全部出现在列表且全部可点，站立菜单显示 `搜索…（同格 3 个）` 并能跳转列表（headless 验证，已清理）
- [x] 3.7 0 AP 目标始终可打开：`_describe_container()` 的 `enabled` 只看射程与 AP，`_search_container()` 移除 `has_remaining_loot()` 提前 return，打开已搜空容器不扣 AP
- [x] 3.8 动词三态统一：没搜过 `搜索`、搜过有货 `继续搜索`、搜过已空 `查看（已空）`；`show_search()` 改为接收 `verb`，单按钮与列表两种模式共用
- [x] 3.9 行动菜单跳转列表菜单改用 `call_deferred`（`Script/main.gd:758`），修掉同帧 hide + popup 被窗口失焦关掉的问题
- [ ] 3.10 验证：真机确认列表菜单弹出后不会自动关闭，且点空白处左键可关闭

## 4. Step 3：待播种队列与播种失败处理

- [ ] 4.1 `Script/battle_container.gd` 用 `pending_loot: Array[String]` 承载未写入临时容器的物品；`configure()` 由 `data["loot"]` 填充
- [ ] 4.2 新增 `take_pending_loot() -> Array[String]`（返回并清空），`has_seeded_loot()` 语义保持不变
- [ ] 4.3 `has_remaining_loot()` 改为 `not pending_loot.is_empty() or 临时容器有物品`
- [ ] 4.4 `_search_container()` 改为逐件调用 `add_search_item()`，成功才从 `pending_loot` 移除，失败保留并统计数量
- [ ] 4.5 播种存在失败时状态栏提示“容器已满，剩余 N 件未取出”，且不得把容器标记为已搜空
- [ ] 4.6 验证：把 `capacity` 临时调小于 `loot` 数量，确认物品留在队列、二次搜索可继续取出、无静默丢失

## 5. Step 4：搜索同层限制、0 AP 文案与菜单宽度

- [x] 5.1 `Script/battle_container.gd:80` `can_be_searched_by()` 最前面加 `actor.current_level != current_level → false`，优先级高于 `requires_attack_range` 短路（丢弃物同样受约束）
- [x] 5.2 `Script/main.gd:680` `_describe_container()` 增加 `same_level` 判定与独立原因“需要与角色位于同一层。”，`enabled` 加入 `same_level`
- [x] 5.3 成本文案统一 `N AP`：容器菜单 `_apply_cost()`、行动菜单 `_search_cost_label`、`_search_container()` 状态栏提示，全部去掉“免费”
- [x] 5.4 `BattleContainerActionMenu`：`min_size` 按最宽一行动态计算（单按钮下限 260、列表下限 320、上限 560）
- [x] 5.5 `BattleContextMenu`：`min_size` 按搜索项文案动态计算（下限 186、上限 420）
- [x] 5.6 两个菜单各加 `_estimate_text_width()` 兜底：`unicode >= 0x2E80` 按 1 个字号宽、其余 0.55，与 `get_string_size()` 取较大值
- [x] 5.7 验证（headless）：二层容器在一层不可搜且原因为“需要与角色位于同一层。”，`begin_search()` 被拦住；同层同格可搜
- [x] 5.8 验证（headless）：已打开容器成本显示 `0 AP`；长名称 `掠夺兵战利品箱 ×2 · 查看（已空）` 撑到 376px，`搜索…（同格 2 个）` 撑到 251px
- [ ] 5.9 验证（真机）：中文字体下菜单不截断，跨层容器在列表里显示为禁用行

## 6. 已取消：同格敌人掉落合并

2026-09-18 决策变更：同格允许存在任意数量的容器，不做合并。原任务（`spawn_enemy_drop()` 合并分支、`append_loot()`、容量扩容、`display_name` 计数）全部作废，相关能力由 Step 1 的一对多查询与 Step 2 的列表菜单覆盖。详见 design.md Decision 2。

## 7. 回归与文档

- [x] 7.1 回归：单个容器右键、站立菜单、AP 扣费不变；搜空后表现按新规则变化（贴图保持 empty，行动项从禁用变为可点、文案 `查看（已空）`）——headless 已验证单候选直接搜索、无容器时搜索项隐藏
- [x] 7.2 回归：丢弃物堆仍按格合并、与同格战利品箱互不混装，且恒定 0 AP 可搜（Decision 6 / 10）
- [x] 7.3 回归：敌方阶段与玩家移动中右键菜单仍被屏蔽（仅相机拖拽放行，代码路径未变）
- [x] 7.4 回归：容器仍绘制在角色之下（未改 `z_index`，只用 `move_child()` 调兄弟顺序）
- [x] 7.5 更新 `doc/battlefield_inventory_implementation_plan.md` 第 2 节（同层限制、0 AP 文案、已搜空可查看）、第 2.1 节（两档优先级、绘制顺序、列表菜单、宽度自适应、不做合并）、第 4.2 节（丢弃物 0 AP）
- [ ] 7.6 更新 `doc/project.md` 中战场容器与搜索相关的模块说明
