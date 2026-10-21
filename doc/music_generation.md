# 音乐生成 API · 请求方法

> 本文是**自足的 API 说明书**：任何 Agent 工具（Codex / Claude Code / Mavis / Cursor…）读完这一篇
> 就能直接调接口生成 BGM，不依赖任何 skill 加载。
> 配套封装脚本：`tools/music_gen.py`（`--direct` 走官方直连，不带参数走 Connector 代理）。
> 行为约定（评审规则、入库流程）见 [audio_pipeline.md](audio_pipeline.md) 与
> [sfx_asset_manifest.md](sfx_asset_manifest.md) §K。

---

## 一、两条通路，先选哪条

| | **A · Connector 代理**（默认） | **B · 官方 API 直连**（推荐） |
|---|---|---|
| 端点 | `mcode-tools connector call connector__matrix__batch_text_to_music` | `POST https://api.minimax.cn/v1/music_generation` |
| 鉴权 | 宿主托管（`mcode-tools auth status` 可见状态，不暴露 token） | `Authorization: Bearer $MINIMAX_API_KEY` |
| 前置条件 | 无需密钥 | 需环境变量 `MINIMAX_API_KEY` |
| prompt 长度 | **≤ 300 字符** | **1 ~ 2000 字符** |
| 无人声开关 | ❌ **没有**（只能靠 prompt 措辞绕） | ✅ **`is_instrumental: true`** |
| 模型选择 | ❌ 不可选 | ✅ `music-3.0` / `music-2.6` / … |
| 单次条数 | ≤ 5 | 1（要多条自己循环） |
| 产物形态 | 返回 `node_id`，再换直链下载 | 返回体里直接带音频（hex） |

**怎么选**：
- 有 `MINIMAX_API_KEY` → **走 B**。`is_instrumental` 是硬开关，能治"一直出现人声吟唱"这个病根。
- 没有密钥 → 走 A。此时必须靠 prompt 写法降低人声率（见 §六），且 prompt 要压到 300 字符内。

---

## 二、通路 B · 官方 API 直连（推荐）

### 端点

```
POST https://api.minimax.cn/v1/music_generation        # 国内
POST https://api-bj.minimaxi.com/v1/music_generation   # 华北
POST https://api.minimax.io/v1/music_generation        # 国际
```

官方文档：<https://platform.minimax.io/docs/api-reference/music-generation>

### 请求头

```
Authorization: Bearer <MINIMAX_API_KEY>
Content-Type: application/json
```

### 请求体

```json
{
  "model": "music-3.0",
  "prompt": "Instrumental. Slow adagio 4/4, D minor, 52 BPM. Continuous double bass foundation, broken mid-low cello melody, off-beat scraped viola bow strokes. ABCA form. Desolate ruined battlefield, somber silent grief.",
  "is_instrumental": true,
  "audio_setting": {
    "sample_rate": 44100,
    "bitrate": 256000,
    "format": "wav"
  }
}
```

| 字段 | 类型 | 说明 |
|---|---|---|
| `model` | string | `music-3.0`（推荐）/ `music-2.6` / `music-cover` / `music-3.0-free` / `music-2.6-free` / `music-cover-free` |
| `prompt` | string | **器乐时必填，1~2000 字符**；非器乐时 0~2000。写风格 / 情绪 / 场景 |
| `is_instrumental` | bool | **无人声硬开关**。`true` 时 `lyrics` 字段不需要；`false`（默认）时模型会自己写词并唱 |
| `lyrics` | string | 器乐时不需要；非器乐时 10~1000 字符 |
| `lyrics_optimizer` | bool | 仅 `music-3.0` / `music-2.6` 系列支持。`true` 且 `lyrics` 为空时自动按 prompt 生成歌词 |
| `audio_setting.sample_rate` | int | 官方支持 32000 / 44100（48000 见下） |
| `audio_setting.bitrate` | int | 128000 / 256000 |
| `audio_setting.format` | string | `mp3` / `wav` |

### 响应

```json
{
  "data": {
    "audio": "hex-encoded audio data",
    "status": 2
  },
  "trace_id": "04ede0ab069fb1ba8be5156a24b1e081",
  "extra_info": {
    "music_duration": 25364,
    "music_sample_rate": 44100,
    "music_channel": 2,
    "bitrate": 256000,
    "music_size": 813651
  },
  "base_resp": { "status_code": 0, "status_msg": "success" }
}
```

- **`data.audio` 是 hex 编码**，落盘前要解码：`bytes.fromhex(data["data"]["audio"])`。
- `data.status == 2` 表示完成。
- `base_resp.status_code != 0` 就是失败，看 `status_msg`。

### curl 示例（可直接粘）

```bash
curl -X POST https://api.minimax.cn/v1/music_generation \
  -H "Authorization: Bearer $MINIMAX_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "music-3.0",
    "prompt": "Instrumental. Slow adagio 4/4, D minor, 52 BPM. Continuous double bass foundation, broken mid-low cello melody, off-beat scraped viola bow strokes. ABCA form. Desolate ruined battlefield, somber silent grief.",
    "is_instrumental": true,
    "audio_setting": {"sample_rate": 44100, "bitrate": 256000, "format": "wav"}
  }' \
  | python3 -c "import sys,json,pathlib; d=json.load(sys.stdin); pathlib.Path('out.wav').write_bytes(bytes.fromhex(d['data']['audio']))"
```

### Python 示例（只用标准库）

```python
import json, os, urllib.request

url = "https://api.minimax.cn/v1/music_generation"
payload = {
    "model": "music-3.0",
    "prompt": "Instrumental. ...",
    "is_instrumental": True,
    "audio_setting": {"sample_rate": 44100, "bitrate": 256000, "format": "wav"},
}
req = urllib.request.Request(
    url, data=json.dumps(payload).encode(), method="POST",
    headers={"Authorization": f"Bearer {os.environ['MINIMAX_API_KEY']}",
             "Content-Type": "application/json"},
)
with urllib.request.urlopen(req, timeout=300) as r:
    d = json.loads(r.read())
open("out.wav", "wb").write(bytes.fromhex(d["data"]["audio"]))
```

### 脚本封装（推荐，别自己重写）

```bash
export MINIMAX_API_KEY=sk-xxxx
python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw \
    --direct --model music-3.0 --to-mp3 \
    --prompt "Instrumental. …"
```

`--direct` 模式下：prompt 长度放宽到 2000、`is_instrumental` 默认 `true`
（要出人声加 `--with-lyrics`）、自动做端点回退、自动落盘 + 客观体检。

---

## 三、通路 A · Connector 代理（无密钥时用）

### 3.1 生成

```bash
mcode-tools connector call connector__matrix__batch_text_to_music --args-file args.json
```

`args.json`：

```json
{ "requests": [{
    "prompt":      "…",           // 必填，10~300 字符
    "lyrics":      "…",           // 可选，10~600；**纯器乐必须整个省略**
    "format":      "wav",         // wav | mp3（无 PCM）
    "sample_rate": 44100,         // 16000 | 24000 | 32000 | 44100（无 48000）
    "bitrate":     256000,        // 32000 | 64000 | 128000 | 256000
    "output_file": "cand_01.wav"  // 下载基础文件名，目录部分被忽略
} ] }                            // 单次 1~5 条
```

返回：

```json
{ "code": 0, "message": "ok",
  "total_requested": 3, "total_success": 3, "total_failed": 0,
  "success_items": [{ "node_id": "454656776917236", "file_name": "cand_01.wav" }],
  "failed_items": [] }
```

### 3.2 下载

产物是 Matrix Drive 节点，要换直链：

```bash
mcode-tools get_asset_url <node_id>
# → {"node_id":"...","download_url":"https://matrix-internal-cn.oss-cn-shanghai.aliyuncs.com/..."}
curl -sL "<download_url>" -o cand_01.wav
```

`get_asset_url` 偶发失败，重试即可。

### 3.3 脚本封装

```bash
python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw \
    --prompt "Instrumental. …" --prompt "Instrumental. …" \
    [--to-mp3] [--loop 90]
```

自动做：300 字符校验 → 调 Connector → 换直链下载（带重试）→ 客观体检 → 可选转 MP3 / 剪循环。

### 3.4 这个 Connector 的真实限制（踩过的坑）

| 限制 | 事实 |
|---|---|
| `prompt` ≤ 300 字符 | 硬限制，超了整条请求被拒 |
| 单次 ≤ 5 条 | 硬限制 |
| **没有 `is_instrumental`** | 只能靠 prompt 措辞降低人声率 → 见 §六 |
| 没有 `model` 选择 | 不知道底层是 music-2.6 还是 3.0 |
| `sample_rate` 无 48000 | 项目规格要 48kHz，得自己 ffmpeg 转 |
| `format` 无 PCM | PCM 承载不了 AIGC 元数据 |
| 产物时长随机 15~65s | 达不到项目 60~120s 规格，要剪循环 |
| 产物普遍削波 | 峰值顶到 -0.0 dBFS，入库前必须过 loudnorm |

---

## 四、限流与账号策略（2026-10-21 核实）

| 项 | 值 |
|---|---|
| 付费模型限流 | `music-3.0` / `music-2.6` / `music-cover` = **120 RPM** |
| 免费模型限流 | `music-3.0-free` / `music-2.6-free` / `music-cover-free` = 3 RPM |
| **2026-08-20 起** | 付费的 Music Generation / Lyrics Generation **不再对新用户开放**，存量付费用户可继续用 |
| **2026-08-20 起** | 免费版 `music-3.0-free` / `music-2.6-free` / `music-cover-free` **已下线** |
| 替代方案 | ① MiniMax Audio 产品页 ② 开源 MiniMax Music 3（HuggingFace `MiniMaxAI/MiniMax-Music3`） |

> 官方文档原话：*"Starting August 20, 2026, the paid APIs (Music Generation and Lyrics Generation)
> will no longer be available to new users; existing paying users can continue to use the current
> API services. The free music generation APIs (Music-3.0-free, Music-2.6-free, music-cover-free)
> will be discontinued."*

**本项目账号实测（2026-10-21）**：用本项目 `MINIMAX_API_KEY`（`sk-cp-` 开头）实测 ——

| 端点 | 结果 |
|---|---|
| `api.minimax.cn/v1/music_generation` | **HTTP 410 / 2153** |
| `api-bj.minimaxi.com/v1/music_generation` | **HTTP 410 / 2153** |
| `api.minimax.io/v1/music_generation` | 2049 invalid api key（`sk-cp-` 是国内 key，国际站不认） |
| `api.minimax.chat/v1/music_generation`（老域名） | **HTTP 410 / 2153** |

返回体：

```json
{"base_resp":{"status_code":2153,"status_msg":"This Music API is no longer available to new
 users. Existing paying customers can continue to use the service. For new access, please try
 MiniMax Audio (https://www.minimax.io/audio) or the open-source model at
 https://huggingface.co/MiniMaxAI/MiniMax-Music3"},"trace_id":"..."}
```

**结论**：key 本身有效（走到业务层判定才被拒，不是鉴权失败），但**这个账号被判定为音乐 API 的
新用户**，付费模型（`music-3.0` / `music-2.6` / `music-cover`）和免费模型（`music-3.0-free` /
`music-2.6-free` / `music-cover-free`）**五个模型全部返回同样的 2153**。

**要开通直连，需要账号本身具备音乐 API 权益**（官方口径是"存量付费客户"）：去
<https://platform.minimax.cn/user-center/basic-information> 看套餐是否包含音乐生成，
或用 MiniMax Audio 产品页（<https://www.minimax.io/audio>）。

> ⚠️ 换 URL 没用 —— 四个域名都试过了。
> **本项目当前只有通路 A（Connector 代理）可用。**

### Connector 不透传额外字段（实测）

Connector 的 schema 写着 `additionalProperties: false`，但**实际传 `is_instrumental` / `model`
不会报错，而是被静默丢弃**。零成本判定法：

```bash
# 传一个不存在的 model 名 —— 成功 = 字段被丢弃；报错 = 字段被透传
mcode-tools connector call connector__matrix__batch_text_to_music --args-file <含 model:"music-nonexistent-probe-xyz" 的 json>
```

实测：**成功** → 额外字段一律被剥离。
**所以 Connector 通路拿不到 `is_instrumental` 硬开关，只能靠 prompt 措辞降低人声率。**

### 开源自建路径（硬件门槛高）

官方 2153 错误指向 <https://huggingface.co/MiniMaxAI/MiniMax-Music3>（MiniMax Music 3.0 开源权重）：

| 项 | 情况 |
|---|---|
| 许可 | MiniMax Music 3.0 Community License，**允许商用**（需署名；营收超 2000 万美元需单独协议） |
| 官方参考部署 | **2 × A100 40GB**（GPU0 跑 Qwen3 + RVQ，GPU1 跑 Flow Matching + 波形解码），SGLang-Omni |
| 最低配置 | 逐层流式 **8GB 显存 + 32GB 内存**（很慢）；CPU 卸载 ~22GB；全精度 <24GB（RTX 4090） |
| 显存不足时 | ComfyUI 0.33.0+ 有现成工作流 |
| 输出 | 44.1kHz 立体声 PCM-16 WAV（diffusers 路径）／32kHz 立体声 WAV（SGLang 路径） |
| 本机可用性 | ❌ **Apple Silicon 无 NVIDIA CUDA，本地跑不了**；需要另找带 NVIDIA 卡的机器 |

---

## 五、Prompt 怎么写

### 5.1 模板

> 全部 ≤ 2000 字符（通路 B）。`[x]` 是可替换槽位。

**A · 配器最全型**
```
Instrumental. [genre] BGM, [scene]. [主奏乐器], [和声乐器], [低音], [打击], [质感层].
[BPM], [调式], [动机描述]. [情绪词]. [混音词].
```

**B · 编曲结构型**
```
Instrumental. [genre] BGM, [scene]. [BPM], [调式], [动机].
[段1]: [a]. [段2]: [b]. [段3]: [c]. [段4]: [d]. [情绪]. [混音].
```

**C · 质感织体型**
```
Instrumental. [genre] BGM, [scene]. [质感层专门描述]. [BPM], [调式], [动机]. [情绪]. [空间/混音].
```

**D · 排除清单型**（只写风格词，**不写人声词**）
```
Instrumental. [genre] BGM, [scene]. [配器]. [BPM], [调式], [动机]. [情绪]. No [风格词1]/[风格词2].
```

### 5.2 调式词表

`D minor` / `A Dorian` / `D Phrygian` / `C major` …
色彩小调写 Dorian / Phrygian / Aeolian，比单纯 minor 更好控。

### 5.3 字符压缩（通路 A 必读）

1. 删冠词：`a melodic` → `melodic`
2. 排除清单斜杠紧凑：`no vocals, no choir, no humming` → `no vocals/choir/humming`
3. 编曲描述只写一次，别四个 section 各写一遍配器
4. 乐器表控制在 5~7 项
5. 混音词压成 3~4 个：`wide mix, tight low end, controlled cymbals`
6. 砍的顺序：编曲细节 → 次要乐器 → 情绪形容词 → 场景描述（最后才砍）

---

## 六、人声陷阱（**必读**）

**先说结论**：能走通路 B 就一定要走 —— `is_instrumental: true` 是硬开关。
通路 A 只能靠 prompt 措辞降低概率。

### 6.1 实测五轮（通路 A，Connector）

| 轮次 | prompt 写法 | 条数 | 结果 |
|---|---|---|---|
| 1 黎明废墟 | 无前缀 + 长排除清单 | 3 | 用户判定全部不可用（**未逐条查人声**，原因未确认） |
| 2 敌方推进 | 无前缀 + 长排除清单 | 3 | **用户确认 3/3 全部带"啊"声人声** → 全部废弃 |
| 3 敌方推进 v2 | `Instrumental.` + 纯正面 4 条 / 带排除 1 条 | 5 | 转写检测 **4/5 干净**；用户选定 2 条，已入库为 `bgm_boot_a` / `bgm_boot_b` |
| 4 战场反攻 | `Instrumental.` + 纯正面 | 5 | 用户判定全部不可用（**未做检测**，原因未确认） |
| 5 废墟弦乐 | `Instrumental.` + 纯正面 2 条 / 带排除 3 条 | 5 | 用户判定全部不可用（**未做检测**，原因未确认） |

**能站得住的结论**（不要外推）：

- 唯一确认「带长排除清单 → 出人声」的数据点是第 2 轮（3/3）；同一轮风格改成 `Instrumental.` +
  纯正面后（第 3 轮）转写检测 4/5 干净，且**这一轮是五轮里唯一被用户接受并入库的一轮**。
- 第 4、5 轮被废弃的原因**未经检测确认**。不能据此说 `Instrumental.` 写法对人声无效，
  也不能说它对音乐质量有效。
- 纯正面**不是 100% 安全**（第 3 轮仍 1/5 命中）。一次出 4~5 条、全量交付、让用户挑。

### 6.2 写法对照

```
❌ 触发吟唱概率高
"Instrumental. Dark hybrid electronic BGM, ruined industrial zone. No vocals,
 no choir, no humming, no lyrics, no vocal pads. Pulsing analog bass, …"

✅ 触发吟唱概率低
"Instrumental. Dark hybrid electronic BGM, ruined industrial zone. Pulsing
 analog bass, granular metal texture, string ostinato, muted brass, industrial
 percussion, alarm synth. 76 BPM, D Phrygian, 3-note motif. Cold tense, wide mix."
```

要点：`Instrumental.` 放最前；乐器名写具体（`staccato strings` / `bowed viola` /
`analog synth arpeggio`），别写抽象的 `orchestral`；情绪词（`desolate` / `mournful` /
`tense`）比风格标签有效。

### 6.3 评审规则（不可绕过）

`AGENTS.md` 一：**多媒体产出物一律由用户本人评审，Agent 不得自评。**
- ❌ 跑 `listen_audio` / `audios_understand` 做"有无人声"预筛后**自行丢弃候选**（哪怕二值判定）
- ✅ 全部候选原样交付，附客观参数（时长 / 峰值 / 削波 / 采样率 / 声道）
- 缺陷判定权在用户手里

---

## 七、从生成到入库（完整流水线）

```bash
# 1) 生成 + 落盘
python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw --prompt "…" --prompt "…"

# 2a) 入库规格 MP3（顺带消除削波）
python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw --prompt "…" --to-mp3
# 或对已有 wav 手工转：
ffmpeg -i cand.wav -af loudnorm=I=-16:TP=-1.5:LRA=11 -ar 48000 -ac 2 \
       -c:a libmp3lame -b:a 128k out.mp3

# 2b) 无缝循环（60~120s）
python3 tools/build_bgm_loop.py --src cand.wav --out out.mp3 --target 90
#   内部：包络检测正文区间 → 首尾等功率交叉淡化 → 重复到目标时长 → R128 两遍归一
#   --start / --end 手工指定正文区间；--crossfade 调淡化秒数
#   接缝检测不通过时自动修复：旋转到低能量切点 + 文件级首尾交叉淡化后重新编码选优
#   （--seam-trials 调候选切点数；--no-seam-fix 关闭）

# 3) 落正式目录 + Godot 导入
cp out.mp3 Art/audio/bgm/bgm_<scene>.mp3
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
#   然后把 .import 里的 loop=false 改成 true（运行时 BgmPlayer 也会再设一次，双保险）

# 4) 接线
#   BgmPlayer.play(&"bgm_<scene>")              固定
#   BgmPlayer.play_random([&"a", &"b"])          随机选一首（缺文件自动剔除）
#   场景侧：Boot._ready() / MainMenu._ready() 等显式声明

# 5) 同步文档
#   doc/sfx_asset_manifest.md §K（cue 表 / 播放规则表 / 制作方式）
#   doc/audio_pipeline.md（现状表 + 已知坑）
#   doc/project.md（场景表的 BGM 口径 —— 三处都要改）
```

### 入库规格

48kHz / 立体声 / MP3 128kbps / -16 LUFS / TP -1.5 dBTP / 峰值 ≤ -1.5 dBFS / 零削波 / 60~120s

### 命名与目录

| 类型 | 路径 | 命名 |
|---|---|---|
| BGM 正式 | `res://Art/audio/bgm/` | `bgm_<scene>.mp3` |
| 评审暂存 | `res://Art/audio/bgm/_raw/` | 同上，定稿后清理（已 gitignore） |

优先复用 `sfx_asset_manifest.md` §K 里**已登记的 cue key**；定位对不上才新开，并在 §K 表格补一行。

---

## 八、模型的已知行为

| 现象 | 实测 | 应对 |
|---|---|---|
| 输出时长随机 | 14.9s ~ 65.2s | 不达标时 `--loop` 或手工截取，由用户定 |
| 尾部带 fade-out | 多数版本尾部 1~2.5s 渐隐 | `build_bgm_loop.py` 会自动裁掉 |
| 输出削波 | 峰值普遍 -0.0 dBFS，满幅采样 5 ~ 78k 个 | loudnorm（TP -1.5）消除；prompt 写 `no clipping` 无效 |
| 语种偏英文 | 英文 prompt 命中率明显高于中文 | 中文描述先自行翻译 |
| 有时冒人声 | 通路 A 实测 1/5 | 通路 B 用 `is_instrumental: true`；通路 A 走 §6.2 写法 |

---

## 九、同一 Connector 里的其他工具

| 工具 | 用途 | 本项目限制 |
|---|---|---|
| `connector__matrix__listen_audio` | 音频转写 | **不用于预筛候选**（`AGENTS.md` 一） |
| `connector__matrix__audios_understand` | 音频问答 | **不用于预筛候选**（`AGENTS.md` 一） |
| `mcode-tools upload_temp_url <file>` | 本地文件传临时直链 | 给上面两个工具用；偶发失败需重试 |
| `connector__matrix__batch_text_to_audio` / `synthesize_speech` | TTS | 语音走 `tools/tts_minimax.py`，见 [minimax_tts_guide.md](minimax_tts_guide.md) |

TTS 与音乐是两条独立管线，别混用。
