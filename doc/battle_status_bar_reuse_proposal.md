# 战场状态栏组件化提案（BattleStatusBar）

> **实施状态（2026-09-28）**：步骤 1–3 已完成。组件位于 `HUD/battle_status_bar.tscn` + `Script/ui/battle_status_bar.gd`，`Battlefield.tscn` 已替换为组件实例（`show_force_evacuation_button = true`），强制撤离按钮已并入组件。步骤 4 采用保守方案：战场保留显式 `status_bar.refresh()` 调用点作为兜底，未做精简。布局暂保留原绝对 offset（含用户微调坐标），未切换为容器布局。

## 现状与问题

当前状态栏与 `Battlefield` 强耦合，复用到新关卡需要复制大量代码和节点：

- `Battlefield.tscn` 中 `UILayer/UIRoot/StatusBar` 硬编码了 AP/HP/头盔/护甲/回合 5 个 Label 和结束回合按钮，全部使用绝对 offset 定位。新增一项（如本次的头盔/护甲）都要手算坐标，且容易与居中的回合标签、结束回合按钮重叠。
- `battlefield.gd` 里散布着 6 个 `@onready` 节点引用，以及 `_configure_hud()`（字体/配色）、`_update_hud()`（取数拼文本）、`_get_hp_color()`、`_update_protection_labels()` / `_apply_protection_label()`（防护值展示）等纯 UI 逻辑，约 60 行。
- `_update_hud()` 在战场脚本里有 7 处手动调用点，另加 `player.profile_changed` 信号连接；每处刷新时机都要人为记得，容易漏。
- 强制撤离按钮是运行时 `Button.new()` 拼出来的（`_setup_evacuation_controls`），与状态栏其余部分风格割裂。

对后续关卡（不同回合上限、可能无防护系统、可能多可操作单位）来说，这套东西每关复制一遍不可维护。

## 目标

- 状态栏成为一个独立场景 + 脚本，任何战斗类场景实例化即用。
- 显示项可配置（防护、回合、撤离按钮等按关卡开关）。
- 刷新自动化：组件自己监听数据源信号，战场脚本不再手动逐处调 `_update_hud()`。
- 不含任何战斗规则逻辑，只做展示与输入事件转发。

## 方案设计

### 组件划分

新增两个文件：

| 文件 | 内容 |
| --- | --- |
| `HUD/battle_status_bar.tscn` | 状态栏场景，根节点挂 `battle_status_bar.gd` |
| `Script/ui/battle_status_bar.gd` | `class_name BattleStatusBar extends Control` |

节点结构改用容器布局，替代绝对 offset：

```
BattleStatusBar (Control, 顶部全宽锚点, 高 68)
├── Background (ColorRect/Panel, 可选)
├── Layout (HBoxContainer, full rect)
│   ├── LeftGroup (HBoxContainer)        # AP、HP、防护槽位……自动排开
│   ├── CenterSpacer (Control, size_flags=expand)
│   ├── TurnLabel (Label)                # 居中区
│   ├── RightSpacer (Control, size_flags=expand)
│   └── RightGroup (HBoxContainer)       # EndTurnButton、ForceEvacuationButton
```

防护槽位（头盔/护甲）**不写死在场景里**，而是运行时按配置生成：

```gdscript
@export var protection_slots: Array[String] = ["helmet", "armor"]
@export var protection_titles := {"helmet": "头盔", "armor": "护甲"}
```

`_ready()` 时遍历 `protection_slots` 动态创建 Label 插入 `LeftGroup`。后续加"盾牌""外骨骼"等槽位只需改导出配置，不动场景。

### 对外接口

```gdscript
# 信号：只转发用户输入，不做任何规则判断
signal end_turn_pressed
signal force_evacuation_pressed

# 绑定数据源；组件内部自行连接 profile_changed / damaged / turn_started 并刷新
func bind(unit: Unit, turn_controller: TurnController) -> void

# 显式刷新兜底（回合开始、战斗结算后等时机仍可调）
func refresh() -> void

# 状态开关
func set_actions_enabled(enabled: bool) -> void        # 结束回合/强制撤离按钮
func set_force_evacuation_visible(visible: bool) -> void
```

显示项开关全部走 `@export`，关卡可按需配置：

```gdscript
@export var show_protection := true
@export var show_turn := true
@export var show_end_turn_button := true
@export var show_force_evacuation_button := false
```

### 数据读取

- AP/HP：直接读 `Unit` 公开字段（`action_points`、`ap_max`、`current_hp`、`max_hp`），对玩家和敌人都通用。
- 头盔/护甲：调用已抽好的 `Player.get_protection_status()`。组件内做类型判断：`unit is Player` 且有 `_battle_inventory` 时才显示防护区，否则整组隐藏——这样同一个组件也能挂在只有 `head_armor`/`body_armor` 数值的普通 `Unit` 上（可加一个读取 `get_protection_snapshot()` 的分支，见 unit.gd 现有实现）。
- 配色规则（`_get_hp_color` 的红/黄/绿阈值）随组件迁移，作为私有方法；后续可升级为 Theme 资源。

### Battlefield 侧的变化

- `Battlefield.tscn`：删除 `StatusBar` 的 6 个子节点，改为实例化 `battle_status_bar.tscn`。
- `battlefield.gd`：
  - 删除 `ap_label` 等 6 个 `@onready` 引用和 `_configure_hud` / `_update_hud` / `_get_hp_color` / `_update_protection_labels` / `_apply_protection_label`。
  - `_ready()` 中一次 `status_bar.bind(player, turn_controller)`，连接 `end_turn_pressed` / `force_evacuation_pressed` 到现有处理函数。
  - 现有 7 处 `_update_hud()` 调用点：绑定信号后大部分可删（`profile_changed`、`damaged`、`turn_started` 已覆盖），保守起见可先统一替换为 `status_bar.refresh()`，跑通后再精简。
  - `_setup_evacuation_controls()` 里手拼按钮的部分移入组件（`show_force_evacuation_button = true` 时显示），战场只连信号。
- 失败结算 overlay、战斗日志、撤离判定等**留在 battlefield**，不属于状态栏职责。

## 迁移步骤（每步可独立验证）

1. 新建 `battle_status_bar.gd` + `battle_status_bar.tscn`，把字体/配色/文本拼装/防护槽位逻辑原样搬入，先保证单场景预览外观与现在一致。
2. `Battlefield.tscn` 替换节点为组件实例；`battlefield.gd` 用 `bind()` + `refresh()` 接管，删旧代码。行为应与迁移前完全一致（AP/HP/头盔/护甲/回合/按钮）。
3. 把强制撤离按钮并入组件，删掉 `_setup_evacuation_controls()` 中的手拼逻辑。
4. 清理 `_update_hud()` 残留调用点，确认信号驱动刷新覆盖所有时机（移动扣 AP、受击、换装、回合开始/结束、战斗结算）。

## 后续可扩展方向（本轮不做）

- **通用 UnitStatusWidget**：点选敌人时弹出的小状态面板（HP/护甲/距离），与本组件共享配色与取数逻辑。
- **Theme 资源化**：把 SystemFont、字号、红黄绿阈值挪到 `conf/themes/battle_hud.tres`，全局统一换肤。
- **多单位支持**：`bind()` 支持切换当前展示单位（未来多干员关卡），或同时挂多个实例。
- **代码挂载入口**：提供 `BattleStatusBar.mount(ui_root: Control)` 静态工厂，供纯代码构建的关卡（如程序化生成的战场）直接挂载，不依赖场景文件。

## 风险与注意点

- 布局从绝对 offset 换成 HBoxContainer 后，各元素间距会和现在有像素级差异，需要一轮目检微调（separator、margin）。
- `bind()` 内部连接信号时要防止重复绑定（记录已绑定的 unit，重绑先 disconnect）。
- 敌方 `Unit` 没有 `get_protection_status()`，组件内必须先做能力判断再取数，避免后续复用到敌人面板时报错。
