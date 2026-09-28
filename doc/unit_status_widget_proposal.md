# 通用 UnitStatusWidget 设计提案

> **实施状态（2026-09-28）**：已按确认后的决策实现。决策结果：①命中才揭示（`resolve_attack` 的 `hit` 为真时 `mark_revealed`，`damaged` 信号兜底）；②AP 只显示总值（回合中剩余 AP 对玩家无意义且易误导），状态异常行移除；③IDLE 左键点选弹出，带"收起"按钮，点其他单位重新渲染，点空地/选中玩家/切换状态/结束回合均隐藏；④面板 `_process` 跟随单位并 clamp 在屏幕内。Theme 资源化（`conf/themes/battle_hud.tres` + `BattleHudTheme`）与代码挂载入口（`UnitStatusWidget.mount` / `BattleStatusBar.mount`）同步落地；多单位仅结构预留。另附带修复：结束回合按钮点击即禁用直到下一玩家回合（防抖），玩家移动动画未播完时延迟切敌方回合，敌方回合阶段禁止按钮与地图交互。无头功能测试全绿。

配套 `doc/battle_status_bar_reuse_proposal.md` 的"后续扩展"落地。目标：点选地图上的单位（先做敌人）弹出跟随式状态面板，数值默认遮蔽（`??? / ???`），被攻击过才揭示真实数值。

## 现有交互盘点（决定触发方式）

`battlefield.gd` 的鼠标输入现状：

- 左键按下/抬起已被相机拖拽追踪占用（`_handle_camera_drag_input`），拖拽阈值 5px 内的点击才进入 `_handle_left_click()`。
- `_handle_left_click()`：ATTACK_STATE 点敌人=攻击；MOVE_STATE 点地面=移动；**IDLE 状态点敌人格子目前无任何行为**（只响应玩家自己格子）。
- 右键：玩家格子弹 BattleContextMenu，容器弹搜索菜单，其余位置取消状态。

结论：**IDLE 状态左键点选敌人**是零冲突的接入点；ATTACK_STATE 的点选攻击不受影响。关闭时机复用"点击其他位置"的模式。

## 组件设计

### 文件

| 文件 | 内容 |
| --- | --- |
| `HUD/unit_status_widget.tscn` | 面板场景（PanelContainer） |
| `Script/ui/unit_status_widget.gd` | `class_name UnitStatusWidget extends PanelContainer` |
| `Script/ui/unit_intel_tracker.gd` | `class_name UnitIntelTracker extends RefCounted`，遮蔽/揭示状态 |
| `conf/themes/battle_hud.tres` | 战场 HUD 共享 Theme |

### 节点结构（行由代码统一生成，天然支持多单位扩展）

```
UnitStatusWidget (PanelContainer, theme variation "BattlePanel", visible=false, mouse_filter=IGNORE)
└── Content (VBoxContainer)
    ├── NameRow (HBox: NameLabel + 阵营/等级 tag)
    ├── HPRow      ("生命  60 / 100" 或 "生命  ??? / ???")
    ├── HeadArmorRow / BodyArmorRow
    ├── APRow
    └── StatusRow (状态异常 tag，空时隐藏)
```

每行由 `_make_stat_row(title) -> Label(value)` 工厂生成并存入 `_rows: Dictionary`，加一行=加一个条目，不改场景。

### 对外接口

```gdscript
# 显示/隐藏；unit 为 null 时隐藏
func show_for(unit: Unit) -> void
func hide_panel() -> void

# 遮蔽策略注入：widget 每次刷新询问 tracker 该单位是否已揭示
func set_intel_tracker(tracker: UnitIntelTracker) -> void

# 代码挂载入口（纯代码关卡用）
static func mount(parent: Control) -> UnitStatusWidget
```

多单位预留：`show_for_units(units: Array[Unit])` 暂不实现，但 Content 的行工厂 + `_rows` 结构已按"每个单位一组行"可扩展设计（未来加单位分隔行或页签即可）。

### 数值遮蔽（UnitIntelTracker）

```gdscript
class_name UnitIntelTracker

func mark_revealed(unit: Unit) -> void   # 记录 instance_id
func is_revealed(unit: Unit) -> bool
func reset() -> void
```

- 揭示时机（双保险）：
  1. `combat_resolver.resolve_attack()` 结算后，battlefield 对 defender 调 `mark_revealed`（**是否含未命中见决策点**）；
  2. tracker 内部监听每个注册单位的 `damaged` 信号兜底（敌人内讧、流血等状态伤害也会揭示）。
- 生命周期：每场战斗在 `battlefield._ready()` new 一个，不落盘；跨战斗记忆情报是后续需求再说。
- 遮蔽范围：HP、头甲、身甲显示 `??? / ???`；**姓名、阵营、状态异常常显**（视觉可见信息）。AP 是否遮蔽见决策点。
- 揭示后：`damaged` / `status_effects_changed` 信号驱动实时刷新。

### 取数抽象（复用给玩家/友军的关键）

widget 不直接读 `Unit` 字段，而是走一个视图数据构建函数：

```gdscript
func _build_view_data(unit: Unit) -> Dictionary:
	# 基础：unit_name / faction / current_hp / max_hp / head_armor / body_armor / action_points / status_effects
	# Player 特化：has_method("get_protection_status") 时用装备名+耐久替代 head/body_armor
```

同一个 widget 由此可挂玩家（常驻或按键呼出）、未来友军单位。

### 定位与跟随

- 挂在 `UILayer/UIRoot`（CanvasLayer 内，不受 Camera2D 影响），世界→屏幕坐标手动换算：
  `var screen_pos := get_viewport().get_canvas_transform() * unit.global_position`
- 显示期间在 `_process` 持续跟随（敌人移动、相机拖拽都跟得上）；
- 默认锚在单位右上方（sprite offset 约 (32,40)，取头顶上方 ~24px）；靠近屏幕右/上边缘时翻转到左侧/下方，并 clamp 到视口内；
- `mouse_filter = IGNORE`，不挡地图点击。

### Theme 资源化（顺带落地）

`conf/themes/battle_hud.tres`：

- `default_font`：SystemFont（PingFang SC / Hiragino Sans GB / Arial），从两个组件的 `_configure_fonts()` 迁出；
- type variation：`BattleStatLabel`（18px）、`BattleStatLabelLarge`（24px）、`BattleTurnLabel`、`BattlePanel`（PanelContainer stylebox，参考 BattleContextMenu 的 `_make_style()` 深色底+描边）；
- 颜色归属：静态配色（AP 蓝、回合金、面板底色）进 Theme；**红/黄/绿动态阈值色保留为共享函数**（`battle_hud_theme.gd` 静态方法 `ratio_color(current, max)`），BattleStatusBar 与 widget 共用，因为它按数值比例计算，不是主题常量。
- 迁移后删除 BattleStatusBar 里的 `_configure_fonts()`，改为 `theme = preload("res://conf/themes/battle_hud.tres")` + 各 Label 设 theme variation。

## Battlefield 接入点（改动清单）

1. `_ready()`：`unit_intel = UnitIntelTracker.new()`；`status_widget = UnitStatusWidget.mount($UILayer/UIRoot)`；`status_widget.set_intel_tracker(unit_intel)`。
2. `_handle_left_click()` IDLE 分支开头：`_get_enemy_at_node(click_node)` 命中 → `status_widget.show_for(enemy)` 并 return；未命中且面板开着 → `hide_panel()`。
3. 攻击结算处（`_handle_left_click` ATTACK_STATE）：`resolve_attack` 后 `unit_intel.mark_revealed(target)`，若 widget 正显示该单位则刷新。
4. `unit.defeated` → 面板隐藏（现有 `_on_unit_defeated` 里加一行）。
5. 右键菜单打开 / 状态切换到 ATTACK、MOVE 时隐藏面板，避免遮挡（可选）。

## 实施顺序

1. Theme 资源 + `ratio_color` 共享函数；BattleStatusBar 切换到 Theme（行为不变，先验证换肤无回归）。
2. UnitIntelTracker + UnitStatusWidget 场景/脚本，静态假数据调外观。
3. battlefield 接入五个触点，联调揭示逻辑。
4. 无头冒烟 + 编辑器目检。

## 待确认决策点

1. **揭示条件**：攻击过即揭示（含未命中，"你已经观察过它"），还是必须命中/造成伤害才揭示？（推荐前者，实现简单且符合直觉）
2. **AP 是否遮蔽**：敌人 AP 属于"可观察行为"，建议常显；若要硬核情报玩法就一起遮蔽。
3. **触发方式确认**：IDLE 左键点选（推荐，零冲突）；备选是悬停 0.5s 自动弹出，但会和相机拖拽、高亮格子提示打架，不推荐。
4. **面板跟随 vs 固定**：推荐跟随（敌人被击退/移动时不错位）；固定弹出实现更省，二选一。
