# 音频生产总览与交接说明

> 版本 v1.0（2026-10-20）
> **本文是所有音频相关工作的入口。** 接手语音／音效／BGM 生产的会话，先读这一篇，再按索引进入对应文档。
> 配套工具在 `tools/`，可执行命令在第 5 节。

---

## 1. 三十秒现状

| 项 | 状态 |
|---|---|
| 正式 SFX | ✅ **65 个 mp3 已落盘**（`Art/audio/sfx/`），已提交 |
| BGM | ❌ **0 个**。需求 9 条，见 `sfx_asset_manifest.md` §K |
| 环境音 | ❌ **0 个**。需求 3 条（30s loop），见 `sfx_asset_manifest.md` §L |
| 角色语音 | 🟡 **3 个文件已落盘**（`Art/audio/sfx/voice_benny_*.mp3`，32kHz mono 128kbps） |
| 已接线的语音 cue | 🟡 **4 个**：`voice_heal` / `select_player` / `fracture_apply` / `bleed_apply`（其中 `bleed_apply` 文件待录） |
| 语音播放通道 | ✅ **独立人声通道**（`BattleSfx.play_voice()`），新语音自动掐断上一条，连点不叠加 |
| TTS 管线 | ✅ 已跑通（官方 API 直连，44.1kHz FLAC），但**音色不达标** |
| 真人配音 | 🔲 需求单已出（`benny_vo_brief.md`），**等录音** |

**当前最关键的两条结论**（别再重复踩）：

1. **代码侧接了 4 个语音 cue，其余触发点还没接。** 音频录好了不接代码不会响。详见第 4 节。
2. **语音质量问题的根因是"挑音色"这条路走不通** —— MiniMax 的 303 个系统音色是通用播音/角色声库，中文女性音色里没有一条符合 Benny 的规格。详见第 3 节。

---

## 2. 文档索引

| 文档 | 管什么 | 状态 |
|---|---|---|
| **[sfx_asset_manifest.md](sfx_asset_manifest.md)** | 音效 cue 总表（95 个 cue）、绑定、落盘状态、命名与采样规范 | 活文档，v1.35 |
| **[item_sfx_manifest.md](item_sfx_manifest.md)** | 道具／场景动作音效逐项需求 | 活文档 |
| **[benny_voice_lines.md](benny_voice_lines.md)** | 贝妮完整台词库（104 条）+ cue 映射 + 演绎规格 | 活文档 |
| **[enemy_voice_lines.md](enemy_voice_lines.md)** | 人形敌人语音（入场台词 + 受击/倒地中文台词） | 新建，待补 |
| **[minimax_tts_guide.md](minimax_tts_guide.md)** | MiniMax TTS 官方 API 接法、可用能力、实测权限 | 活文档 |
| **[benny_vo_brief.md](benny_vo_brief.md)** | 真人配音需求单（可直接交给配音演员） | 活文档 |
| **[benny_vo_lines.csv](benny_vo_lines.csv)** | 录音工作表（12 必录 + 14 推荐） | 活文档 |
| [character_design.md](character_design.md) | 贝妮角色设定（性格三层、视觉、战斗数值） | 活文档 |
| [project.md](project.md) | 项目总纲 | 活文档 |

> `doc/asset_manifest` 之外的 `doc/assets/` 是图像资产目录，与音频无关。

---

## 3. 三条生产路线与选型

音频资产分三类，**生产方式不同，不要混用**：

| 类别 | 生产方式 | 工具 | 现状 |
|---|---|---|---|
| **物理音**（枪声、UI、脚步、装备、容器、合成、门） | 音效库检索 | `game-sfx-search` skill（FreeSound / Mixkit / AudioPapkin 等） | 65 个已落盘，**继续用这条路** |
| **人声**（角色台词、痛呼、喘息） | 真人配音 或 TTS | `benny_vo_brief.md` / `tools/tts_minimax.py` | **进行中** |
| **BGM / 环境音** | 音乐模型 或 音效库 | `batch_text_to_music` / `game-sfx-search` | 12 条待做 |

### 为什么人声不能继续用音效库

`sfx_asset_manifest.md` v1.21 已定案：

> 贝妮的受击 / 倒地统一走 **人物配音 / TTS**，不再用 `game-sfx-search` 搜网络素材。
> **人形敌人已落盘的 hit / down 人声素材保留；后续新增角色语音统一 TTS，不再网搜英文人声。**
> hound / sentry 保持兽类 / 机械音。

现存 6 个人形敌人的 hit/down 挂的是**英文网搜录音**（`Oof` / `Enemy hurt 1` / `Head Impact Grunt` / `Hurt light 1` / `Character Death` / `Damage Hurt ooh!`），按上述定案应当重做成中文人声。

### 为什么 TTS 音色挑不出来（已验证，别再重试）

- 账号 `POST /v1/get_voice` 返回 **303 个系统音色**，其中中文女性音色仅十余条。官方描述里**没有一条是"干练 / 利落 / 英气"**：「清脆少女」= *温暖清脆的少女声音*、「温暖少女」= *温柔温暖*、「嘴硬竹马」= *嘴硬心软、不羁的竹马*。
- 通用 TTS 封装（`mcode-tools` 的 `synthesize_speech`）**固定 32kHz / 128kbps / 单声道 mp3**，不暴露 model 档位。实测传 `model` / `voice_setting` / `audio_setting` 进去**会被静默丢弃**，调用返回成功但参数没生效——这是个陷阱，别再试。
- 官方 API 直连可用且是 44.1kHz / 256kbps / FLAC，但**音色天花板仍在系统声库内**。
- MiniMax 提供的两条"造音色"路，**当前账号都不可用**：

| 能力 | 接口 | 账号实测 | 原因 |
|---|---|---|---|
| 音色设计 | `POST /v1/voice_design` | ❌ | `2061 your current token plan not support model, voice_design` |
| 音色快速复刻 | `POST /v1/voice_clone` | ❌ | `2038 voice clone user forbidden`（需个人/企业实名认证） |
| 混合音色 | `timbre_weights`（T2A 参数） | ✅ | 最多 4 个系统音色按权重融合，**当前唯一能造新音色的手段** |

**结论**：继续试 TTS 时，走 `timbre_weights` 混合 + `voice_modify` 精修，而不是在系统音色里挑。同时推进真人配音与账号认证（认证是复刻的前置开关）。

---

## 4. 语音 cue 接线现状（代码侧）

### 人声通道（角色语音专用）

角色语音**不走 SFX 池**，走 `BattleSfx.play_voice()` 的独立人声通道：

| 特性 | 说明 |
|---|---|
| 独占播放器 | 全局唯一一条 `AudioStreamPlayer`（`BattleSfx._voice_player` 是 `static`），不占 `POOL_MAX = 8` 的音效池 |
| 互斥播放 | 新语音开始时自动掐断上一条。**单个 `AudioStreamPlayer` 无法同时播两条流，叠加在结构上不可能** |
| 跨实例共享 | `static` 变量，`battlefield.gd` 与 `battle_cut_in.gd` 各自的 `BattleSfx` 实例共用同一条通道 |
| 静默失败 | 文件不存在时返回 `null`，不刷 warning（语音文件经常还没录） |
| 用法 | `_sfx.play_voice(&"cue_name", {"attacker": unit})`；音效仍用 `_sfx.play()` / `play_optional()` |

> 连点角色时语音会「重新从头说」而不是叠加，这是设计如此：人声通道只有一条。

### 绑定格式：单文件 vs 多变体

`conf/battle/sfx_bindings.json` 里每个 cue 的值支持两种写法：

```jsonc
"hit": "sfx_hit_benny",                    // ① 单文件（音效，向后兼容，永远播）
"select_player": {                         // ② 多变体（角色台词）
  "files": ["voice_benny_select_01"],       //    候选文件列表，随机选一条
  "probability": 0.2,                      //    触发概率，默认 1.0（总播）
  "avoid_repeat": true                     //    避免连续播同一条，默认 true
}
```

**多变体随机规则**（`BattleSfx._pick_variant()`）：

1. 先把**还没录出来的文件滤掉**——所以你一条条录新变体时，已录的那条每次都能播，不会抽中空文件导致整条不响
2. 候选 ≥ 2 条时随机选一条，并避开该 cue **上一次播过的那条**（`_last_played` 是 `static`，跨实例共享）
3. `probability` 在抽签**之前**判定：未命中就整条不播，不占人声通道

> 加新变体只需往 `files` 数组里追加文件名，**代码不用改**。

### 已接

| cue | 触发点 | 绑定 | 文件状态 |
|---|---|---|---|
| `units.benny.voice_heal` | `Script/battlefield.gd:870` `_sfx.play_voice(&"voice_heal", {"attacker": player})` | `voice_benny_heal_01` | ✅ 已落盘 |
| `units.benny.select_player` | `Script/battlefield.gd:1113` 选中自己进入移动态 `_sfx.play_voice(&"select_player", {"attacker": player})` | `voice_benny_select_01`，**概率 20%** | ✅ 已落盘 |
| `units.benny.fracture_apply` | `Script/battle/battle_cut_in.gd` `show_result()` → `_play_status_voice()` | `voice_benny_fracture_01` | ✅ 已落盘 |
| `units.benny.bleed_apply` | 同上 | `voice_benny_bleed_01` | ❌ 文件未落盘（绑定已就位，文件到位即生效） |

### 待接（触发点存在，但没有 voice 通道）

| 目标 cue | 可用的触发点 | 备注 |
|---|---|---|
| `units.benny.hit` | `battle_cut_in.gd` `show_result()` 里 `_sfx.play(&"hit", ...)` | **与音效 `sfx_hit_benny` 撞名**，需独立 voice cue 名（如 `voice_hit`） |
| `units.benny.battle_cutin_in` | `battle_cut_in.gd:53` `_sfx.play(&"battle_cutin_in", ...)` | cue 通道已存在，`sfx_bindings.json` 里 `default.battle_cutin_in` 为空、`units.benny` 无此项 → **加绑定即生效** |
| `units.benny.unit_down` | `battlefield.gd:1540` / `battle_cut_in.gd:89` | **与音效 `sfx_unit_down` 撞名**，需独立 voice cue 名；且两条路径上下文不一致（一条用 `attacker` 传倒地者、一条用 `victim`） |
| `player_voice.battle_victory` | `battlefield.gd` `_end_battle_as_success()` | `player_voice` 段在 JSON 与 `resolve_binding()` 里**都不存在**，需新建 |
| `player_voice.battle_defeat` | `battlefield.gd` `_end_battle_as_failure()` | 同上 |
| `player_voice.evac_confirm` | `battlefield.gd:416` `_on_force_evacuation_pressed()` | 同上 |
| `player_voice.evac_success` | `_end_battle_as_success()` | 同上 |
| `player_voice.evac_fail` | `_end_battle_as_failure()` | 同上 |

### 接线要注意的四个坑

1. **`hit` / `unit_down` 撞名**：`units.benny.hit` 现在绑的是音效 `sfx_hit_benny`，`units.benny.unit_down` 绑的是音效 `sfx_unit_down`。voice 必须用**独立 cue 名**（如 `voice_hit` / `voice_unit_down`），否则会把音效顶掉。`voice_heal` 已经是这个模式，可作先例。
2. **`player_voice` 段不存在**：`conf/battle/sfx_bindings.json` 只有 `default` / `units` / `weapons` 三段；`Script/battle/battle_sfx.gd` 的 `resolve_binding()` 也只按 `weapons → units.<art_key> → default` 三级查。`player_voice` 要**同时**加 JSON 段和 `resolve_binding()` 查找层。
3. **多台词变体已支持**：绑定值写成 `{ "files": [...], "probability": 0.2 }` 即可，运行时随机选一条且避免连续重复。见上面「绑定格式」。
4. **语音必须用 `play_voice()` 而不是 `play()`**：`play()` 会占用音效池且不做互斥、不做概率判定，连点会叠加。语音一律走 `play_voice()`。

### cue 命名口径（三套并存，建议统一）

| 来源 | 写法 | 示例 |
|---|---|---|
| `sfx_asset_manifest.md` | `sfx_<scene>_<verb>` | `sfx_hit_benny`、`sfx_battle_cutin_in_benny` |
| `benny_voice_lines.md` | `units.<art_key>.<cue>` / `player_voice.<cue>` | `units.benny.hit`、`player_voice.battle_victory` |
| `sfx_bindings.json`（代码实际） | 同上 | `units.benny.voice_heal` |

**以代码实际那套为准**（`units.<art_key>.<cue>` + `player_voice.<cue>`），manifest 的 cue 表应补一列映射注明。

---

## 5. 可执行命令

### TTS（需自己的 API Key）

```bash
export MINIMAX_API_KEY=sk-xxxx

# 12 条接线语音
python3 tools/tts_minimax.py tools/tts_lines_benny.json --out Art/audio/sfx/_review --model speech-2.8-hd

# select_01 演绎候选（8 条）
python3 tools/tts_minimax.py tools/tts_lines_benny_audition.json --out Art/audio/sfx/_review --model speech-2.8-hd

# 混合音色候选（4 条）
python3 tools/tts_minimax.py tools/tts_lines_benny_blend.json --out Art/audio/sfx/_review --model speech-2.8-hd

# 音色设计（当前账号返回 2061，需先解锁套餐）
python3 tools/tts_voice_design.py --preset A
```

脚本已实现：端点自动回退（`api.minimax.cn` ↔ `api-bj.minimaxi.com`）、自适应限速（20 RPM 起步，撞 1002/1039 自动降速）、断点续跑（`.tts_cache.json`，重跑不重复计费）、语气词标签守卫（非 2.8 自动剥离）、可选 `--normalize` 响度归一、输出 `index.json` 索引。

### 音频校验

```bash
# 格式 / 采样率 / 峰值
ffprobe -v error -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 <file>
ffmpeg -i <file> -af volumedetect -f null - 2>&1 | grep max_volume

# 统一响度（入库前）
ffmpeg -i in.flac -af loudnorm=I=-16:TP=-1.5:LRA=11 out.flac
```

### 真人录音入库流程

1. 录音 → 交 WAV（规格见 `benny_vo_brief.md` 第 3 节）
2. 放 `Art/audio/sfx/_review/`（**不要直接进正式目录**）
3. 技术校验（格式 / 峰值 / 削波 / 时长）
4. 接入 `conf/battle/sfx_bindings.json`
5. 人工试听确认 → 转正式文件 `Art/audio/sfx/` → 接绑定 → 清理 review 区
6. Godot 导入：勾选 **Normalize**，Loop 关闭

---

## 6. 目录与命名规范

| 类型 | 路径 | 命名 | 规格 |
|---|---|---|---|
| 音效（正式） | `res://Art/audio/sfx/` | `sfx_<scene>_<verb>.mp3` | 48kHz/16bit 单声道，≤2.5s |
| 语音（正式） | `res://Art/audio/sfx/` | `voice_<char>_<scene>_<variant>.<ext>` | 44.1kHz（FLAC/WAV），按角色档案 |
| BGM | `res://Art/audio/bgm/` | `bgm_<scene>` | 48kHz/24bit 立体声，60~120s |
| 环境音 | `res://Art/audio/amb/` | `amb_<scene>` | 立体声，10~30s loop |
| 试听暂存 | `res://Art/audio/sfx/_review/` | 同上 | 确认后转正式，**用完即清** |

> ⚠️ `_review/` 是暂存区。**清理时只删本次会话自己产出的文件**，不要用通配符批量删——该目录同时被 `game-sfx-search` 等其他工具使用（`cand_b1_freesound_*` 等属它们）。

---

## 7. 待办与阻塞关系

| # | 事项 | 阻塞于 | 谁做 |
|---|---|---|---|
| 1 | MiniMax 账号个人/企业实名认证 | 用户操作 | <https://platform.minimax.cn/user-center/basic-information> |
| 2 | Benny 12 条真人录音 | 事项 1 不阻塞（直接录即可） | 配音演员 / 朋友 |
| 3 | 3 个人形敌人的角色设定（人格、处境） | 用户提供 | 未定 |
| 4 | 敌人是否"开口说话"还是"只要声音" | 用户决策 | 未定 |
| 5 | 敌人 6 条 hit/down 中文台词 | 事项 4 | 可先写生理音版本（不依赖设定） |
| 6 | 9 个 BGM + 3 个环境音 | 无 | 可用 `batch_text_to_music` / 音效库 |
| 7 | 12 个语音 cue 的代码接线 | 音频落盘 | 事项 2 完成后可先做（用占位音频验证） |
| 8 | 试 TTS 混合音色 | 无 | 事项 4（战场干练 vs 少年元气 的取向） |
| 9 | 命名口径统一（manifest 补映射列） | 无 | 随时可做 |

**依赖图**：

```
事项 1（认证）──► 音色复刻可用 ──┐
                                 ├──► 变体台词量产
事项 2（真人录音）──────────────┴──► 12 条正式资产 ──► 事项 7（接线）──► 游戏内可听
事项 3 + 4 ──► 事项 5（敌人台词）──► 敌人语音文档 ──► 事项 7
事项 8 ──► 若 TTS 音色定稿，可替代/补充事项 2
```

---

## 8. 已知坑位

- **通用 TTS 封装会静默吞参数**：`mcode-tools` 的 `synthesize_speech` 传 `model` / `voice_setting` / `audio_setting` 不会报错，但**也不生效**，输出永远是 32kHz mp3。别再用它做质量判断。
- **上游限流是硬窗口**：共享上游的 TTS 封装会长时间 429。官方 API 用自己的 key 有完整的 10~20 RPM，别共用。
- **复刻音色 7 天过期**：复刻得到的 voice_id 若 7 天内没被正式调用会被系统删除。拿到后要立刻用它生成正式台词。
- **`voice_modify.intensity` 方向容易搞反**：**接近 -100 才是"更刚劲"**，接近 +100 是"更轻柔"。战场干练要负值。
- **`<#x#>` 停顿标记有三条硬规则**：必须夹在两段可发音文本之间、不可连续使用、不能放首尾；标记计入计费字符数。
- **音色描述与 `fluent` / `whisper` 的模型限制**：`emotion` 的 `fluent` / `whisper` 仅 2.6/2.8 可用；**语气词标签（`(breath)` 等）仅 2.8 可用**，2.8 也不支持 `whisper`。
- **混合音色要置空 voice_id**：用 `timbre_weights` 时 `voice_setting.voice_id` 必须为空字符串。
- **试听样本的峰值不一致**：不同情绪/音色的原始电平差可达 10 dB，横向对比时容易误判。入库前统一归一。
- **Godot 总线未布局**：`conf/audio/ui_sfx.json` 的 `audio_bus` 填 `SFX`，但项目还没有 SFX/BGM/AMB 总线布局，`BattleSfx._has_bus()` 找不到会回落 `Master`。要做音量滑条需先补总线。
