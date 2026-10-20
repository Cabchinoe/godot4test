# Benny 语音台词与 TTS 资产清单

> 版本 v1.1(2026-10-20)
> 角色：贝妮（Benny）· 白兔女兵 · 19 岁 · 158 cm
> 本文是 Benny 的独立语音文档；台词、cue 映射、TTS 参数都以此处为准。
> `doc/sfx_asset_manifest.md` 只保留系统规则，不再记录 Benny 的具体台词。

---

## 0. 背景与表演锚点

贝妮来自断裂带边缘的温室聚落「白垩谷」，从小跟着育苗师母亲在温室里长大。晶涌爆发那晚，母亲把最后一箱种子塞给她，让她「带出去种」。她走了十一天，是撤离名单上的最后一个名字，也一直记得那个没能跟上的第二育苗师。

表演时抓住三层：

- **日常**：温和、元气、有点小天然。会认真给每一株嫩芽起名字，也会把配给糖偷偷留给哨兵；偶尔冒失，但很快自己调整回来。
- **工作**：努力型可靠。路线、补给、撤离顺序会提前记到烂熟；犯小错时会先慌半拍，然后立刻修正，不长期自责。
- **战场**：带着「把种子和人都带回去」的使命，还没完全准备好就被迫上战场。她会失误，但不会停在失误里；声音要听得出努力和韧性，不是低沉疲惫型。

她不是冷酷的杀手，也不是热血口号型角色。她的力量来自「最后一个走」的执念，以及每次都愿意再试一次的劲头。

---

## 1. 音色与 TTS 方向

| 项 | 要求 |
|---|---|
| 音色 | 年轻女性，清亮、有精神，中音区偏亮；**不低沉、不沙哑、不做疲惫御姐** |
| 气质 | 元气、可靠、努力型；不是甜腻萌音，也不是冷硬御姐 |
| 日常语速 | 约 0.95~1.05 倍，句尾可以轻轻上扬，但不要蹦跳式卖萌 |
| 战斗语速 | 约 1.05~1.15 倍，短句、清晰、有推进感 |
| 情绪高点 | 认真、坚定、带一点鼓励感；不喊口号，不长时间嘶吼 |
| 疼痛表现 | 短促吸气 / 闷哼，随后马上调整呼吸；不要长时间哭腔 |
| 小失误 | 先慌半拍，再用一句「没事 / 再来 / 我调整好了」拉回来；不要持续自责 |
| 植物 / 种子意象 | 只在日常、羁绊、回忆里少量使用；战斗中不要频繁比喻 |
| 禁忌 | 英文台词、低沉疲惫声线、动漫式尖叫、过度撒娇、长篇说教、频繁叹气 |

**统一要求**：全部使用普通话；同一角色所有台词语音保持同一音色；不要烘焙长混响，空间感交给游戏总线处理。

---

## 2. 命名与 cue 映射

文件命名：`voice_benny_<scene>_<variant>.mp3`

当前代码对单个 cue 只绑定一个文件；下表的「默认」先用于接线，其余条目作为后续随机 / 条件变体。若后续要启用多条，需要把 voice 绑定扩展为数组或台词槽。

| 游戏 cue | 默认文件 / line ID | 场景 | 生产状态 | 代码绑定 |
|---|---|---|---|---|
| `units.benny.select_player` | `voice_benny_select_01` | 选中角色 / 进入移动 | ✅ 已落盘 | ✅ **已接**（`battlefield.gd:1113`，选中自己进入移动态时） |
| `units.benny.hit` | `voice_benny_hit_01` | 受击 | 待生产 | ❌ 未接（与音效 `hit` 撞名，需独立 voice cue） |
| `units.benny.bleed_apply` | `voice_benny_bleed_01` | 流血施加 | 待生产 | ✅ **已接**（`battle_cut_in.gd` `show_result()` → `_play_status_voice()`），文件未录 |
| `units.benny.fracture_apply` | `voice_benny_fracture_01` | 骨折施加 | ✅ 已落盘 | ✅ **已接**（同上） |
| `units.benny.voice_heal` | `voice_benny_heal_01` | 医疗道具生效 | ✅ 已落盘 | ✅ **已接**（`battlefield.gd:870`） |
| `units.benny.battle_cutin_in` | `voice_benny_cutin_in_01` | 战斗遮罩入场 | 待生产 | ❌ 未接（通道已在，加绑定即生效） |
| `units.benny.unit_down` | `voice_benny_down_01` | 倒地 / 死亡 | 待生产 | ❌ 未接（与音效 `unit_down` 撞名） |
| `player_voice.battle_victory` | `voice_benny_victory_01` | 胜利结算 | 待生产 | ❌ 未接（`player_voice` 段不存在） |
| `player_voice.battle_defeat` | `voice_benny_defeat_01` | 失败结算 | 待生产 | ❌ 未接（同上） |
| `player_voice.evac_confirm` | `voice_benny_evac_confirm_01` | 撤离确认 | 待生产 | ❌ 未接（同上） |
| `player_voice.evac_success` | `voice_benny_evac_success_01` | 撤离成功 | 待生产 | ❌ 未接（同上） |
| `player_voice.evac_fail` | `voice_benny_evac_fail_01` | 撤离失败 | 待生产 | ❌ 未接（同上） |

> **cue 命名口径**：以本表（`units.<art_key>.<cue>` / `player_voice.<cue>`）为准。
>
> **语音一律走人声通道**：`_sfx.play_voice(&"cue", ctx)`，不占用音效池，新语音会自动掐断上一条（连点角色不会叠加）。详见 `doc/audio_pipeline.md` 第 4 节「人声通道」。
> `doc/sfx_asset_manifest.md` 里的 `sfx_hit_benny` / `sfx_battle_cutin_in_benny` 等是另一套写法，
> 三套命名的映射见 [`audio_pipeline.md`](audio_pipeline.md) 第 4 节。
>
> **敌人台词不在本文档**：人形敌人的入场与受击／倒地台词见 [`enemy_voice_lines.md`](enemy_voice_lines.md)。
>
> **生产方式**：真人配音需求单见 [`benny_vo_brief.md`](benny_vo_brief.md)；
> TTS 接法与实测权限见 [`minimax_tts_guide.md`](minimax_tts_guide.md)。

以下场景目前没有独立 cue，先作为后续扩展台词库：攻击、回合开始、敌方压制、低血量、基地日常、交易、订单、背包、搜刮、羁绊、剧情回忆、小失误 / 调整 / 使命感。

---

## 3. 台词库

### 3.1 选中 / 移动

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_select_01` | 「我在这儿。路线我来带。」 | 平静、可靠，句尾轻收 |
| `voice_benny_select_02` | 「准备好了，走吧。」 | 日常语速，像在确认装备 |
| `voice_benny_select_03` | 「别离我太远。」 | 低声，短句 |
| `voice_benny_select_04` | 「位置我看过了，能走。」 | 工作时语气，清晰 |
| `voice_benny_move_01` | 「跟紧，别踩到碎玻璃。」 | 提醒，不命令 |
| `voice_benny_move_02` | 「这边，脚步轻一点。」 | 压低音量 |
| `voice_benny_move_03` | 「我探路，你看着后面。」 | 分工明确，平静 |
| `voice_benny_move_04` | 「路线我记好了，跟上我，别掉队。」 | 出击前，可靠 |

### 3.2 交火 / 回合

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_attack_01` | 「让开。」 | 短、硬，不喊 |
| `voice_benny_attack_02` | 「别挡路。」 | 咬字清楚 |
| `voice_benny_attack_03` | 「我压制住它，你快走。」 | 紧迫但不慌 |
| `voice_benny_attack_04` | 「三发，够用了。」 | 冷静、带一点自信 |
| `voice_benny_turn_start_01` | 「新的一轮。检查装备。」 | 工作语气 |
| `voice_benny_turn_start_02` | 「我还站得住。」 | 疲惫但稳 |
| `voice_benny_turn_start_03` | 「先看撤离路线。」 | 提醒自己 / 队友 |
| `voice_benny_enemy_01` | 「他们压过来了。别露头。」 | 压低、短促 |
| `voice_benny_enemy_02` | 「脚步声太多，先撤。」 | 判断明确 |
| `voice_benny_enemy_03` | 「别急，等他们过拐角。」 | 克制、冷静 |
| `voice_benny_enemy_04` | 「别管战果了，三点方向撤，我压后。」 | 战况胶着，语速加快 |

### 3.3 受伤 / 状态

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_hit_01` | 「……唔。」 | 短闷哼，不拖长 |
| `voice_benny_hit_02` | 「没事，擦到了。」 | 吸气后压住 |
| `voice_benny_hit_03` | 「别管我，继续。」 | 硬撑，清晰 |
| `voice_benny_hit_04` | 「……还能动。」 | 低声，带喘息 |
| `voice_benny_hit_05` | 「……没事，只是踩空了一步。」 | 轻描淡写，带停顿 |
| `voice_benny_low_hp_01` | 「有点糟……我还能撑。」 | 短吸气后稳住，不拖长 |
| `voice_benny_low_hp_02` | 「我没事。先把人带走。」 | 固执、稳定 |
| `voice_benny_low_hp_03` | 「别回头，我跟着。」 | 压低声量 |
| `voice_benny_bleed_01` | 「伤口裂开了……先包一下。」 | 吸气，实用语气 |
| `voice_benny_bleed_02` | 「血在滴。我知道。」 | 冷静，带一点疲惫 |
| `voice_benny_bleed_03` | 「别慌，我按住它。」 | 安抚队友 |
| `voice_benny_fracture_01` | 「骨头……有点不对劲。」 | 停顿，压低 |
| `voice_benny_fracture_02` | 「这条腿还能撑。」 | 咬牙，短句 |
| `voice_benny_fracture_03` | 「别扶我，我自己走。」 | 固执，不喊 |
| `voice_benny_down_01` | 「……先走。别等我。」 | 气声，句尾下沉 |
| `voice_benny_down_02` | 「种子……还在包里……」 | 意识模糊，轻 |
| `voice_benny_down_03` | 「对不起……这次……没跟上。」 | 很轻，带停顿 |
| `voice_benny_down_04` | 「还要……浇水……」 | 几乎气声，留白 |

### 3.4 医疗道具生效

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_heal_01` | 「好多了。谢谢。」 | 松一口气，轻 |
| `voice_benny_heal_02` | 「包扎好了，能继续。」 | 工作确认语气 |
| `voice_benny_heal_03` | 「……疼，但没事了。」 | 先吸气，再说 |
| `voice_benny_heal_04` | 「别担心，我缓过来了。」 | 安抚，柔和 |

### 3.5 战斗遮罩入场

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_cutin_in_01` | 「我先进去，你压后。」 | 果断，短 |
| `voice_benny_cutin_in_02` | 「让开，这条路线我要了。」 | 咬字变硬 |
| `voice_benny_cutin_in_03` | 「别拖时间。跟上。」 | 战斗语速 |
| `voice_benny_cutin_in_04` | 「人我带出来，东西再说。」 | 平静但不容置疑 |

### 3.6 胜利 / 失败

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_victory_01` | 「结束了。先把伤员带回去。」 | 不庆祝，先处理现场 |
| `voice_benny_victory_02` | 「都还在吗？……好。」 | 停顿后松气 |
| `voice_benny_victory_03` | 「战果不重要，人齐了就行。」 | 平静、笃定 |
| `voice_benny_defeat_01` | 「是我没算好路线……」 | 自责，低声 |
| `voice_benny_defeat_02` | 「别管我了，带他们走。」 | 压住疼痛，坚决 |
| `voice_benny_defeat_03` | 「至少……种子还在。」 | 很轻，苦涩 |

### 3.7 撤离

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_evac_confirm_01` | 「确认撤离。我压后。」 | 清晰、果断 |
| `voice_benny_evac_confirm_02` | 「路线我记好了，跟紧。」 | 工作语气 |
| `voice_benny_evac_confirm_03` | 「现在走，别回头。」 | 压低、短促 |
| `voice_benny_evac_success_01` | 「全员都在。……嗯，一个都没少。」 | 先确认，再松气 |
| `voice_benny_evac_success_02` | 「回来了。先把身上的土拍拍。」 | 日常、轻 |
| `voice_benny_evac_success_03` | 「种子也在。这次没丢。」 | 很小的欣慰 |
| `voice_benny_evac_fail_01` | 「出口被封了……换路线。」 | 紧迫但不慌 |
| `voice_benny_evac_fail_02` | 「我过不去。你们先走。」 | 压低，坚决 |
| `voice_benny_evac_fail_03` | 「别回来。听见没有？」 | 急了，但不尖叫 |

### 3.8 基地 / 温室日常

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_base_01` | 「指挥官，今天温室里第一株卷心菜发芽了哦。」 | 轻快，日常语速 |
| `voice_benny_base_02` | 「这盆土太湿了，得松松。」 | 自言自语式 |
| `voice_benny_base_03` | 「我给这一排起了名字……你别笑。」 | 有点不好意思 |
| `voice_benny_base_04` | 「值夜的时候记得喝热水。」 | 照顾人的语气 |
| `voice_benny_base_05` | 「基地的灯还亮着，就还能撑。」 | 安静、坚定 |

### 3.9 交易 / 订单

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_shop_01` | 「这些够用吗？别乱花信用点。」 | 实用、轻微提醒 |
| `voice_benny_shop_02` | 「种子和药，优先买这两样。」 | 工作语气 |
| `voice_benny_shop_03` | 「价格我看了，不划算。」 | 直说，不刻薄 |
| `voice_benny_shop_04` | 「要是能换点滤芯就好了。」 | 随口念叨 |
| `voice_benny_quest_accept_01` | 「我去。把路线给我。」 | 干脆 |
| `voice_benny_quest_accept_02` | 「他们等多久了？」 | 关切 |
| `voice_benny_quest_accept_03` | 「东西我会带到，人也会带回来。」 | 承诺，平稳 |
| `voice_benny_quest_accept_04` | 「先别告诉温室的人，免得他们担心。」 | 低声、体贴 |
| `voice_benny_quest_turn_in_01` | 「东西都在。你点一下。」 | 事务性 |
| `voice_benny_quest_turn_in_02` | 「他们没事就好。」 | 轻、真心 |
| `voice_benny_quest_turn_in_03` | 「下次缺什么，提前说。」 | 平静 |
| `voice_benny_quest_turn_in_04` | 「不用谢。路上小心。」 | 日常收尾 |

### 3.10 背包 / 搜刮

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_inventory_01` | 「这个位置顺手。」 | 自言自语 |
| `voice_benny_inventory_02` | 「弹匣别放太满，会卡。」 | 经验分享 |
| `voice_benny_inventory_03` | 「背包还能再塞一点。」 | 轻快 |
| `voice_benny_inventory_04` | 「护具旧了，但还能挡一下。」 | 务实 |
| `voice_benny_search_01` | 「有东西。先别出声。」 | 压低 |
| `voice_benny_search_02` | 「空的……走。」 | 短，轻微失望 |
| `voice_benny_search_03` | 「这个箱子我开了。」 | 提醒队友 |

### 3.11 羁绊 / 剧情回忆

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_bond_01` | 「你总是把最危险的位置留给自己。」 | 轻，带一点责备 |
| `voice_benny_bond_02` | 「下次撤的时候，记得叫上我。」 | 认真 |
| `voice_benny_bond_03` | 「那箱种子我一直留着。现在，我想分你一半。」 | 慢，温柔 |
| `voice_benny_bond_04` | 「我不是不怕。我只是……不想再少一个人。」 | 停顿，认真但不消沉 |
| `voice_benny_bond_05` | 「等这里能种出花，我们一起去看。」 | 很轻，带希望 |
| `voice_benny_story_01` | 「白垩谷的温室很大，风一吹，全是湿土的味道。」 | 回忆，慢 |
| `voice_benny_story_02` | 「母亲把种子塞给我，说‘带出去种’。」 | 平静，略微停顿 |
| `voice_benny_story_03` | 「我走了十一天。箱子没丢。」 | 陈述，努力压住情绪 |
| `voice_benny_story_04` | 「那只手套不是遗物。我只是……还没想好怎么还回去。」 | 很轻，停顿 |
| `voice_benny_story_05` | 「如果有一天路修好了，我想回去看看。」 | 温柔、克制 |

### 3.12 小失误 / 调整 / 使命感

| line ID | 台词 | TTS 备注 |
|---|---|---|
| `voice_benny_oops_01` | 「啊……走错边了。没事，我绕回来。」 | 先小慌，立刻恢复元气 |
| `voice_benny_oops_02` | 「刚才那下没站稳……再来。」 | 短促吸气，马上重来 |
| `voice_benny_oops_03` | 「这次算我的。下次不会了。」 | 坦诚，认真，不垂头丧气 |
| `voice_benny_oops_04` | 「别担心，我调整好了。」 | 安抚队友，语气轻快 |
| `voice_benny_oops_05` | 「我还在学，但不会拖后腿。」 | 努力型，真诚 |
| `voice_benny_oops_06` | 「没准备好也得上了。走吧。」 | 使命感，压住紧张 |
| `voice_benny_mission_01` | 「我答应过，要把种子带回去。」 | 坚定，不喊口号 |
| `voice_benny_mission_02` | 「再试一次。总能找到路。」 | 积极调整，清亮 |
| `voice_benny_mission_03` | 「这次我会做得更好。」 | 认真，带一点不服输 |
| `voice_benny_mission_04` | 「大家都在，我就还能往前走。」 | 温暖、可靠 |

---

## 4. 生产建议

1. 先按「默认文件」生成 12 条用于接线的短语音：select、hit、bleed、fracture、heal、cutin_in、down、victory、defeat、evac_confirm、evac_success、evac_fail。
2. 其余条目作为同一 cue 的变体，后续扩展随机 / 条件选择时再批量生成。
3. 同一条 cue 的变体保持相同音色、语速和空间感；不要把不同情绪做成不同角色。
4. 所有文件目标路径：`res://Art/audio/sfx/voice_benny_<scene>_<variant>.<ext>`。
5. TTS 生成后先落 `_review/` 试听；用户说「收录」后再转正式文件、接绑定并清理临时资源。

---

## 5. 12 条默认语音的演绎参数（已与 `tools/tts_lines_benny.json` 对齐）

> 该文件是实际生产用的机器可读清单，本表与之逐条对应。两者任一方改动都要同步另一方。

| line ID | 台词 | emotion | speed | 停顿标记 | 语气词标签 | voice_modify |
|---|---|---|---|---|---|---|
| `voice_benny_select_01` | 我在这儿。路线我来带。 | `fluent` | 1.0 | `<#0.30#>` | — | `intensity:-20, timbre:8` |
| `voice_benny_hit_01` | ……唔。 | `surprised` | 1.05 | — | `(pant)` | — |
| `voice_benny_bleed_01` | 伤口裂开了……先包一下。 | `sad` | 0.98 | `<#0.35#>` | `(inhale)` | — |
| `voice_benny_fracture_01` | 骨头……有点不对劲。 | `fearful` | 0.95 | `<#0.40#>` | — | — |
| `voice_benny_heal_01` | 好多了。谢谢。 | `happy` | 0.98 | `<#0.20#>` | — | — |
| `voice_benny_cutin_in_01` | 我先进去，你压后。 | `angry` | 1.1 | `<#0.25#>` | `(breath)` | `intensity:-35, timbre:8` |
| `voice_benny_down_01` | ……先走。别等我。 | `sad` | 0.92 | `<#0.30#>` | `(exhale)` | — |
| `voice_benny_victory_01` | 结束了。先把伤员带回去。 | `happy` | 1.0 | `<#0.30#>` | — | — |
| `voice_benny_defeat_01` | 是我没算好路线…… | `sad` | 0.95 | — | — | — |
| `voice_benny_evac_confirm_01` | 确认撤离。我压后。 | `angry` | 1.05 | `<#0.25#>` | — | `intensity:-25, timbre:5` |
| `voice_benny_evac_success_01` | 全员都在。……嗯，一个都没少。 | `happy` | 0.98 | `<#0.35#>` `<#0.20#>` | `(emm)` | — |
| `voice_benny_evac_fail_01` | 出口被封了……换路线。 | `angry` | 1.1 | `<#0.30#>` | — | `intensity:-30, timbre:5` |

**参数说明**

- `<#x#>`：官方 API 的**停顿控制**标记，x 为秒数。必须夹在两段可发音文本之间，不可连续使用，不能放首尾。**这是「断句」问题的直接解** —— 用它替代引擎自带的句号长停顿。
- `(breath)` `(pant)` `(inhale)` `(exhale)` `(emm)`：**语气词标签**，仅 `speech-2.8-hd` / `speech-2.8-turbo` 支持。2.8 不支持 `whisper` 情绪。
- `voice_modify.intensity`：**接近 -100 才是「更刚劲」**，接近 +100 是「更轻柔」。战场干练取负值。
- `voice_modify.timbre`：接近 -100 浑厚，接近 +100 清脆。Benny 规格要「清亮」故取小幅正值。
- `emotion` 的 `fluent`（生动）仅 2.6/2.8 可用，用于工作／日常语气。

**注意**：以上是**当前可用音色下的最优解**。音色本身不达标时，调参只能有限改善。音色选型与生产路线见 [`audio_pipeline.md`](audio_pipeline.md) 第 3 节。

