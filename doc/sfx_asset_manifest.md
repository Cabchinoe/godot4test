# 音效资产清单(SFX Asset Manifest)

> 版本 v1.3(2026-09-29)· 配套 `Script/battle/battle_sfx.gd` + `conf/battle/sfx_bindings.json`
> 全表 cue 命名严格沿用 `BattleSfx.play(cue, context)` 现有约定,后续接音频时无需改 GDScript。
> v1.1 修订:A.1 已落盘(2 个 cue,源 mp3 → ffmpeg 切 wav);补 §6 实测经验(AI 音频模型对纯工业音效的输出特点 + 切片策略)。
> v1.2 修订:**B 章节移除独立 cue**,回合过渡复用 A.1 的 `sfx_cutin_in` / `sfx_cutin_out`(横幅与遮罩共用一对反向 cue,语义一致且避免冗余);撤销已生成的 `sfx_turn_player/enemy/evacuation`;总 cue 数 92 → **89**;批次 1 从 26 → **23**;BattleSfx 接入真实播放(AudioStreamPlayer 池 + host 注入)。
> v1.3 修订:**澄清语义分离**——A.1 的 `cutin_in/out` **仅服务回合横幅(`TurnTransition`)**,**不再**被战斗遮罩(`BattleCutIn`)调用;改名为 `turn_in/out`(cue key + 文件名同步);战斗遮罩另起 `battle_cutin_in/out` 两个 cue,目前留空待后续生成;总 cue 数 89 → **91**;批次 1 从 23 → **25**。

---

## 0. 总览

| 项 | 值 |
|---|---|
| 总 cue 数 | **91** |
| 已落盘 | **2**(A.1 turn_in/out) |
| 分类数 | **11**(A、C~L) |
| 命名风格 | `sfx_<scene>_<verb>` / `bgm_<scene>` / `amb_<scene>` |
| 采样规格(目标) | SFX 48kHz/16bit 单声道;BGM 48kHz/24bit 立体声;时长 ≤2.5s(SFX)/60~120s(BGM)/10~30s(loop 环境音) |
| **实际落盘格式** | **MP3 (libmp3lame) 96kbps 单声道**(本机 ffmpeg 8.1 编了 `libmp3lame` / `libopus` 但**没编 `libvorbis`**;MP3 兼容性最广、QuickTime/Win Media/几乎所有播放器直接放;Godot 4 原生支持 `.mp3` import) |
| 文件位置 | `res://Art/audio/sfx/`、`res://Art/audio/bgm/`、`res://Art/audio/amb/` |
| 绑定方式 | `conf/battle/sfx_bindings.json`(`weapons` / `units` / `default`) |
| 优先级 | 批次 1(23 个)→ 批次 2(51 个)→ 批次 3(12 个) |

---

## A. 战斗核心(18)

> 全部走 `BattleSfx.play(cue, context)`,在 `Script/battle/battle_cut_in.gd` 的滑入/开火帧/命中帧/未命中帧/击倒帧/滑出 6 处直接喂入。

### A.1 回合横幅过渡

> 仅服务 `TurnTransition`(回合横幅:"玩家行动" / "敌方行动" 横幅入场)。
> 战斗遮罩(`BattleCutIn`)另起一组 cue key,见 A.5。

| cue key | 时长 | 文件 | 切片位置 | 描述 | 触发点 | 状态 |
|---|---|---|---|---|---|---|
| `sfx_turn_in` | 2.70s | `Art/audio/sfx/sfx_turn_in.mp3` | `cutin_in_v2.mp3` @ 5.20s,取 2.70s | 玩家回合横幅:青蓝斜切 + 金属 scrape + 鼓点冲击 + 衰减尾 | `TurnTransition.play_player()` | ✅ 已落盘 |
| `sfx_turn_out` | 2.00s | `Art/audio/sfx/sfx_turn_out.mp3` | `cutin_out_raw.mp3` @ 15.00s,取 2.00s | 敌方回合横幅:橙红横条 + 锐利金属冲击 + 衰减尾 | `TurnTransition.play_enemy()` | ✅ 已落盘 |

> **A.1 实际值大于清单目标**:目标时长是 0.25~0.30s,但首版听感反馈后调整到 2.0~2.7s(承载完整"冲击 + 衰减"曲线)。如果觉得太长,后续可再切短版覆盖。

### A.5 战斗遮罩过渡(待生成)

> 服务 `BattleCutIn`(战斗入场遮罩:左攻右守立绘 + 数值飘字)。
> 与 A.1 横幅语义不同:**横幅是轻提示**,**战斗遮罩是重头戏**,需要独立的、更有质感的入退场音效。
> 当前 cue key 已占位,binding 值为空,等后续 AI 生成 + 切片后填入。

| cue key | 时长 | 文件 | 描述 | 触发点 | 状态 |
|---|---|---|---|---|---|
| `sfx_battle_cutin_in` | TBD | TBD | 战斗遮罩入场:立绘左攻右守滑入,带更厚重的金属/能量开门声 | `BattleCutIn.begin_session()` | ⏳ 待生成 |
| `sfx_battle_cutin_out` | TBD | TBD | 战斗遮罩退场:反向滑出,衰减余震 | `BattleCutIn.end_session()` | ⏳ 待生成 |

### A.2 开火(按 weapon_id 路由)

> 走 `weapons` 绑定;单位 → 武器 → fire 优先取武器级 cue,缺失回落到 `units.fire`,再缺失回落 `default.attack_fire`。

| cue key | 时长 | 武器 ID | 武器名 | 描述 |
|---|---|---|---|---|
| `sfx_weapon_defender9_fire` | 0.55s | `weapon_benny_defender_9` | 防卫者-9(SMG Lv1) | 中低音 SMG,中等密度,短回响 |
| `sfx_weapon_hare_hopper_fire` | 0.45s | `weapon_benny_hare_hopper` | 野兔跳跃者(SMG Lv2) | 同 SMG 但更紧、更亮,导轨金属感 |
| `sfx_weapon_dawn_pulse_fire` | 0.40s | `weapon_benny_dawn_pulse` | 黎明初霁(SMG Lv3) | 高频脉冲冲锋,带辉石能量"滋滋"尾音 |
| `sfx_weapon_rifle_fire` | 0.65s | `weapon_enemy_rifle` | 掠夺者步枪通用 | 单发步枪,后坐强,弹壳落音 |
| `sfx_weapon_scout_rifle_fire` | 0.50s | `weapon_enemy_scout_rifle` | 斥候步枪 | 短管步枪,更尖的爆发 |
| `sfx_weapon_bulwark_rifle_fire` | 0.80s | `weapon_enemy_bulwark_gun` | 护盾兵重枪 | 低沉厚实,带盾牌共鸣 |
| `sfx_weapon_hound_bite` | 0.45s | `weapon_pyroxene_hound` | 辉石猎犬撕咬 | 肉食撕咬 + 爪击 |
| `sfx_weapon_sentry_laser` | 0.70s | `weapon_pyroxene_sentry` | 哨戒机激光 | 高能激光充能 + 释放,带电子嗡鸣 |
| `sfx_attack_fire_default` | 0.55s | (兜底) | 通用开火 | 同防卫者-9 的中性版本,做 fallback |

### A.3 命中 / 未命中 / 受击

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_hit_armor` | 0.40s | 弹头击穿护甲短金属撞击 + 火花迸射声 | `hit_armor`(吸收) |
| `sfx_hit_flesh` | 0.35s | 入肉钝击 + 湿闷尾音 | `hit_flesh`(真实伤害) |
| `sfx_bullet_whiz` | 0.30s | 子弹擦肩而过的啸叫(同时复用作 miss 兜底) | `miss` |

### A.4 单位受击 / 倒下

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_player_hurt` | 0.50s | 玩家受击:短促闷响 + 呼吸/失神(主角额外红闪对应) | `apply_attack` 后贝妮被打中 |
| `sfx_enemy_hurt` | 0.45s | 敌人受击:肉搏挤压 + 痛叫(泛用,可分两层:punch/grunt) | 敌人被打中 |
| `sfx_unit_down` | 1.20s | 倒地:沉重跌落 + 装备/护甲金属碰撞 + 后续轻尾音 | `unit_down`(击倒帧) |

---

## B. 回合过渡(章节已合并到 A.1 / A.5)

> v1.3 起,本章节不再独立。回合过渡 = A.1(横幅专用) + A.5(战斗遮罩专用,待生成)。
> 详见 A.1 与 A.5。

---

## C. UI 通用(7)

| cue key | 时长 | 描述 |
|---|---|---|
| `sfx_ui_click` | 0.08s | 通用点击:轻塑料感,短促"嗒" |
| `sfx_ui_hover` | 0.06s | 通用悬停:更短的轻"叮" |
| `sfx_ui_open` | 0.18s | 面板打开:布幕拉起 + 软皮绒低音 |
| `sfx_ui_close` | 0.15s | 面板关闭:反向上推合 |
| `sfx_ui_confirm` | 0.22s | 确认/同意:二段"叮→咚"清脆 |
| `sfx_ui_cancel` | 0.18s | 取消/拒绝:低音"嗡"短促 |
| `sfx_ui_error` | 0.30s | 操作失败/禁止:两声短促错误"嘟-嘟" |

---

## D. 战场地图交互(6)

| cue key | 时长 | 描述 | 触发点 |
|---|---|---|---|
| `sfx_move_step` | 0.25s | 单格脚步:贝妮兔耳短靴在废墟地面的"嗒" | 玩家每格移动(`Unit._step_to_next`) |
| `sfx_move_blocked` | 0.18s | 移动被阻挡/AP 不足:短"咚" | AP 不足或目标格不可达 |
| `sfx_select_unit` | 0.15s | 选中玩家单位:青蓝聚焦"叮" | `_change_state(MOVE_STATE)` |
| `sfx_select_enemy` | 0.18s | 选中敌人:橙红聚焦警示音 | `unit_status_widget.show_for(enemy)` |
| `sfx_context_open` | 0.20s | 右键菜单弹出:轻快划动 | `BattleContextMenu.popup()` |
| `sfx_turn_end` | 0.40s | 结束轮次:面板回弹 + 短合音 | `BattleStatusBar.end_turn_pressed` |

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
    "benny": {
      "fire": "sfx_weapon_defender9_fire",
      "hurt": "sfx_player_hurt"
    },
    "raider_infantry":   { "fire": "sfx_weapon_rifle_fire",          "hurt": "sfx_enemy_hurt" },
    "raider_scout":      { "fire": "sfx_weapon_scout_rifle_fire",    "hurt": "sfx_enemy_hurt" },
    "raider_bulwark":    { "fire": "sfx_weapon_bulwark_rifle_fire",  "hurt": "sfx_enemy_hurt" },
    "pyroxene_hound":    { "fire": "sfx_weapon_hound_bite",          "hurt": "sfx_enemy_hurt" },
    "pyroxene_sentry":   { "fire": "sfx_weapon_sentry_laser",        "hurt": "sfx_enemy_hurt" }
  },
  "weapons": {
    "weapon_benny_defender_9":  { "fire": "sfx_weapon_defender9_fire" },
    "weapon_benny_hare_hopper": { "fire": "sfx_weapon_hare_hopper_fire" },
    "weapon_benny_dawn_pulse":  { "fire": "sfx_weapon_dawn_pulse_fire" }
  }
}
```

> 解析优先级(`Script/battle/battle_sfx.gd::resolve_binding`):**weapon_id 命中 → 角色 art_key 命中 → default**。cue key 全部对应表中 cue key,加 `.ogg` 后缀落盘。

---

## 2. 批次工作流

### 批次 1 — MVP 战斗体感(24 个)

| 类别 | 数量 | cue |
|---|---:|---|
| A 战斗核心 | 19 | A.1(横幅,2 个已落盘)+ A.2(开火,9 个)+ A.3(命中,3 个)+ A.4(受击,3 个)+ A.5(战斗遮罩,2 个待生成) |
| G 战斗结算 | 5 | 全部 |

### 批次 2 — UI 与流程(51 个)

| 类别 | 数量 | cue |
|---|---:|---|
| C UI 通用 | 7 | 全部 |
| D 战场交互 | 6 | 全部 |
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

---

## 5. 交付清单(可勾选)

- [x] **批次 1 / A.1**:turn_in + turn_out(2 个)✅ 横幅专用
- [ ] 批次 1:A.2 开火 9 个
- [ ] 批次 1:A.3 命中/未命中 3 个
- [ ] 批次 1:A.4 受击/倒下 3 个
- [ ] 批次 1:A.5 战斗遮罩过渡 2 个
- [ ] 批次 1:G 战斗结算 5 个
- [ ] 批次 2:C~J 全部 51 个
- [ ] 批次 2:L 环境音 3 个
- [ ] 批次 3:K BGM 9 个
- [ ] `Script/battle/battle_sfx.gd` 切换为真实播放实现
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
| C/D UI 短音 | ⚠️ 难度高 | UI 短音(<0.2s)模型难出干净,建议改用 SoX/ffmpeg 程序合成 |
| E/F/G 状态 / 道具 / 结算 | ❌ 不推荐批量 | 长尾/细腻音,单条 prompt 一次 |
| H 装备 / 背包 | ⚠️ 单 cue 出 | 物件声多样,各自 prompt |
| I 存档 | ⚠️ 单 cue 出 | UI 反馈短音,程序合成可能更稳 |
| J 商店 / 订单 | ⚠️ 单 cue 出 | 混合物件声 |
| K BGM | ✅ 9 首独立 | batch_text_to_music 一次最多 5 个,分两批 |
| L 环境音 | ✅ 一次出 3 个 loop | 强调 `continuous loop, no melody, environmental only` |

---

> **下一步**:A.1 听感方向已定,继续推 A.2 武器开火。建议先做贝妮的「防卫者-9」(Lv1 SMG),定下 SMG 的整体音色基调,后面野兔跳跃者 / 黎明初霁 在同一 prompt 模板上做"音色递进"变体即可。