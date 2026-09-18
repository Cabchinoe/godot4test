## Context

容器体系由三层组成：

- `BattleContainer`（`Script/battle_container.gd`）：单个地图节点，持有 `grid_pos` / `current_level` / `resource_id` / `capacity` / `columns` / `loot_item_ids`，并用 `_loot_seeded` 记录“配置掉落是否已写入临时容器”。`get_temporary_container_id()` 返回 `"search:%s" % resource_id`（`Script/battle_container.gd:62`）。三张贴图 closed / opened / empty 分别对应“未打开 / 已打开 / 已搜空”（`Script/battle_container.gd:131`）。
- `BattleContainerSpawner`（`Script/battle_container_spawner.gd`）：把容器挂到当前层 `obstacle` 下，统一 `z_index = obstacle.z_index`、`z_as_relative = false`、`top_level = true`。敌人掉落 `spawn_enemy_drop()` 用 `enemy.name + get_instance_id()` 生成唯一 `resource_id`（`Script/battle_container_spawner.gd:57`）。
- `main.gd`：两条入口选容器（右键地图 `_get_container_at()`、右键角色 `_get_container_at_grid()`），一条入口执行搜索（`_search_container()`），一条回调同步视觉（`_on_temporary_container_changed()`）。物品实体存放在 `WarehouseService` 的本局临时容器字典里，面板一次只展示一个 `_temporary_container_id`（`Script/inventory/ui/battle_loadout_panel.gd:21`）。

两个菜单都是 `PopupPanel` + 固定行数的 `VBoxContainer`：`BattleContextMenu` 四行（攻击 / 搜索 / 结束回合 / 属性，`min_size = Vector2i(186, 186)`，`Script/ui/battle_context_menu.gd:16`），`BattleContainerActionMenu` 一行（标题 + 搜索按钮，`min_size = Vector2i(222, 94)`，`Script/ui/battle_container_action_menu.gd:12`）。两者都已经用 `enabled` + `reason`（tooltip）表达“为什么不能搜”。

“一格一容器”从来不是显式约束，而是这两个查询函数“返回第一个 / 最近一个”的副产品。敌人掉落箱是唯一会在运行时动态新增、且允许同格重复的容器类型，因此堆叠只在它身上出现。

## Goals / Non-Goals

**Goals:**
- 同格存在多个容器时，全部战利品都必须可达，且“玩家看到的”与“玩家点到的”是同一个容器
- 玩家在选择搜索目标前能看到目标是谁、要花多少 AP，不做隐式轮转
- 掉落播种不得因容量不足静默丢失物品
- 同格任意数量的容器都能被看到、被选中、被搜索
- 不改存档结构、不改 `WarehouseService` 对外接口

**Non-Goals:**
- 不做同格容器的像素偏移 / 角标等美术表现（另议）
- 不合并任何容器：同格允许存在任意数量容器（2026-09-18 决策，见 Decision 2）
- 不改 AP 经济数值本身（只改“合并后是否重新收费”的规则，见 Decision 3）
- 不改丢弃物与战利品箱的既有差异（文案、AP、清空后是否销毁节点）
- 不做战术面板内的多容器同时展示或“上一个 / 下一个”切换

## Decisions

### Decision 1: 按“查询 → 交互 → 规则”的顺序推进

Step 1（查询一对多 + 优先级 + 绘制顺序）是纯正确性修复：所有同格容器立刻可达，且默认目标与视觉最上层一致。Step 2（列表菜单）让 ≥2 个候选可以被显式选择。Step 4（同层限制 + 文案 + 宽度）是规则与表现修正。Step 3（播种不丢物品）是独立的健壮性修复，可单独排期。

各步独立可提交，顺序不能反：先做交互（Step 2）而没有 Step 1 的一对多查询，列表里根本拿不到全部候选。

### Decision 2:（已取消，2026-09-18）同格敌人掉落合并

原方案是“同格已有敌人掉落箱时把新掉落并进去”，理由是格子只有 64×64、两个节点必然完全重叠，且两个同名 `掠夺兵战利品箱` 在列表里没有信息量。

**取消原因**：策划明确要求同格允许存在任意数量的容器，不做合并。堆叠带来的可达性与可读性问题改由 Decision 6（两档优先级）+ Decision 7（绘制顺序同步）+ Decision 8（列表菜单）解决：列表里每一行都有独立名称与 AP 成本，玩家能看清同格有几个、分别处于什么状态。

保留下来的结论：同格容器数量不再有上限假设，所有查询与 UI 都必须按“一对多”设计——这也是本次改动的起点。

### Decision 3:（随 Decision 2 取消）合并掉落沿用“已打开即 0 AP”

合并方案取消后不再有“追加掉落”这条路径。原有计费规则本身不变：`get_search_ap_cost()` 对 `is_opened` 的容器返回 0（`Script/battle_container.gd:66`），即首次开启付 AP、之后查看为 0 AP。

### Decision 4: 用“待播种队列”取代 `_loot_seeded` 布尔（Step 3，未实现）

现状 `_loot_seeded` 只能表达“配置掉落有没有写进临时容器一次”（`Script/battle_container.gd:119`），而播种是可能失败的（见 Decision 5），需要“哪些物品还没成功写进临时容器”的语义：

- `configure()` 把 `data["loot"]` 放进 `pending_loot`
- `take_pending_loot()` 由 `_search_container()` 调用，成功播种的物品才从队列移除
- `has_seeded_loot()` 保留“曾经播种过”的语义，供 depleted 判定继续使用（`Script/main.gd:683`）
- `has_remaining_loot()` = `pending_loot` 非空 或 临时容器有物品

### Decision 5: 播种失败留在队列，不静默丢物品（Step 3，未实现）

`WarehouseService.add_temporary_item()` 在容量满或物品 id 不存在时返回 false（`Script/inventory/warehouse_service.gd:258`），而 `_search_container()` 忽略返回值并立刻 `mark_loot_seeded()`（`Script/main.gd:788`）→ 失败的物品既不在临时容器里、又被标记为“已播种”，从此永久消失。

- 播种失败的物品留在 `pending_loot`，状态栏提示“容器已满，剩余 N 件未取出”，下次搜索继续尝试
- 物品 id 在 ItemDB 中不存在时 `push_warning` 输出，避免配置错误被静默吞掉
- 不做动态扩容：合并方案已取消，每个容器的 `capacity` 由配置固定。配置的物品数超过容量时按上面的规则保留并提示，而不是扩容把配置错误盖住

### Decision 6: 优先级两档“没搜过 > 搜过”，丢弃物恒定第 0 档

分档只看“玩家搜过没有”，对应 closed / opened 两种贴图状态：

| 档 | 条件 | 贴图 | 语义 |
| --- | --- | --- | --- |
| 0 | `is_ground_pile == true` 或 `is_opened == false` | closed / 丢弃物 | 没搜过，最值得作为默认目标 |
| 1 | `is_opened == true` | opened 或 empty | 搜过（含已搜空） |

丢弃物不参与分档、恒定第 0 档：它由玩家自己丢出来，只要还存在于地图上就一定有物品（搜空即销毁节点，`Script/main.gd:861`），必须始终能被 0 AP 搜回来，不能被“搜过”压到后面。

不再单列“已搜空”档：已搜空的容器本身就是 0 AP，仍然允许打开面板查看（见 Decision 8）。单列一档会让默认目标跳过玩家刚看过的那个箱子，还会让“档位”和“能不能点”变成两套判断。

`_get_containers_near()` 与 `_get_containers_at_grid()` 共用同一个 `_pick_container(candidates)`，避免两条入口再次分叉。排序键放在 `BattleContainer.get_search_priority()` 上，列表菜单直接复用它排序。

### Decision 7: 绘制顺序与优先级同步

现状所有容器 `z_index = obstacle.z_index`（`Script/battle_container_spawner.gd:35`），同 z 按兄弟顺序绘制 → 后生成的盖在上面，与优先级无关，这是“看到的是 B、点到的是 A”的直接原因。

- 改法：容器状态变化时（生成、首次打开、搜空、合并追加掉落）对同格候选重排兄弟顺序，把优先级最高的 `move_child()` 到父节点末尾。
- 不用 `z_index` 分层：单位用的是 `obstacle.z_index + 1`（`Script/unit.gd:134`），容器抬高会盖住角色。
- 重排后“绘制最上层 = 优先级最高 = 默认目标 = 列表第一行”四者一致，同档平局也就自然由绘制顺序决定，不需要额外的 LRU 状态。

### Decision 8: 两个右键入口在候选 ≥2 时收敛到同一个列表菜单

**入口 A：右键地图上的容器**（`_handle_right_click()` → `_get_containers_near()`，`Script/main.gd:481`）

- 候选 0 个：走现有后续分支（攻击模式退出 / 移动模式退出 / 角色菜单），行为不变。
- 候选 1 个：现有 `BattleContainerActionMenu.show_search()` 单按钮，行为完全不变。
- 候选 ≥2 个：同一组件切换为列表模式。
  - 标题 `同格 N 个目标`，行序 = 优先级序（没搜过的在最上）。
  - 每行 = 名称 + 状态动词 + AP，例如 `掠夺兵战利品箱 ×2 · 搜索（1 AP）`、`丢弃物 · 继续搜索（0 AP）`、`路边垃圾桶 · 查看（已空）（0 AP）`。
  - 动词三态：没搜过 = `搜索`；搜过且有货 = `继续搜索`；搜过且已空 = `查看（已空）`。
  - 可用性只看两件事：是否在 1 格攻击射线内、AP 是否够（只有首次开启才要 AP）。**0 AP 的目标即使已搜空也可点**，打开面板确认里面没东西、不扣 AP；`_search_container()` 因此不再因为“没有剩余物品”提前 return。
  - 禁用行沿用现有 tooltip `reason` 机制给原因（射程不足 / AP 不足）。
  - `min_size` 随行数增长（现固定 `Vector2i(222, 94)`）。
  - 选中行 → `hide()` → 通过既有 `_pending_container` 传给 `_on_container_search_requested()`，`search_requested` 信号签名不变。
  - 关闭方式沿用现状：点空白处左键关闭（`Script/main.gd:388`）。

**入口 B：右键角色（站在容器格上）**（`_show_context_menu()`，`Script/main.gd:500`）

- 候选 0 个：`has_search_target = false`，搜索项隐藏（现状）。
- 候选 1 个：单按钮直接搜，文案取同一套动词三态（`搜索` / `继续搜索` / `查看（已空）`）。
- 候选 ≥2 个：搜索项文案改为 `搜索…（同格 N 个）`，`enabled` = 至少一个候选可搜（全不可用时 tooltip 取默认目标的不可用原因）；点击 → 关闭行动菜单 → 在鼠标位置弹出入口 A 的同一个列表菜单。
- 格子上只要有丢弃物，行动菜单的搜索项就必须出现且可用（丢弃物恒为 0 AP），保证玩家能把丢出去的东西搜回来。

不在行动菜单里内嵌列表：`BattleContextMenu` 是固定四行 + `min_size = Vector2i(186, 186)`，插入可变长度列表会把“结束回合 / 属性”挤到很下面，且同一套列表样式要维护两遍。一次跳转的成本远低于此。

### Decision 9: 不做隐式轮转

备选方案是“搜完一个自动把默认目标切到下一个”（需要给容器加 LRU 时间戳）。否决理由：

- 首次搜索要扣 AP，玩家必须在扣费前知道目标是谁；隐式轮转会制造“我想搜丢弃物，它却开了战利品箱并且扣了 1 AP”的事故。
- Decision 7 已经保证绘制顺序与优先级一致，同档平局由绘制顺序决定，引入 LRU 会让“看到的”与“点到的”再次分叉。
- 列表菜单已经能表达全部选择需求，隐式轮转是多余的第二套心智模型。

### Decision 10: 丢弃物堆与战利品箱不合并

两者语义不同（玩家主动丢弃 vs 敌人掉落），AP 规则、面板标题、清空后是否销毁节点都不同（`Script/main.gd:861`）。同格可以同时存在一个丢弃物堆和一个战利品箱，由 Decision 6 的优先级决定默认目标，由 Decision 8 的列表菜单负责显式选择。

### Decision 11: 行动菜单跳转列表菜单时延迟一帧弹出

`_on_context_menu_search_requested()` 里先 `context_menu.hide()` 再弹列表菜单时，如果两次调用发生在同一帧，新弹出的 `PopupPanel` 会被窗口失焦逻辑立刻关掉（headless 实测：弹出当帧 `visible == true`，下一帧变回 `false`）。改为 `_show_container_action_menu.call_deferred(candidates, screen_position)`（`Script/main.gd:758`），在本帧末尾弹出后稳定可见。

### Decision 12: 搜索必须与角色同层

`can_be_searched_by()` 原本对 `requires_attack_range == false`（丢弃物）直接返回 true，其余情况用 `BulletRange.get_reachable_cells(..., 1, [], true)` 判定；而 `BulletRange` 的“低打高”规则允许命中相邻层的格子（见 `openspec/changes/archive/2026-06-26-add-bullet-range`），于是站在二层能搜一层的容器。

改法：在函数最前面加 `if actor.current_level != current_level: return false`（`Script/battle_container.gd:80`），优先级高于 `requires_attack_range` 短路，保证丢弃物同样受同层约束。`_describe_container()` 单独给出原因“需要与角色位于同一层。”（`Script/main.gd:680`），与“超出射程”“AP 不足”区分。

`_get_containers_near()` 仍然跨层收集候选：地图上两层同时可见（层间只有 16px 偏移），点到哪一层由距离决定；跨层目标以禁用行的形式出现并说明原因，比“点了没反应”更好。

### Decision 13: 成本文案统一 `N AP`，菜单宽度按内容自适应

- “免费”改为 `0 AP`：容器菜单、行动菜单、搜索状态栏三处统一，避免同一件事有两种说法。
- 两个菜单原本用硬编码 `min_size`（容器菜单 222×94、行动菜单 186×186），长文案会被截断。改为按最宽一行动态计算：`文字宽度 + 成本标签宽度 + 内边距`，并设上下限（容器菜单单按钮 260 / 列表 320，上限 560；行动菜单 186 ~ 420）。
- `get_string_size()` 在字体缺字形时返回 0（headless 与部分中日韩回退字体会命中），因此额外用字符数兜底估算：`unicode >= 0x2E80` 按 1 个字号宽、其余按 0.55 个字号宽，取两者较大值。实测 `掠夺兵战利品箱 ×2 · 查看（已空）` 撑到 376px，`搜索…（同格 2 个）` 撑到 251px。

## Risks / Trade-offs

- 不做合并 → 同格可能出现多个同名 `掠夺兵战利品箱` 行。列表能显示各自的动词与 AP 成本，玩家仍能区分“哪个没搜过”；但贴图完全重叠，地图上看不出数量。若后续需要区分，走角标或像素偏移（本次范围外）。
- ~~掉落配置里存在无效物品 id~~ 已修（2026-09-18）：`conf/items/material.json` 按 `doc/warehouse_art_manifest.md` 补齐 21 项材料（共 25 项，Lv0~Lv8），`conf/enemies.json` 与 `Script/main.gd` 掉落表引用的 13 个 id 现在全部可解析。Step 3 仍需实现，用来兜住将来再出现无效 id 或容量不足时的静默丢失。
- 列表模式让 `BattleContainerActionMenu` 从固定一行变成可变行数，`min_size` 与按钮需要动态重建；实现时注意复用同一份样式函数，避免出现两种视觉风格。
- PopupPanel 之间的跳转对帧内顺序敏感（Decision 11）；后续再增加菜单跳转时统一走 `call_deferred`，不要在同一帧里 hide + popup。
- 允许打开已搜空的容器会多出一个空面板；换来的是“0 AP 就一定能看”的一致规则，玩家不用去记哪些目标点得动。
- 优先级规则改变后，站立菜单的默认目标可能与改动前不同（改动前是树序第一个，通常是被盖住的那个）。这是刻意修正。
- `pending_loot`（Step 3）是运行时状态、不入存档，与现有 `_loot_seeded` 一致；若将来容器需要跨局持久化，两者要一起进存档。
- 允许打开已搜空的容器会多出一个空面板；换来的是“0 AP 就一定能看”的一致规则。
- 菜单宽度依赖字体测量 + 字符数兜底估算，极端长名称会撞到上限（容器菜单 560 / 行动菜单 420）后仍可能截断；容器名建议控制在 12 个中日韩字符以内。

## Migration Plan

单局内数据，无存档迁移。建议提交顺序：

1. ✅ Step 1 查询一对多 + 两档优先级 + 绘制顺序重排（`main.gd` + `BattleContainer.get_search_priority()`）
2. ✅ Step 2 列表菜单（`BattleContainerActionMenu` 列表模式 + 两个入口按候选数分支 + 0 AP 目标始终可打开）
3. ⬜ Step 3 待播种队列与播种失败处理（`BattleContainer` + `_search_container()`）——待确认是否要做
4. ✅ Step 4 搜索同层限制 + 成本文案 `N AP` + 菜单宽度自适应（`BattleContainer.can_be_searched_by()` + 两个菜单）
5. ❌ 同格敌人掉落合并——已取消（Decision 2）
6. 文档同步：`doc/battlefield_inventory_implementation_plan.md` 第 2、2.1、4.2 节已更新；`doc/project.md` 模块说明待补
