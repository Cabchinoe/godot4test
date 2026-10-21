# Prompt 写法模板与实测证据

> 接口地址 / 请求体 / 响应格式 / 入库流水线 → 看 [`doc/music_generation.md`](../../../doc/music_generation.md)（全 Agent 通用）。
> 本文只放**怎么写 prompt**、**实测结论**、**字符压缩技巧**。

## 一、两条通路的 prompt 差异

| | Connector 代理 | 官方直连（`--direct`） |
|---|---|---|
| 长度上限 | **300 字符** | **2000 字符** |
| 无人声开关 | 无 | `is_instrumental: true`（硬开关） |
| 写多长合适 | 压到 260 以内留余量 | 可以写满，把配器 / 速度 / 调式 / 段式 / 混音 / 排除项全写清 |

**有密钥就直接 `--direct`**：`is_instrumental` 才是治人声的根，prompt 措辞只是绕。

## 二、模板

> `[x]` 是可替换槽位。

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

**调式词表**：`D minor` / `A Dorian` / `D Phrygian` / `C major` …
色彩小调写 Dorian / Phrygian / Aeolian，比单纯 minor 好控。

## 三、字符压缩（Connector 300 字符时必读）

1. 删冠词：`a melodic` → `melodic`
2. 排除清单斜杠紧凑：`no vocals, no choir, no humming` → `no vocals/choir/humming`
3. 编曲描述只写一次，别四个 section 各写一遍配器
4. 乐器表控制在 5~7 项
5. 混音词压成 3~4 个：`wide mix, tight low end, controlled cymbals`
6. 砍的顺序：编曲细节 → 次要乐器 → 情绪形容词 → 场景描述（最后才砍）

## 四、人声陷阱：实测五轮（Connector 通路）

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

### 写法对照

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
`tense`）比风格标签有效；需要排除时只写风格词。

### 评审规则

`AGENTS.md` 一：**多媒体产出物一律由用户本人评审，Agent 不得自评。**
不跑 `listen_audio` / `audios_understand` 做"有无人声"预筛后自行丢弃候选（哪怕二值判定也不行）。
全部候选原样交付 + 客观参数，缺陷判定权在用户手里。

## 五、模型的已知行为

| 现象 | 实测 | 应对 |
|---|---|---|
| 输出时长随机 | 14.9s ~ 65.2s | 不达标时 `--loop` 或手工截取，由用户定 |
| 尾部带 fade-out | 多数版本尾部 1~2.5s 渐隐 | `build_bgm_loop.py` 会自动裁掉 |
| 输出削波 | 峰值普遍 -0.0 dBFS，满幅采样 5 ~ 78k 个 | loudnorm（TP -1.5）消除；prompt 写 `no clipping` 无效 |
| 语种偏英文 | 英文 prompt 命中率明显高于中文 | 中文描述先自行翻译 |
| 有时冒人声 | Connector 通路实测 1/5 | 走直连用 `is_instrumental: true`；否则按 §四 写法 |
