# 战场敌人与容器美术资产清单

> 本清单面向下一批 AI 生成与导入。运行时规格遵循 `Art/tilesets/urban_night/README.md`、`manifest.json` 与本项目的 Urban Night 风格；所有资产必须先交付高分辨率母版，再导出运行时 PNG。

## 1. 已有资产审计

| 类别 | 现有文件 | 尺寸 | 可直接用于搜索状态 | 处理结论 |
| --- | --- | ---: | --- | --- |
| 补给箱关闭 | `Art/tilesets/urban_night/props/containers/supply_crate_closed_a.png` | 64×64 | 是 | 已被地图容器与敌人战利品箱复用。 |
| 补给箱开启 | `Art/tilesets/urban_night/props/containers/supply_crate_open_a.png` | 64×64 | 是 | 与关闭态构图、占格一致，可直接切换。 |
| 医疗柜关闭 | `Art/tilesets/urban_night/props/containers/medical_locker_closed_a.png` | 128×128 | 否 | 缺少开启/掏空态；可见绿色抠像残留，需要从 `medical_locker_master_01.png` 重新抠底导出。 |
| 垃圾桶 | `Art/tilesets/urban_night/props/containers/trash_bin_a.png` | 64×64 | 否 | 缺少翻盖/掏空态。 |
| 售货机 | `Art/tilesets/urban_night/props/containers/vending_machine_a.png` | 64×64 | 否 | 缺少破门/空机态。 |
| 高金属架 | `Art/tilesets/urban_night/props/furniture/metal_shelf_tall_a.png` | 64×128 | 否 | 可作为可搜索家具底图，缺少翻倒/搜空态。 |
| 冰箱 | `Art/tilesets/urban_night/props/furniture/refrigerator_a.png` | 64×64 | 否 | 可作为食物容器底图，缺少开门/空置态。 |
| 车辆、床、沙发、台面 | `Art/tilesets/urban_night/props/...` | 64×64～128×192 | 否 | 目前只作为场景障碍；除非补齐明确开闭态，否则不设为可搜索容器。 |

母版现状：医疗柜、废弃轿车为 1024×1024；现有敌人原始图为 1024×1024（`eagle_soldier_raw_01.png`），精修母版为 512×512（`eagle_soldier_master_01.png`）。新批次统一提升到 1024px 母版，避免后续重做时细节不足。

## 2. 统一交付规范

### 2.1 战场敌人

- **唯一视角基准**：敌人必须以 `Art/characters/benny/benny_idle.png`、`benny_walk.png`、`benny_aim.png` 与 `benny_sprites.tres` 为唯一运行时视角、朝向、比例和锚点基准。敌人和贝妮必须像站在同一张战场平面上，不能使用严格 90° 顶视、等距视角或其他独立角度。
- **镜头与构图**：采用与贝妮一致的正面偏 3/4 战场小人角度：脸部、胸前、双手与手持武器可见，脚部朝画布下方；不是立绘式大透视，也不是只看头顶的俯视图。敌人站姿、头身比例和占格高度必须与贝妮一致。
- **母版**：1024×1024 PNG，纯 `#00FF00` 绿幕；无地面、投影、文字、Logo 或黑边。
- **运行时**：每帧透明底 `64×80` PNG，角色底部锚点与贝妮一致，至少留 6px 安全边距。首批图集至少交付 `idle` 4 帧、`walk` 6 帧；如需瞄准动画则交付 `aim` 4 帧，帧数与 `benny_sprites.tres` 对齐。
- **轮廓**：深海军蓝、湿混凝土灰、低饱和墨绿为主体；琥珀工程灯作功能点；敌对威胁只用小面积橙红；辉石单位才可使用紫青 / 冰青发光。
- **技术检查**：去绿边、无半透明地面阴影；将敌人与贝妮帧并排叠放检查头高、脚底、武器高度和画面朝向。生成后必须检查脚、武器、肢体是否完整。

### 2.2 容器与家具

- **64×64 小型容器**：生成 1024×1024 绿幕母版，导出透明 64×64。相同容器的关闭/开启/搜空三态必须共用相同镜头、占格、轮廓与锚点。
- **128×128 / 64×128 大型容器**：生成 1024×1024 绿幕母版，运行时保持对应 footprint；禁止缩成 64×64。
- **严格描述**：`camera directly overhead; show only upward-facing surfaces; no front, side, underside, floor plane, or cast shadow`。
- **导入路径**：母版存 `Art/source/urban_night/<group>/`；运行时存 `Art/tilesets/urban_night/props/<group>/`；更新 atlas、`manifest.json` 与 TileSet 区域后才可在关卡引用。

## 3. 敌人重设计清单

当前 `conf/enemies.json` 已有数值和 `art_key`，但全部临时复用 `eagle_soldier_sprites.tres`。下表为需要生成的独立战场图集。

| 优先级 | art_key / 敌人 | 视觉描述 | 剪影锚点 | 数值身份 |
| --- | --- | --- | --- | --- |
| P0 | `raider_infantry` / 街区掠夺兵 | 湿旧雨披、拼装胸甲、短卡宾枪、背包外挂杂物；深蓝灰主色与橙红臂带。 | 宽肩、斜挎枪、矩形旧背包。 | 70 HP、4 AP 的中程压制基线。 |
| P0 | `raider_scout` / 斥候掠夺者 | 窄身连帽雨披、简易呼吸面罩、折叠冲锋枪、腿侧信号弹；橄榄灰+冷青反光条。 | 细长、前倾、长兜帽。 | 58 HP、5 AP、高闪避的侧翼单位。 |
| P1 | `raider_bulwark` / 护盾掠夺者 | 拆解防暴盾、厚重拼接护甲、短管霰弹枪；煤灰+黄色警示条。 | 最大矩形盾面、短粗身形。 | 110 HP、30 护甲、低机动。 |
| P1 | `pyroxene_hound` / 辉石猎犬 | 四足机械晶兽，石墨装甲缝隙长出紫青晶体，前爪为切割刃。 | 低矮四足、背脊晶簇。 | 6 AP、近战、流血威胁。 |
| P1 | `pyroxene_sentry` / 晶涌哨戒机 | 悬浮/三足小型哨戒单元，圆形传感器、侧置能量发射器、晶体散热鳍。 | 单眼核心、三角或三足底盘。 | 6 射程、辉石灼蚀远程单位。 |

每个敌人需要：`<art_key>_idle.png`、`<art_key>_walk.png`、`<art_key>_sprites.tres`；导入后将对应 `sprite_frames_path` 从占位路径替换为该 `.tres`。

## 4. 容器美术待生成列表

### P0：运行时必需

| ID / 文件目标 | 规格 | 关闭态描述 | 开启 / 搜空态描述 |
| --- | --- | --- | --- |
| `medical_locker_open_a.png` | 128×128 | 复用现有暗绿战地医疗柜；红十字仅作小型磨损贴纸，不使用文字。 | 顶视柜门拉开，内部可见 2～3 个暗色隔板与少量医疗盒，保持 2×2 footprint。 |
| `medical_locker_empty_a.png` | 128×128 | — | 柜门半开、隔板空置，避免地面与投影；用于已搜索状态。 |
| `trash_bin_closed_a.png` | 64×64 | 深灰金属垃圾桶，盖板闭合，少量雨水污渍。 | 作为现有 `trash_bin_a` 的重命名/统一版本。 |
| `trash_bin_open_a.png` | 64×64 | — | 盖板翻开，能看到低饱和杂物袋；轮廓仍只占一格。 |
| `trash_bin_empty_a.png` | 64×64 | — | 盖板半开、内部空置；与关闭态视角和锚点一致。 |
| `vending_machine_breached_a.png` | 64×64 | — | 现有售货机被撬开，玻璃破口、取货槽外翻、无发光文字；橙色紧急灯仅一小点。 |
| `vending_machine_empty_a.png` | 64×64 | — | 货格空置 / 显示屏熄灭，仍保持可识别售货机轮廓。 |

### P1：扩大地图搜索密度

| ID / 文件目标 | 规格 | 描述 |
| --- | --- | --- |
| `metal_shelf_searched_a.png` | 64×128 | 现有高金属架的搜空态：纸箱被翻开、货架空两层；不要散落到地面。 |
| `refrigerator_open_a.png` | 64×64 | 顶视冰箱门向侧面打开，露出空格架和少量冷凝水；为食物容器。 |
| `refrigerator_empty_a.png` | 64×64 | 门微开、内部空置；与关闭态严格同占格。 |
| `tool_case_closed_a.png` / `tool_case_open_a.png` | 各 64×64 | 新增低值工程工具箱，深蓝灰硬壳、琥珀色封签；开态可见扳手与线缆轮廓。 |
| `ammo_crate_closed_a.png` / `ammo_crate_open_a.png` | 各 64×64 | 新增军备箱，橄榄灰金属、橙红危险贴纸；开态内是模块化弹匣/零件，避免真实品牌标志。 |
| `field_cache_closed_a.png` / `field_cache_open_a.png` | 各 64×64 | 布质野战包与防水封条，适合放置医疗、食物或织物物资。 |

### AI 生成提示骨架

```
original tactical-anime 2D game prop, [物体描述], camera directly overhead,
strict 90-degree top-down orthographic, one centered object, [64x64 或 footprint],
wet urban-night extraction palette: navy, slate, concrete gray, restrained amber practical light,
flat exact #00FF00 chroma-key background, no ground plane, no cast shadow, no text, no logo,
no isometric, no three-quarter perspective, no cinematic lighting, no border
```

## 5. 导入验收

1. 透明运行时 PNG 的尺寸、锚点和关闭/开启状态完全一致。
2. 补给箱关闭 / 开启 / 搜空三态在同一 TileMap cell 中无跳动。
3. 医疗柜等大容器的动态障碍 footprint 与视觉 footprint 一致后，才允许配置到关卡。
4. 生成文件导入后，更新 `Art/tilesets/urban_night/manifest.json`、相关 atlas 与对应 TileSet。
5. 将新敌人帧打成 `SpriteFrames` 后，与贝妮 `64×80` 帧并排放入战场截图，验证脚底锚点、朝向、比例、颜色对比和可读性。

## 6. 可直接交给外部 AI 的重制提示词

### 6.1 通用材质前缀与负面约束

每条提示词都应保留下列技术要求，并把输出先作为 1024×1024 母版保存：

```text
Original tactical-anime 2D game asset for an original urban-night extraction game,
crisp readable silhouette,
restrained navy, slate, wet concrete gray and muted olive palette, subtle amber practical lights,
small red accents only for hostile danger, cyan-violet glow only on pyroxene technology.
Flat exact #00FF00 chroma-key background, one centered subject, no text, no logo, no watermark,
no ground plane, no cast shadow, no reflection, no border.
Negative prompt: isometric, cinematic scene, floor, backdrop, dramatic cast shadow,
photorealism, 3D render, UI text.
```

### 6.2 敌人专用视角前缀

每个敌人提示词必须额外附带以下段落；生成时应同时提供贝妮运行时帧作为视觉参考。

```text
Match the exact runtime battle-sprite camera, facing direction, character scale, bottom anchor,
and front three-quarter chibi-proportioned presentation of the supplied Benny sprite-sheet reference.
Use a 64x80 per-frame target: face, chest, hands, and held weapon remain visible;
feet point toward the bottom of the frame. The enemy must look like it stands beside Benny
on the same tactical battlefield. Do not use strict overhead top-down, isometric, side view,
or a different camera angle.
```

### 6.3 敌人图集

生成每个敌人的 `idle`、`walk` 与可选 `aim` 动作参考；最终导出透明底 `64×80`，`idle` 为 4 帧、`walk` 为 6 帧、`aim` 为 4 帧，所有帧共享贝妮同款锚点和占格。

**街区掠夺兵（`raider_infantry`）**

```text
[Use the common material prefix and the enemy camera prefix.]
Battle sprite of a street raider infantryman: worn rain poncho, pieced-together chest armor,
short compact carbine held across the torso, rectangular scavenger backpack with loose utility straps,
wide shoulders and clear carbine silhouette, navy-gray clothing, faded orange-red armband.
Single full body, centered, designed to read beside Benny at 64x80 pixels.
```

**斥候掠夺者（`raider_scout`）**

```text
[Use the common material prefix and the enemy camera prefix.]
Battle sprite of a fast raider scout: narrow hooded rain cape, improvised respirator mask,
folding SMG, small signal flare pouch on thigh, slim forward-leaning silhouette,
muted olive-gray cloth with thin cold-cyan reflective strip, no bulky shield or backpack.
Single full body, centered, designed to read beside Benny at 64x80 pixels.
```

**护盾掠夺者（`raider_bulwark`）**

```text
[Use the common material prefix and the enemy camera prefix.]
Battle sprite of a heavy raider bulwark: large salvaged rectangular riot shield,
thick patchwork armor, short shotgun tucked behind the shield, short broad body,
charcoal gray materials with weathered amber-yellow safety stripe, clear shield-first silhouette.
Single full body, centered, designed to read beside Benny at 64x80 pixels.
```

**辉石猎犬（`pyroxene_hound`）**

```text
[Use the common material prefix and the enemy camera prefix.]
Battle sprite of a four-legged pyroxene hound: low mechanical beast,
graphite armor plates split by small cyan-violet crystal growths, cutting foreclaws,
low stance, long spine with asymmetric crystal cluster, no human anatomy.
Single creature, centered, designed to read beside Benny at 64x80 pixels.
```

**晶涌哨戒机（`pyroxene_sentry`）**

```text
[Use the common material prefix and the enemy camera prefix.]
Battle sprite of a compact pyroxene sentry machine: triangular three-leg chassis,
single circular sensor eye, side-mounted energy emitter, cyan-violet crystal cooling fins,
small amber maintenance indicator, readable mechanical silhouette, no text.
Single machine, centered, designed to read beside Benny at 64x80 pixels.
```

### 6.3 容器与丢弃物

**补给箱三态（关闭 / 开启 / 搜空）**

```text
[Use the common material prefix. Add a strict top-down orthographic camera for this container.]
Create a matched set of three strict top-down 64x64 supply crate states:
1) closed hard military supply crate with dark slate metal, muted olive panels and a small amber seal;
2) the exact same crate open, lid hinged back, showing a few generic dark supply modules;
3) the exact same crate searched empty, open lid and empty interior.
All three states must have identical camera, footprint, scale and anchor.
```

**医疗柜三态（关闭 / 开启 / 搜空）**

```text
[Use the common material prefix. Add a strict top-down orthographic camera for this container.]
Create a matched set of three strict top-down 128x128 field medical locker states:
dark green battered metal cabinet, two-by-two tile footprint, subtle worn medical cross marking with no text.
1) doors closed; 2) doors open, showing 2 or 3 dark shelves and generic medical cases;
3) doors half open with empty shelves.
All states must keep exactly the same 128x128 footprint, scale and anchor.
```

**垃圾桶三态（关闭 / 开启 / 搜空）**

```text
[Use the common material prefix. Add a strict top-down orthographic camera for this container.]
Create a matched set of three strict top-down 64x64 metal trash bin states:
dark gray wet urban trash bin with hinged lid and small rain stains.
1) lid closed; 2) lid open with a few muted junk bags visible;
3) lid half open with an empty interior.
No loose trash on the ground. Identical camera, footprint, scale and anchor.
```

**售货机三态（完整 / 撬开 / 搜空）**

```text
[Use the common material prefix. Add a strict top-down orthographic camera for this container.]
Create a matched set of three strict top-down 64x64 compact vending machine states:
old dark teal vending machine, no readable brand or text, small amber maintenance light.
1) sealed intact front; 2) pried-open door and broken pickup flap, a few generic supplies visible;
3) pried-open empty machine, unlit display and empty slots.
Identical camera, footprint, scale and anchor.
```

**地面丢弃物（新增）**

```text
[Use the common technical prefix.]
Strict top-down 64x64 loose discarded loot pile for a tactical game:
one small dark canvas field pouch, one folded muted textile roll, one generic metal component,
compact pile contained within one grid, readable from directly overhead, no weapons, no text,
no visible ground plane and no cast shadow. The pile must be small enough that a character can stand on the same cell.
```
