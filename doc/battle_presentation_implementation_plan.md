# 战场表现层实施计划（战斗遮罩 / 敌人行动序列 / 回合演出 / 音效接入点）

> 版本 v2（2026-09-29）· 状态：待开工。
> 上游规则：`battlefield_combat_design.md`——本计划**不修改战斗规则**，只调整结算调用时序（roll / apply 拆分）。
> 关联：`battlefield_art_asset_plan.md`（美术交付规范）、`unit_status_widget_proposal.md`（情报遮蔽）、`battle_status_bar_reuse_proposal.md`（状态栏组件）。
> v2 修订（范围收敛）：**不做**战场内的曳光 / 火光 / 后坐 / 闪白与战场飘字；效果全部收进遮罩，且只保留「立绘旁数值面板飘字 + 遮罩抖动」。**音效系统本期不搭建**，只在表现时序中预留按「角色 + 武器」绑定的接入点。

## 0. 已定决策（本计划前提，不再讨论）

| 编号 | 决策 |
|---|---|
| D1 | 敌人回合**不出现 AP 条**。复用点击敌人时的 `UnitStatusWidget` 做跟随面板；`move` 步骤结束后隐藏。 |
| D2 | 本期**不做空格 fast-forward**（"直接结算剩余计划"）。现有空格加速移动的行为保持不变。 |
| D3 | 战斗遮罩对**所有攻击**生效（玩家 + 敌人），无开关、**无跳过**。 |
| D4 | 遮罩美术先用**各角色 idle 母版**顶着：敌人用 `Art/source/urban_night/enemies/masters/` 下的 `*_idle_master.png`，贝妮用 `Art/characters/benny/benny_base_01.png` 立绘；**不使用 64×80 战斗帧**，不做帧动画 / gif 效果。 |
| D5 | 敌方连续攻击时遮罩**持续存在**（一次会话内连播多段），全部攻击播完后才退出。 |
| D6 | 接受把 `resolve_attack` 拆成 **`roll_attack` + `apply_attack`**，扣血发生在遮罩的开火帧。 |
| D7 | 打击感范围收敛：**不做**战场内的曳光 / 火光 / 后坐 / 闪白与战场飘字；只做**遮罩内**的「立绘旁数值飘字」与「遮罩抖动」。 |
| D8 | **不搭建音效系统**（不做总线、播放器、音频资源、音量 UI）；只在切入 / 开火 / 命中 / 未命中 / 击倒等时序点预留 `BattleSfx.play(cue, context)` 空实现 + 「角色 / 武器 → cue」绑定数据结构。 |

## 1. 范围与非目标

### 1.1 本期交付

1. 战斗结算拆分为 roll / apply，扣血时机从"点击当帧"改为"遮罩开火帧"。
2. Fire Emblem 式战斗遮罩：静态母版立绘 + 立绘旁实时数值飘字 + 遮罩抖动 + 多段不消失 + 开火帧结算。
3. 音效接入点预留：本期不产出音频，只在表现时序中留出 cue 调用与"角色 / 武器绑定"数据结构。
4. 敌人回合行动序列（决策 / 执行分离、镜头聚焦、跟随面板、路线绘制）。
5. 回合切换演出。
6. 数值反馈收尾（状态栏差值动画、状态异常图标、撤离倒计时角标）。

### 1.2 非目标（本期不做）

- 战场内的曳光 / 枪口火光 / 后坐 / 受击闪白 / 战场飘字 / 受击暗角（`DamageVignette`）。
- 攻击 / 受击 / 死亡**帧动画**与 `SpriteFrames` 扩展（`attack/hit/death` 帧、`EnemySpriteFramesFactory` 改造）。
- 遮罩的 gif / 帧动画、立绘差分、Boss 专属演出与开场台词。
- 遮罩跳过、自动跳过、fast-forward、命中率显示开关、`cutin_mode` 开关。
- 音效系统本身：音频总线、`AudioStreamPlayer` 池、音频资源、战斗 BGM / 环境音、音量设置 UI。
- 战斗规则、数值、掉落、存档结构的任何修改。

## 2. 现状与差距（计划依据）

### 2.1 差距摘要

| 环节 | 现状 | 证据 |
|---|---|---|
| 帧动画 | 只有 `idle`(4 帧) / `walk`(4–6 帧) / `aim`(4 帧) | `Art/characters/**/*_sprites.tres` |
| 攻击时序 | `spend_ap → resolve_attack → print → 回 IDLE` 同一帧完成 | `Script/battlefield.gd:675-688` |
| 敌方攻击 | `while _try_attack(...): pass` 一帧内打空 AP | `Script/enemy_ai.gd:37,69` |
| 受击 / 死亡 | 无反馈；敌人 `queue_free()` 瞬间消失 | `Script/unit.gd:270`、`Script/battlefield.gd:1151` |
| 数值展示 | 只有顶栏文本与 console 日志；无面板数值变化 | `Script/ui/battle_status_bar.gd:73` |
| 状态异常 | 流血 / 骨折在 UI 中不可见 | `unit_status_widget_proposal.md` 决策② |
| 回合切换 | 无过渡，仅顶栏文本变化 | `Script/battlefield.gd:361` |
| 音效 | 0 音频文件、0 播放器、无总线配置（本期只留接入点） | 全库检索为空 |

### 2.2 敌人 AI 输出模型（P2 的改造依据）

**混合模型：移动逐格 await 播放，攻击同帧直接改数值，全链路没有动作事件层。**

1. 移动：一次 BFS 选终点 → 一次性 `spend_ap(全部步数)` → `set_move_path()` → `Unit._step_to_next()` 逐格推进（`await movement_finished`）；`battlefield_tactics.gd:105-115`。
2. 攻击：`spend_ap` → `resolve_attack()`（内部直接 `receive_damage()` / `absorb_damage_at_location()` / `add_status()`）→ `print`；`enemy_ai.gd:69-77`。
3. `await` 只存在于移动；敌人原地开火时整个回合不产生帧间隔，镜头不跟随，敌人 AP 不可见（本期改用跟随面板，不做 AP 条）。

结论：要按「聚焦 → 路线 → 移动 → 攻击」播放，必须先把 AI 拆成 **`decide_turn()` 纯计算 + 计划执行器**（见 P2）。

## 3. 目标架构

### 3.1 运行时结构

```
Battlefield (Node2D)
├── Enemies / Player                                    ← 单位保持原样，不加特效组件
├── HUD (敌方路径线 EnemyCoverSprite + 玩家 CoverSprite)
├── Camera2D (+ battle_camera.gd：focus_on / release，仅用于敌方回合聚焦)
└── UILayer (CanvasLayer 10)
    ├── BattleStatusBar                                 ← 差值动画（P4）
    ├── UnitStatusWidget                                ← 敌人行动跟随面板（P2 复用）
    └── BattleCutIn / TurnTransition (CanvasLayer 20)    ← 遮罩与回合过场，互斥显示

BattlePresentation (RefCounted)     ← 表现编排：唯一决定表现顺序的地方
BattleSfx（本期空实现）              ← cue 接入点，绑定角色 / 武器，后续接音频系统
```

### 3.2 新增 / 修改文件清单

| 文件 | 动作 | 说明 |
|---|---|---|
| `Script/battle_combat_resolver.gd` | 改 | 拆出 `roll_attack()` / `apply_attack()`，`resolve_attack()` 变兼容包装 |
| `Script/battle/battle_presentation.gd` | 新增 | 表现编排（攻击、敌人回合） |
| `Script/battle/battle_cut_in.gd` + `HUD/battle_cut_in.tscn` | 新增 | 战斗遮罩，CanvasLayer 20（立绘 / 数值飘字 / 抖动） |
| `Script/battle/battle_sfx.gd` | 新增 | 音效接入点：cue → 绑定解析 + 空播放实现 |
| `Script/battle/battle_camera.gd` | 新增 | 仅 `focus_on(unit)` / `release()`（敌方回合聚焦，不含抖动） |
| `Script/battle/enemy_action_plan.gd` | 新增 | ActionPlan 结构与执行器 |
| `Script/battle/turn_transition.gd` + `HUD/turn_transition.tscn` | 新增 | 回合切换演出 |
| `conf/battle/presentation.json` | 新增 | 遮罩节奏 / 抖动强度 / 停留时长 |
| `conf/battle/cutin_art.json` | 新增 | 遮罩立绘路径 / 高度比 / 偏移 / 翻转 |
| `conf/battle/sfx_bindings.json` | 新增 | 「角色 / 武器 → cue」绑定表（本期只落数据） |
| `tools/extract_cutin_art.mjs` | 新增（工具） | 母版抠底 → `Art/ui/battle_cutin/` |
| `Script/battlefield.gd` | 改 | 接入表现编排、输入封锁、敌人回合序列、`_draw_path_on()` 抽取、击倒延后 |
| `Script/enemy_ai.gd` | 改 | 拆出 `decide_turn(enemy) -> EnemyActionPlan` |
| `Script/ai/battlefield_tactics.gd` | 改 | 拆 `plan_move()`（只读）/ `execute_move()`（改状态） |
| `Script/ui/unit_status_widget.gd` | 改 | 增加只读模式（隐藏「收起」按钮）供敌人行动跟随使用 |
| `Script/ui/battle_status_bar.gd` | 改 | `set_value_with_delta()`、受击红闪、护甲破碎态 |

### 3.3 核心接口

```gdscript
# battle_combat_resolver.gd —— P0
func roll_attack(attacker: Unit, defender: Unit) -> Dictionary
    # 只掷骰与读快照：hit / hit_chance / roll / distance / location / raw_damage / 公式 / 快照
    # 零副作用：不改 HP、护甲、状态，不发信号
func apply_attack(attacker: Unit, defender: Unit, roll: Dictionary) -> Dictionary
    # 护具吸收 → receive_damage() → 伤口判定；返回与现 resolve_attack 同构的合并结果
func resolve_attack(attacker: Unit, defender: Unit) -> Dictionary
    # 兼容包装：apply_attack(attacker, defender, roll_attack(...))

# battle_cut_in.gd —— P1
func begin_session(attacker: Unit) -> void
func set_defender(defender: Unit) -> void
func play_attack_lead_in(roll: Dictionary) -> void   # await；播放到开火帧返回
func show_result(applied: Dictionary) -> void        # 立绘旁数值飘字 / 血条 / 伤口 / 击倒
func finish_round() -> void                          # await；停留读数
func end_session() -> void                           # 连续攻击结束才滑出
func is_open() -> bool

# battle_presentation.gd —— P1/P2
func play_attack(attacker: Unit, defender: Unit) -> Dictionary   # 单次攻击（玩家点击 / 敌方一段）
func play_enemy_turn(enemy: Unit, plan: EnemyActionPlan) -> void # 敌方整回合
func is_busy() -> bool

# enemy_ai.gd —— P2
func decide_turn(enemy: Unit) -> EnemyActionPlan      # 纯计算，零状态修改

# battle_sfx.gd —— P1（本期空实现）
func play(cue: StringName, context: Dictionary = {}) -> void
    # cue：&"cutin_in" / &"attack_fire" / &"hit_armor" / &"hit_flesh" / &"miss" / &"unit_down"
    # context：{"attacker": Unit, "defender": Unit, "weapon_id": String}
func resolve_binding(cue: StringName, context: Dictionary) -> String   # 读 sfx_bindings.json
```

## 4. 分阶段任务

依赖关系：P0 → P1 → P2；P1/P2 → P3；P4 可与 P2/P3 并行；P5 收尾。

### P0 结算拆分 roll / apply（0.5 天，独立）

**目标**：把"掷骰"与"改数值"分开，为遮罩的开火帧扣血铺路。

- [ ] `roll_attack()`：掷命中骰 + 部位骰 + 全部伤害预计算，**零副作用**；未命中在 roll 阶段就返回 `hit=false`。
- [ ] `apply_attack(roll)`：`absorb_damage_at_location()` → `receive_damage()` → `_apply_unprotected_debuffs()`；把 roll 的字段合并进返回结果，保证与现 `resolve_attack()` 输出**逐字段同构**。
- [ ] `resolve_attack()` 改为兼容包装，现有调用点（`battlefield.gd`、`enemy_ai.gd`）本阶段不动。
- [ ] 对照测试（临时 headless 脚本）：同一局面、同一随机种子各跑 200 次，断言 `resolve_attack()` 与 `apply(roll())` 的结果字段完全一致。
- [ ] 确认 RNG 消耗顺序不变：命中骰 → 部位骰（仅命中）→ 伤口骰（仅 apply）。

**验收**：`BattleCombatLogFormatter.format_attack()` 输出的日志在拆分前后逐字段一致；玩家 / 敌人攻击结果无变化。

### P1 战斗遮罩（2.5 天，依赖 P0）

**目标**：Fire Emblem 式切入——左攻右守、静态母版、多段不消失、开火帧扣血；演出效果只做「立绘旁数值飘字 + 遮罩抖动」。

- [ ] 资产准备：`tools/extract_cutin_art.mjs` 复用 `game-art` skill 的 `extract_chroma.mjs`，把 5 张敌人 `*_idle_master.png`（1024×1024 绿幕）抠底为透明 PNG → `Art/ui/battle_cutin/<id>_idle.png`；贝妮直接引用 `Art/characters/benny/benny_base_01.png`。
- [ ] `conf/battle/cutin_art.json`：`unit_id → {path, height_ratio, offset, flip}`；统一"按舞台高度归一 + 底部对齐"，逐角色微调（贝妮 896×1200 与敌人 1024×1024 比例不同）。
- [ ] `HUD/battle_cut_in.tscn` + `Script/battle/battle_cut_in.gd`（CanvasLayer 20）：
  - `Dim`（黑 65%）、`Stage`（左攻右守立绘 + 名牌 + HP / 护甲条）、`DamageLabels`（立绘旁数值飘字层）。
  - 立绘用 `TextureRect`（`STRETCH_KEEP_ASPECT_CENTERED`，保持默认线性过滤）；**不做 SpriteFrames 播放**。
- [ ] 数值面板飘字（§5.2）：飘字锚定在**受击方立绘旁边**上浮淡出；同击多数字（护甲 / 生命 / 状态）做垂直错位排队；HP / 护甲条按结算结果动画下降。
- [ ] `_shake(intensity)`：**遮罩舞台位移抖动**（全屏遮罩下世界相机抖动不可见，所以抖遮罩自身）；强度与时长进 `presentation.json`。抖动只作用于 `Stage`，`DamageLabels` 保持稳定以免数字发糊。
- [ ] 会话模型：`begin_session(attacker)`（滑入一次）→ `play_attack_lead_in(roll)`（对峙 → 开火，await 到开火帧）→ `apply_attack()` → `show_result(applied)` → `finish_round()`；多段攻击循环 `play_attack_lead_in / show_result`，**不退出遮罩**；`end_session()` 才滑出。
- [ ] 目标切换：`set_defender()` 支持同一会话内切换受击方（换位淡入 / 滑动）。
- [ ] 音效接入点（D8，本期空实现）：在 `cutin_in` / `attack_fire` / `hit_armor` / `hit_flesh` / `miss` / `unit_down` / `cutin_out` 七处调用 `BattleSfx.play(cue, context)`；`context` 携带 attacker / defender / weapon_id；`debug_sfx` 开启时打印解析结果，便于后续接音频。
- [ ] 击倒与掉落延后：`_on_unit_defeated()` 只做组移除与"待处理"记录（停止被瞄准 / 停止 AI），`queue_free()` 与掉落箱生成统一挪到 `end_session()` 之后；**玩家被击倒**同样先播完遮罩再进 `_end_battle_as_failure()`。
- [ ] 数据来源全部读取结算结果（见 §5.3），不新增判定。
- [ ] 遮罩期间锁定战场输入（保留相机拖拽）；节奏参数进 `presentation.json`。

**验收**：

1. 敌方 4 AP 连打只进 / 出遮罩各一次，段间遮罩不闪断。
2. 在 `apply_attack()` 前后打点，确认扣血发生在开火帧而非点击帧。
3. 左攻右守；MISS / 护甲吸收 / 真实伤害 / 伤口 / 击倒表现正确；数值飘字在受击方立绘旁可读。
4. 抖动幅度不导致立绘或数字模糊；同击多数字不重叠。
5. 掉落箱在遮罩结束后出现；`remove_from_group` 仍在结算当帧执行（不可再被瞄准 / 行动）。
6. `BattleSfx.play()` 全部 cue 均被调用到（打印验证），但不产生任何音频系统依赖。

### P2 敌人行动序列（1.5 天，依赖 P1）

**目标**：敌人回合"聚焦 → 跟随面板 → 路线 → 移动 → 攻击"，去掉 AP 条与 fast-forward。

- [ ] `Script/battle/enemy_action_plan.gd`：`steps`（`move` / `attack` / `wait`）+ `EnemyActionPlan` 执行器。
- [ ] `Script/enemy_ai.gd::decide_turn(enemy) -> EnemyActionPlan`：纯计算，复用 `BattlefieldPerception` / `BattlefieldTactics` 的只读部分；`run_turn()` 保留为兼容入口（内部 = decide + execute）。
- [ ] `Script/ai/battlefield_tactics.gd`：拆 `plan_move()`（只读，返回路径与 AP 成本）与 `execute_move()`（扣 AP + `set_move_path()`）；`patrol()` / `retreat()` / `find_attack_path()` 改为只读取值。
- [ ] `battlefield._run_enemy_phase()`：逐个敌人 `decide_turn` → `BattlePresentation.play_enemy_turn(enemy, plan)` → `status_bar.refresh()`。
- [ ] 镜头：`battle_camera.focus_on(enemy)`（0.25 s）→ 行动收尾 `release()`；`presentation.json` 可配是否聚焦。
- [ ] 跟随面板：**有 `move` 步骤时**行动开始 `status_widget.show_for(enemy)`，`move` 步骤完成即 `hide_panel()`（D1）；无移动直接进入遮罩、不显示面板。
  - [ ] `Script/ui/unit_status_widget.gd` 增加只读模式：隐藏「收起」按钮（避免行动中误点）。
  - [ ] 未揭示的敌人保持现有遮蔽显示（行动本身不揭示情报，沿用 `UnitIntelTracker` 规则）。
- [ ] 路线绘制：`_draw_path()` 抽成 `_draw_path_on(line, path)`；新增 `EnemyCoverSprite`（橙红 `#FF6B57`，透明度 0.35，`z_index = 10`）；起点格用 `moverange.png` 做呼吸高亮。
- [ ] 移动表现：沿用现有逐格移动；**不显示 AP 条、不显示 AP 数字**。
- [ ] 行为等价回归：固定种子对照新旧实现的"移动目标格 / 攻击次数 / AP 消耗 / 最终位置"日志，必须一致。
- [ ] 执行前兜底：每步开始前重算 `is_walkable`，目标格被占时跳过该步并在日志标记。

**验收**：镜头聚焦正确；面板跟随并在移动结束后消失；路线可见且不与玩家绿线互相覆盖；敌人移动-攻击序列与改造前逐字段一致。

### P3 回合切换演出（0.5 天，依赖 P1）

- [x] `HUD/turn_transition.tscn` + `Script/battle/turn_transition.gd`（CanvasLayer 20，与遮罩互斥）：
  - 玩家变体：青蓝斜向擦除 + 「第 N / M 回合 · 玩家行动」，0.2 s 擦入 → 0.5 s 停留 → 0.3 s 擦出。
  - 敌方变体：橙红横向条带 + 「敌方行动」，约 0.8 s。
- [x] 接入 `_on_turn_started()` 与 `_on_phase_changed(ENEMY_PHASE)`；敌方横幅擦出后立刻开始第一次镜头聚焦。
- [x] 撤离倒计时行：`evacuation_pending` 时横幅追加「撤离倒计时：撑过本回合」。
- [x] 音效接入点（D8）：`turn_player` / `turn_enemy` 两个 cue 走 `BattleSfx.play()`（空实现）。

**验收**：回合切换有 1 s 左右过场；玩家 / 敌方观感明确区分；不造成输入卡死。

### P4 数值反馈收尾（0.5 天，可并行）

- [ ] `BattleStatusBar.set_value_with_delta()`：HP / AP 差值角标、主角屏幕红闪已实现；护甲 / 头盔归零置灰 + 「破」标记待完成；`refresh()` 语义不变。
- [x] 单位头顶状态图标（流血 / 骨折 + 层数角标）：状态新增或叠加时脉冲；状态栏与单位面板同步刷新（不做战场飘字）。
- [x] 撤离倒计时角标（状态栏右侧；受击不再中断撤离，保留至下回合结算）。

**验收**：掉血 / 掉 AP / 流血都有可见来源；状态来源不再需要看日志。

### P5 回归与打磨（0.5 天）

- [ ] 全流程回归：新游戏 → 指挥中心 → 战场 → 交战（玩家 / 敌方） → 搜箱 → 撤离成功 / 撤离失败。
- [ ] 性能：3 敌人 ×4 段连续遮罩播放，帧率稳定。
- [ ] 存档兼容回归：战斗前后存档、装备耐久、临时容器。
- [ ] 更新 `doc/project.md` 的战场章节与本计划状态标记。

## 5. 资产与数据表

### 5.1 遮罩立绘（本期用母版顶替）

| 单位 | 源文件 | 处理 | 运行时路径 |
|---|---|---|---|
| 贝妮 | `Art/characters/benny/benny_base_01.png`（896×1200，已有 alpha） | 直接引用 | 同左 |
| 街区掠夺兵 | `Art/source/urban_night/enemies/masters/raider_infantry_idle_master.png` | 抠底 | `Art/ui/battle_cutin/raider_infantry_idle.png` |
| 斥候掠夺者 | `Art/source/urban_night/enemies/masters/raider_scout_idle_master.png` | 抠底 | `Art/ui/battle_cutin/raider_scout_idle.png` |
| 护盾掠夺者 | `Art/source/urban_night/enemies/masters/raider_bulwark_idle_master.png` | 抠底 | `Art/ui/battle_cutin/raider_bulwark_idle.png` |
| 辉石猎犬 | `Art/source/urban_night/enemies/masters/pyroxene_hound_idle_master.png` | 抠底 | `Art/ui/battle_cutin/pyroxene_hound_idle.png` |
| 晶涌哨戒机 | `Art/source/urban_night/enemies/masters/pyroxene_sentry_idle_master.png` | 抠底 | `Art/ui/battle_cutin/pyroxene_sentry_idle.png` |

注意事项：

- 抠底后逐张检查绿边；统一按"舞台高度归一 + 底部对齐"，用 `cutin_art.json` 的 `offset` 修左右与高低差。
- 贝妮立绘（写实比例）与敌人母版（像素风）同框比例可能不一致，先接受；后续「gif 化」时再统一出战斗专用立绘。
- 立绘是 1024 级母版 / 896×1200 立绘，屏幕上是**缩小**显示，保持默认线性过滤即可；不要再把 64×80 战斗帧放大使用（D4 已排除）。

### 5.2 立绘旁数值飘字样式（遮罩内）

| 用途 | 文案示例 | 颜色 | 字号 | 动效 |
|---|---|---|---:|---|
| 生命伤害 | `-8` | `#FF5252` | 24（头部 ×1.3） | 立绘旁上浮 28 px + 淡出，0.7 s |
| 护甲吸收 | `-12 护甲` | `#81DFF6` | 18 | 上浮 20 px，0.6 s |
| 护甲破碎 | `护具破碎` | `#D6E2E8` | 18 | 左右抖 2 次，0.5 s |
| 未命中 | `MISS` | `#9AA7B4` | 20 | 缓上浮，0.5 s |
| 状态触发 | `流血！` / `骨折！` | `#B388FF` / `#FFB74D` | 18 | 放大入场后上浮 |

（本表不再包含治疗 `+20`：本期不涉及治疗演出，治疗反馈由状态栏与背包面板承担。）

### 5.3 遮罩数据来源（零新增判定）

| 显示项 | 来源 |
|---|---|
| 名牌 / 阵营 | `Unit.unit_name` / `Unit.faction` |
| HP 条 | 开场读 `defender.current_hp`（apply 之前），结束值 = 起始值 − `applied.damage` |
| 护甲条 | 玩家 `get_protection_status()`；敌人 `head_armor / body_armor` |
| 未命中 | `roll.hit == false` |
| 数值 | `applied.damage_formula.absorbed / final_hp_damage` |
| 伤口 | `applied.injury_checks[].triggered` |
| 击倒 | `applied.defeated` |

### 5.4 音效接入点与绑定（本期只落数据）

cue 清单一律走 `BattleSfx.play(cue, context)`，实现为空；绑定表 `conf/battle/sfx_bindings.json` 先定义结构，后续接音频系统时直接消费：

```json
{
  "unit": {
    "benny": {"fire": "sfx_weapon_smg_fire", "hurt": "sfx_player_hurt", "down": "sfx_unit_down"},
    "raider_infantry": {"fire": "sfx_rifle_fire", "hurt": "sfx_enemy_hurt"}
  },
  "weapon": {
    "weapon_benny_defender_9": {"fire": "sfx_weapon_defender9_fire"}
  },
  "default": {
    "hit_armor": "sfx_hit_armor",
    "hit_flesh": "sfx_hit_flesh",
    "miss": "sfx_bullet_whiz",
    "down": "sfx_unit_down",
    "cutin_in": "sfx_cutin_in",
    "cutin_out": "sfx_cutin_out"
  }
}
```

解析优先级：`weapon[cue]` > `unit[cue]` > `default[cue]`。本期验收只看"cue 是否在正确时序被调用 + 绑定解析结果是否正确打印"。

| cue | 触发点 |
|---|---|
| `cutin_in` / `cutin_out` | 遮罩滑入 / 滑出 |
| `attack_fire` | 开火帧（context 带 attacker 与 weapon_id） |
| `hit_armor` / `hit_flesh` | 命中且护具吸收 / 造成真实伤害 |
| `miss` | `roll.hit == false` |
| `unit_down` | `applied.defeated` |
| `turn_player` / `turn_enemy` | 回合过场（P3） |

### 5.5 数据表

| 文件 | 内容 |
|---|---|
| `conf/battle/presentation.json` | 遮罩节奏（切入 / 对峙 / 开火 / 停留 / 滑出）、抖动强度、是否聚焦 |
| `conf/battle/cutin_art.json` | 遮罩立绘路径 / 高度比 / 偏移 / 翻转 |
| `conf/battle/sfx_bindings.json` | 角色 / 武器 / 默认 → cue 绑定（本期只落数据） |

## 6. 回归与验收清单

| 检查项 | 期望 |
|---|---|
| 结算一致性 | `resolve_attack()` 与 `apply(roll())` 结果逐字段一致（固定种子 200 次） |
| 伤害时机 | 扣血发生在遮罩开火帧，点击帧不结算 |
| 连续攻击 | 敌方 N 连击只进出遮罩一次；段间无闪断 |
| 遮罩表现 | 左攻右守；MISS / 护甲 / 真伤 / 伤口 / 击倒表达正确；飘字不重叠、不模糊 |
| 敌人行为等价 | 改造前后移动目标、攻击次数、AP 消耗、最终位置一致 |
| 面板跟随 | 敌人在移动中面板跟随、无抖动越界；`move` 结束即消失 |
| 击倒顺序 | 组移除当帧生效；掉落箱与 `queue_free` 在遮罩结束后 |
| cue 接入点 | 七个 cue 在正确时序被调用，绑定解析可打印；无音频系统依赖 |
| 日志 | 两条攻击日志（中文 + JSON）字段不变 |
| 存档 | 战斗前后存档、护甲耐久、临时容器行为不变 |
| 性能 | 3 敌人 ×4 段连续遮罩播放不掉帧 |

## 7. 风险与对策

| 风险 | 对策 |
|---|---|
| 遮罩无跳过 → 敌方回合变长（3 敌 ×4 击可达 20 s+） | 单段节奏压到 1.2–1.5 s；先记录实际耗时，跳过 / 自动跳过列入 §8 首批后续项 |
| roll / apply 分离后 RNG 顺序被其他系统插入消耗 | 攻击严格串行（表现队列保证 roll 后立即 apply）；对照测试覆盖 |
| 遮罩期间延后 `queue_free` / 掉落 | 组移除与"不可被瞄准"仍在结算当帧；只延后视觉与物品生成，回归清单覆盖 |
| 母版抠底绿边、比例不一 | 抠底后逐张目检；统一高度归一 + 底部锚点 + 逐角色 offset；贝妮立绘风格差异先接受 |
| 抖动导致立绘 / 数字模糊 | 抖动只作用于 `Stage`；幅度上限 6–8 px、时长 ≤0.2 s；数值层不参与抖动 |
| 同击多数字重叠 | 90 ms 排队 + 垂直错位 + 水平抖动；单侧最多同时 3 条 |
| `UnitStatusWidget` 复用引入交互副作用 | 新增只读模式隐藏「收起」按钮；行动结束强制 `hide_panel()` |
| 镜头聚焦与面板跟随同时移动造成观感抖动 | 聚焦用缓动（0.25 s）并在聚焦期间冻结面板位置更新（或让面板跟随使用同一缓动） |
| AI 重构悄悄改变敌人强度 | 固定种子对照日志（移动目标格 / 攻击次数 / AP 消耗） |
| 音效接入点被后续音频系统推翻 | 本期只固定 cue 名与 context 结构，并把绑定表独立成 JSON；音频系统实现时只替换 `BattleSfx.play()` 内部 |
| 存档兼容 | 表现状态不写入战斗存档字段 |

## 8. 后续（不在本期，按优先级）

1. 音效系统搭建：AudioServer 总线、`AudioStreamPlayer` 池、音频资源、音量设置 UI；直接消费本期的 cue 与绑定表。
2. 遮罩跳过 / 自动跳过（敌方）与整体节奏压缩。
3. 战场内打击感（曳光 / 火光 / 后坐 / 闪白 / 战场飘字 / 受击暗角）——如届时仍需要。
4. 攻击 / 受击 / 死亡帧动画（`SpriteFrames` 扩展、`EnemySpriteFramesFactory` 支持任意动画名与 `loop`）与遮罩的 gif / 帧动画化。
5. `resolve_attack` 只保留 roll / apply 两段（删除兼容包装），清理旧调用点。
6. 敌人空格 fast-forward（一次性结算剩余计划）。
7. 命中率显示、`cutin_mode` 三档开关、Boss 专属遮罩与台词。
