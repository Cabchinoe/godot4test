# AGENTS.md

《辉石之痕：黎明阵线》（Trace of Pyroxene: Dawn Frontline）—— AI 协作者工作约定。

> 本文件是 Agent 在本仓库的**行为约定**，优先级高于任何历史文档里的旧流程描述。
> 项目的技术细节以 `doc/` 下的专项文档为准（索引见 `doc/project.md`）。

---

## 一、多媒体产出物评审规则（最高优先级 · 硬性约束）

> **所有多媒体产出物一律由用户本人评审。Agent 不得自评。**

### 适用范围

图像、音频、音乐（BGM）、音效（SFX）、语音（TTS / 真人录音）、视频、动画、UI 素材 —— **一切多媒体产出物**。不区分是否由 AI 生成、是否入库、是否进入正式目录。

### 具体约束

| | 行为 |
|---|---|
| ❌ | 用模型自评审代替用户判断（如 `audios_understand` 音频打分、`mcode-tools` 图像评分与择优） |
| ❌ | 因为自评分数低就自行丢弃、重做或改稿产出物 |
| ❌ | 替用户决定「哪一版更好」并只交付自选的那一版 |
| ❌ | **用模型音频/视觉理解工具做预筛检测后自行剔除候选**（如 `listen_audio` 转写判人声、`audios_understand` 查缺陷）—— **哪怕是「有/无某缺陷」这种二值判定也不做**。缺陷判定权在用户手里：全部候选一律原样交付，用户自己听出问题再返工。 |
| ✅ | 按需求生成、落盘到约定路径、文件名与规格（格式 / 采样率 / 响度 / 命名）符合规范 |
| ✅ | 做**客观技术体检**：时长、采样率、声道、峰值、削波、静音、循环点连续性、能否被引擎正常加载 |
| ✅ | 把**成品与备选一起交付**，附上客观参数，由用户试听 / 试看后拍板取舍 |
| ✅ | 需要迭代时，先把候选交给用户；按用户反馈再改，不自行脑补方向 |

### 与旧文档的冲突处理

`doc/sfx_asset_manifest.md` §6.5 记录的「模型自评 → 按评审意见精修出定稿」流程，**自本规则起改为「模型只做客观描述与结构标注，取舍由用户拍板」**。§6.5 中关于技术参数与校验手段的部分（ffprobe / volumedetect / loudnorm）仍然有效，不受此规则影响。

---

## 二、项目速览

| 项 | 内容 |
|---|---|
| 类型 | 二次元轻奇幻战棋（SRPG）+ 战区搜打撤 + 基地建设农耕 + 同级物资二合 + 居民援助订单 |
| 基调 | 战后废墟中的生机与救赎；明朗温暖、务实重建，拒绝晦涩谜语人叙事 |
| 引擎 | Godot 4.6（Mobile 渲染管线、Jolt Physics），GDScript |
| 视口 | 1920×1080，`canvas_items` 拉伸；网格瓦片 64×64 |
| 场景流 | `Boot.tscn` → `MainMenu.tscn` → `CommandCenter.tscn` → `Battlefield / Warehouse / TradingPost / Base` |

### 关键目录

| 路径 | 内容 |
|---|---|
| `doc/` | 专项文档。`project.md` 是总纲与索引，`game_design.md` 是企划，`sfx_asset_manifest.md` / `audio_pipeline.md` 管音频 |
| `Script/` | 全部 GDScript |
| `conf/` | 配置（`items/`、`enemies.json`、`levels/`、`battle/sfx_bindings.json`、`audio/ui_sfx.json`） |
| `Art/` | 美术与音频资产（`audio/sfx/`、`audio/bgm/`、`audio/amb/`、`backgrounds/`、`tilesets/`） |
| `tools/` | 音频生产脚本（TTS 客户端、音色设计、台词清单） |
| `openspec/` | 能力规格（`specs/`）与历次变更归档（`changes/archive/`） |

### 约定

- 改玩法 / 数值 / 资产规范时，**同步更新声明依赖它的文档**（`doc/project.md` 有依赖关系说明）。
- 新增能力走 `openspec/changes/<slug>/`（proposal + design + tasks + specs），完成后归档到 `changes/archive/`。
- 音频资产命名与规格以 `doc/sfx_asset_manifest.md` §3 为准；BGM / 环境音走 `Art/audio/bgm/`、`Art/audio/amb/`。
- 素材一律先落 `_review/` 暂存区，人工确认后再转正式目录。

---

## 三、音乐生成（BGM）

> **任何 Agent 工具接 BGM 任务，先读 [`doc/music_generation.md`](doc/music_generation.md)。**
> 那里有完整的 API 地址、请求头 / 请求体 / 响应格式、可直接粘贴的 curl 与 Python 示例、
> prompt 写法模板、入库流水线。本节是入口索引。

```bash
# 官方 API 直连（推荐：prompt 可到 2000 字符，带 is_instrumental 无人声硬开关）
export MINIMAX_API_KEY=sk-xxxx
python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw --direct --to-mp3 --prompt "Instrumental. …"

# Connector 代理（无需密钥：prompt ≤300 字符，单次 ≤5 条，没有 is_instrumental 开关）
python3 tools/music_gen.py --out-dir Art/audio/bgm/_raw --prompt "Instrumental. …" --prompt "Instrumental. …"

# 剪成无缝循环（60~120s）
python3 tools/build_bgm_loop.py --src cand.wav --out out.mp3 --target 90
```

三条铁律（详见 doc）：

1. **人声**：能走官方直连就用 `is_instrumental: true`（硬开关）。只能走代理时，prompt 开头写
   `Instrumental.` 且**全篇不出现 vocals / choir / voice / humming / lyrics** —— 写排除清单反而更容易
   生成人声（实测 3/3 命中，纯正面写法 4/5 干净）。
2. **不预筛**：不跑 `listen_audio` / `audios_understand` 做"有无人声"判定后自行丢弃候选。全部原样交付。
3. **入库规格**：48kHz / 立体声 / MP3 128kbps / -16 LUFS / TP -1.5 dBTP / 零削波 / 60~120s，
   命名 `bgm_<scene>.mp3` 落 `Art/audio/bgm/`，`.import` 的 `loop` 置 `true`。
   改了播放规则要同时改 `doc/sfx_asset_manifest.md` §K、`doc/audio_pipeline.md`、`doc/project.md` 三处。
   例外：`bgm_battlefield` 是用户指定的 34.7s 截取段，**不要**自作主张给它做无缝循环（见 §K.3）。

Mavis / Claude Code 一类读 SKILL.md 的工具，另见 `.minimax/skills/music-generation/`。

---

## 四、常用校验命令

```bash
# 音频客观体检：格式 / 采样率 / 峰值 / 削波
ffprobe -v error -show_entries stream=codec_name,sample_rate,channels -of csv=p=0 <file>
ffmpeg -i <file> -af volumedetect -f null - 2>&1 | grep max_volume

# 入库前统一响度
ffmpeg -i in.flac -af loudnorm=I=-16:TP=-1.5:LRA=11 out.flac

# Godot 无头导入 / 场景冒烟
godot --headless --path . --import
```

---

## 五、提交前自检

- [ ] 多媒体产出物**未经 Agent 自评择优**，成品与备选均已交付用户
- [ ] 客观参数符合 `doc/sfx_asset_manifest.md` §3（采样率 / 声道 / 码率 / 峰值 / 命名 / 路径）
- [ ] 受影响的 `doc/` 文档已同步更新
- [ ] `git status` 无意外产物（暂存区、缓存、评审中间件）
