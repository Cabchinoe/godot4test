# 音效资产清单(SFX Asset Manifest)

> 版本 v1.4(2026-09-30)· 配套 `Script/battle/battle_sfx.gd` + `conf/battle/sfx_bindings.json`
> 全表 cue 命名严格沿用 `BattleSfx.play(cue, context)` 现有约定,后续接音频时无需改 GDScript。
> v1.1 修订:A.1 已落盘(2 个 cue,源 mp3 → ffmpeg 切 wav);补 §6 实测经验(AI 音频模型对纯工业音效的输出特点 + 切片策略)。
> v1.2 修订:**B 章节移除独立 cue**,回合过渡复用 A.1 的 `sfx_cutin_in` / `sfx_cutin_out`(横幅与遮罩共用一对反向 cue,语义一致且避免冗余);撤销已生成的 `sfx_turn_player/enemy/evacuation`;总 cue 数 92 → **89**;批次 1 从 26 → **23**;BattleSfx 接入真实播放(AudioStreamPlayer 池 + host 注入)。
> v1.3 修订:**澄清语义分离**——A.1 的 `cutin_in/out` **仅服务回合横幅(`TurnTransition`)**,**不再**被战斗遮罩(`BattleCutIn`)调用;改名为 `turn_in/out`(cue key + 文件名同步);战斗遮罩另起 `battle_cutin_in/out` 两个 cue,目前留空待后续生成;总 cue 数 89 → **91**;批次 1 从 23 → **25**。
> v1.4 修订:**C 类 UI 通用 7/7 全部落盘**——`ui_open` / `ui_close` 改走**程序合成**(numpy 分层合成 → ffmpeg 编 MP3),一次出 4 个变体(wood / wood2 / latch / soft),经 `audios_understand` 试听评审 + 人工试听后选定 **soft(布幕/皮绒)** 版;`conf/battle/sfx_bindings.json` 的 `ui_open` / `ui_close` 已回填;新增 §6.5 合成配方与验证闭环;已落盘 2 → **9**。**并新增 autoload `UiSfx`,把 C 类 7 个 cue 全量接线到所有场景**(按钮/悬停/面板开关/对话框确认取消/失败文案),详见 §C 与 §4.1。
> v1.5 修订(2026-10-10):**A.2 收录 2 个 SMG 家族 cue**——`sfx_weapon_hare_hopper_fire`(Silenced SMG 三点射 ×2 直拼,0.883s)/ `sfx_weapon_dawn_pulse_fire`(dimapain sci-fi shot 前 1s + hare_hopper 版双轨叠加,1.000s),来源均 CC0;已落盘 10 → **12**;候选与加工中间产物已按「收录」流程清理;详见 §6.8。
> v1.6 修订(2026-10-10):**敌人开火绑定定案**——敌人没有装备系统,**不引入武器 id / 新属性**:开火直接按 `art_key` 绑在 `units[<art_key>].attack_fire`(复用 `resolve_binding` 现成的 units 通道,零代码改动);`weapons[]` 只保留贝妮 3 把,弃用 `weapon_enemy_rifle` 等 5 个敌人武器计划名;cue key 定为 `sfx_weapon_raider_infantry_fire` / `sfx_weapon_raider_scout_fire` / `sfx_weapon_raider_bulwark_fire` / `sfx_weapon_hound_bite` / `sfx_weapon_sentry_laser`(归属一眼可见)。
> v1.7 修订(2026-10-10):**A.2 收录 3 个敌人开火音**(raider 三件套)——`sfx_weapon_raider_infantry_fire`(AK-47 单发切前 0.8s)/ `sfx_weapon_raider_scout_fire`(autorifle metallic punchy 切前 0.7s)/ `sfx_weapon_raider_bulwark_fire`(pgi Heavy weapon 002 切前 0.8s),均 CC0 + 尾 30ms 淡出;已落盘 12 → **15**;候选与中间产物已按「收录」流程清理;详见 §6.9。
> v1.8 修订(2026-10-10):**A.2 9/9 收尾**——收录 `sfx_weapon_hound_bite`(Escorpion_melee 原长直用 0.556s)/ `sfx_weapon_sentry_laser`(Spaceship laser burst + Laser Gun 01 各取前 1s 双轨合并 1.000s)/ `sfx_attack_fire_default`(machinegun-one-shot ×2 跨淡化直拼 0.701s);`conf/battle/sfx_bindings.json` 的 `default.attack_fire` 由空串回填;已落盘 15 → **18**;详见 §6.10。
> v1.9 修订(2026-10-10):**移动类 cue 全部改按角色自身绑定**——D.1 `sfx_move_step` 更名 **`sfx_move_step_benny`**、D.2 `sfx_move_blocked` 更名 **`sfx_move_blocked_benny`**,均绑 `units[benny].*`;新增 M 类「角色移动脚步(补充)」,补 5 个敌人脚步 cue(`sfx_move_step_raider_infantry` / `raider_scout` / `raider_bulwark` / `pyroxene_hound` / `pyroxene_sentry`,绑 `units[<art_key>].move_step`);分类数 11 → **12**(A、C~M),表内口径 cue 总数 81 → **86**;详见 §M。
> v1.10 修订(2026-10-10):**M 类收录 4 件脚步**——`sfx_move_step_benny`(Freesound DavidJohnson2019 `Footsteps Run` 原长 3.91s)/ `sfx_move_step_raider_scout`(Mixkit `Footsteps on mattress loop` 取前 5s)/ `sfx_move_step_raider_bulwark`(Mixkit `Giant monster footstep` 取前 5s)/ `sfx_move_step_pyroxene_hound`(Freesound qubodup `Dog Running Past` 取 2s~5s = 3.0s);已落盘 18 → **22**;raider_infantry / pyroxene_sentry 候选不满意、重搜中;详见 §6.11。
> v1.11 修订(2026-10-10):**M 类 `pyroxene_sentry` 收录**——Mixkit `Robot step` #2530 取前 5s(5.000s);已落盘 22 → **23**;M 类 5/6,仅剩 `raider_infantry`(改角度:雨中砖地步行/跑步,重搜中);详见 §6.11。
> v1.12 修订(2026-10-10):**M 类 6/6 收官**——`sfx_move_step_raider_infantry`(Freesound `Small Puddle Splash` **×10 等间隔直拼** @450ms/步 = 4.456s,雨中踩水步感);已落盘 23 → **24**;M 类全齐;详见 §6.11。
> v1.13 修订(2026-10-10):**M 类脚步接线落地**——`Battlefield` 新增 `BattleSfx` 实例,监听所有单位 `grid_position_changed`(移动中只起播一次)→ 播 `move_step`(`units[art_key]` 路由),`movement_finished` 后**最短保底 450ms** 再 80ms 淡出停止(单格移动曾因同帧淡出而听不到,已修;`BattleSfx.play` 改为返回播放器);`move_blocked` 待音频收录后接线。
> v1.14 修订(2026-10-10):**新增并收录 D.7 移动悬停提示音 `sfx_move_hover_benny`**——选中角色进入移动预览、且 `action_points > 0` 时,指针悬停/滑过**可移动格**播放轻提示音(绑 `units[benny].move_hover`,沿用 v1.9「移动类按角色绑定」;与 C 类 `ui_hover` 语义分离——`ui_hover` 只服务真按钮,格子类控件仍静音,互不冲突);D 类 6 → **7**,总 cue 数 91 → **92**,批次 2 从 51 → **52**;候选 14 个落 `_review/` 试听后选定 **Freesound loganzsound · `Lightswitch Flick_02`(CC0)**,已落盘 + 绑定 + 接线(详见 §6.12)。

---

## 0. 总览

| 项 | 值 |
|---|---|
| 总 cue 数 | **92** |
| 已落盘 | **25**(A.1 turn_in/out 2 个 + A.2 `defender9` / `hare_hopper` / `dawn_pulse` / `raider_infantry` / `raider_scout` / `raider_bulwark` / `hound_bite` / `sentry_laser` / `attack_fire_default` 9 个 + C 类 UI 7 个 + D.7 移动悬停 1 个 + M 类脚步 6 个) |
| 分类数 | **12**(A、C~M) |
| 命名风格 | `sfx_<scene>_<verb>` / `bgm_<scene>` / `amb_<scene>` |
| 采样规格(目标) | SFX 48kHz/16bit 单声道;BGM 48kHz/24bit 立体声;时长 ≤2.5s(SFX)/60~120s(BGM)/10~30s(loop 环境音) |
| **实际落盘格式** | **MP3 (libmp3lame) 96kbps 单声道**(本机 ffmpeg 8.1 编了 `libmp3lame` / `libopus` 但**没编 `libvorbis`**;MP3 兼容性最广、QuickTime/Win Media/几乎所有播放器直接放;Godot 4 原生支持 `.mp3` import) |
| 文件位置 | `res://Art/audio/sfx/`、`res://Art/audio/bgm/`、`res://Art/audio/amb/` |
| 绑定方式 | `conf/battle/sfx_bindings.json`(`weapons` / `units` / `default`) |
| UI 音效入口 | autoload **`UiSfx`**(`Script/ui/ui_sfx.gd`)+ `conf/audio/ui_sfx.json`;战斗演出仍由 `TurnTransition` / `BattleCutIn` 各自持有的 `BattleSfx` 播放 |
| 优先级 | 批次 1(23 个)→ 批次 2(51 个)→ 批次 3(12 个) |

---

## A. 战斗核心(18)

> 全部走 `BattleSfx.play(cue, context)`,在 `Script/battle/battle_cut_in.gd` 的滑入/开火帧/命中帧/未命中帧/击倒帧/滑出 6 处直接喂入。

### A.1 回合横幅过渡

> 仅服务 `TurnTransition`(回合横幅:"玩家行动" / "敌方行动" 横幅入场)。
> 战斗遮罩(`BattleCutIn`)另起一组 cue key,见 A.5。

| cue key | 时长 | 文件 | 切片位置 | 描述 | 触发点 | 状态 |
|---|---|---|---|---|---|---|
| `sfx_turn_in` | **1.50s** | `Art/audio/sfx/sfx_turn_in.mp3` | `cand_a1_audpapkin_cinematic_woosh008.mp3` @ 0.00s,取 1.50s | 玩家回合横幅:cinematic + 金属冲击 + 鼓点冲击 + 衰减尾 | `TurnTransition.play_player()` | ✅ 已落盘(2026-10-08 重做,v1 batch_text_to_music 切片 → AudioPapkin · Cinematic Woosh SFX-008 CC0 切前 1.5s;48kHz 单声道 96kbps) |
| `sfx_turn_out` | 2.00s | `Art/audio/sfx/sfx_turn_out.mp3` | `cutin_out_raw.mp3` @ 15.00s,取 2.00s | 敌方回合横幅:橙红横条 + 锐利金属冲击 + 衰减尾 | `TurnTransition.play_enemy()` | ✅ 已落盘 |

> **A.1 实际值大于清单目标**:目标时长是 0.25~0.30s,但首版听感反馈后调整到 2.0~2.7s(承载完整"冲击 + 衰减"曲线)。**`sfx_turn_in` 在 2026-10-08 重做,从 2.7s 缩短到 1.5s**——之前 2.7s 版本在 `_review/rejected_sfx_turn_in_v1_batch_music_2.7s.mp3` 留底,新版本改用 AudioPapkin CC0 cinematic woosh 切前 1.5s,带金属 + 鼓点冲击 + 衰减尾。`sfx_turn_out` 仍保留 v1 的 2.0s 切片。


### A.2 开火(按 weapon_id 路由,**与角色无关**)

> 贝妮走 `weapons` 绑定、**敌人走 `units[art_key]` 绑定**(v1.6 定案,见下)。**开火 cue 按武器 / 敌人类型绑定**——同一把武器、同一类敌人,谁拿 / 哪只都是同一个 fire 音。命中目标是另一个事(那是 A.3 / A.4)。
>
> 解析路径:**`weapons[weapon_id].fire` → `units[attacker.cutin_art_key].fire` → `default.fire`**(weapon 优先、unit 做"该角色用别的武器时的兜底"、default 是全集兜底)。**所有 `weapons[weapon_id]` 节点只允许写 `fire` 类 cue**,不写 hurt/miss——hurt 是按角色绑的(见 A.4),miss 默认走 default 兜底+bulwark 特殊(见 A.3 末尾)。
>
> v1.6 起**敌人开火按 `units[<art_key>].attack_fire` 绑**(敌人无装备系统,不走 weapons);贝妮开火仍走 `weapons[weapon_id]`。

| cue key | 时长 | 武器 ID / 绑定 | 武器名 | 描述 | 状态 |
|---|---|---|---|---|---|
| `sfx_weapon_defender9_fire` | 0.55s(实落 1.20s) | `weapon_benny_defender_9` | 防卫者-9(SMG Lv1) | 中低音 SMG,中等密度,短回响 | ✅ 已落盘(`Freesound pgi · MG001 triple shot` CC0 1.20s) |
| `sfx_weapon_hare_hopper_fire` | 0.45s(实落 0.88s) | `weapon_benny_hare_hopper` | 野兔跳跃者(SMG Lv2) | 同 SMG 但更紧、更亮,导轨金属感 | ✅ 已落盘(`Freesound qubodup · Silenced SMG Three-Shot Burst` CC0 0.441s **×2 直拼**,详见 §6.8) |
| `sfx_weapon_dawn_pulse_fire` | 0.40s(实落 1.00s) | `weapon_benny_dawn_pulse` | 黎明初霁(SMG Lv3) | 高频脉冲冲锋,带辉石能量"滋滋"尾音 | ✅ 已落盘(`dimapain sci-fi shot` 前 1s + hare_hopper 成品**双轨叠加**,CC0,详见 §6.8) |
| `sfx_weapon_raider_infantry_fire` | 0.65s(实落 0.80s) | `units[raider_infantry]` | 掠夺者步兵步枪 | 单发步枪,后坐强,弹壳落音 | ✅ 已落盘(`Freesound serøutōnin · AK-47 single` CC0 取前 0.8s,详见 §6.9) |
| `sfx_weapon_raider_scout_fire` | 0.50s(实落 0.70s) | `units[raider_scout]` | 斥候步枪 | 短管步枪,更尖的爆发 | ✅ 已落盘(`Freesound serøutōnin · autorifle metallic punchy` CC0 取前 0.7s,详见 §6.9) |
| `sfx_weapon_raider_bulwark_fire` | 0.80s | `units[raider_bulwark]` | 护盾兵重枪 | 低沉厚实,带盾牌共鸣 | ✅ 已落盘(`Freesound pgi · Heavy weapon 002` CC0 取前 0.8s,详见 §6.9) |
| `sfx_weapon_hound_bite` | 0.45s(实落 0.56s) | `units[pyroxene_hound]` | 辉石猎犬撕咬 | 肉食撕咬 + 爪击 | ✅ 已落盘(`Freesound CSStudios · Escorpion_melee` CC0 原长直用 + 尾 30ms 淡出,详见 §6.10) |
| `sfx_weapon_sentry_laser` | 0.70s(实落 1.00s) | `units[pyroxene_sentry]` | 哨戒机激光 | 高能激光充能 + 释放,带电子嗡鸣 | ✅ 已落盘(`spaceship laser burst` 前 1s + `Laser Gun 01` 前 1s **双轨合并**,CC0,详见 §6.10) |
| `sfx_attack_fire_default` | 0.55s(实落 0.70s) | `default.attack_fire` | 通用开火 | 同防卫者-9 的中性版本,做 fallback | ✅ 已落盘(`machinegun-one-shot` **×2 跨淡化直拼**,CC0,详见 §6.10) |

### A.3 命中 / 未命中 / 受击

> 命中(`hit_armor` / `hit_flesh`)和未命中(`miss`)**按角色 art_key 绑定的语义不冲突——本表把它们列在一起,只是因为它们都是"被击中侧"的反应**。实际解析时:
> - **`hit_armor` / `hit_flesh` / `miss` 都走 `default` 兜底**——一个通用命中、通用入肉、通用擦肩啸叫,所有角色共用。
> - **`miss` 有且仅有一个角色特殊例外:护盾兵 `raider_bulwark`**——它有"格挡"或"护盾反弹"的特殊 miss 音,因为它的护盾机制要单独表达。所以 `units[raider_bulwark].miss` 单独覆盖。
>
> 即:"开火按武器,miss 默认兜底+bulwark 特殊,hit 类(命中/入肉)目前统一 default,无角色区分"。

| cue key | 时长 | 描述 | 触发点 | 绑定 |
|---|---|---|---|---|
| `sfx_hit_armor` | 0.40s | 弹头击穿护甲短金属撞击 + 火花迸射声 | `hit_armor`(吸收) | `default` 兜底(暂未做角色区分) |
| `sfx_hit_flesh` | 0.35s | 入肉钝击 + 湿闷尾音 | `hit_flesh`(真实伤害) | `default` 兜底(暂未做角色区分) |
| `sfx_bullet_whiz` | 0.30s | 子弹擦肩而过的啸叫 | `default.miss` 全局兜底 |  |
| `sfx_bulwark_shield_miss` | 0.45s | 护盾兵格挡反弹音,金属护盾共鸣 + 滑开 | `units[raider_bulwark].miss` 特殊覆盖 | ⏳ 待生成 |

### A.4 单位受击 / 倒下(**严格按角色 art_key 绑定,和武器/护甲无关**)

> 受击 = 被打的那个人是谁 → 谁就叫。所以**按角色 art_key 绑定**,不按武器,也不按"当前穿着什么护甲":
> - 护甲只影响伤害数字(`hit_armor` vs `hit_flesh` 走 A.3),**不替换**受击本身;
> - 武器不替换受击;
> - 一个角色在不同姿态(站立/蹲下/跑动)被打也是同一个受击 cue。
>
> 解析:`units[unit.cutin_art_key].hurt` → `default.hurt`(不查 weapons,因为受击跟开火不同轴)。

| cue key | 时长 | 描述 | 触发点 | 绑定 |
|---|---|---|---|---|
| `sfx_player_hurt` | 0.50s | 玩家受击:短促闷响 + 呼吸/失神(主角额外红闪对应) | `apply_attack` 后贝妮被打中 | `units[benny].hurt` |
| `sfx_enemy_hurt` | 0.45s | 敌人受击:肉搏挤压 + 痛叫(泛用,可分两层:punch/grunt) | 敌人被打中 | 所有敌人 `units[*].hurt` 共用;或 `default.enemy_hurt` 兜底 |
| `sfx_unit_down` | 1.20s | 倒地:沉重跌落 + 装备/护甲金属碰撞 + 后续轻尾音 | `unit_down`(击倒帧) | 按角色 art_key 绑(每个敌人可能有不同倒地声) |

### A.5 战斗遮罩过渡(待生成)

> 服务 `BattleCutIn`(战斗入场遮罩:左攻右守立绘 + 数值飘字)。
> 与 A.1 横幅语义不同:**横幅是轻提示**,**战斗遮罩是重头戏**,需要独立的、更有质感的入退场音效。
> 当前 cue key 已占位,binding 值为空,等后续 AI 生成 + 切片后填入。

| cue key | 时长 | 文件 | 描述 | 触发点 | 状态 |
|---|---|---|---|---|---|
| `sfx_battle_cutin_in` | TBD | TBD | 战斗遮罩入场:立绘左攻右守滑入,带更厚重的金属/能量开门声 | `BattleCutIn.begin_session()` | ⏳ 待生成 |
| `sfx_battle_cutin_out` | TBD | TBD | 战斗遮罩退场:反向滑出,衰减余震 | `BattleCutIn.end_session()` | ⏳ 待生成 |

---

## B. 回合过渡(章节已合并到 A.1 / A.5)

> v1.3 起,本章节不再独立。回合过渡 = A.1(横幅专用) + A.5(战斗遮罩专用,待生成)。
> 详见 A.1 与 A.5。

---

## C. UI 通用(7)

| cue key | 时长 | 描述 | 接入点(v1.4 已生效) | 状态 |
|---|---|---|---|---|
| `sfx_ui_click` | 0.08s | 通用点击:轻塑料感,短促"嗒" | autoload `UiSfx` 监听 `SceneTree.node_added`,给全项目每个 `BaseButton.pressed` 自动挂钩 → 主菜单 / 指挥中心 / 仓库 / 贸易站 / 战斗 HUD 的按钮全覆盖;**格子类控件不响**(见下方「只给真按钮出声」) | ✅ 已接入 |
| `sfx_ui_hover` | 0.06s | 通用悬停:更短的轻"叮" | 同上,挂 `BaseButton.mouse_entered`,带 60ms 冷却;**禁用态按钮、格子类控件不出声**(格子长时间 hover 只弹内置 tooltip,不出声) | ✅ 已接入 |
| `sfx_ui_open` | 0.22s(目标 0.18s) | 面板打开:布幕拉起 + 软皮绒低音 | ① `Popup.about_to_popup`——3 个 `PopupPanel`(`battle_context_menu` / `battle_container_action_menu` / `battle_item_action_menu`);② `AcceptDialog.visibility_changed`——3 个 `ConfirmationDialog`(强制撤离 `battlefield.gd:290`、丢弃 `battle_loadout_panel.gd:116`、存档覆盖/删除 `save_load_ui.gd:7`);③ `UiSfx.attach_panel()` 的常驻面板:`unit_status_widget.gd:33`、`battle_loadout_panel.gd:125`、`save_load_ui.gd:16`。**引擎内置 tooltip 整棵跳过**——它是 `theme_type_variation = "TooltipPanel"` 的 `PopupPanel`,鼠标停留就会弹,不能算面板打开 | ✅ 已接入 |
| `sfx_ui_close` | 0.20s(目标 0.15s) | 面板关闭:反向上推合 | ① `Popup.popup_hide`;② `attach_panel()` 面板的 `visibility_changed` 转 false。**对话框不播 close**——已有 `ui_confirm` / `ui_cancel` 反馈,避免叠音;**面板上的「收起」按钮已 `set_silent()`**——关闭音由面板给出,不再叠一层 click;**菜单项点击引起的关闭也不叠 close**(只留 click),点空白处 / ESC 关菜单才单独出 close | ✅ 已接入 |
| `sfx_ui_confirm` | 0.22s | 确认/同意:二段"叮→咚"清脆 | `AcceptDialog.confirmed` 自动挂钩;**确定按钮本身不出 `ui_click`**,只有 confirm 一个音 | ✅ 已接入 |
| `sfx_ui_cancel` | 0.18s | 取消/拒绝:两声短促错误"嘟-嘟" | `AcceptDialog.canceled` 自动挂钩——此前全项目**没有任何一处**连接 `canceled`,现在三个对话框的取消按钮 / ESC / 标题栏 X 都响;**取消按钮本身不出 `ui_click`**,只有 cancel 一个音 | ✅ 已接入 |
| `sfx_ui_error` | 0.30s | 操作失败/禁止:低音"嗡"短促 | `UiSfx.report_status(text)` 按失败关键字判定,出口: `warehouse.gd:917 _set_status()`(49 处文案:空间不足 / 接口不兼容 / 未选择武器 …)、`battle_loadout_panel.gd:524 _set_status()`(14 处,含战场"行动点不足""无法丢弃""丢弃物堆已满")、`trading_post.gd:74 _set_feedback()`(3 处,含"信用点不足");关键字表在 `conf/audio/ui_sfx.json` 的 `error_markers`,成功/提示文案保持安静 | ✅ 已接入 |
> **接入实现(v1.4)**:UI 层不再逐场景手接。新增 autoload **`UiSfx`**(`Script/ui/ui_sfx.gd`,`project.godot:23`),内部持有一个常驻 `BattleSfx`(host = autoload 节点,`AudioStreamPlayer` 池跟随整个游戏生命周期,切场景不断音),启动时监听 `SceneTree.node_added` 自动为 `BaseButton` / `Popup` / `AcceptDialog` 挂钩,并延迟全树扫一遍兜底。开关与手感参数集中在 `conf/audio/ui_sfx.json`:逐个 cue 的 `cues` 开关、`hover_cooldown_seconds`、`error_markers` 失败关键字、`debug`(打印 `cue -> 文件名`)、`audio_bus`。
>
> **只反馈玩家操作**:C 类音效定位是"玩家操作的反馈",系统自动弹出的 UI 不能响。`UiSfx` 提供 `begin_system_ui(owner)` / `end_system_ui()` 静默作用域(计数可嵌套,期间所有 cue 静音),已用在**敌方回合**——`battlefield.gd:553` 把 `await _run_enemy_phase()` 整段包起来,敌方移动时自动弹出的单位面板(`battlefield.gd:610` `status_widget.show_for(enemy)`)不再播 `ui_open` / `ui_close`;玩家自己点敌人查看(`battlefield.gd:1018`)照常响。`owner` 传发起方节点,该节点被释放时作用域自动归零,避免 begin/end 没配对导致 UI 音效永久静音。
>
> **只给真按钮出声**:C 类音效只反馈"玩家点了个按钮 / 开了个面板",不是"点什么都响"。两条排除机制:① `UiSfx.set_silent(node)` 逐个标记(已用在三个面板的收起/关闭按钮:`unit_status_widget.gd:38`、`battle_loadout_panel.gd:86`、`save_load_ui.gd:18`);② `conf/audio/ui_sfx.json` 的 `silent_scripts` 按脚本路径整类排除——已列 `inventory_slot.gd` / `operator_equipment_slot.gd` / `weapon_attachment_slot.gd`(它们 `extends Button` 但语义是**格子**:点击是选中物资、hover 是弹名称,都不该有按钮音)。静默判定放在**触发时**而不是绑定时,所以标记晚于 `node_added` 也生效。另外引擎内置 tooltip 的 `Popup` 因为直接挂在 Viewport 下,绑定阶段就整棵跳过。
>
> **一个交互只出一个音**:按钮的职责就是关闭/取消/确认时,只保留结果音,不叠 `ui_click`;按钮是执行动作、关闭只是副作用时,只保留 `ui_click`,不叠 `ui_close`。三条规则:① `AcceptDialog` 自带的 确定 / 取消 按钮静音(`_is_dialog_own_button()`,用 `get_ok_button()` / `get_cancel_button()` 精确识别,塞进对话框内容的自定义按钮不受影响;标题栏 X 不是 Button 节点,走 `close_requested`,本来就没有 click);② 面板上的收起/关闭按钮 `set_silent()`,关闭音由面板 `visibility_changed` 给出;③ 菜单项点击后 popup 的关闭延一帧结算(`CLOSE_SETTLE_MSEC = 400`),同帧内登记过该 popup 的点击即判定为"点击引起的关闭",只留 click。
>
> **有意保留的两组连响**:点存档槽的 存/读/删 → `ui_click` + 随后确认框的 `ui_open`(两个独立事件);操作被拒 → `ui_click` + `ui_error`(错误音有信息量)。
>
> **tooltip 一律不出声**:Godot 4.6 的内置 tooltip 是 `theme_type_variation = "TooltipPanel"` 的 `PopupPanel`,**每次显示都新建一个,并 `add_child` 到被 hover 的那个控件下面**(不是 Viewport —— 按父节点类型判断拦不住),`_bind_popup` 用 `_is_engine_tooltip()` 认 type variation,父节点是 Viewport 只作兜底;另外 `CommandCenter.tscn` 六个卡片按钮的 `tooltip_text`("进入战场"之类)已直接删掉——文案和按钮名重复,没有信息量。带信息量的 tooltip 保留:战斗菜单里不可用原因(`battle_context_menu.gd:91`、`battle_container_action_menu.gd:53`)、背包格子的物资名(`inventory_slot.gd:55`)。
>
> **故意不接的三类**:① `battle_discard_zone`、`battle_status_bar` 的飘字 Label —— 拖拽/每次数值变化都会切换显隐,会被误判成开关面板;② 战斗结算遮罩 `success_overlay` / `failure_overlay`(`battlefield.gd:304`、`:359`)—— 留给 G 类 `sfx_battle_victory` / `sfx_battle_defeat`,不占用 `ui_open` / `ui_close`;③ 敌方回合的系统驱动 UI(见上一条)。非 Popup 的常驻面板仍需显式调一次 `UiSfx.attach_panel(self)`。
>
> **总线**:`conf/audio/ui_sfx.json` 的 `audio_bus` 填的是 `SFX`,但项目**还没有 SFX/BGM/AMB 总线布局**,`BattleSfx._has_bus()` 找不到就回落 `Master`;要做音量滑条需先补 §4 第 3~4 步。

> **C 类已全部落盘(7/7)**:`ui_open` / `ui_close` 文件为 `Art/audio/sfx/sfx_ui_open.mp3`(0.222s)、`Art/audio/sfx/sfx_ui_close.mp3`(0.200s),48kHz 单声道 MP3 96k;实际时长略长于清单目标,因为尾部保留了自然衰减(不做硬切)。
>
> **定稿过程**:AI 路线(`batch_text_to_music`)对这两个 cue 不可用——open 给了电子 screech、close 直接给了人声呼气;v1.4 改走程序合成,出 `wood`(木箱咔哒)/`wood2`(加箱体共鸣 + 早反射)/`latch`(金属卡扣)/`soft`(布幕皮绒)4 个变体,先用 `connector__matrix__audios_understand` 做客观试听评审(wood 9/10、latch 9/10、soft 7/10,并按评审意见补出 wood2),再人工试听定稿 **soft** 版——最贴本表原描述「布幕拉起 + 软皮绒低音」,且音色柔和不抢 `ui_click` / `ui_confirm`。合成配方与验证闭环见 §6.5。


---

## D. 战场地图交互(7)

> v1.9 补充:**移动类 cue 全部按角色自身绑定**——D.1 更名 `sfx_move_step_benny`(绑 `units[benny].move_step`)、D.2 更名 `sfx_move_blocked_benny`(绑 `units[benny].move_blocked`);5 类敌人脚步见 §M(`units[<art_key>].move_step`)。
> v1.14 补充:新增 D.7 `sfx_move_hover_benny`(**移动预览悬停可移动格**的轻提示音,绑 `units[benny].move_hover`);触发前提为"已选中移动 + 仍有剩余 AP",格子不可达 / 无 AP 时不出声。

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_move_step_benny` | 0.25s | 单格脚步:贝妮兔耳短靴在废墟地面的"嗒" | 玩家每格移动(`Unit._step_to_next`),绑 `units[benny].move_step` |
| `sfx_move_blocked_benny` | 0.18s | 移动被阻挡/AP 不足:短"咚" | AP 不足或目标格不可达,绑 `units[benny].move_blocked` |
| `sfx_move_hover_benny` | 0.10s(实落 0.150s) | 移动预览悬停:指针移到/滑过**可移动格**上的轻提示(比 `ui_hover` 更短更收,连续扫格不疲劳) | `Battlefield` 移动态(`MOVE_STATE`):悬停格变化且可达、`action_points > 0`;绑 `units[benny].move_hover` |
| `sfx_select_unit` | 0.15s | 选中玩家单位:青蓝聚焦"叮" | `_change_state(MOVE_STATE)` |
| `sfx_select_enemy` | 0.18s | 选中敌人:橙红聚焦警示音 | `unit_status_widget.show_for(enemy)` |
| `sfx_context_open` | 0.20s | 右键菜单弹出:轻快划动 | `BattleContextMenu.popup()` |
| `sfx_turn_end` | 0.40s | 结束轮次:面板回弹 + 短合音 | `BattleStatusBar.end_turn_pressed` |

> **D.7 状态**:✅ 已落盘(2026-10-10,Freesound loganzsound `Lightswitch Flick_02` CC0,实落 0.150s);`conf/battle/sfx_bindings.json` 已回填 `units[benny].move_hover`;接线在 `Script/battlefield.gd` 移动悬停变化处调 `_sfx.play(&"move_hover", {"attacker": player})`(60ms 冷却);详见 §6.12。

---

## E. 状态效果 / 数值反馈(6)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_bleed_apply` | 0.45s | 流血状态触发:液体滴落 + 短促痛叫 | `unprotected_debuffs[bleeding]` 触发 |
| `sfx_bleed_tick` | 0.30s | 流血持续伤害(每回合):滴答血滴 | 回合结算时流血 damage |
| `sfx_fracture_apply` | 0.55s | 骨折触发:骨裂脆响 + 装备震动 | `unprotected_debuffs[fractured]` 触发 |
| `sfx_heal_tick` | 0.40s | 治疗反馈(道具 / 状态):轻恢复光粒音 |
| `sfx_armor_break` | 0.50s | 护甲破碎:金属碎裂 + 警示"叮" |
| `sfx_status_removed` | 0.25s | 状态移除:状态净化光粒音 |

---

## F. 道具 / 容器(7)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_item_pickup` | 0.20s | 拾取物品:清脆"叮"+ 短回响 | 地面掉落物被收进背包 |
| `sfx_item_use` | 0.45s | 使用消耗品:打开 → 倒 → 落 + 效果触发 | `BattleItemUseResolver.apply()` |
| `sfx_item_discard` | 0.30s | 丢弃:撕扯布 + 物品落地 | `battle_loadout_panel.discard_requested` |
| `sfx_container_open` | 0.55s | 开战利品箱:箱盖吱呀 + 弹簧 | `BattleContainer.opened` 信号 |
| `sfx_container_search` | 0.65s | 搜刮完成:物品翻动 + 短总结 | 搜刮 AP 消耗后产出 |
| `sfx_container_empty` | 0.40s | 空箱:箱内沙沙 + 失落"嗡" | `is_depleted` |
| `sfx_item_merge` | 0.80s | 二合合并:辉光合拢 + 提升"叮" | 同级同种 2 → 1 高 1 级 |

---

## G. 战斗结算(5)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_battle_victory` | 3.00s | 胜利:鼓点上扬 + 短号角 + 余韵 | `_end_battle_as_victory` |
| `sfx_battle_defeat` | 3.50s | 失败:低沉心碎 + 警报衰减 | `_end_battle_as_failure` |
| `sfx_evac_success` | 2.50s | 撤离成功:撤离舱启动 + 远景引擎 + 胜利提示 | 撤离点成功撤离 |
| `sfx_evac_fail` | 2.80s | 撤离失败:撤离舱告警 + 爆炸衰减 | 撤离中死亡 |
| `sfx_evac_confirm` | 0.30s | 撤离确认:警报提示 + 红色警示 | `evacuation_confirmation.popup_centered()` |

---

## H. 装备 / 背包(8)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_equip_weapon` | 0.40s | 装备武器:咔哒装填 + 金属上膛 | `operator_equipment_slot` 安装武器 |
| `equip_armor` | 0.35s | 装备护甲/头盔:绑带扣紧 | 装备方式改 |
| `sfx_unequip` | 0.30s | 卸下:松开卡扣 | 卸下装备 |
| `sfx_attachment_install` | 0.40s | 安装配件:导轨啮合 + 卡入 | `weapon_attachment_slot` 安装 |
| `sfx_attachment_remove` | 0.35s | 移除配件:卡扣弹出 | 卸下配件 |
| `sfx_drag_start` | 0.10s | 拖拽开始:轻"嘿" | `InventorySlot.gd::_get_drag_data` |
| `sfx_drag_drop` | 0.20s | 拖拽放下:落槽"咔哒" | `InventorySlot.gd::_drop_data` |
| `sfx_inventory_sort` | 0.50s | 整理:物品归位 + 短合音 | 整理背包动作 |

---

## I. 存档(5)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_save_success` | 0.45s | 存档成功:写入"刷" + 提示"叮" | `SaveManager.save` 成功 |
| `sfx_save_fail` | 0.50s | 存档失败:错误"嘟-嘟" + 提示 | `SaveManager.save` 失败 |
| `sfx_load_success` | 0.55s | 读档成功:加载"刷" + 提示 | `SaveManager.load` |
| `sfx_load_fail` | 0.50s | 读档失败:数据损坏"嘶-砰" | `SaveManager.load` 失败 |
| `sfx_delete_confirm` | 0.35s | 删除存档:低频撕裂 + 衰减 | 删除前确认 |

---

## J. 商店 / 订单(5)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_shop_open` | 0.40s | 进入商店:推门铃 + 商贩招呼 | `TradingPost` `_ready` |
| `sfx_shop_buy` | 0.30s | 购买成功:硬币落袋 + 物品落手 | `trading_post._buy_item` 成功 |
| `sfx_shop_insufficient` | 0.35s | 金币不足:钱袋空响 + 提示 | 信用点不足时 |
| `sfx_quest_accept` | 0.45s | 接取订单:纸张展开 + 印章 | 接取居民援助 |
| `sfx_quest_turn_in` | 0.55s | 交付订单:物品交递 + 居民感谢 + 奖励"叮" | 完成援助交付 |

---

## K. 背景音乐(9)

> 全部 stereo / 48kHz / 24bit / 60~120s,可用 FMOD / Wwise 风格循环点剪辑。Godot 4 端通过 `AudioStreamPlayer.stream.loop = true` 处理。

| cue key | 时长 | 场景 | 风格基调 |
|---|---|---|---|
| `bgm_main_menu` | 120s | 主菜单 | 钢琴 + 弦乐 + 缓慢 Pad;战后废墟中"家"的温度 |
| `bgm_command_center` | 90s | 指挥中心 | 暖色调 acoustic + 轻微电流 base;建设希望 |
| `bgm_battlefield_player` | 80s | 玩家回合(战区) | 紧缓电子 + 短脉冲;能推进但不压迫 |
| `bgm_battlefield_enemy` | 80s | 敌方回合 | 慢节奏紧张 Pad + 低频心跳 + 警报 |
| `bgm_battlefield_tense` | 60s | 紧张战斗(玩家回合击杀残血) | 鼓点 + 弦乐急推 + 危机感 |
| `bgm_trading_post` | 75s | 贸易站 | 轻快原声吉他 + 街区市井感 |
| `bgm_warehouse` | 60s | 仓库 | 安静环境 + 偶尔物件声;整理整顿 |
| `bgm_victory` | 60s | 胜利结算 | 鼓号齐鸣 + 升华旋律 |
| `bgm_defeat` | 60s | 失败结算 | 慢板沉郁 + 弦乐余音 + 寄望 |

---

## L. 环境音(3)

> 全部 stereo / loop,挂 `AudioStreamPlayer.stream.loop = true`。

| cue key | 时长 | 场景 | 内容 |
|---|---|---|---|
| `amb_field` | 30s loop | 战区废墟户外 | 远处风声 + 偶尔金属结构吱呀 + 远处爆破余响;无音乐 |
| `amb_base` | 30s loop | 基地室内 | 发电机低频 + 远处人声 + 偶尔物件声;温暖 + 安全 |
| `amb_interior` | 30s loop | 仓库/贸易站 | 室内空间感 + 偶尔脚步声 + 物件轻碰 |

---

## M. 角色移动脚步(补充,v1.9)

> v1.9 新增。**移动脚步按角色绑**:`units[<art_key>].move_step`,复用 v1.6 定案的 units 通道(零代码改动)。
> 现状:D 类只有 `sfx_move_step_benny`(v1.9 更名)一个,仅描述贝妮;5 类敌人移动没有任何脚步 cue——本章补齐;移动类(含 `sfx_move_blocked_benny`)全部按角色自身绑定,不走 default。
> 触发点统一是 `Unit._step_to_next()`(`Script/unit.gd:419`,所有单位共用);敌人移动经 `enemy_ai` → `battlefield_tactics.execute_move` 驱动,步进节拍 `move_interval = 0.3s`(`Script/unit.gd:51`)。
> 建议排期:与 D 类同批(批次 2)。

| cue key | 时长 | 绑定 | 描述 | 状态 |
|---|---|---|---|---|
| `sfx_move_step_benny` | 0.25s(实落 3.91s) | `units[benny].move_step` | (D.1 已有条目,更名)贝妮兔耳短靴在废墟地面的"嗒" | ✅ 已落盘(`Freesound DavidJohnson2019 · Footsteps Run` CC0 原长,详见 §6.11) |
| `sfx_move_step_raider_infantry` | 0.25s(实落 4.46s) | `units[raider_infantry].move_step` | 掠夺兵硬底靴:碎砖砾石 + 布料摩擦 | ✅ 已落盘(Freesound `Small Puddle Splash` ×10 @450ms,详见 §6.11) |
| `sfx_move_step_raider_scout` | 0.20s(实落 5.00s) | `units[raider_scout].move_step` | 斥候轻装:更轻、更快的软底一步 | ✅ 已落盘(Mixkit `Footsteps on mattress loop` 取前 5s,详见 §6.11) |
| `sfx_move_step_raider_bulwark` | 0.30s(实落 5.00s) | `units[raider_bulwark].move_step` | 护盾兵重甲:沉重落地 + 装备晃动 | ✅ 已落盘(Mixkit `Giant monster footstep` 取前 5s,详见 §6.11) |
| `sfx_move_step_pyroxene_hound` | 0.25s(实落 3.00s) | `units[pyroxene_hound].move_step` | 辉石猎犬四足:爪尖刮擦 + 晶簇轻响 | ✅ 已落盘(Freesound qubodup `Dog Running Past` 取 2s~5s,详见 §6.11) |
| `sfx_move_step_pyroxene_sentry` | 0.30s(实落 5.00s) | `units[pyroxene_sentry].move_step` | 哨戒机机械步伐:伺服 + 金属落地(walk 动画 4 帧) | ✅ 已落盘(Mixkit `Robot step` 取前 5s,详见 §6.11) |

- 单格节拍 0.3s,脚步 cue 建议 ≤0.3s;规格沿用 §3(48kHz / 单声道 / MP3 96kbps)。
- **接线已落地(v1.13)**:`Battlefield` 监听每单位 `grid_position_changed`(每次移动起播一次)+ `movement_finished` 后最短保底 450ms 再 80ms 淡出停止;当前按「每次移动播一段」策略——3~5s 段落与单格节拍不匹配,若要严格逐格同步需把段落切成单步。
- 现成 CC0 参考(pgi 库,前轮已核对授权):`mech_step_001.ogg`(1.60s)、`mech_step_002.ogg`(1.70s)、`sand_step.ogg`(0.59s)——sentry / 步兵类候选,可切片。

---

## 1. 绑定表(填法示例)

> 在 `conf/battle/sfx_bindings.json` 中按下面形式填,接音频时直接消费。

```json
{
  "default": {
    "cutin_in": "sfx_cutin_in",
    "cutin_out": "sfx_cutin_out",
    "attack_fire": "sfx_attack_fire_default",
    "hit_armor": "sfx_hit_armor",
    "hit_flesh": "sfx_hit_flesh",
    "miss": "sfx_bullet_whiz",
    "unit_down": "sfx_unit_down"
  },
  "units": {
    "benny":           { "hurt": "sfx_player_hurt" },
    "raider_infantry": { "hurt": "sfx_enemy_hurt", "attack_fire": "sfx_weapon_raider_infantry_fire" },
    "raider_scout":    { "hurt": "sfx_enemy_hurt", "attack_fire": "sfx_weapon_raider_scout_fire" },
    "raider_bulwark":  { "hurt": "sfx_enemy_hurt", "miss": "sfx_bulwark_shield_miss", "attack_fire": "sfx_weapon_raider_bulwark_fire" },
    "pyroxene_hound":  { "hurt": "sfx_enemy_hurt", "attack_fire": "sfx_weapon_hound_bite" },
    "pyroxene_sentry": { "hurt": "sfx_enemy_hurt", "attack_fire": "sfx_weapon_sentry_laser" }
  },
  "weapons": {
    "weapon_benny_defender_9":  { "attack_fire": "sfx_weapon_defender9_fire" },
    "weapon_benny_hare_hopper": { "attack_fire": "sfx_weapon_hare_hopper_fire" },
    "weapon_benny_dawn_pulse":  { "attack_fire": "sfx_weapon_dawn_pulse_fire" }
  }
}
```

> **绑定策略(v1.6 修订)**
> - **开火 `fire`(贝妮)**:按 `weapons[weapon_id]`——同一把武器,谁拿都是同一个音。
> - **开火 `fire`(敌人)**:敌人没有装备系统,**按 `units[<art_key>].attack_fire` 绑**——同一类敌人 = 同一把武器,语义等价,且零代码改动。
> - **移动 `move_step` / `move_blocked` / `move_hover`(v1.9 / v1.14)**:移动类**全部按角色自身绑**——`units[<art_key>].move_step`(贝妮 + 5 类敌人)、`units[benny].move_blocked`、`units[benny].move_hover`(移动预览悬停可移动格的提示音);不走 default 兜底。
> - **受击 `hurt`**:严格按 `units[unit.cutin_art_key]`——和穿什么护甲无关(护甲只影响伤害类型 → A.3 的 `hit_armor`/`hit_flesh`),和用什么武器打过来也无关。
> - **`miss`**:全局 `default.miss` 兜底(目前 `sfx_bullet_whiz` 兼用);**只有 `raider_bulwark` 一个角色有 `units[*].miss` 特殊覆盖**(`sfx_bulwark_shield_miss`,格挡反弹音,体现护盾机制)。
> - **解析路径**(`Script/battle/battle_sfx.gd::resolve_binding`):**`weapons[weapon_id].<cue>` → `units[attacker_or_victim.cutin_art_key].<cue>` → `default.<cue>`**。命中侧(A.3 / A.4)的 context 用 `victim` 代替 `attacker`。
> - cue key 全部对应表中 cue key,加 `.mp3` 后缀落盘。

---

## 2. 批次工作流

### 批次 1 — MVP 战斗体感(24 个)

| 类别 | 数量 | cue |
|---|---:|---|
| A 战斗核心 | 19 | A.1(横幅,2 个已落盘)+ A.2(开火,9 个)+ A.3(命中,3 个)+ A.4(受击,3 个)+ A.5(战斗遮罩,2 个待生成) |
| G 战斗结算 | 5 | 全部 |

### 批次 2 — UI 与流程(52 个)

| 类别 | 数量 | cue |
|---|---:|---|
| C UI 通用 | 7 | 全部 |
| D 战场交互 | 7 | 全部 |
| E 状态 / 数值 | 6 | 全部 |
| F 道具 / 容器 | 7 | 全部 |
| H 装备 / 背包 | 8 | 全部 |
| I 存档 | 5 | 全部 |
| J 商店 / 订单 | 5 | 全部 |
| L 环境音(可放批次 3 也可提前) | 3 | — |

### 批次 3 — 氛围(12 个)

| 类别 | 数量 |
|---|---:|
| K BGM | 9 |
| L 环境音(若批次 2 没做) | 3 |

---

## 3. 命名/规格规范

- **cue key**:`sfx_` / `bgm_` / `amb_` 前缀 + 小写蛇形
- **文件名**:`<cue_key>.mp3`(`res://Art/audio/sfx/sfx_hit_armor.mp3`)
- **采样率**:48kHz(SFX/BGM/AMB 一致)
- **编码格式**:MP3 (libmp3lame),SFX 96kbps 单声道;BGM/AMB 128kbps 立体声
- **声道**:SFX 单声道,BGM/AMB 立体声
- **峰值**:-1 dBFS(留余量,防削波)
- **loop**:BGM / AMB 必带 loop-friendly 剪辑点(0 起始与终点对齐)
- **SFX 短音**:尾部留 30~50ms 自然衰减,避免硬切

---

## 4. 接 audio 系统的实现路径(预告,不在本表范围内)

1. **资源就位**:按本表 cue key 生成音频文件落到 `Art/audio/{sfx,bgm,amb}/`。
2. **改 `Script/battle/battle_sfx.gd`**:把 `_debug_enabled` 走 false 时用 `AudioStreamPlayer` 池播放;`play(cue, context)` → `resolve_binding(cue, context)` → 拿 cue key → 在 `AudioCueLibrary`(新文件)中查 OGG → 取空闲播放器播放。
3. **总线**:Godot 4 `AudioBus` 三总线 — `SFX`、`BGM`、`AMB`,UI 层加静音 / 音量滑条。
4. **UI 音量**:新增 `conf/audio/volume.json`,启动时 `AudioServer.set_bus_volume_db`。

### 4.1 进度(v1.4)

- **已完成**:第 1 步的 C 类资源;第 2 步的 UI 部分——autoload `UiSfx` 复用同一个 `BattleSfx`(相同 binding 表 + 播放器池),C 类 7 个 cue 全场景自动生效。
- **未完成**:第 3 步三总线布局(当前 `audio_bus` 写 `SFX` 会回落 `Master`)、第 4 步音量配置与 UI。
- **验证**:叠音规则测过 4 个用例(对话框 OK 只出 confirm / Cancel 只出 cancel / 对话框内自定义按钮照常 click / 菜单项 click 后 popup_hide 不叠 close,无点击时 close 延一帧照出);静默规则测过 7 个用例(普通按钮 click+hover / 三类格子全静音 / 收起按钮只出 close / Viewport 下的 Popup 不绑定 / Control 下的 PopupPanel 正常 open+close);系统驱动作用域测过 6 个场景(玩家操作有声 / 作用域内全静音含 `report_status` / 结束后恢复 / 嵌套计数 / owner 释放自动归零 / 禁用按钮 hover 静音);`Godot --headless --path . --import` 无脚本错误;MainMenu / Warehouse / TradingPost / CommandCenter / Battlefield 五个场景 headless 跑 60 帧无报错;单独校验过 Button / PopupPanel / ConfirmationDialog / `attach_panel` 的信号连接数与 7 个 cue 的 binding 解析。

---

## 5. 交付清单(可勾选)

- [x] **批次 1 / A.1**:turn_in + turn_out(2 个)✅ 横幅专用
- [x] **批次 2 / C**:UI 通用 7 个 ✅(click / hover / open / close / confirm / cancel / error)
- [x] **C 类接线**:autoload `UiSfx` + `conf/audio/ui_sfx.json`,全场景按钮/悬停/面板开关/对话框/失败文案已挂钩
- [x] **D.7 移动悬停接线**:`sfx_move_hover_benny`(CC0)落盘 + `units[benny].move_hover` 绑定 + `Battlefield` hover 接线 ✅
- [x] 批次 1:A.2 开火 9 个 ✅(defender9 / hare_hopper / dawn_pulse / raider_infantry / raider_scout / raider_bulwark / hound_bite / sentry_laser / attack_fire_default)
- [ ] 批次 1:A.3 命中/未命中 3 个
- [ ] 批次 1:A.4 受击/倒下 3 个
- [ ] 批次 1:A.5 战斗遮罩过渡 2 个
- [ ] 批次 1:G 战斗结算 5 个
- [ ] 批次 2:D~J 全部 45 个
- [ ] 批次 2:L 环境音 3 个
- [x] M 类:角色移动脚步 6 个 ✅(benny / raider_scout / raider_bulwark / pyroxene_hound / pyroxene_sentry / raider_infantry)
- [ ] 批次 3:K BGM 9 个
- [x] `Script/battle/battle_sfx.gd` 切换为真实播放实现 ✅(AudioStreamPlayer 池 + host 注入)
- [ ] `conf/audio/volume.json` + 音量 UI

---

## 6. 实测经验(v1.1 新增)

### 6.1 AI 音频模型对游戏音效的真实表现

用 `connector__matrix__batch_text_to_music`(纯音乐模型)做 A.1 两轮测试,得到的实战经验:

| 观察 | 影响 | 应对 |
|---|---|---|
| **模型会跑偏到"音乐"**:即使 prompt 强调 `non-musical sound effect`,v1 还是给出了"男声吟唱 + 电子鼓"。 | prompt 约束不够强时,模型走"配乐"路线 | v2 加 `no vocals no singing no chanting, no melody no harmony no rhythm, just one single sharp metallic scrape` 才拿到纯音效段 | 
| **不能精确控制时长**:prompt 写 `0.3 second`,模型实际给 16~47s 的完整片段。 | 实际切片需要自己挑爆点 | 一次生成 → 多窗口人工探路 → 选最有冲击的 0.5~3s 区间 |
| **生成体积不可控**:即使 cue 目标 0.3s,模型给 16~47s。 | token 输出浪费大 | 同上策略;但生成一次跑多个 cue 时,**单条 prompt 仍只能产出一段长音乐**,不能"5 个 0.3s 拼成 15s" |
| **生成内容里常有"上升 scrape + 冲击 + 衰减"的隐式结构**(cutin_out 的 v1 就是这种结构)。 | 适合做 cut-in/out 类音效 | 切片时直接利用隐式结构,选合适的爆点 |
| **同 prompt 反复跑可能拿到不同的"音乐流派"**(v1 给吟唱,v2 给电子打击乐)。 | 不可控,但给我们更多选择 | 多次跑挑最合适的 |

### 6.2 ffmpeg 切片实操

- **格式**:MP3 (libmp3lame) — 本机 ffmpeg 8.1 缺 `libvorbis`,但 `libmp3lame` 工作良好,兼容性最广
- **命令模板(切片 + 编码一次到位)**:
  ```bash
  ffmpeg -y -ss 00:00:05.200 -i <source>.mp3 -t 2.70 \
    -c:a libmp3lame -b:a 96k -ar 48000 -ac 1 \
    <dest>.mp3
  ```
- **fast seek(`-ss` 在 `-i` 前)**:0.1s 精度,适合 1s+ 切片
- **slow seek(`-ss` 在 `-i` 后)**:帧精度,适合短切片
- **规范**:`-ar 48000 -ac 1`(单声道、48kHz),`libmp3lame -b:a 96k`
- **目标路径**:`Art/audio/sfx/<cue_key>.mp3`

### 6.3 落盘流程(实战版)

1. `mcode-tools connector call batch_text_to_music --args-file <X.json>` 一次出 1~5 段音乐
2. `mcode-tools get_asset_url <node_id>` 拿下载链接
3. `curl` 下载到 `_batch/`(临时工作区)
4. `mcode-tools upload_temp_url` + `audios_understand` 探路(可选但推荐)
5. 找到爆点 → `ffmpeg` 切多档 → 听 → 选定最终长度
6. 文件重命名为 `<cue_key>.wav`,落到正式目录
7. 清理 `_batch/` 中间产物

### 6.4 后续批次的判断

| 类别 | 用 batch_text_to_music 是否可行 | 推荐做法 |
|---|---|---|
| A.2 开火(各武器) | ⚠️ 谨慎,可能跑偏 | 一次出 1 把武器,多档听;同家族(SMG 三把)试一次 batch |
| A.3 / A.4 命中受击 | ⚠️ 谨慎 | 单 cue 出,加 `single transient impact` 强约束 |
| C/D UI 短音 | ❌ 不可行 | UI 短音(<0.25s)模型出不了干净素材,**必须程序合成**(见 §6.5,C 类 7 个已全部落盘) |
| E/F/G 状态 / 道具 / 结算 | ❌ 不推荐批量 | 长尾/细腻音,单条 prompt 一次 |
| H 装备 / 背包 | ⚠️ 单 cue 出 | 物件声多样,各自 prompt |
| I 存档 | ⚠️ 单 cue 出 | UI 反馈短音,程序合成可能更稳 |
| J 商店 / 订单 | ⚠️ 单 cue 出 | 混合物件声 |
| K BGM | ✅ 9 首独立 | batch_text_to_music 一次最多 5 个,分两批 |
| L 环境音 | ✅ 一次出 3 个 loop | 强调 `continuous loop, no melody, environmental only` |

### 6.5 程序合成实操(v1.4 新增,C 类 UI 短音的可用路线)

C 类 7 个 cue 全部用 **numpy 分层合成 → ffmpeg 编 MP3** 落盘,配方可直接复用到 D/I 类的 UI 短音:

| 层 | 做法 | 作用 |
|---|---|---|
| 撞击瞬态 | 白噪 burst(0.25ms 起振 + 指数衰减 τ≈2ms),经 rfft 掩膜带限 300~7kHz | "咔"的棱角 |
| 木体/箱体模态 | 非谐波分音 462/731/1043/1568/2286/3360Hz(τ 8~50ms)+ 空腔模态 148/211Hz;起始 3.5% 音高下滑模拟接触非线性 | 材质辨识度 |
| 软皮绒低音 | 正弦 138→56Hz 快速下滑 + τ≈70~90ms | 面板厚度 / 关盖下潜 |
| 布幕扫动 | 逐帧时变高斯带通白噪(512 样本窗 / hop 128)+ overlap-add,中心频率按指数扫动;**开=上扫、关=下扫** | 开关的方向感 |
| 空间感 | 11/17/24ms 三个早反射,wet 14~16%(不用长混响) | 干声变"在房间里"又不糊 |

- **必备收尾**:每层加 6~22ms release 淡出(否则层拼接处会硬切爆音)→ 整曲 `tanh` 软限幅 → 尾部按 -46dB 门限裁静音 → 末端 5ms 淡出
- **响度对齐**:不要按 §3 的 -1 dBFS 峰值归一(C 类既有文件峰值只有 0.065~0.400),要按 **RMS 对齐家族**:click .0375 / hover .0386 / confirm .0543 / cancel .0521 → `ui_open` 取 **.050**、`ui_close` 取 **.046**
- **验证闭环(关键)**:`mcode-tools upload_temp_url <file.mp3>` → `mcode-tools connector call connector__matrix__audios_understand --args-file <args.json>`(**单次最多 5 条**),让音频模型客观描述材质/结构/瑕疵并打分,再按评审意见迭代;本轮即"三变体评审 → 按意见精修出 wood2 → 人工定稿 soft"
- **坑**:numpy float64 数组直接喂 `ffmpeg -f f32le` 会让 libmp3lame 断言崩溃(`psymodel.c:576 calc_energy`),必须先 `.astype(np.float32)`

### 6.6 网上找音频素材(本轮新增)

batch_text_to_music 对 A.2 武器开火不可用(见 §6.1),本轮改走"Freesound / Sonilo 等免登录 preview + 高质量素材库"路线。

| 来源 | 授权 | 适合 | 备注 |
|---|---|---|---|
| **Freesound** `freesound.org` | 多数 **CC0** / CC-BY | 单发、三连、loop 全覆盖;按 tag 搜 `smg` / `submachine` / `gun` / `full-auto` | 完整原文件需登录,**preview mp3 公开直链**(`cdn.freesound.org/previews/<id>/<id>_<user>-hq.mp3`) |
| **Sonilo** `sonilo.com/royalty-free-sound-effects/guns/` | royalty-free / 商用免署名 | 已烘焙好混响的成品 burst | JSON-LD 直接给 `contentUrl` mp3 直链;编辑评分 |
| **SFX Engine** `sfxengine.com/sound-effects/firearm` | royalty-free | Kriss Vector 等 SMG 专项,loop-ready mono 48k 0.3s | 短小干净,适合切片 |
| **SFX Mint** `sfxmint.com/sounds/machine-gun-burst` | CC0 | 2 变体 2.5s | 直接 mp3 + wav 下载 |
| **Mixkit** `mixkit.co/free-sound-effects/gun/` | Mixkit License 免署名 | 23 个 gun SFX 通用 | 免登录直下 |
| **Audio.com** `audio.com/category/sound-effect/gunshot` | 各异 | 700+ gunshot 资源 | 部分游戏风格素材 |
| **BudgetPixel** `budgetpixel.com/sfx/...` | royalty-free | 3.0s rapid machine gun burst,AI 生成但编辑评分 10.0/10 | 干净 |
| **Soniss GDC Bundle** `soniss.com` | royalty-free | The Gun Locker 500+ 文件 96kHz/24bit;**每年 GDC 期间免费** | 顶级专业库 |
| **Boom Library** `boomlibrary.com` | 付费 | Toy Guns / WWI / WWII Firearms,192kHz/24bit | 商单项目优先 |

**SMG 单发/连发最常用备选(本轮已下到 `Art/audio/sfx/_review/` 待挑)**:

| 文件 | 时长 | 来源 | 授权 | 评分 | 特征 |
|---|---:|---|---|---|---|
| `cand1_freesound_mp5_single_hq.mp3` | 0.81s | Freesound smill.and.welson | CC-BY 4.0 | 暂无 | **真 H&K MP5 SMG 9mm 实弹**;48kHz/32bit 立体声;需署名 American Sub Gunner |
| `cand2_freesound_mg002_single_hq.mp3` | 1.01s | Freesound pgi | **CC0** | 4.6 / 98 | 电子合成 SMG 单发;免署名 |
| `cand3_freesound_mg001_single_hq.mp3` | 1.00s | Freesound pgi | **CC0** | 4.7 / 95 | 电子合成,评分最高 |
| `cand4_sonilo_distant_smg_burst.mp3` | 1.88s | Sonilo | royalty-free | 编辑 10/10 | 远景 SMG 短点射 + 户外 reverb,已烘焙好 |
| `cand5_pgi_mg001_triple_hq.mp3` | 1.20s | Freesound pgi | **CC0** | 4.5 / 72 | **电子合成 3 连发**——本轮**已落盘为 `sfx_weapon_defender9_fire.mp3`** |
| `cand6_pgi_mg002_triple_hq.mp3` | 1.61s | Freesound pgi | **CC0** | 4.4 / 58 | 电子合成 3 连发 |
| `cand7_pgi_mg002_loop_hq.mp3` | 0.90s | Freesound pgi | **CC0** | 4.3 / 55 | 电子合成 loop 段 |
| `cand8_pgi_mg001_loop_hq.mp3` | 0.30s | Freesound pgi | **CC0** | 4.4 / 10 | 电子合成 loop 段,可叠 burst |

**A.2 第一个落盘决策(`sfx_weapon_defender9_fire`)**:从 cand1~8 里选 **cand5 pgi MG001 triple shot(1.20s 三连发,CC0)**。理由:**1.20s 比清单 0.55s 目标长,但和 A.1 实际值大于清单目标一脉相承**(承载完整"3 发 + 衰减"曲线),且三连发在 SMG 武器里比单发更"SMG 感";CC0 商用无负担;可以直接复用到 A.2 其他 SMG 武器变体(野兔跳跃者、黎明初霁)的"音色递进"基准。

**绑定策略澄清(本轮新增,与 §1 绑定表互锁)**:

1. **开火按武器**——同一把武器,谁拿都是同一个 fire 音;`units[*]` 不写 fire,避免"用别的武器时角色级兜底"语义被误读;
2. **受击按角色**——被打的人是谁 → 谁就叫;和穿什么护甲无关(护甲只影响伤害类型 → A.3 `hit_armor`/`hit_flesh`),和用什么武器打过来也无关;
3. **miss 走统一 default 兜底**——`sfx_bullet_whiz` 一个全局,所有角色共用;
4. **bulwark 一个特殊 miss**——`units[raider_bulwark].miss` 单独覆盖为 `sfx_bulwark_shield_miss`,体现护盾机制。

### 6.7 A.1 回合横幅音重做(`sfx_turn_in`,2026-10-08)

`sfx_turn_in` 第一版走的是 `batch_text_to_music` 路线(源 `cutin_in_v2.mp3` 切片),时长 2.7s。2.7s 在 §A.1 v1.1 修订时就说过"实际值大于清单目标 0.25~0.30s"——但听感上对"回合横幅入场"还是偏长,玩家在战斗中会等那个衰减走完才看到行动条。

本轮重做,从 Freesound AudioPapkin 候选里挑了 `Cinematic Woosh SFX-008.wav` (3.89s,CC0) 切**前 1.5s**,保留"金属冲击 + 鼓点 + 衰减"三段结构,去掉尾段无信息量的拖尾。

| 文件 | 时长 | 来源 | 授权 | 评分 | 切片 |
|---|---:|---|---|---|---|
| `cand_a1_audpapkin_swoosh3.mp3` | 1.57s | Freesound AudioPapkin · Swoosh 3 | **CC0** | 暂无 | — |
| `cand_a1_audpapkin_swoosh7.mp3` | 2.03s | Freesound AudioPapkin · Swoosh 7 | **CC0** | 暂无 | — |
| **`cand_a1_audpapkin_cinematic_woosh008.mp3`** | **3.89s** | Freesound AudioPapkin · Cinematic Woosh SFX-008 | **CC0** | 10 评 | **@ 0.00s 取 1.50s → 已落盘为 `sfx_turn_in.mp3`** |
| `cand_a1_audpapkin_futuristic_organic46.mp3` | 4.11s | Freesound AudioPapkin · Futuristic organic effect (46) | **CC0** | 7 评 | — |

**ffmpeg 切片命令**(本轮 §6.2 模板的具体应用):
```bash
ffmpeg -y -ss 00:00:00.000 -i cand_a1_audpapkin_cinematic_woosh008.mp3 -t 1.50 \
  -c:a libmp3lame -b:a 96k -ar 48000 -ac 1 \
  Art/audio/sfx/sfx_turn_in.mp3
```

输出规格:48kHz / 16bit / 单声道 / 96kbps MP3 / 1.500s,符合 §3 规范。

**A.1 落盘状态变化**:
- `sfx_turn_in` 2.7s → **1.5s**,v1 切片备份在 `_review/rejected_sfx_turn_in_v1_batch_music_2.7s.mp3`
- `sfx_turn_out` 2.0s **未动**(用户本次只重做 turn_in,turn_out 仍走 v1 切片)

### 6.8 A.2 收录 2 个 SMG 家族 cue(`hare_hopper` / `dawn_pulse`,2026-10-10)

本轮走 game-sfx-search 技能(Freesound 免登录 preview 路线),单源产出 12 个候选 → 用户听选后指定加工配方 → ffmpeg 合成落盘;未选中的 10 个候选与加工中间产物已按「收录」流程清理(`_review/` 已清空)。

| cue | 加工配方 | 成品时长 | 电平(实测) | 来源(均 CC0) |
|---|---|---:|---:|---|
| `sfx_weapon_hare_hopper_fire` | `Silenced SMG Three-Shot Burst`(0.441s)**×2 直拼**——源尾 30ms 已自然衰减至 -59dB,拼接点无爆音;节奏为 3+3 连发 | 0.883s | 峰值 -1.2dBFS / RMS -12.2dB | Freesound qubodup #740120 |
| `sfx_weapon_dawn_pulse_fire` | `sci-fi weapon shot` 取**前 1s** + hare_hopper 成品**双轨叠加**(0~0.88s 两层齐响,0.88~1.0s 仅 dimapain 尾段;叠加前峰值 +5.26dB → 统一压回 -1dBFS;末端 30ms 淡出防硬切) | 1.000s | 峰值 -1.0dBFS / RMS -14.1dB | Freesound dimapain #867558 |

- 规格:48kHz / 单声道 / MP3 96kbps(§3);实落时长大于清单目标(0.45 / 0.40s),与 defender9(1.20s)同量级,延续 A.1/A.2「实际值大于目标」惯例。
- 电平参考:defender9 实测峰值 0.0dBFS / RMS -7.9dB;本两件峰值 -1.2 / -1.0,RMS -12.2 / -14.1——后续若要统一家族响度,可加软限幅版。
- 绑定:`conf/battle/sfx_bindings.json` 的 `weapons[weapon_benny_hare_hopper / weapon_benny_dawn_pulse].attack_fire` 原本即指向这两个 cue key,**未改任何代码,落盘即生效**;`--headless --path . --import` 通过(仅既有 TileSet 图集类报错,与音频无关),两个新文件的 `.import` 与 `.godot/imported` 缓存均已生成。

### 6.9 A.2 收录 3 个敌人开火音(`raider_infantry` / `raider_scout` / `raider_bulwark`,2026-10-10)

用户听选 3 个候选并指定切片 → ffmpeg 落盘(降混单声道 48k → 尾 30ms 淡出 → 峰值校到 ≈ -1dBFS → MP3 96k);三个来源均 CC0;绑定已在位(`units[<art_key>].attack_fire`,v1.6),**未改代码,落盘即生效**;候选与中间产物已按「收录」流程清理。

| cue | 配方 | 成品时长 | 电平(实测) | 来源(均 CC0) |
|---|---|---:|---:|---|
| `sfx_weapon_raider_infantry_fire` | `AK-47 single` 取前 0.8s(切口处 -32.4dB,补 30ms 淡出) | 0.800s | 峰值 -1.3dBFS / RMS -16.4dB | Freesound serøutōnin #855841 |
| `sfx_weapon_raider_scout_fire` | `autorifle metallic punchy` 取前 0.7s(切口处 -23.8dB,补 30ms 淡出) | 0.700s | 峰值 -1.2dBFS / RMS -18.7dB | Freesound serøutōnin #855655 |
| `sfx_weapon_raider_bulwark_fire` | `pgi Heavy weapon 002 single` 取前 0.8s(切口处 -6.7dB,补 30ms 淡出) | 0.800s | 峰值 -1.2dBFS / RMS -8.9dB | Freesound pgi #257962 |

- 家族响度参考(RMS):defender9 -7.9 / hare_hopper -12.2 / dawn_pulse -14.1;本次 scout 偏轻(-18.7)、bulwark 偏厚(-8.9),如需统一响度可后续出软限幅版。
- 三个新文件的 `.import` 与 `.godot/imported` 缓存已生成;`--headless --path . --import` 通过(仅既有 TileSet 图集类报错,与音频无关)。

### 6.10 A.2 收尾:收录 3 个 cue(`hound_bite` / `sentry_laser` / `attack_fire_default`,2026-10-10)

A.2 最后三件一并收录;`conf/battle/sfx_bindings.json` 的 `default.attack_fire` 由空串回填为 `sfx_attack_fire_default`(本表唯一需要显式回填的绑定);三个来源均 CC0;候选与中间产物已按「收录」流程清理。

| cue | 配方 | 成品时长 | 电平(实测) | 来源(均 CC0) |
|---|---|---:|---:|---|
| `sfx_weapon_hound_bite` | `Escorpion_melee` 原长直用(源尾 30ms 仍是 -0.1dB → 补 30ms 淡出) | 0.556s | 峰值 -0.8dBFS / RMS -16.6dB | Freesound CSStudios #871496 |
| `sfx_weapon_sentry_laser` | `Spaceship laser burst` 前 1s + `Laser Gun 01` 前 1s **双轨合并**(叠加前峰值 +2.3dB → 统一压回;切口处 laser_gun 仍有 -15.5dB → 尾 30ms 淡出) | 1.000s | 峰值 -0.7dBFS / RMS -16.8dB | Freesound randbsoundbites #868441 + mrspivey #805193 |
| `sfx_attack_fire_default` | `machinegun-one-shot` **×2 跨淡化直拼**(10ms 交界 crossfade——源尾/源首均 ~0dB 满电平;尾 30ms 淡出) | 0.701s | 峰值 -0.9dBFS / RMS -20.4dB | Freesound DeltaCode #668347 |

- **A.2 9/9 全部落盘**;规格均为 48kHz / 单声道 / MP3 96kbps(§3);三个新文件的 `.import` 与 `.godot/imported` 缓存已生成。

### 6.11 M 类收录 6 件移动脚步(benny / scout / bulwark / hound / sentry / infantry,2026-10-10)

Mixkit + Freesound 混合源(均 CC0 / Mixkit License)。**注意:实落为"步伐段落"(3~5s)而非单步**——用户指定段落;单格节拍 0.3s 的调用策略待代码接线时定(循环 / 整段 / 再切单步)。

| cue | 配方 | 成品时长 | 电平(实测) | 来源 |
|---|---|---:|---:|---|
| `sfx_move_step_benny` | `Footsteps Run` 原长直用(尾 30ms 补淡出) | 3.905s | 峰值 -1.0dBFS / RMS -24.7dB | Freesound DavidJohnson2019 #867161(CC0) |
| `sfx_move_step_raider_scout` | Mixkit `Footsteps on mattress loop`(23.2s)取**前 5s**,两端 30ms 淡化 | 5.000s | 峰值 -1.0dBFS / RMS -22.2dB | Mixkit #1274 |
| `sfx_move_step_raider_bulwark` | Mixkit `Giant monster footstep`(29.4s)取**前 5s**,两端 30ms 淡化 | 5.000s | 峰值 -0.9dBFS / RMS -24.6dB | Mixkit #1270 |
| `sfx_move_step_pyroxene_hound` | qubodup `Dog Running Past`(5.22s)取 **2s~5s**,两端 30ms 淡化 | 3.000s | 峰值 -0.9dBFS / RMS -22.5dB | Freesound qubodup #827320(CC0) |
| `sfx_move_step_pyroxene_sentry` | Mixkit `Robot step`(9.6s)取**前 5s**,两端 30ms 淡化 | 5.000s | 峰值 -1.0dBFS / RMS -19.8dB | Mixkit #2530 |
| `sfx_move_step_raider_infantry` | `Small Puddle Splash`(0.406s)**×10 等间隔直拼**(450ms/步,无随机变化),尾 30ms 淡化 | 4.456s | 峰值 -1.2dBFS / RMS -30.0dB | Freesound Robo9418 #841834(CC0) |

- 两端 30ms 淡化用于防切片爆音;若改 seamless loop 使用,需去掉淡化并重做 loop 点。
- 6 件的 `.import` 与 `.godot/imported` 缓存已生成;**M 类 6/6 全部落盘**(infantry 采用「`puddle_splash` ×10 等间隔直拼」工艺,450ms/步)。

---

### 6.12 D.7 移动悬停音收录(`sfx_move_hover_benny`,2026-10-10)

走 game-sfx-search 技能单源(Freesound 免登录 preview)产出 14 个候选 → 用户听选 `loganzsound · Lightswitch Flick_02`(CC0,48kHz 单声道,源长 0.250s);落盘 + 绑定 + 接线一次完成;未选中候选与中间产物已按「收录」流程清理。

| 项 | 值 |
|---|---|
| 源 | Freesound loganzsound #872834 `Lightswitch Flick_02`(CC0;48kHz 单声道) |
| 配方 | 去前 12.5ms 引导静音 → 取 0.150s → 尾 30ms 淡出 → +12.70dB 峰值校至 -1.00dBFS(wav 阶段)→ 48kHz 单声道 MP3 96kbps |
| 成品实测 | 0.150s;峰值 -2.3dBFS(编解码后实测,短瞬态经 MP3 编码的自然衰减)/ RMS -27.3dB(与 C 类 `ui_hover` 家族 -28.3dB 对齐) |
| 绑定 | `conf/battle/sfx_bindings.json` → `units[benny].move_hover` |
| 接线 | `Script/battlefield.gd`:`_process` 移动态中悬停格变化且可达、`action_points > 0` 时 `_sfx.play(&"move_hover", {"attacker": player})`;新增 `MOVE_HOVER_SFX_COOLDOWN_MSEC = 60` 冷却(与 `UiSfx` 按钮 hover 的 60ms 冷却同口径,防快速扫格叠音) |
| 验证 | `--headless --path . --import` 通过(仅既有 TileSet 类报错);Battlefield headless 90 帧无脚本错误;单独校验 `units[benny].move_hover` → `sfx_move_hover_benny` → 资源存在(0.150s) |

---

> **下一步**:A.2 **9/9 全部落盘** ✅、M 类 **6/6 全部落盘** ✅、D.7 移动悬停 ✅;接着 A.3 命中类(4)+ A.4 受击(3)、A.5 战斗遮罩(2)、G 结算(5)。`sfx_turn_out` 如果你也想重做(走 Freesound cinematic impact 但**比 turn_in 更"敌对"**——比如 "industrial bass boom" / "epic explosion" / "synth drop")告诉我。
