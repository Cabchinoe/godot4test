# MiniMax T2A v2 语音合成接入指南

> 面向《辉石之痕：黎明阵线》的角色语音资产生产。
> 依据官方文档整理：<https://platform.minimax.cn/docs/guides/speech-t2a-websocket>、<https://platform.minimax.cn/docs/api-reference/speech-t2a-http>、<https://platform.minimax.cn/docs/guides/rate-limits>
> 客户端脚本：`tools/tts_minimax.py`

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
| 情绪档位 | `emotion: happy/sad/angry/fearful/disgusted/surprised/calm/fluent/whisper` | 比通用封装的 7 档多 `calm`/`fluent`/`whisper`；其中 `fluent`/`whisper` 仅 2.6/2.8 可用 |
| **语气词标签** | 文本内插 `(breath)` `(pant)` `(gasps)` `(sighs)` `(inhale)` `(exhale)` `(emm)` … | **仅 `speech-2.8-hd`/`speech-2.8-turbo` 支持**。战斗喘息、闷哼、吸气 |
| **停顿控制** | 文本内插 `<#0.30#>`（秒，0.01~99.99） | **精确控制词间停顿**，取代引擎自带的句号长停顿 |
| 行内发音替换 | `(he2)平`、IPA 音标 | 多音字、项目专名（白垩谷、晶涌、防卫者-9） |
| 发音字典 | `pronunciation_dict.tone` | 专名统一读法 |
| 声音效果器 | `voice_modify.intensity`（力量感）/ `.timbre`（清脆）/ `.pitch` | "刚劲""清脆"的可调旋钮 |
| 混合音色 | `timbre_weights`（最多 4 个，权重 1~100） | 复合声线 |
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

## 3. 速率限制

| 账户类型 | T2A v2 RPM | Voice Cloning RPM | Voice Design RPM |
|---|---|---|---|
| 免费用户 | **10** | 60 | 20 |
| 充值用户 | **20** | 60 | 20 |

- 超出时返回 `base_resp.status_code = 1002`（触发限流）或 `1039`（TPM 限流）。
- 客户端脚本默认按 8 RPM 节流，并对 1002/1039 做阶梯退避重试。
- 脚本内置 node 级缓存思路：**同一条台词不要反复重生成**，先在 `_review/` 试听定型再批量产出。
- 如需提速，可按官方指引发邮件 `api@minimax.io` 申请提额（需 3~5 个工作日）。

---

## 4. 快速开始

```bash
export MINIMAX_API_KEY=sk-xxxxxxxx

# 生成 Benny 的 12 条接线语音到试听目录
python3 tools/tts_minimax.py tools/tts_lines_benny.json --out Art/audio/sfx/_review

# 换更高档模型重出（2.8 支持语气词标签）
python3 tools/tts_minimax.py tools/tts_lines_benny.json --out Art/audio/sfx/_review \
    --model speech-2.8-hd --force
```

脚本行为：

- 读取 JSON 清单，逐条调用 `POST /v1/t2a_v2`，把返回的 hex 音频解码写盘；
- 同时写一个同名 `.json` 旁注文件，记录 `duration_ms / sample_rate / bitrate / usage_characters / trace_id`，便于追溯与计费核对；
- 已存在的文件默认跳过（`--force` 可覆盖）；
- 遇到 1002/1039 自动退避重试同一请求。

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
  "voice_modify": { "intensity": 20, "timbre": 10 },
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

### 停顿标记的规则（容易踩坑）

- 标记必须夹在**两段可发音文本之间**，不能放在开头或结尾；
- **不能连续使用多个**停顿标记；
- 标记本身计入计费字符数；
- 放在句末时会被读作断句，所以想要"句中顿一下"要写在句子中间。

例：
- ✅ `我先进去<#0.30#>你压后。` —— 逗号处的 0.3 秒停顿
- ❌ `<#0.3#>我先进去，你压后。` —— 开头无效
- ❌ `我先进去<#0.2#><#0.3#>你压后。` —— 连续标记无效

---

## 6. 声线选择

系统音色 ID 与通用 TTS 封装返回的列表是**同一套**，可直接复用。查询全部音色：
`GET /v1/get_voice`（见官方 `/api-reference/voice-management-get`）。

Benny 的选型标准见 [`doc/benny_voice_lines.md`](benny_voice_lines.md) 第 1 节：
年轻女性、清亮有精神、中音区偏亮；不低沉、不沙哑、不做疲惫御姐；不是甜腻萌音。

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
- **命名**：`voice_benny_<scene>_<variant>.<ext>`，与 `doc/benny_voice_lines.md` 第 2 节的 cue 映射表一一对应。
- **正式路径**：`res://Art/audio/sfx/`；试听阶段落 `res://Art/audio/sfx/_review/`，确认后再转正式文件并接绑定。
