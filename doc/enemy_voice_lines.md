# 人形敌人语音文档

> 版本 v1.0（2026-10-20）
> 角色：三个**人形**掠夺者（街区掠夺兵 / 斥候掠夺者 / 护盾掠夺者）
> 关联：[`doc/audio_pipeline.md`](audio_pipeline.md)（总入口）· [`doc/sfx_asset_manifest.md`](sfx_asset_manifest.md) J 类与 A.4 节 · [`doc/minimax_tts_guide.md`](minimax_tts_guide.md)

---

## 0. 适用范围

| 角色 | `art_key` | 显示名 | 走人声？ |
|---|---|---|---|
| 街区掠夺兵 | `raider_infantry` | 街区掠夺兵 | ✅ |
| 斥候掠夺者 | `raider_scout` | 斥候掠夺者 | ✅ |
| 护盾掠夺者 | `raider_bulwark` | 护盾掠夺者 | ✅ |
| 辉石猎犬 | `pyroxene_hound` | 辉石猎犬 | ❌ 兽类，保持犬吠/哀鸣 |
| 晶涌哨戒机 | `pyroxene_sentry` | 晶涌哨戒机 | ❌ 机械，保持电子/爆炸音 |

> 依据 `sfx_asset_manifest.md` v1.21 定案：*"hound / sentry 保持兽类 / 机械音"*。
> 本文只管三个人形掠夺者。

**为什么有这份文档**：`sfx_asset_manifest.md` v1.21 已定 *"后续新增角色语音统一 TTS，不再网搜英文人声"*，但这 6 个人形敌人的 hit/down 至今挂的是**英文网搜录音**，且**全项目没有任何中文台词设计**。本文补上这个缺口。

---

## 1. 现有英文素材（待替换）

| 现有文件 | 英文素材 | 时长 | 状态 |
|---|---|---|---|
| `sfx_hit_raider_infantry` | `Oof` | 0.27s | ⏳ 待重做（中文） |
| `sfx_hit_raider_scout` | `Enemy hurt 1` | 1.43s | ⏳ 待重做（中文） |
| `sfx_hit_raider_bulwark` | `Head Impact Grunt` | 1.14s | ⏳ 待重做（中文） |
| `sfx_unit_down_raider_infantry` | `Hurt light 1` | 0.43s | ⏳ 待重做（中文） |
| `sfx_unit_down_raider_scout` | `Character Death` | 1.13s | ⏳ 待重做（中文） |
| `sfx_unit_down_raider_bulwark` | `Damage Hurt ooh!` | 1.06s | ⏳ 待重做（中文） |

> 保留旧文件直到新文件定稿替换，避免中途丢失反馈。**不要提前删除**。

---

## 2. 三个角色的音色方向

`sfx_asset_manifest.md` J 类已给的方向，加上本文件的演绎细化：

| 角色 | 清单原文方向 | 本文件细化 | 音色禁忌 |
|---|---|---|---|
| `raider_infantry` 街区掠夺兵 | 粗粝街头感 | 中年男性，**喉音重、偏沙**，中低频厚。说话带街头腔的懒散和戒备，不是军人号令式 | 不要播音腔、不要精英感、不要清晰的标准普通话腔 |
| `raider_scout` 斥候掠夺者 | 更尖更疾 | 年轻男性，**偏亮偏薄**，语速快、气息浅。**惊觉、警觉**的多 | 不要低沉、不要慢、不要温吞 |
| `raider_bulwark` 护盾掠夺者 | 低沉厚重 + 金属共鸣 | 中年男性，**最低最厚**，胸腔共鸣重、几乎不动。沉重、压迫感 | 不要尖、不要快、不能有气声；力度要够但不能喊 |

**共同要求**（与贝妮的区别）：

- 这三个是**敌人**，不是主角。声音要**让玩家听出敌意**，而不是听出"又一个人类"
- 不要有主角那种"努力型可靠"和"元气"——掠夺者是**被逼到断裂带边缘的人**，不是战士
- 全部标准普通话，但**允许口音和含混**（街头感）；不要念得像播音员
- 不要英文字幕式的表演，不要夸张的日漫式惨叫

---

## 3. 受击 / 倒地台词（已定稿，不依赖人格设定）

这 6 条是**纯生理音**（痛呼、闷哼、倒地喘息），与角色人格无关，可直接进入生产。

| # | line ID | 目标 cue | 台词 | 演绎 |
|---|---|---|---|---|
| 1 | `voice_raider_infantry_hit_01` | `units.raider_infantry.hit` | ——唔！ | 短促痛呼，不拖长。带一丝怒意 |
| 2 | `voice_raider_scout_hit_01` | `units.raider_scout.hit` | 什——！ | **被打断**的感觉，后半截吞掉。惊觉 |
| 3 | `voice_raider_bulwark_hit_01` | `units.raider_bulwark.hit` | 嗯！ | 闷哼，几乎是鼻音。身体很结实的一声 |
| 4 | `voice_raider_infantry_down_01` | `units.raider_infantry.unit_down` | 呵…… | 倒地气声，喉音 |
| 5 | `voice_raider_scout_down_01` | `units.raider_scout.unit_down` | 不……可能…… | 难以置信，不甘，尾音断掉 |
| 6 | `voice_raider_bulwark_down_01` | `units.raider_bulwark.unit_down` | 撤…… | 还在下命令，气息已经撑不住 |

### TTS 参数建议

| line ID | emotion | speed | 语气词标签 | voice_modify |
|---|---|---|---|---|
| `voice_raider_infantry_hit_01` | `angry` | 1.05 | `(pant)` | `intensity:-20` |
| `voice_raider_scout_hit_01` | `surprised` | 1.15 | `(gasps)` | `timbre:15` |
| `voice_raider_bulwark_hit_01` | `angry` | 0.95 | — | `intensity:-45` |
| `voice_raider_infantry_down_01` | `sad` | 0.9 | `(exhale)` | `intensity:-15` |
| `voice_raider_scout_down_01` | `surprised` | 1.0 | — | `timbre:10` |
| `voice_raider_bulwark_down_01` | `sad` | 0.85 | `(exhale)` | `intensity:-40` |

> 停顿标记：第 2 条「什——！」用 `<#0.15#>` 制造被打断；第 5、6 条句中各加一处 `<#0.25#>`。

### 真人配音时怎么录这 6 条

这 6 条**不需要配音演员**——它们是生理音，一个人对着麦克风做 6 组短促发声即可：

- **受击**：掐自己一下 / 被人拍肩膀的瞬间发声，或直接演。**要真疼**，演出来的是"闷"不是"痛"
- **倒地**：先憋一口气再瘫掉，从有气到没气
- 每个角色换不同音色录同一套动作（喉音重 / 薄而急 / 厚而沉）

> 也因此，这 6 条**用真人录音比 TTS 更划算**，且没有音色不达标的问题。

---

## 4. 战斗入场台词（🔲 待决策）

`sfx_asset_manifest.md` J 类把 `sfx_battle_cutin_in_*` 同时标成了**音效描述**和**TTS 台词**，两者冲突：

| cue key | 清单原描述 | 清单标注 |
|---|---|---|
| `sfx_battle_cutin_in_raider_infantry` | 掠夺兵：粗粝街头感 | TTS 台词 · ⏳ 台词待定 |
| `sfx_battle_cutin_in_raider_scout` | 斥候：更尖更疾 | TTS 台词 · ⏳ 台词待定 |
| `sfx_battle_cutin_in_raider_bulwark` | 护盾兵：低沉厚重 + 金属共鸣 | TTS 台词 · ⏳ 台词待定 |

**需要先定的一件事**：敌人入场时**开口说话**，还是**只要声音**（喘息、金属、逼近感）？

| 方案 | 做法 | 优点 | 缺点 |
|---|---|---|---|
| **A｜开口** | 每个敌人 2~3 句入场喊话 | 战斗信息量大，敌人有性格 | 要写台词、要 3 个角色的配音量；可能吵 |
| **B｜不出声** | 只做喘息/金属/逼近音效 | 压迫感更强，不干扰玩家指令；省配音量 | 敌人没有存在感 |
| **C｜混合** | 只有护盾兵喊一句命令（体量感最强），另两个不出声 | 有层次 | 需要单独设计 |

> 倾向 **C**：护盾兵作为"扛线"角色发号施令最合理，斥候和掠夺兵保持沉默反而更吓人。

**决策后再写台词。** 本文先留好 cue 与文件命名占位：

| line ID | 目标 cue | 台词 |
|---|---|---|
| `voice_raider_infantry_cutin_in_01` | `units.raider_infantry.battle_cutin_in` | 待决策后填 |
| `voice_raider_scout_cutin_in_01` | `units.raider_scout.battle_cutin_in` | 待决策后填 |
| `voice_raider_bulwark_cutin_in_01` | `units.raider_bulwark.battle_cutin_in` | 待决策后填 |

---

## 5. 接线现状

| cue | 代码触发点 | 绑定状态 |
|---|---|---|
| `units.raider_infantry.hit` | `battle_cut_in.gd:86` `_sfx.play(&"hit", _sfx_context(&"hit"))` | ✅ 通道在，当前绑英文音效 `sfx_hit_raider_infantry` |
| `units.raider_scout.hit` | 同上 | ✅ 通道在，绑 `sfx_hit_raider_scout` |
| `units.raider_bulwark.hit` | 同上 | ✅ 通道在，绑 `sfx_hit_raider_bulwark` |
| `units.raider_infantry.unit_down` | `battlefield.gd:1540` / `battle_cut_in.gd:89` | ✅ 通道在，绑 `sfx_unit_down_raider_infantry` |
| `units.raider_scout.unit_down` | 同上 | ✅ 通道在，绑 `sfx_unit_down_raider_scout` |
| `units.raider_bulwark.unit_down` | 同上 | ✅ 通道在，绑 `sfx_unit_down_raider_bulwark` |
| `units.raider_*.battle_cutin_in` | `battle_cut_in.gd:53` | ❌ `units` 段无此项，需加绑定 |

**替换时注意**：`hit` / `unit_down` 这两个 cue 名现在绑的是音效。要让语音与音效共存，必须**改用独立的 voice cue 名**（如 `voice_hit` / `voice_unit_down`），否则语音会把音效顶掉。`voice_heal` 已经是这个模式，可作先例。

改造点：
1. `conf/battle/sfx_bindings.json`：`units.<art_key>` 下新增 `voice_hit` / `voice_unit_down` / `voice_battle_cutin_in` 键
2. `Script/battle/battle_sfx.gd`：`resolve_binding()` 增加 `voice_` 前缀 cue 的查找层（或在调用侧改用新 cue 名）
3. `Script/battle/battle_cut_in.gd` / `Script/battlefield.gd`：在播放音效 hit/unit_down 的同时，额外播一次 voice cue

---

## 6. 生产与入库

1. 录音 / TTS → `Art/audio/sfx/_review/`
2. 技术校验（格式 / 峰值 / 削波 / 时长）
3. 试听确认 → 转正式文件 `Art/audio/sfx/voice_<art_key>_<scene>_<variant>.<ext>`
4. 旧英文文件改名保留为 `*.legacy.mp3` 或移入 `_review/`，**待用户确认后再删**
5. 接绑定 → 清理 review 区

命名规范：`voice_<art_key>_<scene>_<variant>.<ext>`，例 `voice_raider_scout_hit_01.flac`。

> ⚠️ `_review/` 目录同时被 `game-sfx-search` 等工具使用。**清理时只删自己本次产出的文件，不要用通配符批量删。**

---

## 7. 待办

- [ ] **决策：敌人入场开口还是只出声**（§4）→ 决定后写 3 条入场台词
- [ ] 6 条 hit/down 中文语音生产（§3）
- [ ] 3 个角色的音色方向定稿（§2）—— 目前只有清单里的一行方向，缺人格设定
- [ ] `voice_hit` / `voice_unit_down` 独立 cue 改造（§5）
- [ ] 替换后删除 6 个旧英文文件
