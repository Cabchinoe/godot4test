# MiniMax T2A v2 语音合成接入指南

> 面向《辉石之痕：黎明阵线》的角色语音资产生产。
> 依据官方文档整理：<https://platform.minimax.cn/docs/guides/speech-t2a-websocket>、<https://platform.minimax.cn/docs/api-reference/speech-t2a-http>、<https://platform.minimax.cn/docs/guides/rate-limits>、<https://platform.minimax.cn/docs/api-reference/voice-design-design>、<https://platform.minimax.cn/docs/api-reference/voice-cloning-clone>、<https://platform.minimax.cn/docs/api-reference/voice-management-get>
> 客户端脚本：`tools/tts_minimax.py`（合成）、`tools/tts_voice_design.py`（音色设计）
> 台词清单：`tools/tts_lines_benny*.json`
> 上级入口：[`doc/audio_pipeline.md`](audio_pipeline.md)

---

## 0. 账号能力实测（2026-10-20）

用项目自己的 key 实测各接口，结论如下。**接手前先读这节，别再重复试错。**

| 能力 | 接口 | 状态 | 实测返回 |
|---|---|---|---|
| 语音合成 | `POST /v1/t2a_v2` | ✅ 可用 | 44.1kHz / 256kbps / FLAC |
| 查询可用音色 | `POST /v1/get_voice` | ✅ 可用 | 303 个系统音色，**0 个复刻 / 0 个文生音色** |
| 音色设计 | `POST /v1/voice_design` | ❌ 不可用 | `2061 your current token plan not support model, voice_design` |
| 音色快速复刻 | `POST /v1/voice_clone` | ❌ 无权限 | `2038 voice clone user forbidden` |
| 混合音色 | `timbre_weights`（T2A 参数） | ✅ 可用 | **当前唯一能造出新音色的手段** |

### 解锁条件

- **音色设计**：需要套餐包含该模型。查询 <https://platform.minimax.cn/user-center/basic-information>
- **音色复刻**：需要完成**个人或企业实名认证**（同一页）。另外复刻得到的音色 **7 天内未被正式调用会被系统删除**，拿到 voice_id 后要立刻用它生成正式台词。
- **文件上传**（复刻前置）：`POST /v1/files/upload`，`purpose` 取 `voice_clone`（10 秒~5 分钟，≤20MB，mp3/m4a/wav）或 `prompt_audio`（<8 秒，小样本增强相似度）。用 `curl --http1.1` 上传，HTTP/2 会出现 `PROTOCOL_ERROR`。

### ⚠️ 通用封装的陷阱

`mcode-tools` 的 `synthesize_speech` 虽然 schema 标了 `additionalProperties: false`，但**未知字段不会被拒绝，而是被静默丢弃**。传 `model: speech-2.8-hd` / `voice_setting` / `audio_setting` 进去，**调用返回成功但参数没生效**，输出永远是 32kHz mono mp3。

实测证据：官方嵌套字段请求与扁平字段请求，产出的 `codec_name` / `sample_rate` / `bitrate` 全部是 `mp3 / 32000 / 128000`；只有 `text` 字段是原样透传的白名单。

**结论**：要做质量判断，必须走官方 API 直连，不要用通用封装。

---

## 1. 为什么不用通用 TTS 封装

通用封装（`mcode-tools` 的 `synthesize_speech` / `batch_text_to_audio`）只暴露
`text / voice_id / emotion / speed / pitch / volume`，**固定 32kHz / 128kbps / mp3 单声道**，
不暴露 model 档位。实测输出为 32kHz mono，语音高频被砍掉，动态被拉平——这是"没质感"的直接技术原因。

官方 T2A v2 API 额外提供下面这些能力，全部与本项目的两个痛点（质感、断句）直接相关：

| 能力 | 参数 | 解决的问题 |
|---|---|---|
| 模型档位 | `model: speech-2.8-hd` / `speech-2.6-hd` / `speech-02-hd` … | 更高自然度与韵律 |
| 高规格音频 | `sample_rate: 44100`、`bitrate: 256000`、`format: flac` | 齿音、气息、清晰度 |
| 情绪档位 | `emotion: happy/sad/angry/fearful/disgusted/surprised/calm/fluent/whisper` | 比通用封装的 7 档多 `calm`/`fluent`/`whisper`；其中 `fluent`/`whisper` 仅 2.6/2.8 可用，**2.8 不支持 `whisper`** |
| **语气词标签** | 文本内插 `(breath)` `(pant)` `(gasps)` `(sighs)` `(inhale)` `(exhale)` `(emm)` … | **仅 `speech-2.8-hd`/`speech-2.8-turbo` 支持**。战斗喘息、闷哼、吸气 |
| **停顿控制** | 文本内插 `<#0.30#>`（秒，0.01~99.99） | **精确控制词间停顿**，取代引擎自带的句号长停顿 |
| 行内发音替换 | `(he2)平`、IPA 音标 | 多音字、项目专名（白垩谷、晶涌、防卫者-9） |
| 发音字典 | `pronunciation_dict.tone` | 专名统一读法 |
| 声音效果器 | `voice_modify.intensity`（力量感）/ `.timbre`（清脆）/ `.pitch` / `.sound_effects` | "刚劲""清脆"的可调旋钮；`sound_effects` 可做无线电通讯音（`lofi_telephone`） |
| 混合音色 | `timbre_weights`（最多 4 个，权重 1~100） | **复合声线，当前唯一可造新音色的手段** |
| 文本归一化 | `text_normalization_mode: basic/quality` | 数字、日期的口语化读法（`quality` 仅 2.6/2.8 非流式支持） |
| 字幕时间戳 | `subtitle_enable` + `subtitle_type: sentence/word` | 句/词级时间戳，可直接驱动游戏字幕 |

---

## 2. 接入地址与鉴权

| 场景 | 地址 |
|---|---|
| HTTP 同步合成（**本项目用这个**） | `https://api.minimax.cn/v1/t2a_v2` |
| HTTP 同步合成（华北优化） | `https://api-bj.minimaxi.com/v1/t2a_v2` |
| WebSocket 流式 | `wss://api.minimax.cn/ws/v1/t2a_v2` |
| 双向流式（大模型对接） | `wss://api.minimax.cn/ws/v1/t2a_v2_bidi` |

请求头：

```
Authorization: Bearer <MINIMAX_API_KEY>
Content-Type: application/json
```

API Key 在 <https://platform.minimax.cn/user-center/basic-information/interface-key> 获取。

> WebSocket 那条链路是给实时播报（按句下发、边合成边播）用的。做游戏资产用 HTTP 即可，
> 一次提交完整文本、拿回完整音频，不需要装 mpv、不需要处理流式分片。

---

## 2.5 混合音色（`timbre_weights`）——当前唯一能造新音色的手段

系统音色只有 303 个，且中文女性音色里没有一条符合本项目的角色规格（详见
[`audio_pipeline.md`](audio_pipeline.md) 第 3 节）。**`timbre_weights` 可以把最多 4 个系统音色按权重融合成一个新音色**，
这是当前账号下唯一可行的"造音色"路径。

### 用法

用 `timbre_weights` 时，**`voice_setting.voice_id` 必须置为空字符串**：

```json
{
  "model": "speech-2.8-hd",
  "text": "我先进去<#0.25#>你压后。跟紧我，别掉队。",
  "voice_setting": {
    "voice_id": "",
    "speed": 1.1,
    "emotion": "angry"
  },
  "timbre_weights": [
    {"voice_id": "Chinese (Mandarin)_Crisp_Girl", "weight": 40},
    {"voice_id": "Arrogant_Miss", "weight": 35},
    {"voice_id": "Chinese (Mandarin)_Warm_Bestie", "weight": 25}
  ],
  "voice_modify": { "intensity": -35, "timbre": 5 }
}
```

- `weight` 取值 1~100，单一音色权重越高越接近该音色
- 最多 4 个音色
- 4 个配比候选在 `tools/tts_lines_benny_blend.json`

### 音色方向速查（取自 `POST /v1/get_voice` 返回的官方描述）

| voice_id | 官方描述 |
|---|---|
| `Chinese (Mandarin)_Crisp_Girl` | 一位温暖清脆的少女声音，标准普通话。 |
| `Chinese (Mandarin)_Warm_Bestie` | 一位温暖清脆的青年女性闺蜜声音，标准普通话，友好而清晰。 |
| `Arrogant_Miss` | 一位嚣张自信的青年女性声音，标准普通话，展现出优越感。 |
| `Chinese (Mandarin)_Stubborn_Friend` | 一位嘴硬心软、不羁的青年竹马声音，标准普通话。 |
| `Chinese (Mandarin)_Soft_Girl` | 一位温暖柔软的青年女性声音，带有南方口音的中文。 |
| `Chinese (Mandarin)_Pure-hearted_Boy` | 一位认真清澈的邻家少年弟弟声音，标准普通话。 |
| `Chinese (Mandarin)_Straightforward_Boy` | 一位认真率真的少年弟弟声音，标准普通话。 |

> 全部 303 个系统音色及其官方描述已导出到 `tools/system_voices.json`，
> 接手时直接查这个文件，不要再调接口拉。

---

## 3. 速率限制

| 账户类型 | T2A v2 RPM | Voice Cloning RPM | Voice Design RPM |
|---|---|---|---|
| 免费用户 | **10** | 60 | 20 |
| 充值用户 | **20** | 60 | 20 |

- 超出时返回 `base_resp.status_code = 1002`（触发限流）或 `1039`（TPM 限流）。
- 客户端脚本默认按 20 RPM 节流（撞限流自动降速、连续成功自动提速）。
- 脚本内置 node 级缓存思路：**同一条台词不要反复重生成**，先在 `_review/` 试听定型再批量产出。
- 如需提速，可按官方指引发邮件 `api@minimax.io` 申请提额（需 3~5 个工作日）。
- **通用 TTS 封装的共享上游限流远比官方严格** —— 实测连续退避重试 30 分钟、7 次尝试仍 0 产出。用自己的 key 走官方 API 才有完整的 10~20 RPM。

---

## 4. 快速开始

```bash
export MINIMAX_API_KEY=sk-xxxxxxxx

# 12 条接线语音
python3 tools/tts_minimax.py tools/tts_lines_benny.json --out Art/audio/sfx/_review --model speech-2.8-hd

# select_01 演绎候选（8 条）
python3 tools/tts_minimax.py tools/tts_lines_benny_audition.json --out Art/audio/sfx/_review --model speech-2.8-hd

# 混合音色候选（4 条）
python3 tools/tts_minimax.py tools/tts_lines_benny_blend.json --out Art/audio/sfx/_review --model speech-2.8-hd

# 音色设计（当前账号返回 2061，需先解锁套餐）
python3 tools/tts_voice_design.py --preset A
```

脚本行为：

- 读取 JSON 清单，逐条调用 `POST /v1/t2a_v2`，把返回的 hex 音频解码写盘；
- 同时写一个同名 `.json` 旁注文件，记录 `duration_ms / sample_rate / bitrate / usage_characters / trace_id`，便于追溯与计费核对；
- 端点自动回退（`api.minimax.cn` ↔ `api-bj.minimaxi.com`）、自适应限速（撞 1002/1039 降速、连续成功提速）；
- 断点续跑：`.tts_cache.json` 记录 node_id，重跑不重复计费；已存在的文件默认跳过（`--force` 覆盖）；
- 语气词标签守卫：模型不是 2.8 时自动剥离标签，避免被当正文念出来；
- 可选 `--normalize` 用 ffmpeg 统一响度到 -16 LUFS（入库前建议开）。

> **审核策略**：本项目要求**一次只生成一条**供人工筛选，别一次刷完整清单。

---

## 4.5 语气词标签全表（仅 `speech-2.8-hd` / `speech-2.8-turbo`）

| 标签 | 含义 | 标签 | 含义 |
|---|---|---|---|
| `(laughs)` | 笑声 | `(sighs)` | 叹气 |
| `(chuckle)` | 轻笑 | `(snorts)` | 喷鼻息 |
| `(coughs)` | 咳嗽 | `(burps)` | 打嗝 |
| `(clear-throat)` | 清嗓子 | `(lip-smacking)` | 咂嘴 |
| `(groans)` | 呻吟 | `(humming)` | 哼唱 |
| `(breath)` | 正常换气 | `(hissing)` | 嘶嘶声 |
| `(pant)` | 喘气 | `(emm)` | 嗯 |
| `(inhale)` | 吸气 | `(whistles)` | 口哨 |
| `(exhale)` | 呼气 | `(sneezes)` | 喷嚏 |
| `(gasps)` | 倒吸气 | `(crying)` | 抽泣 |
| `(sniffs)` | 吸鼻子 | `(applause)` | 鼓掌 |

用法：`"tags": "(pant)"` 等价于在正文前插入该标签。也可以直接写在 `text` 里。

---

## 5. 清单条目字段

```json
{
  "line_id": "voice_benny_cutin_in_01",
  "text": "我先进去<#0.30#>你压后。",
  "voice_id": "Chinese (Mandarin)_Crisp_Girl",
  "speed": 1.1,
  "vol": 1.0,
  "pitch": 0,
  "emotion": "angry",
  "tags": "(breath)",
  "pause_after": 0.2,
  "pronunciation": ["白垩谷/(bai2)(e2)gu3"],
  "voice_modify": { "intensity": -35, "timbre": 8 },
  "timbre_weights": [
    {"voice_id": "Chinese (Mandarin)_Crisp_Girl", "weight": 40},
    {"voice_id": "Arrogant_Miss", "weight": 35}
  ],
  "output": "voice_benny_cutin_in_01.flac"
}
```

| 字段 | 说明 |
|---|---|
| `text` | 正文。可直接内嵌 `<#0.30#>` 停顿标记与 `(breath)` 语气词标签 |
| `tags` | 语气词标签，等价于插在正文前。**仅 `speech-2.8-*` 生效** |
| `pause_after` | 句末追加停顿标记（秒） |
| `pronunciation` | 发音字典 `tone` 数组，格式 `原文/替换` |
| `voice_modify` | 声音效果器：`pitch`(-100~100) / `intensity`(-100~100 力量感) / `timbre`(-100~100 清脆) / `sound_effects` |
| `output` | 输出文件名。扩展名决定实际格式，脚本按 `audio_setting.format` 请求 |
| `sample_rate` / `bitrate` / `format` / `channel` | 覆盖默认音频规格 |
| `timbre_weights` | 混合音色。**用了它 `voice_id` 必须置空**，最多 4 个音色按权重融合 |

### 停顿标记的规则（容易踩坑）

- 标记必须夹在**两段可发音文本之间**，不能放在开头或结尾；
- **不能连续使用多个**停顿标记；
- 标记本身计入计费字符数；
- 放在句末时会被读作断句，所以想要"句中顿一下"要写在句子中间。

例：
- ✅ `我先进去<#0.30#>你压后。` —— 逗号处的 0.3 秒停顿
- ❌ `<#0.3#>我先进去，你压后。` —— 开头无效
- ❌ `我先进去<#0.2#><#0.3#>你压后。` —— 连续标记无效

**实测验证**：同一句「我在这儿，路线我来带。」分别加 `<#0.30#>` 与 `<#0.80#>`，产出时长差为 +0.30s 与 +0.80s 级别，确认标记被引擎真实解析。

---

## 6. 声线选择

系统音色 ID 与通用 TTS 封装返回的列表是**同一套**，可直接复用。查询全部音色：
`POST /v1/get_voice`（见官方 `/api-reference/voice-management-get`），返回体里的 `description` 字段是每个音色的**官方自然语言描述**。

**全部 303 个系统音色及其描述已导出到 `tools/system_voices.json`**，接手时直接查这个文件。

Benny 的选型标准见 [`doc/benny_voice_lines.md`](benny_voice_lines.md) 第 1 节：
年轻女性、清亮有精神、中音区偏亮；不低沉、不沙哑、不做疲惫御姐；不是甜腻萌音。

> ⚠️ **在系统音色里挑不出 Benny**。中文女性音色只有十余条，官方描述无一符合"干练／利落"。
> 详见 [`audio_pipeline.md`](audio_pipeline.md) 第 3 节。要造新音色走 `timbre_weights`。

---

## 7. 产出规格约定

- **采样率 44100 / 比特率 256000 / flac**：flac 无损，Godot 可直接导入（`AudioStreamWAV`）。
  如果要减小包体，可改 `format: mp3` + `bitrate: 256000`。
- **单声道**：角色语音不需要立体声。
- **响度归一**：不同音色/情绪的原始电平差异可达 10 dB。入库前统一处理：
  ```bash
  ffmpeg -i in.flac -af loudnorm=I=-16:TP=-1.5:LRA=11 out.flac
  ```
  或在 Godot 导入时勾选 Normalize。
- **命名**：`voice_<char>_<scene>_<variant>.<ext>`（Benny 为 `voice_benny_<scene>_<variant>`，敌人为 `voice_<art_key>_<scene>_<variant>`），
  与 [`doc/benny_voice_lines.md`](benny_voice_lines.md) 第 2 节的 cue 映射表一一对应。
- **正式路径**：`res://Art/audio/sfx/`；试听阶段落 `res://Art/audio/sfx/_review/`，确认后再转正式文件并接绑定。

---

## 8. 相关文档

| 文档 | 内容 |
|---|---|
| [`audio_pipeline.md`](audio_pipeline.md) | **音频总入口**：现状、三条生产路线、cue 接线现状、可执行命令、待办与阻塞关系、已知坑位 |
| [`benny_voice_lines.md`](benny_voice_lines.md) | 贝妮 104 条台词库 + cue 映射 + 12 条默认语音的演绎参数 |
| [`enemy_voice_lines.md`](enemy_voice_lines.md) | 人形敌人语音：音色方向、6 条受击/倒地中文台词、入场台词待决策 |
| [`benny_vo_brief.md`](benny_vo_brief.md) | 真人配音需求单（可直接交给配音演员） |
