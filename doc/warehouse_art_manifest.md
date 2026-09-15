# 仓库资源与图标美术清单

## 1. 当前可入仓物品

所有物品**均可在仓库与背包内部流转**(装备栏另议);背包容量是唯一的携行上限。装备栏保留原始 4 槽位设计(weapon / backpack / armor / helmet),**不可**作为通用存储。货币不能带入对局,因此既不占仓库格也不占背包容量。当前配置共 **11 项**入仓物品(基础材料 + 战术消耗品 + 携行装备 + 武器 + 配件 + 收藏品中**未进入二合树**的部分),加上二合树节点、Lv0 原料与战场物资包后，首轮图标目录共 **95 项**。

| 仓库分区 | 物品 | ID | 主要用途 / 解锁 | 战场携带属性 | 战场效果 ID | 交易行单价 | 图标目标路径 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 基础材料 | 基础种子包 | `material_seed_pack_01` | 允许玩家重启温室循环，但不提供指定稀有作物 | 否 | — | 35 | `res://Items/icons/material/material_seed_pack_01.png` |
| 战术消耗品 | 肾上腺素 | `consumable_adrenaline_01` | 对局中可恢复行动力 | 是 | `restore_action_points` | — | `res://Items/icons/consumable/consumable_adrenaline_01.png` |
| 携行装备 | 基础背包 | `backpack_basic_01` | Lv1 背包，提供基础携行格，4x4空间 | 否（装入 `backpack` 槽） | — | — | `res://Items/icons/backpack/backpack_basic_01.png` |
| 武器 | 防卫者-9 | `weapon_benny_defender_9` | 贝妮 tier-1 初始武器，9mm 紧凑 SMG | 否（装入 `weapon` 槽） | — | — | `res://Items/icons/weapon/weapon_benny_defender_9.png` |
| 武器 | 野兔跳跃者 | `weapon_benny_hare_hopper` | 贝妮 tier-2 中阶武器，战术 SMG + 全息瞄准 | 否（装入 `weapon` 槽） | — | — | `res://Items/icons/weapon/weapon_benny_hare_hopper.png` |
| 武器 | 黎明初霁 | `weapon_benny_dawn_pulse` | 贝妮 tier-3 高阶武器，高频脉冲 SMG；仅配共鸣核心槽位 | 否（装入 `weapon` 槽） | — | — | `res://Items/icons/weapon/weapon_benny_dawn_pulse.png` |
| 枪械配件 | 反射瞄具 | `attachment_reflex_sight_01` | SCOPE 槽配件，提高中距离瞄准 | 否（绑定武器） | — | — | `res://Items/icons/weapon_attachment/attachment_reflex_sight_01.png` |
| 枪械配件 | 线性补偿器 | `attachment_compensator_01` | BARREL 槽配件，降低连续射击偏移 | 否（绑定武器） | — | — | `res://Items/icons/weapon_attachment/attachment_compensator_01.png` |
| 枪械配件 | 轻型伸缩枪托 | `attachment_light_stock_01` | STOCK 槽配件，改善移动射击 | 否（绑定武器） | — | — | `res://Items/icons/weapon_attachment/attachment_light_stock_01.png` |
| 枪械配件 | 晨辉共鸣核心 | `attachment_benny_resonance_core_01` | RESONANCE_CORE 槽配件，仅黎明初霁可用 | 否（绑定武器） | — | — | `res://Items/icons/weapon_attachment/attachment_benny_resonance_core_01.png` |
| 收藏品 | 荣誉徽章 | `collectible_badge_01` | 用于收藏、剧情或订单 | 否 | — | — | `res://Items/icons/collectible/collectible_badge_01.png` |

## 2. 二合树与 Lv0 原料图标（54 项）

下表的物品全部应进入仓库，且可装入背包(占背包容量)。每条记录附带「主要用途」「战场携带属性」「战场效果 ID」「交易行单价」4 列 — 这些列的来源是 `crafting_design.md` 第三节与第六节的字段，以及本次审阅补全。表格按谱系分组列出，每个谱系包含一条「起始档位」标注（如护甲/头盔树的最基础件）以及 Lv0–Lv8 二合树节点。

| 谱系 | 等级 | 物品 | 主要用途 / 解锁 | 战场携带属性 | 战场效果 ID | 交易行单价 | 规划 ID | 图标目标路径 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 织物 | 起始档位 | — | — | — | — | — | — | — |
| 织物 | Lv0 | 破损纤维 | 极低概率在野生纤维类残骸中获得 | 否 | — | — | `material_frayed_fiber_00` | `res://Items/icons/material/material_frayed_fiber_00.png` |
| 织物 | Lv1 | 纺织线 | 支持"线→布→背包/作业服"的早期体验 | 否 | — | 18 | `material_textile_thread_01` | `res://Items/icons/material/material_textile_thread_01.png` |
| 织物 | Lv2 | 加捻线束 | 强化纺织线，纤维方向一致 | 否 | — | — | `material_twisted_thread_02` | `res://Items/icons/material/material_twisted_thread_02.png` |
| 织物 | Lv3 | 粗织布 | 第一次有可作为建筑结构材料的成品 | 否 | — | — | `material_coarse_cloth_03` | `res://Items/icons/material/material_coarse_cloth_03.png` |
| 织物 | Lv4 | 密织布包 | 修补轻度受损的掩体或临时路障，4x5空间 | 是 | `repair_cover_small` | — | `material_dense_fabric_pack_04` | `res://Items/icons/material/material_dense_fabric_pack_04.png` |
| 织物 | Lv5 | 耐磨帆布包 | 修补中度受损掩体，适合长线撤离，4x6空间 | 是 | `repair_cover_medium` | — | `material_durable_canvas_pack_05` | `res://Items/icons/material/material_durable_canvas_pack_05.png` |
| 织物 | Lv6 | 模块化背包主体 | 介于常规背包与远征背包之间的中级携行件，5x6空间 | 否（装入 `backpack` 槽） | — | — | `backpack_modular_frame_06` | `res://Items/icons/backpack/backpack_modular_frame_06.png` |
| 织物 | Lv7 | 远征背包 | 提高本局撤离物资携行上限，6x6空间 | 是 | `increase_carry_capacity` | — | `backpack_expedition_07` | `res://Items/icons/backpack/backpack_expedition_07.png` |
| 织物 | Lv8 | 战术作业背包 | 重型战术作业背包，本局最大携行上限，并提供抗污染过滤 | 是 | `increase_carry_capacity_max` | — | `backpack_tactical_pack_08` | `res://Items/icons/backpack/backpack_tactical_pack_08.png` |
| 食物 | 起始档位 | — | — | — | — | — | — | — |
| 食物 | Lv0 | 损耗作物 | 残次品，几乎无用 | 否 | — | — | `material_spoiled_crop_00` | `res://Items/icons/material/material_spoiled_crop_00.png` |
| 食物 | Lv1 | 赤浆果 | 防止基础食物链被单一掉落卡住 | 否 | — | — | `consumable_red_berry_01` | `res://Items/icons/consumable/consumable_red_berry_01.png` |
| 食物 | Lv2 | 清洗果盒 | 第一次可长期保存的食物成品 | 否 | — | — | `consumable_clean_fruit_box_02` | `res://Items/icons/consumable/consumable_clean_fruit_box_02.png` |
| 食物 | Lv3 | 晒干果脯 | 长期保存的食物成品 | 是 | `restore_stamina_small` | — | `consumable_dried_fruit_03` | `res://Items/icons/consumable/consumable_dried_fruit_03.png` |
| 食物 | Lv4 | 压缩口粮 | 恢复较多行动资源，临时增加1AP | 是 | `restore_stamina_medium` | — | `consumable_compressed_ration_04` | `res://Items/icons/consumable/consumable_compressed_ration_04.png` |
| 食物 | Lv5 | 热量餐包 | 自热型卡路里密集餐盒，临时增加3AP | 否 | — | — | `consumable_calorie_meal_05` | `res://Items/icons/consumable/consumable_calorie_meal_05.png` |
| 食物 | Lv6 | 强化野战餐 | 单兵野战加固餐盒，临时增加5AP | 否 | — | — | `consumable_field_meal_06` | `res://Items/icons/consumable/consumable_field_meal_06.png` |
| 食物 | Lv7 | 班组补给箱 | 中型班组补给件 | 否 | — | — | `consumable_squad_supply_07` | `res://Items/icons/consumable/consumable_squad_supply_07.png` |
| 食物 | Lv8 | 前哨应急粮储 | 大型前哨长期储存级 | 否 | — | — | `consumable_outpost_rations_08` | `res://Items/icons/consumable/consumable_outpost_rations_08.png` |
| 医疗 | 起始档位 | — | — | — | — | — | — | — |
| 医疗 | Lv0 | 药渣 | 残次品，几乎无用 | 否 | — | — | `material_herbal_residue_00` | `res://Items/icons/material/material_herbal_residue_00.png` |
| 医疗 | Lv1 | 灰叶药草 | 为医疗树提供保底起点 | 否 | — | — | `material_grayleaf_herb_01` | `res://Items/icons/material/material_grayleaf_herb_01.png` |
| 医疗 | Lv2 | 干燥药包 | 恢复20生命值 | 是 | `heal_small` | — | `consumable_dried_medicine_02` | `res://Items/icons/consumable/consumable_dried_medicine_02.png` |
| 医疗 | Lv3 | 清创敷料 | 清除流血等持续伤害 | 是 | `stop_bleeding` | — | `consumable_debridement_dressing_03` | `res://Items/icons/consumable/consumable_debridement_dressing_03.png` |
| 医疗 | Lv4 | 无菌绷带组 | 战斗负伤包扎，清除骨折的负面影响 | 是 | — | — | `consumable_sterile_bandage_04` | `res://Items/icons/consumable/consumable_sterile_bandage_04.png` |
| 医疗 | Lv5 | 急救包 | 战场基础医疗与中阶居民订单，恢复40生命值 | 是 | `heal_small`（基础版） | — | `consumable_medkit_01` | `res://Items/icons/consumable/consumable_medkit_01.png` |
| 医疗 | Lv6 | 战地医疗箱 | 班组级医疗供应，恢复90生命值 | 否 | — | — | `consumable_field_medical_case_06` | `res://Items/icons/consumable/consumable_field_medical_case_06.png` |
| 医疗 | Lv7 | 创伤处理包 | 处理中重度战伤，恢复100生命值，清除流血和骨折 | 否 | — | — | `consumable_trauma_kit_07` | `res://Items/icons/consumable/consumable_trauma_kit_07.png` |
| 医疗 | Lv8 | 前线救援套件 | 大型综合急救套件，恢复全部生命值，清除流血和骨折 | 否 | — | — | `consumable_frontline_rescue_08` | `res://Items/icons/consumable/consumable_frontline_rescue_08.png` |
| 护甲 | 起始档位 | — | — | — | — | — | — | — |
| 护甲 | Lv0 | 破损甲片 | 极低概率在野装甲残骸中获得 | 否 | — | — | `material_damaged_armor_plate_00` | `res://Items/icons/material/material_damaged_armor_plate_00.png` |
| 护甲 | Lv1 | 金属碎片 | 防止基础建设被单一掉落卡住，最常见的一阶原料 | 否 | — | 10 | `material_metal_01` | `res://Items/icons/material/material_metal_01.png` |
| 护甲 | Lv2 | 铆接板材 | 第一次具有结构强度的护甲原料 | 否 | — | — | `material_riveted_plate_02` | `res://Items/icons/material/material_riveted_plate_02.png` |
| 护甲 | Lv3 | 加固护板 | 抗小口径直射的复合板 | 否 | — | — | `material_reinforced_plate_03` | `res://Items/icons/material/material_reinforced_plate_03.png` |
| 护甲 | Lv4 | 抗冲击衬层 | 抗冲击吸能的复合衬层 | 否 | — | — | `material_impact_liner_04` | `res://Items/icons/material/material_impact_liner_04.png` |
| 护甲 | Lv5 | 轻型护甲组件 | 第一件可实际穿着的护甲，护甲值20，受击后为破损状态，不可再合成 | 否（装入 `armor` 槽） | — | — | `armor_light_component_05` | `res://Items/icons/armor/armor_light_component_05.png` |
| 护甲 | Lv6 | 模块化护甲 | 可挂载附加组件的战术护甲，护甲值40，受击后为破损状态，不可再合成 | 否（装入 `armor` 槽） | — | — | `armor_modular_06` | `res://Items/icons/armor/armor_modular_06.png` |
| 护甲 | Lv7 | 晶纤维防护板 | 复合晶能纤维，重型护甲的原料 | 否 | — | — | `armor_crystal_fiber_plate_07` | `res://Items/icons/armor/armor_crystal_fiber_plate_07.png` |
| 护甲 | Lv8 | 前哨防护护甲 | 大型前哨终极防护护甲，护甲值180，受击后为破损状态，不可再合成 | 否（装入 `armor` 槽） | — | — | `armor_outpost_defense_08` | `res://Items/icons/armor/armor_outpost_defense_08.png` |
| 头盔 | 起始档位 | — | — | — | — | — | — | — |
| 头盔 | Lv0 | 破损盔壳 | 极低概率在野战头盔残骸中获得 | 否 | — | — | `material_damaged_helmet_shell_00` | `res://Items/icons/material/material_damaged_helmet_shell_00.png` |
| 头盔 | Lv1 | 废旧盔壳 | 破旧的，不能再用的头盔 | 否 | — | — | `helmet_salvaged_shell_01` | `res://Items/icons/helmet/helmet_salvaged_shell_01.png` |
| 头盔 | Lv2 | 拼接盔壳 | 修补后不能再次服役的头盔 | 否 | — | — | `helmet_patched_shell_02` | `res://Items/icons/helmet/helmet_patched_shell_02.png` |
| 头盔 | Lv3 | 缓冲内衬 | 提供冲击缓冲的内部衬垫 | 否 | — | — | `helmet_cushion_liner_03` | `res://Items/icons/helmet/helmet_cushion_liner_03.png` |
| 头盔 | Lv4 | 加固盔体 | 抗小口径直射的加固壳，护甲值8，受击后为破损状态，不可再合成 | 否（装入 `helmet` 槽） | — | — | `helmet_reinforced_shell_04` | `res://Items/icons/helmet/helmet_reinforced_shell_04.png` |
| 头盔 | Lv5 | 战术头盔组件 | 准备挂载夜视与导轨的战术件 | 否 | — | — | `helmet_tactical_component_05` | `res://Items/icons/helmet/helmet_tactical_component_05.png` |
| 头盔 | Lv6 | 模块化战术头盔 | 完整模块化战术盔，护甲值35，受击后为破损状态，不可再合成 | 否（装入 `helmet` 槽） | — | — | `helmet_modular_tactical_06` | `res://Items/icons/helmet/helmet_modular_tactical_06.png` |
| 头盔 | Lv7 | 晶纤维战术头盔 | 复合晶能纤维的高级战术盔，护甲值80，受击后为破损状态，不可再合成 | 否（装入 `helmet` 槽） | — | — | `helmet_crystal_fiber_07` | `res://Items/icons/helmet/helmet_crystal_fiber_07.png` |
| 头盔 | Lv8 | 前哨防护头盔 | 大型前哨终极防护盔，护甲值160，受击后为破损状态，不可再合成 | 否（装入 `helmet` 槽） | — | — | `helmet_outpost_defense_08` | `res://Items/icons/helmet/helmet_outpost_defense_08.png` |
| 净水 | 起始档位 | — | — | — | — | — | — | — |
| 净水 | Lv0 | 污损滤材 | 极低概率在野战净水残骸中获得 | 否 | — | — | `material_soiled_filter_00` | `res://Items/icons/material/material_soiled_filter_00.png` |
| 净水 | Lv1 | 净水滤棉 | 为净水树提供保底起点 | 否 | — | 14 | `material_filter_cotton_01` | `res://Items/icons/material/material_filter_cotton_01.png` |
| 净水 | Lv2 | 粗滤芯 | 第一次可重复使用的净水耗材 | 否 | — | — | `material_rough_filter_02` | `res://Items/icons/material/material_rough_filter_02.png` |
| 净水 | Lv3 | 活性滤芯 | 第一次具备活性炭层 | 否 | — | — | `material_active_filter_03` | `res://Items/icons/material/material_active_filter_03.png` |
| 净水 | Lv4 | 压力过滤罐 | 抗压型滤罐，配合水泵使用 | 否 | — | — | `material_pressure_filter_04` | `res://Items/icons/material/material_pressure_filter_04.png` |
| 净水 | Lv5 | 净化模块 | 模块化净水组件 | 否 | — | — | `material_purification_module_05` | `res://Items/icons/material/material_purification_module_05.png` |
| 净水 | Lv6 | 便携净水器 | 单兵手压泵式净水器 | 否 | — | — | `material_portable_purifier_06` | `res://Items/icons/material/material_portable_purifier_06.png` |
| 净水 | Lv7 | 社区净水单元 | 社区级多户净水单元 | 否 | — | — | `material_community_water_unit_07` | `res://Items/icons/material/material_community_water_unit_07.png` |
| 净水 | Lv8 | 晶能净化核心 | 大型晶能驱动的终极净水核心 | 否 | — | — | `material_crystal_purification_core_08` | `res://Items/icons/material/material_crystal_purification_core_08.png` |

## 3. 战场物资包图标（30 项）

物资包本身也进入仓库，且可装入背包(占容量)；需要与普通材料保持明显不同：统一使用封口军需袋、硬质补给箱或带封签的模块箱轮廓，并按谱系使用不同识别色。

| 谱系 | Lv1 | Lv2 | Lv3 | Lv4 | Lv5 |
| --- | --- | --- | --- | --- | --- |
| 织物 | 散装纤维袋 `supply_textile_01` | 线材补给包 `supply_textile_02` | 织物加工包 `supply_textile_03` | 耐磨织物箱 `supply_textile_04` | 远征纺织箱 `supply_textile_05` |
| 食物 | 残存口粮袋 `supply_food_01` | 常规补给袋 `supply_food_02` | 野战食品箱 `supply_food_03` | 班组餐食箱 `supply_food_04` | 前哨粮秣箱 `supply_food_05` |
| 医疗 | 废弃医用包 `supply_medical_01` | 基础医疗包 `supply_medical_02` | 无菌医疗箱 `supply_medical_03` | 野战医疗箱 `supply_medical_04` | 救援医疗柜 `supply_medical_05` |
| 护甲 | 损坏护甲零件包 `supply_armor_01` | 标准护甲补给包 `supply_armor_02` | 加固护甲维修包 `supply_armor_03` | 战术护甲材料箱 `supply_armor_04` | 重型护甲军需箱 `supply_armor_05` |
| 头盔 | 损坏头盔零件包 `supply_helmet_01` | 标准头盔补给包 `supply_helmet_02` | 加固头盔维修包 `supply_helmet_03` | 战术头盔材料箱 `supply_helmet_04` | 重型头盔军需箱 `supply_helmet_05` |
| 净水 | 废弃滤材袋 `supply_water_01` | 基础滤芯包 `supply_water_02` | 净水维修包 `supply_water_03` | 社区净水材料箱 `supply_water_04` | 晶能净化军需箱 `supply_water_05` |

所有物资包的图标路径统一为：`res://Items/icons/supply_package/<ID>.png`。例如，`supply_armor_03` 对应 `res://Items/icons/supply_package/supply_armor_03.png`。

## 4. 图标制作规范

- **交付格式**：贝妮的三把武器使用 `512 × 512` PNG 母版；其余所有物品（材料、消耗品、防具、背包、枪械配件、收藏品、二合物与物资包）统一使用 `256 × 256` PNG 母版。全部透明背景、无文字、单个物品居中，占画面约 70%~80%。
- **统一风格**：二次元战后重建风；干净的硬边轮廓、低饱和军用底色，以青蓝辉石微光作为高阶或能量部件点缀。
- **视角**：武器与背包使用略微俯视的 3/4 视角；材料、药品、配件使用正面或 3/4 视角，避免复杂背景与角色手部。
- **辨识原则**：同类物品以轮廓优先区分——材料看包装与材质、消耗品看医疗/注射特征、配件看对应槽位结构、武器看枪身剪影。

## 5. 角色武器关系

| 角色 | 初始武器 | 后续武器 | 专属配件 |
| --- | --- | --- | --- |
| 贝妮 | 防卫者-9 | 野兔跳跃者 → 黎明初霁 | 晨辉共鸣核心（仅限黎明初霁） |

贝妮目前是唯一已配置角色；因此首轮武器美术只需围绕她的“紧凑冲锋枪 → 战术冲锋枪 → 高频脉冲冲锋枪”形成清晰的三段成长轮廓。
