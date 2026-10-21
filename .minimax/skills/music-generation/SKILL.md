---
name: music-generation
description: |
  Generate, convert and ship BGM for this Godot project with the MiniMax music
  model, covering the official direct API (POST /v1/music_generation, with the
  is_instrumental no-vocals switch) and the mcode-tools Connector proxy, plus
  the wav → MP3 → seamless-loop → Godot-import pipeline. Use this skill when the
  user asks to 生成 BGM / 背景音乐 / 配乐 / 主题曲 / battle music / 战场音乐, when
  re-doing or extending existing BGM, or when turning a music brief into a
  shippable asset under Art/audio/bgm/. Do NOT use it for sound effects
  (doc/sfx_asset_manifest.md), TTS or voice lines, or when the user only wants
  to play/inspect BGM that already exists.
---

# Music Generation

## Inputs to collect

- **用途场景** → 决定 cue key 与规格（启动页 / 指挥中心 / 战场 / 仓库 / 交易行 / 结算）。
- **风格描述** → 配器、调式、速度、情绪、段式。用户给中文描述也行，自己翻成英文。
- **交付形态** → 只试听（不碰 `doc/` 与正式目录）还是正式入库。
- **有没有 API Key** → 决定走哪条通路（见步骤 2）。

## Procedure

1. 读 `doc/music_generation.md`（**API 自足文档：地址 / 请求体 / 响应 / curl / Python / prompt 模板 /
   入库流水线**）、`doc/audio_pipeline.md` 与 `doc/sfx_asset_manifest.md` §K。
   原因：这些是本项目已有的约定，另起一套会让 manifest 与代码对不上。
   顺带确认：**优先复用 §K 里已登记的 cue key**（如 `bgm_battlefield_enemy`），只有当音乐
   定位与已有条目都对不上时才新开一个 key，并在 §K 表格里补一行。

2. **选通路**：
   - 官方直连（`--direct`）**有 `is_instrumental` 硬开关，是治人声的正路** ——
     但**本项目账号实测走不通**（2026-10-21：`sk-cp-` key 在四个域名上全部返回
     HTTP 410 / 2153「Music API is no longer available to new users」，
     付费与免费五个模型全部一样；Connector 那边也证实额外字段会被静默丢弃，
     拿不到 `is_instrumental`）。**别再重试直连，除非用户确认换了有音乐权益的 key。**
   - 所以默认走 **Connector 代理**：prompt 要压到 300 字符内、一次最多 5 条，
     **没有任何无人声开关**，只能靠措辞降低人声率（步骤 3）。
   - 完整诊断记录（错误码、端点、判定方法、开源自建门槛）见 `doc/music_generation.md` §四。

3. 写 prompt：**开头必须是 `Instrumental.`**，之后只正面罗列乐器名与音乐属性。
   prompt 里不要出现 vocals / no vocals / choir / voice / humming / lyrics 这类词。
   原因（实测数据）：把排除清单写进 prompt 反而会"提示"模型 —— 唯一确认带长排除清单的一轮
   3 条全部出"啊"声人声，改成纯正面写法后 5 条里 4 条干净，且那一轮是五轮里唯一被用户接受
   入库的一轮。完整证据与"哪些结论不能外推"见 `references/prompt-recipes.md` §四。
   代价：纯正面仍不是 100% 安全（实测仍有 1/5 命中），所以步骤 4 要多出几条备选。

4. 一次生成 **4~5 条不同侧重的变体**（配器向 / 编曲向 / 质感向 / 混合向…），全部交给用户选。
   原因：模型输出长度随机（15~65s）、音色不稳定，单条命中率低；且项目规则要求成品与备选一起交付。

5. 调用 `tools/music_gen.py`：

   ```bash
   # 官方直连（推荐）
   MINIMAX_API_KEY=sk-xxx python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw \
       --direct --model music-3.0 --to-mp3 --prompt "Instrumental. …"

   # Connector 代理（无密钥，一次最多 5 条）
   python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw \
       --prompt "Instrumental. …" --prompt "Instrumental. …" --to-mp3
   ```

   原因：脚本封装了字符数校验、接口调用、直链下载与重试、客观体检、可选转 MP3 / 剪循环。
   完整参数见 `python3 tools/music_gen.py --help`。

6. 只做客观技术体检（时长 / 峰值 / 削波 / 采样率 / 声道），**不评价音乐内容**。
   原因：`AGENTS.md` 一 —— 多媒体产出物一律由用户评审。Agent 不自评、不打分、不择优，
   也不用 `listen_audio` / `audios_understand` 做"有无人声"这类预筛后自行丢弃候选。
   全部候选原样交付，有没有人声由用户听出来。

7. 用户选定后入库：
   - 转 MP3：`--to-mp3`（48kHz / 立体声 / 128kbps / -16 LUFS / TP -1.5 dBTP）。
     这一步同时消除模型输出的削波（模型普遍顶到 -0.0 dBFS，满幅采样上万）。
   - 需要无缝循环：`--loop 90`，或单独跑
     `python3 tools/build_bgm_loop.py --src <wav> --out <mp3> --target 90`。
   - 命名 `bgm_<scene>.mp3` 落 `Art/audio/bgm/`；同目录 `.import` 的 `loop` 置 `true`。
   - Godot 导入：`/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import`。
   - 接线：`BgmPlayer.play(&"bgm_x")`，要随机就 `BgmPlayer.play_random([&"bgm_a", &"bgm_b"])`
     （见 `Script/audio/bgm_player.gd`）。
   - 同步 `doc/sfx_asset_manifest.md` §K、`doc/audio_pipeline.md` 的现状表，
     **并核对 `doc/project.md` 的场景表** —— 这三处都在描述同一套播放规则，改一处容易漏另两处
     （已发生过一次口径漂移：文档写"战场沿用指挥中心那首"，代码实际是 `BgmPlayer.stop()` 无声）。

## Output contract

- 候选产物：`<out-dir>/cand_*.wav` + `music_gen_manifest.json`
  （`node_id` / 时长 / 峰值 / 削波 / 落盘路径）。
- 交付给用户时给**可播放的文件本体**（`<media>` 标签）＋客观参数表，
  并写清每条在配器 / 编曲 / 质感上的侧重差异。
- 正式成品：`Art/audio/bgm/bgm_<scene>.mp3`，48kHz 立体声 128kbps，-16 LUFS，
  峰值 ≤ -1.5 dBFS，零削波，60~120s。
- 评审暂存区 `Art/audio/bgm/_raw/` 用完即清（该目录已 gitignore）。

## Failure handling

- 接口返回非 0 → 把 `message` / `error` 原样报给用户，不要静默重试。
- `--direct` 报缺 `MINIMAX_API_KEY` → 让用户去
  <https://platform.minimax.cn/user-center/basic-information/interface-key> 取 key，
  不要退回代理通路假装无事发生。
- 官方端点 404 / 401 → 脚本已按 `api.minimax.cn` → `api-bj.minimaxi.com` → `api.minimax.io` 顺序回退；
  全挂则把三端的错误原样报出来。
- `get_asset_url` 偶发失败 → 脚本内置 3 次重试；仍失败则报出 `node_id`，用户可稍后重取直链。
- 候选时长远短于规格 → 照实交付并说明，由用户决定截取还是剪成循环，不要伪造时长。
- 候选出现人声 → 用户会自己听出来并要求返工。优先改用 `--direct` 拿 `is_instrumental` 硬开关；
  只能走代理时改用纯正面写法，而不是堆更多排除清单。
- 候选全部不合口味 → 换个方向重来（调配器 / 调速度 / 换段式 / 换情绪词），
  不要在同一 prompt 上微调措辞后反复重试。

## Examples

Input: 「给战场配一段废弃废墟、荒凉肃寂的弦乐 BGM，纯器乐」

Output: 直连模式下 1 条 prompt 落 `Art/audio/bgm/_raw/`，形如
`Instrumental. Slow adagio 4/4, D minor, 52 BPM. Continuous double bass foundation,
broken mid-low cello melody, off-beat scraped viola bow strokes as rhythmic texture.
ABCA form. Desolate ruined battlefield, somber silent grief.`
（开头 `Instrumental.`，全篇无 vocal 类词，`is_instrumental: true` 由 `--direct` 自动带上），
附 `music_gen_manifest.json` 与客观参数表，附可播放文件本体。用户选定后再转 MP3 并入库。

## Windows (win32) platform notes

- `tools/music_gen.py` 跨平台：只用 Python 标准库，外部依赖 `mcode-tools`（仅代理通路）/
  `ffmpeg` / `curl`（仅代理通路）三个二进制。直连通路只用 Python 标准库 + ffmpeg。
- Windows 上把 `curl` 换成 `curl.exe`（Win10+ 自带），`ffmpeg` 需自行加入 PATH；
  `mcode-tools` 用 `.cmd` 包装时命令写成 `mcode-tools.cmd`。
- 路径含空格时给 `--out-dir` 加引号。

## 环境提示（macOS / Linux）

- `godot` **不在 PATH**，实际路径是 `/Applications/Godot.app/Contents/MacOS/Godot`
  （4.6.3.stable）。导入资源用
  `/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import`。
- `ffmpeg` / `ffprobe` / `mcode-tools` 均已在 PATH。
- `MINIMAX_API_KEY` **当前未设置** → 官方直连通路需要用户先提供 key。
