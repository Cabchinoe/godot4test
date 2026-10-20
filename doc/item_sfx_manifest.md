# 道具音效需求(精简版)

> 版本 v2.10(2026-10-20)
> 只保留两类：**道具绑定音效**、**场景动作绑定音效**。
> 角色台词(含 `voice_heal`、居民订单 TTS)见 `doc/benny_voice_lines.md` 等角色语音文档。
> 未列出的物品统一使用默认拾取兜底，不再逐项展开。
> 专属拾取覆盖不计入主清单的 86 个有效 cue，作为 item-bound 变体单独管理。

---

## 1. 道具绑定

### 1.1 默认拾取兜底

```text
default.item_pickup -> sfx_item_pickup
```

所有物品默认走这一条。只有下表物品覆盖为专属拾取音。

### 1.2 拾取专属覆盖

| 物品 ID | 专属 cue | 说明 |
|---|---|---|
| `collectible_badge_01` | `sfx_pickup_badge` | 荣誉徽章，金属亮响 |
| `weapon_benny_dawn_pulse` | `sfx_pickup_energy_weapon` | 辉石能量武器，可选专属 |
| `attachment_benny_resonance_core_01` | `sfx_pickup_resonance_core` | 共鸣核心，晶能轻鸣 |
| `material_crystal_purification_core_08` | `sfx_pickup_crystal_core` | 晶能净化核心，大型晶簇感 |
| `material_seed_pack_01` | `sfx_pickup_seed_pack` | 种子袋，纸袋 + 种子沙沙 |

未列出的武器、护甲、头盔、背包、配件、消耗品、材料、订单品全部使用 `sfx_item_pickup`。

### 1.3 物品类型 → 音效

| 物品类型 | 音效 |
|---|---|
| 武器 | 拾取默认；装备 `sfx_equip_weapon`；开火按武器已有 cue |
| 护甲 / 头盔 / 背包 | 拾取默认；穿 / 脱 / 丢弃统一 `sfx_equip_gear` |
| 武器配件 | 拾取默认；安装 / 拆卸统一 `sfx_attachment_install` / `sfx_attachment_remove` |
| 医疗消耗品 | 拾取默认；使用按物品 `heal_sfx`(7 个医疗物品各一条)；生效后 `voice_heal` |
| 食物 / AP 消耗品 | 拾取默认；使用按物品 `use_sfx`(当前压缩口粮 / 强化野战餐 / 热量餐包各一条) |
| 材料 | 拾取默认；二合 `sfx_item_merge` |
| 收藏品 / 订单品 | 拾取默认或专属覆盖；交易 / 交付走场景动作 |

### 1.4 消耗品绑定

| 物品 ID | 名称 | 分类 | 战斗效果 | 绑定音效 |
|---|---|---|---|---|
| `consumable_dried_medicine_02` | 干燥药包 | 医疗 | 恢复 8 HP | `sfx_heal_tick_consumable_dried_medicine_02` ✅ + `voice_heal` |
| `consumable_debridement_dressing_03` | 清创敷料 | 医疗 | 清除全部流血 | `sfx_heal_tick_consumable_debridement_dressing_03` ✅ + `voice_heal` |
| `consumable_sterile_bandage_04` | 无菌绷带组 | 医疗 | 处理骨折 | `sfx_heal_tick_consumable_sterile_bandage_04` ✅ + `voice_heal` |
| `consumable_medkit_01` | 急救包 | 医疗 | 恢复 40 HP，移除 1 层流血 | `sfx_heal_tick_consumable_medkit_01` ✅ + `voice_heal` |
| `consumable_field_medical_case_06` | 战地医疗箱 | 医疗 | 恢复 80 HP，处理骨折 | `sfx_heal_tick_consumable_field_medical_case_06` ✅ + `voice_heal` |
| `consumable_trauma_kit_07` | 创伤处理包 | 医疗 | 恢复 100 HP，移除流血 + 骨折 | `sfx_heal_tick_consumable_trauma_kit_07` ✅ + `voice_heal` |
| `consumable_frontline_rescue_08` | 前线救援套件 | 医疗 | 回满 HP，清除流血 + 骨折 | `sfx_heal_tick_consumable_frontline_rescue_08` ✅ + `voice_heal` |
| `consumable_adrenaline_01` | 肾上腺素 | 刺激剂 / AP | 恢复 2 AP | `sfx_item_adrenaline` ✅ |
| `consumable_compressed_ration_04` | 压缩口粮 | 食物 / AP | 恢复 2 AP | `sfx_item_use_consumable_compressed_ration_04` ✅ |
| `consumable_field_meal_06` | 强化野战餐 | 食物 / AP | 恢复 3 AP | `sfx_item_use_consumable_field_meal_06` ✅ |
| `consumable_calorie_meal_05` | 热量餐包 | 食物 / AP | 恢复 3 AP | `sfx_item_use_consumable_calorie_meal_05` ✅ |

> 当前代码的 `_is_medical_item()` 只认 `heal` / `heal_full` / `remove_statuses` / `remove_status_stacks`；肾上腺素只有 `restore_ap`，不会触发 `sfx_heal_tick` 或 `voice_heal`。若要做专属注射音，需要另接 `sfx_item_adrenaline`。
>
> **v2.1 B1 收录**:三个食物/AP 物品改为物品级 `use_sfx` 字段(写在 `conf/items/consumable.json`),分别落盘三条 mp3;`sfx_item_use` 保留为语义族名,不再对应单一文件。肾上腺素仍走 `sfx_item_adrenaline`(可选,待生产)。
>
> **v2.2 B2 口径**:医疗使用音同样按物品绑定,7 个医疗物品各搜一条 `heal_sfx`;`sfx_heal_tick` 保留为语义族名,不再对应单一通用文件。候选按物品分别落 `_review/`。
>
> **v2.3 B2 收录**:`consumable_dried_medicine_02` / `consumable_debridement_dressing_03` / `consumable_sterile_bandage_04` 三条 `heal_sfx` 已落盘;其余 4 个医疗物品仍待搜。
>
> **v2.4 B2 收录**:`consumable_frontline_rescue_08` 使用 `ECG sim ×6 @1.5×` 落盘;医疗 `heal_sfx` 完成 4/7,剩余急救包 / 战地医疗箱 / 创伤处理包。
>
> **v2.5 B2 医疗收尾**:急救包 / 战地医疗箱 / 创伤处理包三条 `heal_sfx` 落盘;肾上腺素 `sfx_item_adrenaline` 落盘。医疗 `heal_sfx` 完成 7/7。
>
> **v2.6**:`consumable_sterile_bandage_04` 改为两段绷带缠绕 x2(120ms 间隔);`sfx_item_merge` 正在重做更干净的“咚”。
>
> **v2.7**:`sfx_item_merge` 定稿为脆叮(C5 523.25Hz 基础音 + 高频泛音 + 短起振),成品 0.400s;按半音表移调后实际音区 C5~C6。
>
> **v2.8**:`sfx_item_merge` 整体降八度定稿,基础音回到 C4 261.63Hz,实际音区 C4~C5;成品 0.395s。
>
> **v2.9**:二合预制成 8 个文件 `sfx_item_merge_lv1~lv8.mp3`,对应 C4 / D4 / E4 / F4 / G4 / A4 / B4 / C5。
>
> **v2.10**:追加备用 Lv9 D5 / Lv10 E5,二合共预制 10 个变体。

---

## 2. 场景动作绑定

| 场景 / 动作 | cue | 规则 |
|---|---|---|
| 任意物品拾取 | `sfx_item_pickup` | 有专属拾取则覆盖，否则用默认 |
| 头甲背包穿 / 脱 / 物品丢弃 | `sfx_equip_gear` | 全部共用同一个音效 |
| 武器装备 | `sfx_equip_weapon` | 与头甲背包分开 |
| 武器配件安装 | `sfx_attachment_install` | 所有配件共用 |
| 武器配件拆卸 | `sfx_attachment_remove` | 所有配件共用 |
| 非医疗消耗品使用 | 物品 `use_sfx` | 食物 / 口粮 / 热量餐包各一条；肾上腺素仍走 `sfx_item_adrenaline` |
| 医疗消耗品使用 | 物品 `heal_sfx` | 7 个医疗物品各一条；生效后另接 `voice_heal` |
| 二合成功 | `sfx_item_merge` | 按产出等级选 C 大调音高 |
| 容器开启 | `sfx_container_open` | 只保留开箱，不做 search / empty 独立音 |
| 进入商店 | `sfx_shop_open` | 推门铃 + 商贩招呼 |
| 商店购买成功 | `sfx_shop_buy` | 交易行 |
| 信用点不足 | `sfx_ui_error` | 复用错误音，不新建 insufficient cue |
| 居民订单接取 / 交付 | 居民角色 TTS | 后续生成，不占 SFX |

**不再作为通用 SFX**：`sfx_drag_start`、`sfx_drag_drop`、`sfx_inventory_sort`、`sfx_container_search`、`sfx_container_empty`、`sfx_shop_insufficient`。`sfx_quest_accept` / `sfx_quest_turn_in` 改为居民角色 TTS。

> `sfx_equip_gear` 替代旧的 `sfx_item_discard` / `sfx_unequip` / `sfx_equip_armor`；不要再分别建 cue。

---

## 3. 二合音高

`sfx_item_merge` 已预制 10 个变体；播放时按**产出等级**直接选对应文件(Lv9~Lv10 备用)。

公式：`MIDI = 60 + [0, 2, 4, 5, 7, 9, 11, 12][level - 1]`。

> 当前成品 `sfx_item_merge.mp3` 的基础音为 **C4(261.63Hz)**,实际音区为 C4~C5,与上式一致。

| 等级 | 音名 | MIDI | 文件 |
|---:|---|---:|---|
| 1 | C4 | 60 | `sfx_item_merge_lv1.mp3` |
| 2 | D4 | 62 | `sfx_item_merge_lv2.mp3` |
| 3 | E4 | 64 | `sfx_item_merge_lv3.mp3` |
| 4 | F4 | 65 | `sfx_item_merge_lv4.mp3` |
| 5 | G4 | 67 | `sfx_item_merge_lv5.mp3` |
| 6 | A4 | 69 | `sfx_item_merge_lv6.mp3` |
| 7 | B4 | 71 | `sfx_item_merge_lv7.mp3` |
| 8 | C5 | 72 | `sfx_item_merge_lv8.mp3` |
| 9 | D5 | 74 | `sfx_item_merge_lv9.mp3`(备用) |
| 10 | E5 | 76 | `sfx_item_merge_lv10.mp3`(备用) |

| 产出等级 | 音名 | MIDI |
|---|---|---:|
| Lv1 | C4（中央 C） | 60 |
| Lv2 | D4 | 62 |
| Lv3 | E4 | 64 |
| Lv4 | F4 | 65 |
| Lv5 | G4 | 67 |
| Lv6 | A4 | 69 |
| Lv7 | B4 | 71 |
| Lv8 | C5 | 72 |

---

## 4. 生产状态

### 4.1 已落盘(B1 + B2 通用项,2026-10-20)

| cue / 物品 | 正式文件 | 来源 | 时长 | 授权 |
|---|---|---|---:|---|
| `sfx_item_pickup` | `sfx_item_pickup.mp3` | Freesound loganzsound `Deep Click` | 0.190s | CC0 |
| `sfx_equip_gear` | `sfx_equip_gear.mp3` | Freesound brandondelehoy `Jacket/Cloth Rustle 7` | 0.604s | CC0 |
| `sfx_equip_weapon` | `sfx_equip_weapon.mp3` | Freesound BaggoNotes `Rifle_Equip1` | 0.416s | CC0 |
| `sfx_attachment_install` | `sfx_attachment_install.mp3` | Freesound smill.and.welson `G3 Bolt Slap (2)` | 0.348s | CC-BY 4.0 |
| `sfx_attachment_remove` | `sfx_attachment_remove.mp3` | Freesound smill.and.welson `Stoner 63 Mag Out` | 0.710s | CC-BY 4.0 |
| `sfx_item_merge` | `sfx_item_merge_lv1~lv10.mp3` | C4 脆叮 → C 大调 10 级预制(Lv9~Lv10 备用) | 0.358~0.395s | 自制 |
| `consumable_dried_medicine_02` | `sfx_heal_tick_consumable_dried_medicine_02.mp3` | Freesound AvillivA `Pills_1` | 0.543s | CC0 |
| `consumable_debridement_dressing_03` | `sfx_heal_tick_consumable_debridement_dressing_03.mp3` | Freesound SecureSubset `Tape Bandages Rip` | 0.813s | CC0 |
| `consumable_sterile_bandage_04` | `sfx_heal_tick_consumable_sterile_bandage_04.mp3` | Freesound Frostnox `Bandage Wrap Heal 1` ×2(120ms 间隔) | 1.164s | CC-BY 4.0 |
| `consumable_frontline_rescue_08` | `sfx_heal_tick_consumable_frontline_rescue_08.mp3` | Freesound univ_lyon3 `ECG sim` ×6 @1.5× | 2.383s | CC0 |
| `consumable_medkit_01` | `sfx_heal_tick_consumable_medkit_01.mp3` | `Box Latch` + Water Squirt 后 50% ×3 @0.75× 降 4 半音 | 2.048s | CC0 |
| `consumable_field_medical_case_06` | `sfx_heal_tick_consumable_field_medical_case_06.mp3` | `Box Latch` + 绷带撕开 | 1.130s | CC0 |
| `consumable_trauma_kit_07` | `sfx_heal_tick_consumable_trauma_kit_07.mp3` | `Zipper Zipping` + Water Squirt 后 50% ×3 @0.75× 降 4 半音 | 2.098s | CC0 / CC-BY 4.0 |
| `consumable_adrenaline_01` | `sfx_item_adrenaline.mp3` | Water Squirt 后 50% ×3 @0.75× 降 4 半音 | 1.548s | CC0 |
| `consumable_compressed_ration_04` | `sfx_item_use_consumable_compressed_ration_04.mp3` | Freesound ImmergoMedia `PlasticScrunch05` | 0.592s | CC0 |
| `consumable_field_meal_06` | `sfx_item_use_consumable_field_meal_06.mp3` | Freesound fleurescence `opening a cap` | 0.388s | CC0 |
| `consumable_calorie_meal_05` | `sfx_item_use_consumable_calorie_meal_05.mp3` | Sonilo `Snack Wrapper Tear Open` | 0.511s | Sonilo Library License |

> 全部 48kHz / 单声道 / MP3 96kbps,尾部 30ms 淡出。`sfx_equip_gear` 0.604s 超出 0.25~0.45s 目标,按选定候选原长保留。Sonilo 免费账号为 10 MP3/月、需署名、仅自有社交频道;游戏/商业使用需付费计划。

### 4.2 待生产

- `sfx_shop_open` / `sfx_shop_buy`
- `sfx_bleed_tick`(可选)
- `sfx_pickup_badge` / `sfx_pickup_energy_weapon` / `sfx_pickup_resonance_core` / `sfx_pickup_crystal_core` / `sfx_pickup_seed_pack`(可选专属拾取)

### 4.3 B2 完成

B2 全部完成:4 个通用 cue + 7 个医疗 `heal_sfx` + 肾上腺素。

### 4.4 B2 医疗复合方案(已落盘)

可复用片段:卡扣打开 / 硬箱开启 / 拉链打开 / 缠绷带 / 注射 / 心电滴滴。

- `consumable_medkit_01` 急救包 = 卡扣打开 + 注射针剂
- `consumable_field_medical_case_06` 战地医疗箱 = 硬箱开启 + 缠绷带
- `consumable_trauma_kit_07` 创伤处理包 = 拉链打开 + 注射针剂
- `consumable_frontline_rescue_08` 前线救援套件 = 心电滴滴(可加短卡扣)
- `sfx_item_adrenaline` = 注射针剂

> 按当前候选原长拼接约 0.9~1.2s;若要压到 0.6s 以内,拼接时裁短各片段。
>
> **最终配方(2026-10-20)**:急救包 = `Box Latch` + `Water Squirt` 后 50% ×3 @0.75× 降 4 半音;战地医疗箱 = `Box Latch` + 绷带撕开;创伤处理包 = `Zipper Zipping` + 同款注射;前线救援套件 = `ECG sim ×6 @1.5×`;肾上腺素 = 同款注射单独使用。

