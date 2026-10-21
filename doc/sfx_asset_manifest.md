# 音效资产清单(SFX Asset Manifest)

> 版本 v1.39(2026-10-20)· 配套 `Script/battle/battle_sfx.gd` + `conf/battle/sfx_bindings.json`
> 道具逐项音效需求见 [`doc/item_sfx_manifest.md`](item_sfx_manifest.md);Benny 台词与 TTS 资产见 [`doc/benny_voice_lines.md`](benny_voice_lines.md)。
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
> v1.15 修订(2026-10-10):**A.5 战斗遮罩改为按角色绑定**——弃用固定 cue `sfx_battle_cutin_in/out`,改为 `units[<attacker art_key>].battle_cutin_in / .battle_cutin_out`(**发起 attack 的角色**各一对,6 角色共 **12 个** cue:`sfx_battle_cutin_in_benny` … `sfx_battle_cutin_out_pyroxene_sentry`);`default.*` 保留兜底;**零代码改动**(`BattleCutIn._sfx_context` 已带 attacker);总 cue 数 92 → **102**;详见 §A.5。
> v1.16 修订(2026-10-10):**命中 / 受击合并为「每角色一个」**——弃用 `hit_armor` / `hit_flesh` / `hurt`(打击层 + 语音层的两层设计),改为 `units[<victim art_key>].hit` 共 6 个 cue(`sfx_hit_benny` … `sfx_hit_pyroxene_sentry`),absorbed / damage 都播它,不再区分击中护甲/入肉;保留 `sfx_bullet_whiz`(`default.miss`)与 `sfx_bulwark_shield_miss`(bulwark 特例);`sfx_unit_down` 改挂 `Unit.defeated` 信号——**真正死亡时**播放(含 debuff 流血流死);代码同步:`battle_cut_in` 两分支合并为 `hit`、`unit_down` 移到 `Battlefield._on_unit_defeated`;总 cue 数 102 → **104**。
> v1.17 修订(2026-10-10):**受击/倒地细化 + benny 走 TTS**——`unit_down` 由全局单个改为**按角色**(`units[<art_key>].unit_down` 6 个,`default.unit_down` 仅兜底);benny 受击**留空**(女声素材网络池不可用,改走 **TTS 模型**路线待做),benny 倒地待定;已选待收录:infantry hit←`Oof` / scout hit←`Enemy hurt 1` / hound hit←`Bark and Growl`、infantry down←`Hurt light 1` / bulwark down←`Damage Hurt ooh!` / hound down←`Small Dog Cry`、whiz←`subsonic flyby`;**重搜**:bulwark hit / sentry hit(小爆炸)/ scout down / sentry down(较大爆炸)/ bulwark_shield_miss;总 cue 数 104 → **109**;详见 §A.4。
> v1.18 修订(2026-10-10):**A.4 选型推进**——sentry hit←`Explosion (Pixel SFX)` / sentry down←`EXPLOSION_SFX1`(取前 1.2s)/ `bulwark_shield_miss`←`deepcrash`(均已选待收录);人形单位(掠夺系)的**命中 / 倒地 = 痛呼人声**方向,bulwark hit / scout down 重搜候选试听中;benny 仍走 TTS。
> v1.19 修订(2026-10-10):**A.3 / A.4 收录 12 件**(落盘即生效)——hit×5(infantry←`Oof` / scout←`Enemy hurt 1` / bulwark←`Head Impact Grunt` 取 0.6s→ / hound←`Bark and Growl` / sentry←`Explosion (Pixel)`)+ unit_down×5(infantry←`Hurt light 1` / scout←`Character Death` / bulwark←`Damage Hurt ooh!` / hound←`Small Dog Cry` / sentry←`EXPLOSION_SFX1` 取前 1.2s)+ `bullet_whiz`←`subsonic flyby` + `bulwark_shield_miss`←`deepcrash`;benny 的 hit / down 留空(TTS / 待定);已落盘 25 → **37**;详见 §6.13。
> v1.20 修订(2026-10-19):**角色表现改为「语音台词优先」**——贝妮相关语音统一走**人物配音 / TTS**,不使用 `game-sfx-search` 搜网络素材;人形敌人(`raider_infantry` / `raider_scout` / `raider_bulwark`)的遮罩台词可用 `game-sfx-search` 搜人声候选;非人形(`pyroxene_hound` / `pyroxene_sentry`)保持兽类 / 机械音。**G 战斗结算 5 个 cue 重构为 Player 语音台词槽**,每个事件支持多条可选台词,后续用 TTS 生成。详见 §A.4 / §A.5 / §G / §N。
> v1.21 修订(2026-10-19):**撤销 A.5 退场与网搜人声方案**——A.5 只保留每个角色的 `battle_cutin_in`,删除全部 `battle_cutin_out` cue 及 `BattleCutIn.end_session()` 播放接入点;A.5 由 12 个降为 **6 个**。战斗遮罩台词(含人形敌人)后续统一走 **TTS**,不再用 `game-sfx-search` 搜英文人声;hound / sentry 仍按兽类 / 机械 SFX 处理。A.1 回合横幅的 `turn_in` / `turn_out` 不受影响。当前有效 cue 去重口径 **104 → 98**。
> v1.22 修订(2026-10-19):**D 类收口**——`sfx_move_blocked_benny` 改为通用 `sfx_move_blocked`,复用 `sfx_ui_error` 并接入移动受阻分支;`sfx_select_unit` 改为 `sfx_select_player`,按 player 绑定、后续 TTS;删除 `sfx_context_open`(现有 `ui_open` 已覆盖)与 `sfx_turn_end`(回合转换已有音效)。当前有效 cue **98 → 96**。
> v1.23 修订(2026-10-19):**删除 `sfx_select_enemy`**——选中敌人会打开 `UnitStatusWidget`,已通过 `UiSfx.attach_panel()` 播 `ui_open`,不再单独做选中敌人 cue。当前有效 cue **96 → 95**。
> v1.24 修订(2026-10-20):**E 类收口**——`sfx_bleed_apply` / `sfx_fracture_apply` 改为按受害者 `art_key` 绑定的 TTS 短语音;`sfx_bleed_tick` 标记为可选待定(实际触发在角色**回合开始**,不是回合结束);删除 `sfx_armor_break` 与 `sfx_status_removed`,状态移除复用 `sfx_heal_tick`。当前有效 cue **95 → 93**。
> v1.25 修订(2026-10-20):**医疗道具拆成两个接入点**——`sfx_heal_tick` 只在医疗道具消耗成功后、效果结算前播放;新增 `voice_heal`,在医疗效果实际生效后按角色播 TTS 语音。两个接入点已写进 `Battlefield._on_consumable_use_requested()`;音频 / TTS 未生成时用 `BattleSfx.play_optional()` 静默跳过。当前有效 cue **93 → 94**。
> v1.26 修订(2026-10-20):**文档拆分与 heal_tick 待生产**——`sfx_heal_tick` 本轮候选全部否决并清理,状态改为**待生产**;新增 `doc/item_sfx_manifest.md` 盘点全部道具音效需求;Benny 台词与 TTS 资产移入 `doc/benny_voice_lines.md`,本表只保留系统规则。有效 cue 数仍为 **94**。
> v1.27 修订(2026-10-20):**道具音效收口**——头甲背包穿 / 脱 / 丢弃合并为 `sfx_equip_gear`;删除拖拽 / 整理 / 容器搜索 / 空箱 / 商店不足独立 cue;`sfx_item_merge` 按产出等级移调到 C 大调;居民订单改居民 TTS;拾取改为物品覆盖 + 默认兜底;配件安装 / 拆卸各自共用。`doc/item_sfx_manifest.md` 精简为「道具绑定 / 场景动作绑定」两张表。当前有效 cue **94 → 86**。
> v1.28 修订(2026-10-20):**B1 道具基础 SFX 收录**——`sfx_item_pickup` / `sfx_equip_gear` / `sfx_equip_weapon` 落盘;三个食物/AP 物品改为物品级 `use_sfx`(压缩口粮 / 强化野战餐 / 热量餐包各一条,`sfx_item_use` 按 1 个 cue 族计)。已落盘 **37 → 41 cue / 43 个 mp3**;新增 §6.14 记录来源、规格与接线。下一批定为 **B2 道具 / 装备闭环**(附件装拆、二合、开箱、医疗 use)。
> v1.29 修订(2026-10-20):**B2 口径修正**——`sfx_heal_tick` 改为按 **7 个医疗物品**分别搜索 / 绑定 `heal_sfx`,不再做单一通用文件;`sfx_heal_tick` 保留为语义族名。B2 由 5 个 cue 调整为 **11 个搜索组**(4 个通用 cue + 7 个医疗物品变体)。
> v1.30 修订(2026-10-20):**B2 通用项收录**——`sfx_attachment_install` / `sfx_attachment_remove` 落盘并接入仓库 / 战斗配装面板;`sfx_item_merge` 改为 ffmpeg 合成的单条 C 基频“咚”(0.750s,C4 261.63Hz),按 Lv1~Lv8 做 C 大调移调。已落盘 **41 → 44 cue / 46 个 mp3**;剩余 B2 为 7 个医疗物品 `heal_sfx` 候选。
> v1.31 修订(2026-10-20):**B2 医疗 3/7 收录**——`consumable_dried_medicine_02` / `consumable_debridement_dressing_03` / `consumable_sterile_bandage_04` 三个 `heal_sfx` 落盘并接入;其余 4 个医疗物品仍待搜。已落盘 **44 / 86 cue + 49 个 mp3**。
> v1.32 修订(2026-10-20):**B2 医疗 4/7 收录**——`consumable_frontline_rescue_08` 使用 `ECG sim ×6 @1.5×` 落盘;剩余急救包 / 战地医疗箱 / 创伤处理包 3 个 `heal_sfx`。已落盘 **44 / 86 cue + 50 个 mp3**。
> v1.33 修订(2026-10-20):**B2 医疗 7/7 收录**——急救包 = `Box Latch` + Water Squirt 后 50% ×3 @0.75× 降 4 半音;战地医疗箱 = `Box Latch` + 绷带撕开;创伤处理包 = `Zipper Zipping` + 同款注射;肾上腺素单独使用同款注射。已落盘 **44 / 86 cue + 54 个 mp3**。B2 仅剩 `sfx_container_open`。
> v1.34 修订(2026-10-20):**B2 完成**——`sfx_container_open` 收录 Freesound `PLASTIC_BRIEFCASE_OPENING_4`(CC0),接 `BattleContainer.begin_search()` 的 `opened_now` 分支。已落盘 **45 / 86 cue + 55 个 mp3**;下一批 B3 存档 / 商店。
> v1.35 修订(2026-10-20):**无菌绷带组改 x2**——`sfx_heal_tick_consumable_sterile_bandage_04.mp3` 改为两段绷带缠绕、120ms 间隔,成品 1.164s;`sfx_item_merge` 重做候选试听中(旧版偏混)。
> v1.36 修订(2026-10-20):**`sfx_item_merge` 定稿为脆叮**——采用 `crisp_tick3`(C5 523.25Hz + C6/C7 泛音 + 短高频起振),成品 0.400s;旧 0.750s 低频“咚”版本替换。注意:当前基础音为 C5,按半音表移调后实际音区为 C5~C6。
> v1.37 修订(2026-10-20):**`sfx_item_merge` 降八度定稿**——`crisp_tick3` 整体降八度,基础音回到 C4 261.63Hz,实际音区 C4~C5,符合原 MIDI 60 口径;成品 0.395s,峰值 -1.3dBFS。
> v1.38 修订(2026-10-21):**状态语音改到玩家回合开始**——`sfx_bleed_apply` / `sfx_fracture_apply` 不再在受击结算播放;玩家回合开始、状态结算后从当前负面状态随机播一条。同步修复 `Unit.add_status()` 在已有状态时漏加新状态的问题。
> v1.38 修订(2026-10-20):**二合预制 8 个变体**——以 Lv1 C4 脆叮为基础,生成 `sfx_item_merge_lv1~lv8.mp3`,对应 C4 / D4 / E4 / F4 / G4 / A4 / B4 / C5;8 个 binding 已写入 `default.item_merge_lv*`。mp3 总数 55 → **62**。
> v1.39 修订(2026-10-20):**二合备用 2 级**——追加 `sfx_item_merge_lv9.mp3`(D5)与 `sfx_item_merge_lv10.mp3`(E5),继续 C 大调;绑定同步到 `default.item_merge_lv9/lv10`。mp3 总数 62 → **64**。

---

## 0. 总览

| 项 | 值 |
|---|---|
| 总 cue 数 | **86**(当前有效 cue,已去重 D/M 的 `sfx_move_step_benny`;A.5 只保留 in;D/E/F/H/J 类已按 v1.27 收口) |
| 已落盘 | **45 / 86 cue + 64 个 mp3**(A.1 turn_in/out 2 + A.2 开火 9 + A.3 未命中 2 + A.4 命中倒地 10 + C 类 UI 7 + D.7 移动悬停 1 + M 类脚步 6 + F 拾取/物品使用/二合/开箱 4 + H 武器装备/头甲背包/配件装拆 4;另有 `sfx_item_use` 3 个物品变体、`sfx_heal_tick` 7/7 个医疗物品变体、`sfx_item_adrenaline` 1 个、`sfx_item_merge` 10 个等级变体) |
| 分类数 | **12**(A、C~M) |
| 命名风格 | `sfx_<scene>_<verb>` / `bgm_<scene>` / `amb_<scene>` |
| 采样规格(目标) | SFX 48kHz/16bit 单声道;BGM 48kHz/24bit 立体声;时长 ≤2.5s(SFX)/60~120s(BGM)/10~30s(loop 环境音) |
| **实际落盘格式** | **MP3 (libmp3lame) 96kbps 单声道**(本机 ffmpeg 8.1 编了 `libmp3lame` / `libopus` 但**没编 `libvorbis`**;MP3 兼容性最广、QuickTime/Win Media/几乎所有播放器直接放;Godot 4 原生支持 `.mp3` import) |
| 文件位置 | `res://Art/audio/sfx/`、`res://Art/audio/bgm/`、`res://Art/audio/amb/` |
| 绑定方式 | `conf/battle/sfx_bindings.json`(`weapons` / `units` / `default`) |
| UI 音效入口 | autoload **`UiSfx`**(`Script/ui/ui_sfx.gd`)+ `conf/audio/ui_sfx.json`;战斗演出仍由 `TurnTransition` / `BattleCutIn` 各自持有的 `BattleSfx` 播放 |
| 优先级 | 批次 1 已完成;B1 道具基础 SFX 已完成;下一批 **B2 道具 / 装备闭环**(5 个 SFX,+1 可选);其余见 §2 |

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

### A.3 未命中 / 特殊命中(v1.16 精简)

> v1.16 改设计:`hit_armor` / `hit_flesh` 两个"打击层" cue 弃用——命中(含护甲吸收 / 入肉)与单位受击合并为**每角色一个** `hit`(见 A.4)。本节只保留未命中与护盾兵特例。
> **`miss` 有且仅有一个角色特殊例外:护盾兵 `raider_bulwark`**——"格挡/护盾反弹"的 miss 音单独覆盖(`units[raider_bulwark].miss`)。

| cue key | 时长 | 描述 | 触发点 | 绑定 |
|---|---|---|---|---|
| `sfx_bullet_whiz` | 0.30s | 子弹擦肩而过的啸叫 | `miss`(未命中帧) | `default.miss` 全局兜底 |
| `sfx_bulwark_shield_miss` | 0.45s | 护盾兵格挡反弹音,金属护盾共鸣 + 滑开 | `miss` 且受害者为护盾兵 `raider_bulwark` | `units[raider_bulwark].miss` 特殊覆盖 |

> 状态(2026-10-10):`sfx_bullet_whiz` ✅ 已落盘(`subsonic flyby`,1.334s);`sfx_bulwark_shield_miss` ✅ 已落盘(`deepcrash`,1.073s)。

### A.4 单位被击中 / 倒下(按角色 art_key 绑定,v1.17 细化)

> **命中**与**受击**合并为一个 cue:被打中的是谁 → 播谁(`absorbed` / `damage` 都走它),不再分"打击音 + 语音"两层,也不再分护甲/入肉。
> **`unit_down` 同样按角色(v1.17)**:`units[<art_key>].unit_down`,在**真正死亡时**播放(击倒落定 + debuff 流血致死,挂 `Unit.defeated` 信号);`default.unit_down` 仅兜底。
> **benny 特例(v1.21 定案)**:贝妮的受击 / 倒地统一走 **人物配音 / TTS**,不再用 `game-sfx-search` 搜网络素材;`sfx_hit_benny` / `sfx_unit_down_benny` 暂留空,台词与 TTS 资产见 [`doc/benny_voice_lines.md`](benny_voice_lines.md)。人形敌人已落盘的 hit / down 人声素材保留;后续新增角色语音统一 TTS,不再网搜英文人声。hound / sentry 保持兽类 / 机械音。
> **v1.18 方向**:人形单位(掠夺系)的**命中 / 倒地 = 痛呼人声**(网络素材);非人形按各自语义(hound 兽类、sentry 爆炸/机械)。

**hit(命中 / 受击)**

| cue key | 时长 | 描述 | 绑定 | 状态 / 选型 |
|---|---|---|---|---|
| `sfx_hit_benny` | 0.50s | 贝妮被击中 | `units[benny].hit` | ⏳ 人物配音 / TTS(禁止 `game-sfx-search`) |
| `sfx_hit_raider_infantry` | 0.45s(实落 0.27s) | 掠夺兵被击中 | `units[raider_infantry].hit` | ✅ 已落盘(`unfa · Oof`,详见 §6.13) |
| `sfx_hit_raider_scout` | 0.45s(实落 1.43s) | 斥候被击中 | `units[raider_scout].hit` | ✅ 已落盘(`K27K_Mike · Enemy hurt 1`) |
| `sfx_hit_raider_bulwark` | 0.50s(实落 1.14s) | 护盾兵被击中 | `units[raider_bulwark].hit` | ✅ 已落盘(`Head Impact Grunt` 取 0.6s→尾) |
| `sfx_hit_pyroxene_hound` | 0.40s(实落 0.74s) | 猎犬被击中(兽类) | `units[pyroxene_hound].hit` | ✅ 已落盘(`Dogs · Bark and Growl`) |
| `sfx_hit_pyroxene_sentry` | 0.45s(实落 0.39s) | 哨戒机被击中 | `units[pyroxene_sentry].hit` | ✅ 已落盘(`Explosion (Pixel SFX)`) |

**unit_down(真正死亡,含 debuff 致死)**

| cue key | 时长 | 描述 | 绑定 | 状态 / 选型 |
|---|---|---|---|---|
| `sfx_unit_down_benny` | 1.20s | 贝妮倒下 | `units[benny].unit_down` | ⏳ 人物配音 / TTS(台词待定) |
| `sfx_unit_down_raider_infantry` | 1.00s(实落 0.43s) | 掠夺兵倒下 | `units[raider_infantry].unit_down` | ✅ 已落盘(`Kreha · Hurt light 1`) |
| `sfx_unit_down_raider_scout` | 1.00s(实落 1.13s) | 斥候倒下 | `units[raider_scout].unit_down` | ✅ 已落盘(`randbsoundbites · Character Death`) |
| `sfx_unit_down_raider_bulwark` | 1.20s(实落 1.06s) | 护盾兵倒下 | `units[raider_bulwark].unit_down` | ✅ 已落盘(`Damage Hurt ooh!`) |
| `sfx_unit_down_pyroxene_hound` | 1.00s(实落 0.82s) | 猎犬倒下 | `units[pyroxene_hound].unit_down` | ✅ 已落盘(`Small Dog Cry`) |
| `sfx_unit_down_pyroxene_sentry` | 1.50s(实落 1.20s) | 哨戒机倒下 | `units[pyroxene_sentry].unit_down` | ✅ 已落盘(`EXPLOSION_SFX1` 取前 1.2s) |

> 旧全局 cue `sfx_unit_down` 退役为 `default.unit_down` 兜底(可为空);`sfx_bullet_whiz` 已选 `subsonic flyby`、`bulwark_shield_miss` 已选 `deepcrash`(待收录)。

### A.5 战斗遮罩入场(按发起 attack 的角色绑定,v1.21 只保留 in)

> 服务 `BattleCutIn`(战斗入场遮罩:左攻右守立绘 + 数值飘字)。
> v1.15 起:入场音按**发起 attack 的角色**绑定——`units[<attacker art_key>].battle_cutin_in`(复用 resolve_binding 的 units 通道;`BattleCutIn._sfx_context` 已带 attacker)。
> **v1.21 起:退场 `battle_cutin_out` 全部取消**——`BattleCutIn.end_session()` 不再播任何 cue;`conf/battle/sfx_bindings.json` 同步删除 `battle_cutin_out` 兜底项。旧固定 cue `sfx_battle_cutin_in/out` 弃用。
> **v1.21 表演路线**:保留的 in cue 中,「角色台词」和「过渡底音」仍分两层。贝妮与人形敌人的台词后续统一走 **TTS**,不再用 `game-sfx-search` 搜英文人声;Benny 台词见 [`doc/benny_voice_lines.md`](benny_voice_lines.md)。hound / sentry 保持兽类 / 机械音,可走 SFX。若遮罩仍需要 whoosh / 金属冲击底音,再单独做 SFX 层,不要与台词混成一个 cue。

| 角色(art_key) | 入场 cue | 描述 | 表现路线 | 状态 |
|---|---|---|---|---|
| `benny` | `sfx_battle_cutin_in_benny` | 贝妮突入:轻快果断 + 短促金属 | 人物配音 / TTS | ⏳ 台词待定 |
| `raider_infantry` | `sfx_battle_cutin_in_raider_infantry` | 掠夺兵:粗粝街头感 | TTS 台词 | ⏳ 台词待定 |
| `raider_scout` | `sfx_battle_cutin_in_raider_scout` | 斥候:更尖更疾 | TTS 台词 | ⏳ 台词待定 |
| `raider_bulwark` | `sfx_battle_cutin_in_raider_bulwark` | 护盾兵:低沉厚重 + 金属共鸣 | TTS 台词 | ⏳ 台词待定 |
| `pyroxene_hound` | `sfx_battle_cutin_in_pyroxene_hound` | 猎犬:兽性冲刺 | 兽类非人声 | ⏳ 后续搜 SFX |
| `pyroxene_sentry` | `sfx_battle_cutin_in_pyroxene_sentry` | 哨戒机:机械上电 | 机械 / 电子音 | ⏳ 后续搜 SFX |

> 触发点:`BattleCutIn.begin_session()`;绑定值在音频收录时回填 `units[<art_key>]`。`BattleCutIn.end_session()` 只做遮罩淡出,不再播放 cue。

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

## D. 战场地图交互(4)

> v1.21 收口:**移动被阻挡不再按角色拆 cue**——`sfx_move_blocked_benny` 改为通用 **`sfx_move_blocked`**,直接复用已落盘的 `sfx_ui_error`(`default.move_blocked → sfx_ui_error`),不新增音频。
> `sfx_select_unit` 改为 **`sfx_select_player`**,按 player 自身绑定(`units[<player art_key>].select_player`);不同 player 以后发出不同语音,走后续 TTS,不做网搜。
> **`sfx_context_open` 删除**:`BattleContextMenu` 是 `PopupPanel`,现有 `UiSfx` 已自动播 `ui_open`。
> **`sfx_turn_end` 删除**:回合转换已有 `turn_in` / `turn_out` 横幅音,不再单独做结束回合 cue。
> **`sfx_select_enemy` 删除**:选中敌人会打开 `UnitStatusWidget`,已通过 `UiSfx.attach_panel()` 播 `ui_open`,不再单独做选中敌人 cue。

| cue key | 时长 | 描述 | 触发点 / 绑定 |
|---|---|---|---|
| `sfx_move_step_benny` | 0.25s | 单格脚步:贝妮兔耳短靴在废墟地面的"嗒" | 玩家每格移动(`Unit._step_to_next`),绑 `units[benny].move_step` |
| `sfx_move_blocked` | 复用 `sfx_ui_error` | 移动被阻挡 / AP 不足:直接复用低音错误提示 | `default.move_blocked → sfx_ui_error`;不新增文件 |
| `sfx_move_hover_benny` | 0.10s(实落 0.150s) | 移动预览悬停:指针移到/滑过**可移动格**上的轻提示 | 绑 `units[benny].move_hover` |
| `sfx_select_player` | 0.15s(语音长度待定) | 选中玩家单位:按当前 player 播专属短语音 | `_change_state(MOVE_STATE)`;绑 `units[<player art_key>].select_player`,后续 TTS |

> **已落盘 / 已接**:`sfx_move_step_benny`、`sfx_move_hover_benny`;`sfx_move_blocked` 复用 `sfx_ui_error`,无需新音频,已在 `Battlefield` 的移动态对“可达范围外的可行走格 / AP 不足”播放。`sfx_select_player` 等 TTS;选中敌人复用 `ui_open`,不再单独做 cue。

---

## E. 状态效果 / 数值反馈(5)

> v1.24 收口:`sfx_bleed_apply` / `sfx_fracture_apply` 不再做通用 SFX,改为按**受害者** `art_key` 绑定的 TTS 短语音。
> `sfx_bleed_tick` 的实际触发点是**角色回合开始**(`BattleCombatResolver.begin_turn()` 按层数扣 5 点真伤),不是回合结束;当前先标为**可选待定**,不排进下一批。
> `sfx_armor_break` 删除;`sfx_status_removed` 删除,状态移除统一复用 `sfx_heal_tick`。
> **v1.25 医疗道具双接入点**:① 消耗成功、效果结算前播 `sfx_heal_tick`;② `BattleItemUseResolver.apply()` 返回且确有治疗 / 状态移除后,按当前角色播 `voice_heal`(TTS)。两处均只在医疗道具上触发,AP 恢复类食物不触发。

| cue key | 时长 | 描述 | 触发点 / 绑定 |
|---|---|---|---|
| `sfx_bleed_apply` | 0.45s(语音长度待定) | 流血触发:角色痛呼 / 短台词 | 施加时只标记状态;角色语音改为玩家回合开始随机播(`Battlefield._play_player_status_voice()`) |
| `sfx_bleed_tick` | 0.30s(可选) | 流血持续伤害:每层在持有者回合开始扣 5 点 | `BattleCombatResolver.begin_turn()`;当前有受伤飘字 / 状态脉冲,是否保留待定 |
| `sfx_fracture_apply` | 0.55s(语音长度待定) | 骨折触发:角色痛呼 / 短台词 | 施加时只标记状态;角色语音改为玩家回合开始随机播(`Battlefield._play_player_status_voice()`) |
| `sfx_heal_tick` | 0.30~0.50s(按物品) | 医疗道具使用音效;按 7 个医疗物品拆 item-bound 变体 | `Battlefield._on_consumable_use_requested()`:消耗成功后、`BattleItemUseResolver.apply()` 前;按物品 `heal_sfx` |
| `voice_heal` | TTS 长度待定 | 医疗效果生效后的角色短语音 | `BattleItemUseResolver.apply()` 后且 `_has_medical_effect()` 为真;绑 `units[<actor art_key>].voice_heal`,具体角色文件见角色语音文档 |

> **接入状态**:两个代码接入点已落地;`sfx_heal_tick` 改为按 7 个医疗物品分别搜索 / 绑定 `heal_sfx`(B2 进行中);`voice_heal` 的角色 TTS 尚未生成。当前通过 `BattleSfx.play_optional()` 静默跳过,不会刷 missing 警告。
>
> **heal_sfx 进度(2026-10-20)**:7/7 医疗物品已落盘;急救包 / 战地医疗箱 / 创伤处理包 / 前线救援套件均为物品级 `heal_sfx`。

---

## F. 道具 / 容器(4)

> 逐项道具音效需求(消耗品、材料、容器、交易、订单)见 [`doc/item_sfx_manifest.md`](item_sfx_manifest.md)。

| cue key | 时长 | 描述 | 触发点 | 状态 |
|---|---|---|---|---|
| `sfx_item_pickup` | 0.19s | 默认拾取兜底；短咔哒,不区分物品 | 临时容器 → 背包成功转移 | ✅ 已落盘(CC0;`loganzsound · Deep Click`) |
| `sfx_item_use` | 0.30~0.60s | 非医疗消耗品使用；按物品 `use_sfx` 选择文件 | 食物 / 口粮 / 热量餐包;肾上腺素另走 `sfx_item_adrenaline` | ✅ 已落盘 3 个物品变体(见下) |
| `sfx_item_merge` | 0.36~0.39s | 二合成功；清脆“叮”，已预制 Lv1~Lv10 C 大调变体（Lv9~Lv10 备用） | 同级同种 2 → 1 高 1 级 | ✅ 已落盘 10 个变体(ffmpeg 合成；C4 261.63Hz 起) |
| `sfx_container_open` | 0.33s | 开战利品箱:塑料硬箱卡扣开启 | `BattleContainer.begin_search()` 的 `opened_now` 分支 | ✅ 已落盘(CC0;`TomaszBuga · PLASTIC_BRIEFCASE_OPENING_4`) |

> 物品丢弃已合并到头甲背包穿 / 脱的 `sfx_equip_gear`；`sfx_container_search` / `sfx_container_empty` 已删除。
>
> **物品级 `use_sfx`(2026-10-20 B1)**:
> - `consumable_compressed_ration_04` → `sfx_item_use_consumable_compressed_ration_04.mp3`(0.592s)
> - `consumable_field_meal_06` → `sfx_item_use_consumable_field_meal_06.mp3`(0.388s)
> - `consumable_calorie_meal_05` → `sfx_item_use_consumable_calorie_meal_05.mp3`(0.511s)
>
> `sfx_item_use` 仍按 1 个 cue 族计入 86;三条文件为 item-bound 变体。`conf/items/consumable.json` 已写入 `use_sfx` 字段,`Battlefield._on_consumable_use_requested()` 按字段播放。

---

## G. 战斗结算(5)—重构为 Player 语音台词槽

> **v1.20 重构**:本节 5 个 cue 不再按通用 SFX 设计,统一绑定 **Player 语音**。每个事件对应一个「台词槽」,槽内可配置 1~N 条可选台词;运行时随机选一条并避免连续重复。具体台词见角色文档,音频后续用 **TTS** 生成,当前不落盘、不接入播放代码。
>
> cue key 暂时保留原值,便于现有触发点映射;实际播放走 Player 语音槽,不走 `BattleSfx` 的 `Art/audio/sfx/` 目录。TTS 生成并经用户「收录」后,再按台词槽接入代码。
>
> 当前代码只有 `_end_battle_as_success` / `_end_battle_as_failure` 两个终局函数;`sfx_battle_victory` 与 `sfx_evac_success` 的触发边界需在接线时确认,避免同一事件叠两条语音。

| cue key | 触发点 | 语音槽 | 可选台词 | 状态 |
|---|---|---|---|---|
| `sfx_battle_victory` | 胜利结算(当前代码未单独接线) | `player_voice.battle_victory` | 建议 2~3 条,待定稿 | ⏳ 后续 TTS |
| `sfx_battle_defeat` | `_end_battle_as_failure` | `player_voice.battle_defeat` | 建议 2~3 条,待定稿 | ⏳ 后续 TTS |
| `sfx_evac_success` | `_end_battle_as_success` / 撤离点成功撤离 | `player_voice.evac_success` | 建议 2~3 条,待定稿 | ⏳ 后续 TTS |
| `sfx_evac_fail` | 强制撤离 / 时限耗尽 / 干员生命归零 | `player_voice.evac_fail` | 建议 2~3 条,待定稿 | ⏳ 后续 TTS |
| `sfx_evac_confirm` | `evacuation_confirmation.popup_centered()` | `player_voice.evac_confirm` | 建议 1~2 条,待定稿 | ⏳ 后续 TTS |

> **建议配置形态**(仅记录,未创建文件):
> ```json
> {
>   "player_voice": {
>     "battle_victory": ["line_id_1", "line_id_2"],
>     "battle_defeat": ["line_id_1"],
>     "evac_success": ["line_id_1", "line_id_2"],
>     "evac_fail": ["line_id_1"],
>     "evac_confirm": ["line_id_1"]
>   },
>   "lines": {
>     "line_id_1": {
>       "text": "台词文本",
>       "tts_voice": "benny",
>       "audio": "",
>       "status": "pending_tts"
>     }
>   }
> }
> ```

---

## H. 装备 / 背包(4)

> 逐项装备音效需求(武器、护甲、头盔、背包、配件)见 [`doc/item_sfx_manifest.md`](item_sfx_manifest.md)。

| cue key | 时长 | 描述 | 触发点 | 状态 |
|---|---|---|---|---|
| `sfx_equip_weapon` | 0.42s | 武器装备;短金属 / 卡扣 | 武器槽装备成功 | ✅ 已落盘(CC0;`BaggoNotes · Rifle_Equip1`) |
| `sfx_equip_gear` | 0.60s | 头甲背包穿 / 脱 / 物品丢弃共用 | 护甲、头盔、背包、丢弃 | ✅ 已落盘(CC0;`brandondelehoy · Jacket/Cloth Rustle 7`) |
| `sfx_attachment_install` | 0.35s | 所有武器配件安装共用 | `weapon_attachment_slot` 安装 | ✅ 已落盘(CC-BY 4.0;`smill.and.welson · G3 Bolt Slap`) |
| `sfx_attachment_remove` | 0.71s | 所有武器配件拆卸共用 | 卸下配件 | ✅ 已落盘(CC-BY 4.0;`smill.and.welson · Stoner 63 Mag Out`) |

> `sfx_item_discard`、`sfx_unequip`、`sfx_equip_armor` 已合并为 `sfx_equip_gear`。拖拽开始 / 放下 / 整理不再单独做音效。
>
> **接线(v1.28)**:`WarehouseScreen` 与 `BattleLoadoutPanel` 在装备 / 卸下 / 丢弃成功分支播 `equip_gear` 或 `equip_weapon`;绑定在 `conf/battle/sfx_bindings.json` 的 `default.*`。

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

## J. 商店 / 订单(4)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_shop_open` | 0.40s | 进入商店:推门铃 + 商贩招呼 | `TradingPost` `_ready` |
| `sfx_shop_buy` | 0.30s | 购买成功:硬币落袋 + 物品落手 | `trading_post._buy_item` 成功 |
| `sfx_quest_accept` | 居民 TTS | 接取订单：居民角色短语音 | 接取居民援助 |
| `sfx_quest_turn_in` | 居民 TTS | 交付订单：居民角色短语音 | 完成援助交付 |

> `sfx_shop_insufficient` 已删除，信用点不足复用 `sfx_ui_error`。`sfx_quest_accept` / `sfx_quest_turn_in` 不再是通用 SFX，后续按居民角色 TTS 处理。

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
> 现状:D 类只有 `sfx_move_step_benny`(v1.9 更名)一个,仅描述贝妮;5 类敌人移动没有任何脚步 cue——本章补齐;`move_blocked` 已于 v1.21 改为通用 cue 并复用 `sfx_ui_error`,不再按角色绑定。
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

## N. 角色语音 / TTS 台词(v1.20 定案)

> 目的:把「角色台词」和「动作 / 环境 SFX」分开。角色说人话的 cue 不再用普通 SFX 搜索或 AI 音效生成替代。

| 范围 | 处理方式 | 素材来源 | 当前状态 |
|---|---|---|---|
| Benny 全部角色语音(选中 / 受击 / 倒地 / 流血 / 骨折 / 医疗 / 遮罩 / 结算) | 独立角色文档维护 | **禁止** `game-sfx-search` | 见 [`doc/benny_voice_lines.md`](benny_voice_lines.md) |
| `sfx_select_player` | 按 player 绑定的短语音 | **禁止** `game-sfx-search` | ⏳ 后续 TTS |
| `sfx_bleed_apply` / `sfx_fracture_apply` | 按受害者 `art_key` 绑定的短痛呼 / TTS | **禁止** `game-sfx-search` | ⏳ 台词待定稿 |
| `sfx_bleed_tick` | 可选,触发在角色回合开始 | 待定 | ⏳ 可选 |
| `voice_heal` | 医疗效果生效后按当前角色播 TTS | **禁止** `game-sfx-search` | ⏳ TTS 待生成 |
| 人形敌人 A.5 `battle_cutin_in` | TTS 台词 | **禁止** `game-sfx-search` 搜英文人声 | ⏳ 台词待定稿 |
| `pyroxene_hound` A.5 | 兽类非人声 | 可用 `game-sfx-search` 搜 SFX | ⏳ 待处理 |
| `pyroxene_sentry` A.5 | 机械 / 电子音 | 可用 `game-sfx-search` 搜 SFX | ⏳ 待处理 |
| 居民订单接取 / 交付 | 居民角色 TTS | **禁止** `game-sfx-search` | ⏳ TTS 待生成 |
| A.5 `battle_cutin_out` | **已取消**,不生成、不绑定 | — | ✅ 接入点已移除 |
| G 战斗结算 5 个事件 | Player 语音槽,每个事件 1~N 条可选台词 | 后续 TTS | ⏳ 待 TTS |

**规则**

- 所有 player 与人形敌人(`raider_infantry` / `raider_scout` / `raider_bulwark`)的角色语音只用人物配音 / TTS,不走 `game-sfx-search`,也不走 `batch_text_to_music` 之类的音效生成路线。Benny 的具体台词见独立角色文档。
- 流血 / 骨折的施加语音按受害者绑定 TTS;`sfx_bleed_tick` 的实际触发点在回合开始,当前仅标记为可选。
- 状态移除不再单独做 cue,统一复用 `sfx_heal_tick`;`sfx_armor_break` 已取消。
- 居民订单接取 / 交付不再做通用 SFX,后续按居民角色 TTS 处理。
- 医疗道具使用音效 `sfx_heal_tick` 与生效后角色语音 `voice_heal` 是两个独立接入点,不要合并成一个 cue。
- 战斗遮罩退场 `battle_cutin_out` 已取消;不要再补 cue、候选或绑定。
- hound / sentry 不套人声台词;hound 用兽类叫声,sentry 用机械 / 电子音。
- 台词层与底音层分开;如果遮罩需要 whoosh / 金属冲击,另建 SFX cue,不要和角色台词混在一起。
- 用户说「收录」后,再按选定台词 / 音频做代码接入;按当前约定不跑验证,并清理 `_review/` 临时资源。
- A.4 已落盘的人形敌人 `hit` / `unit_down` 人声素材暂不重做;若后续要改成完整台词,按 TTS 规则处理,不再网搜英文人声。

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
> - **移动 `move_step` / `move_hover`**:按角色自身绑——`units[<art_key>].move_step`(贝妮 + 5 类敌人)、`units[benny].move_hover`。
> - **移动被阻挡 `move_blocked`(v1.21)**:通用 cue,走 `default.move_blocked → sfx_ui_error`,复用 C 类错误提示音,不按角色拆。
> - **选中玩家 `select_player`(v1.21)**:按当前 player 绑 `units[<player art_key>].select_player`;不同 player 后续用不同 TTS 语音。
> - **战斗遮罩入场 `battle_cutin_in`(v1.21)**:按**发起 attack 的角色**绑——`units[<attacker art_key>].battle_cutin_in`(`BattleCutIn._sfx_context` 已带 attacker);`default.battle_cutin_in` 仅作兜底。**退场 `battle_cutin_out` 已取消**,不再绑定。
> - **受击 `hit` / `unit_down`(v1.16 / v1.17)**:命中与受击**合并为每角色一个**——`units[<victim art_key>].hit`(absorbed / damage 都走它,不分护甲/入肉、不分打击/语音两层);**`unit_down` 亦按角色**(`units[<art_key>].unit_down`,真正死亡时播,含 debuff 致死);benny 受击留空走 **TTS**。
> - **`miss`**:全局 `default.miss` 兜底(目前 `sfx_bullet_whiz` 兼用);**只有 `raider_bulwark` 一个角色有 `units[*].miss` 特殊覆盖**(`sfx_bulwark_shield_miss`,格挡反弹音,体现护盾机制)。
> - **解析路径**(`Script/battle/battle_sfx.gd::resolve_binding`):**`weapons[weapon_id].<cue>` → `units[attacker_or_victim.cutin_art_key].<cue>` → `default.<cue>`**。命中侧(A.3 / A.4)的 context 用 `victim` 代替 `attacker`。
> - cue key 全部对应表中 cue key,加 `.mp3` 后缀落盘。

---

## 2. 批次工作流

### 批次 1 — MVP 战斗体感(13 个)

| 类别 | 数量 | cue |
|---|---:|---|
| A 战斗核心 | 8 | A.4 贝妮 hit / down 2 个 + A.5 战斗遮罩入场 6 个 |
| G 战斗结算 | 5 | 全部 |

### 批次 2 — UI 与流程(v1.27 历史口径)

> 下表保留 v1.27 排期;实际执行状态以 `v1.28 当前剩余与 B2` 为准。

| 类别 | 数量 | cue |
|---|---:|---|
| C UI 通用 | 7 | 全部 |
| D 战场交互 | 4 | `move_blocked` 复用 `ui_error`;`select_player` 等 TTS;选中敌人复用 `ui_open` |
| E 状态 / 数值 | 5 | `bleed_apply` / `fracture_apply` / `voice_heal` 走 TTS;`heal_tick` 做医疗道具 SFX;`bleed_tick` 可选待定 |
| F 道具 / 容器 | 4 | 拾取 / 使用 / 二合 / 开箱 |
| H 装备 / 背包 | 4 | 武器 / 头甲背包共用 / 配件装 / 配件拆 |
| I 存档 | 5 | 全部 |
| J 商店 / 订单 | 4 | 商店 2 个 + 居民订单 TTS 2 个 |
| L 环境音(可放批次 3 也可提前) | 3 | — |

### 批次 3 — 氛围(12 个)

| 类别 | 数量 |
|---|---:|
| K BGM | 9 |
| L 环境音(若批次 2 没做) | 3 |

### v1.28 当前剩余与 B2

> 以 86 个有效 cue 为口径;TTS、BGM、环境音不计入 B2。

| 批次 / 类别 | 内容 | 数量 |
|---|---|---:|
| **B2 已完成** | `sfx_attachment_install` / `sfx_attachment_remove` / `sfx_item_merge` / `sfx_container_open` + 7 个医疗 `heal_sfx` + `sfx_item_adrenaline` | **12** |
| **B2 剩余** | 无 | **0** |
| B2 可选增补 | `sfx_item_adrenaline` | 1 |
| B3 存档 / 商店 | `sfx_save_success` / `sfx_save_fail` / `sfx_load_success` / `sfx_load_fail` / `sfx_delete_confirm` / `sfx_shop_open` / `sfx_shop_buy` | 7 |
| B4 战斗遮罩非人声 | `sfx_battle_cutin_in_pyroxene_hound` / `sfx_battle_cutin_in_pyroxene_sentry` | 2 |
| B5 氛围 | K BGM 9 + L 环境音 3 | 12 |
| 可选增补 | `sfx_bleed_tick` / 5 个专属拾取变体 | 6 |

> TTS 并行项(不计入 SFX 批次):Benny / 人形敌人 `battle_cutin_in`、`sfx_select_player`、`sfx_bleed_apply` / `sfx_fracture_apply`、`voice_heal`、G 战斗结算 5 个、居民订单接取 / 交付 2 个。

**B2 逐项清单(建议下一批)**

| cue | 目标时长 | 用途 | 生产要点 |
|---|---:|---|---|
| `sfx_attachment_install` | 0.40s | 所有武器配件安装共用 | 金属卡扣 + 短滑动;不要枪声 |
| `sfx_attachment_remove` | 0.35s | 所有武器配件拆卸共用 | 卡扣释放 + 短金属滑动 |
| `sfx_item_merge` | 0.36~0.39s | 二合成功 | 已预制 Lv1~Lv10 C 大调变体(Lv9~Lv10 备用),按产出等级直接选文件 |
| `sfx_container_open` | 0.55s | 战利品箱开启 | 箱盖吱呀 + 弹簧 / 卡扣;不做 search / empty 独立音 |
| `sfx_heal_tick` | 0.30~0.50s | 7 个医疗物品使用瞬间 | 按物品分别搜 `heal_sfx`;轻恢复 / 光粒,不要人声,`voice_heal` 另走 TTS |
| `sfx_item_adrenaline` | 0.30s | 肾上腺素使用(可选) | 短注射 / 气流;与医疗 `heal_tick` 分开 |

> 医疗 `heal_sfx` 7 项:`consumable_dried_medicine_02` / `consumable_debridement_dressing_03` / `consumable_sterile_bandage_04` / `consumable_medkit_01` / `consumable_field_medical_case_06` / `consumable_trauma_kit_07` / `consumable_frontline_rescue_08`。每条按物品单独搜索,不复用同一文件。

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
- **B1 接线(2026-10-20)**:`item_pickup` 接在临时容器→背包成功转移;`equip_gear` 接头甲背包穿 / 脱 / 丢弃;`equip_weapon` 接武器装备;三个食物/AP 物品按 `use_sfx` 字段播放。
- **未完成**:第 3 步三总线布局(当前 `audio_bus` 写 `SFX` 会回落 `Master`)、第 4 步音量配置与 UI。
- **验证**:叠音规则测过 4 个用例(对话框 OK 只出 confirm / Cancel 只出 cancel / 对话框内自定义按钮照常 click / 菜单项 click 后 popup_hide 不叠 close,无点击时 close 延一帧照出);静默规则测过 7 个用例(普通按钮 click+hover / 三类格子全静音 / 收起按钮只出 close / Viewport 下的 Popup 不绑定 / Control 下的 PopupPanel 正常 open+close);系统驱动作用域测过 6 个场景(玩家操作有声 / 作用域内全静音含 `report_status` / 结束后恢复 / 嵌套计数 / owner 释放自动归零 / 禁用按钮 hover 静音);`Godot --headless --path . --import` 无脚本错误;MainMenu / Warehouse / TradingPost / CommandCenter / Battlefield 五个场景 headless 跑 60 帧无报错;单独校验过 Button / PopupPanel / ConfirmationDialog / `attach_panel` 的信号连接数与 7 个 cue 的 binding 解析。

---

## 5. 交付清单(可勾选)

- [x] **批次 1 / A.1**:turn_in + turn_out(2 个)✅ 横幅专用
- [x] **批次 2 / C**:UI 通用 7 个 ✅(click / hover / open / close / confirm / cancel / error)
- [x] **C 类接线**:autoload `UiSfx` + `conf/audio/ui_sfx.json`,全场景按钮/悬停/面板开关/对话框/失败文案已挂钩
- [x] **D 移动悬停接线**:`sfx_move_hover_benny`(CC0)落盘 + `units[benny].move_hover` 绑定 + `Battlefield` hover 接线 ✅
- [x] **D 移动阻挡复用**:`sfx_move_blocked_benny` → `sfx_move_blocked`,绑定 `default.move_blocked → sfx_ui_error`,不新增音频;已接 `Battlefield` 移动受阻分支 ✅
- [x] 批次 1:A.2 开火 9 个 ✅(defender9 / hare_hopper / dawn_pulse / raider_infantry / raider_scout / raider_bulwark / hound_bite / sentry_laser / attack_fire_default)
- [x] 批次 1:A.3 未命中 / 特殊 2 个 ✅(bullet_whiz ← subsonic flyby;bulwark 特殊 miss ← deepcrash)
- [ ] 批次 1:A.4 命中 / 倒下(10/12 已落盘;benny 的 hit/down 改为人物配音 / TTS,禁止 `game-sfx-search`)
- [ ] 批次 1:A.5 战斗遮罩入场(贝妮 / 人形敌人走 TTS;hound / sentry 走兽类 / 机械 SFX;退场 cue 已取消)
- [ ] 批次 1:G 战斗结算 5 个事件重构为 Player 可选语音台词槽(TTS 后续生成)
- [x] **B1 道具基础 SFX**:`sfx_item_pickup` / `sfx_equip_gear` / `sfx_equip_weapon` + 3 个食物/AP 物品 `use_sfx` ✅
- [x] **B2 通用项**:`sfx_attachment_install` / `sfx_attachment_remove` / `sfx_item_merge` ✅
- [x] **B2 医疗 3/7**:干燥药包 / 清创敷料 / 无菌绷带组 `heal_sfx` ✅
- [x] **B2 医疗 4/7**:前线救援套件 `ECG sim ×6 @1.5×` ✅
- [x] **B2 医疗 7/7**:急救包 / 战地医疗箱 / 创伤处理包 `heal_sfx` ✅
- [x] **B2 可选增补**:`sfx_item_adrenaline` ✅
- [x] **B2 剩余**:`sfx_container_open` ✅
- [ ] **B3 存档 / 商店**:7 个 SFX
- [ ] **B4 战斗遮罩非人声**:hound / sentry 入场 2 个 SFX
- [ ] **B5 氛围**:K BGM 9 + L 环境音 3
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

### 6.13 A.3 / A.4 收录 12 件(2026-10-10)

命中/倒地改为按角色后的第一批落盘(hit×5 + unit_down×5 + whiz + shield);全部走既定规格(48kHz / 单声道 / MP3 96kbps,峰值 ≈ -1dBFS);benny 的 hit / down 留空(女声走 TTS 路线待做)。

| cue | 配方 | 成品时长 | 峰值 / RMS | 来源 |
|---|---|---:|---:|---|
| `sfx_hit_raider_infantry` | `Oof` 原长 | 0.273s | -1.1 / -16.1 | Freesound unfa #719053(CC0) |
| `sfx_hit_raider_scout` | `Enemy hurt 1` 原长 | 1.425s | -0.9 / -20.7 | Freesound K27K_Mike #853659(CC0) |
| `sfx_hit_raider_bulwark` | `Head Impact Grunt` 取 **0.6s→尾**(切口 30ms 淡入) | 1.141s | -0.8 / -16.7 | Freesound DeqstersLab #848188(CC-BY) |
| `sfx_hit_pyroxene_hound` | `Bark and Growl` 原长 | 0.737s | -0.9 / -17.6 | Freesound TheKingOfGeeks360 #868312(CC0) |
| `sfx_hit_pyroxene_sentry` | `Explosion (Pixel SFX)` 原长 | 0.387s | -1.0 / -14.1 | Freesound heyheytheree #871887(CC-BY) |
| `sfx_unit_down_raider_infantry` | `Hurt light 1` 原长 | 0.427s | -0.9 / -14.7 | Freesound kreha #840222(CC0) |
| `sfx_unit_down_raider_scout` | `Character Death` 原长 | 1.129s | -1.0 / -15.8 | Freesound randbsoundbites #796567(CC0) |
| `sfx_unit_down_raider_bulwark` | `Damage Hurt ooh!` 原长 | 1.059s | -0.9 / -14.3 | Freesound gunpowderstudios #863709(CC0) |
| `sfx_unit_down_pyroxene_hound` | `Small Dog Cry` 原长 | 0.824s | -1.0 / -18.9 | Freesound haulaway #735365(CC0) |
| `sfx_unit_down_pyroxene_sentry` | `EXPLOSION_SFX1` 取前 1.2s | 1.200s | -1.0 / -19.0 | Freesound AgusIvan #868375(CC0) |
| `sfx_bullet_whiz` | `Fly-by whiz (subsonic)` 原长 | 1.334s | -1.2 / -25.4 | Freesound modusmogulus #789222(CC0) |
| `sfx_bulwark_shield_miss` | `deepcrash 3 long` 原长 | 1.073s | -0.9 / -18.7 | Freesound Logicogonist #811250(CC0) |

- 全部 `.import` 与缓存已生成;**代码接线早已就位**(命中走 `battle_cut_in` victim 路由、倒地挂 `Unit.defeated` 含 debuff 致死、whiz/shield 走 miss 分支)→ 落盘即响。
- 授权:10 CC0 + 2 CC-BY(bulwark hit / sentry hit,需署名)。
- 候选与中间产物已清(`_review/` 清空)。

---

### 6.14 B1 道具基础 SFX 收录(2026-10-20)

用户听选 5 条候选 + 上一轮 `sfx_equip_weapon`,本轮共落盘 6 个 mp3。全部转 48kHz / 单声道 / MP3 96kbps,尾部 30ms 淡出;旧 B1 候选已从 `_review/` 清理。

| cue / 物品 | 正式文件 | 来源 | 时长 | 峰值 | 授权 |
|---|---|---|---:|---:|---|
| `sfx_item_pickup` | `sfx_item_pickup.mp3` | Freesound loganzsound #874468 `Deep Click` | 0.190s | -1.4dBFS | CC0 |
| `sfx_equip_gear` | `sfx_equip_gear.mp3` | Freesound brandondelehoy #494793 `Jacket/Cloth Rustle 7` | 0.604s | -1.1dBFS | CC0 |
| `sfx_equip_weapon` | `sfx_equip_weapon.mp3` | Freesound BaggoNotes #784753 `Rifle_Equip1` | 0.416s | -0.9dBFS | CC0 |
| `consumable_compressed_ration_04` | `sfx_item_use_consumable_compressed_ration_04.mp3` | Freesound ImmergoMedia #689661 `PlasticScrunch05` | 0.592s | -1.6dBFS | CC0 |
| `consumable_field_meal_06` | `sfx_item_use_consumable_field_meal_06.mp3` | Freesound fleurescence #573120 `opening a cap` | 0.388s | -1.2dBFS | CC0 |
| `consumable_calorie_meal_05` | `sfx_item_use_consumable_calorie_meal_05.mp3` | Sonilo `Snack Wrapper Tear Open` | 0.511s | -1.2dBFS | Sonilo Library License |

- **绑定**:`default.item_pickup` / `default.equip_gear` / `default.equip_weapon`;三个 `item_use_consumable_*` 绑定。
- **物品字段**:`conf/items/consumable.json` 三个食物/AP 物品写入 `use_sfx`;`Battlefield._on_consumable_use_requested()` 非医疗分支按字段播放。
- **接线**:`BattleLoadoutPanel._try_transfer()` 在临时容器→背包成功时播 `item_pickup`;装备/卸下头甲背包播 `equip_gear`;`Battlefield._on_discard_requested()` 丢弃成功播 `equip_gear`;`WarehouseScreen` 装备/卸下同样播 `equip_gear` / `equip_weapon`。
- **注意**:`sfx_equip_gear` 成品 0.604s,超出 0.25~0.45s 目标,按用户选中的候选原长保留。Sonilo 免费账号为 10 MP3/月、需署名、仅自有社交频道;游戏/商业使用需付费计划,发布前确认许可。
- **文档**:`doc/item_sfx_manifest.md` 同步更新为物品级 `use_sfx`;未执行 Godot import 命令。

---

### 6.15 B2 通用项收录(2026-10-20)

| cue | 正式文件 | 来源 / 配方 | 时长 | 峰值 | 授权 |
|---|---|---|---:|---:|---|
| `sfx_attachment_install` | `sfx_attachment_install.mp3` | Freesound smill.and.welson #858721 `G3 Bolt Slap (2)` | 0.348s | -0.8dBFS | CC-BY 4.0 |
| `sfx_attachment_remove` | `sfx_attachment_remove.mp3` | Freesound smill.and.welson #858785 `Stoner 63 Mag Out` | 0.710s | -0.7dBFS | CC-BY 4.0 |
| `sfx_item_merge_lv1~lv10` | `sfx_item_merge_lv1~lv10.mp3` | 以 `sfx_item_merge.mp3`(C4 脆叮)为 Lv1,按 C 大调半音表预制 10 个变体(Lv9~Lv10 备用) | 0.358~0.395s | -1.0~-1.6dBFS | 自制,无第三方授权 |

- **二合音阶**:当前成品基础音为 **C4(261.63Hz)**;Lv1~Lv8 按 `MIDI = 60 + [0,2,4,5,7,9,11,12][level-1]` 移调,实际音区为 **C4 / D4 / E4 / F4 / G4 / A4 / B4 / C5**,与原口径一致。

| Lv | 音名 | 文件 |
|---:|---|---|
| 1 | C4 | `sfx_item_merge_lv1.mp3` |
| 2 | D4 | `sfx_item_merge_lv2.mp3` |
| 3 | E4 | `sfx_item_merge_lv3.mp3` |
| 4 | F4 | `sfx_item_merge_lv4.mp3` |
| 5 | G4 | `sfx_item_merge_lv5.mp3` |
| 6 | A4 | `sfx_item_merge_lv6.mp3` |
| 7 | B4 | `sfx_item_merge_lv7.mp3` |
| 8 | C5 | `sfx_item_merge_lv8.mp3` |
| 9 | D5 | `sfx_item_merge_lv9.mp3` |
| 10 | E5 | `sfx_item_merge_lv10.mp3` |

- **接线**:`WarehouseScreen` 与 `BattleLoadoutPanel` 的配件安装 / 拆卸成功分支播 `attachment_install` / `attachment_remove`;绑定在 `conf/battle/sfx_bindings.json` 的 `default.*`。`sfx_item_merge_lv1~lv10` 绑定已就位,但仓库代码目前没有二合执行入口,尚无触发点。
- **CC-BY 4.0**:允许商用、修改、再分发,但必须署名作者、附许可链接并注明修改;裁剪 / 降噪 / 转码不改变署名义务,不能靠后期处理规避。两条配件音正式发布前需写入 credits。
- **B2 剩余(当时)**:`sfx_container_open` + 7 个医疗物品 `heal_sfx` 候选;其中 3 个已在 §6.16 收录。

---

### 6.16 B2 医疗 heal_sfx 收录 3/7(2026-10-20)

| 物品 | 正式文件 | 来源 | 时长 | 峰值 | 授权 |
|---|---|---|---:|---:|---|
| `consumable_dried_medicine_02` | `sfx_heal_tick_consumable_dried_medicine_02.mp3` | Freesound AvillivA #859670 `Pills_1` | 0.543s | -0.8dBFS | CC0 |
| `consumable_debridement_dressing_03` | `sfx_heal_tick_consumable_debridement_dressing_03.mp3` | Freesound SecureSubset #800275 `Tape Bandages Rip` | 0.813s | -1.4dBFS | CC0 |
| `consumable_sterile_bandage_04` | `sfx_heal_tick_consumable_sterile_bandage_04.mp3` | Freesound Frostnox #796014 `Bandage Wrap Heal 1` ×2(120ms 间隔) | 1.164s | -0.8dBFS | CC-BY 4.0 |

- **绑定**:`default.heal_tick_consumable_dried_medicine_02` / `debridement_dressing_03` / `sterile_bandage_04`;三个物品写入 `heal_sfx` 字段。
- **接线**:`Battlefield._on_consumable_use_requested()` 医疗分支优先读 `heal_sfx`,缺失时回落 `heal_tick`。
- **剩余(当时)**:急救包 / 战地医疗箱 / 创伤处理包 / 前线救援套件 4 个 `heal_sfx` 待搜;前线救援已在 §6.17 收录。

---

### 6.17 B2 前线救援套件 heal_sfx 收录(2026-10-20)

| 物品 | 正式文件 | 来源 / 配方 | 时长 | 峰值 | 授权 |
|---|---|---|---:|---:|---|
| `consumable_frontline_rescue_08` | `sfx_heal_tick_consumable_frontline_rescue_08.mp3` | Freesound univ_lyon3 #201849 `ECG sim` ×6 @1.5× | 2.383s | -1.2dBFS | CC0 |

- **配方**:`cand_b2_freesound_ecg_sim.mp3` 连续 6 次 → `atempo=1.5` 加速 → 48kHz 单声道 MP3 96kbps。
- **绑定**:`default.heal_tick_consumable_frontline_rescue_08`;物品写入 `heal_sfx`。
- **剩余(当时)**:急救包 / 战地医疗箱 / 创伤处理包 3 个医疗 `heal_sfx`;已在 §6.18 完成。

---

### 6.18 B2 医疗 heal_sfx 收尾 + 肾上腺素(2026-10-20)

| cue / 物品 | 正式文件 | 配方 | 时长 | 峰值 | 授权 |
|---|---|---|---:|---:|---|
| `consumable_medkit_01` | `sfx_heal_tick_consumable_medkit_01.mp3` | `Box Latch` 0.45s + Water Squirt 后 50% ×3 @0.75× 降 4 半音 | 2.048s | -1.5dBFS | CC0 |
| `consumable_field_medical_case_06` | `sfx_heal_tick_consumable_field_medical_case_06.mp3` | `Box Latch` 0.45s + 绷带撕开 0.60s | 1.130s | -1.5dBFS | CC0 |
| `consumable_trauma_kit_07` | `sfx_heal_tick_consumable_trauma_kit_07.mp3` | `Zipper Zipping` 0.50s + 同款注射 | 2.098s | -0.9dBFS | CC0 / CC-BY 4.0 |
| `sfx_item_adrenaline` | `sfx_item_adrenaline.mp3` | Water Squirt 后 50% ×3 @0.75× 降 4 半音 | 1.548s | -1.9dBFS | CC0 |

- **注射配方**:Water Squirt 后 50%(0.259s)→ 0.75× 速度 → 降 4 半音 → ×3、260ms 间隔。
- **绑定**:三个医疗物品写入 `heal_sfx`;肾上腺素写入 `use_sfx = item_adrenaline`,并绑定 `default.item_adrenaline`。
- **B2 状态(当时)**:医疗 `heal_sfx` 7/7 + 肾上腺素完成;`sfx_container_open` 已在 §6.19 收录。

---

### 6.19 B2 收尾:`sfx_container_open`(2026-10-20)

| cue | 正式文件 | 来源 | 时长 | 峰值 | 授权 |
|---|---|---|---:|---:|---|
| `sfx_container_open` | `sfx_container_open.mp3` | Freesound TomaszBuga #728897 `PLASTIC_BRIEFCASE_OPENING_4` | 0.325s | -1.2dBFS | CC0 |

- **配方**:96kHz/24bit 原始录音 → 48kHz 单声道 MP3 96kbps,尾部 30ms 淡出。
- **绑定**:`default.container_open → sfx_container_open`。
- **接线**:`Battlefield._search_container()` 在 `BattleContainer.begin_search()` 返回 `opened_now = true` 时播放。
- **B2 状态**:**完成**;下一批 B3 存档 / 商店 7 个 SFX。

---

> **下一步(v1.34)**:B2 已完成。下一批 **B3 存档 / 商店**:`sfx_save_success` / `sfx_save_fail` / `sfx_load_success` / `sfx_load_fail` / `sfx_delete_confirm` / `sfx_shop_open` / `sfx_shop_buy`。TTS、BGM、环境音不混入本批。
