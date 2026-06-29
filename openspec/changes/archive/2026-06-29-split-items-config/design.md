## Context

`conf/items.json` 为单个 37KB 扁平 JSON 数组，约 120 条记录，混杂 10 种 `type`（WEAPON ~36、AMMO ~75、其余护甲/材料/消耗等各 1~2）。加载入口在 `Script/boot.gd`，由 `ItemDB.load_from_file("res://conf/items.json")`（`Script/item/item_db.gd`）解析单文件、按 `type` 校验后存入 `_items` 字典。

项目为 Godot 工程，运行时已全程使用 `res://` / `user://` 虚拟路径，OS 路径由引擎抽象，`.gitattributes`（`eol=lf`）与 `.editorconfig`（utf-8）已统一换行与编码。`Items/icons/` 下子目录均为小写，`icon` 字段引用形如 `res://Items/icons/weapon/...`，当前大小写一致。

## Goals / Non-Goals

**Goals:**
- 按 `type` 将 items 拆为 10 个文件，降低编辑定位成本
- 加载器改为按 `VALID_TYPES` 键驱动，加载并合并，行为对外等价
- 缺失/损坏类型文件时容错（跳过 + 告警，不崩）
- 启动期校验 `icon` 资源存在性，早暴露大小写漂移
- 固化跨平台路径约定

**Non-Goals:**
- 不改物品数据结构与字段（除分文件外内容不变）
- 不改 `get_item` / `get_items_by_type` / `get_all_items` 对外签名与语义
- 不引入运行时路径转换 helper（`res://` 已足够）
- 不处理 `enemies.json`（本次仅 items）

## Decisions

**决策 1：拆分粒度 = 按 type 一文件一类（10 文件）**
- 理由：与既有 `VALID_TYPES` 天然对齐，加载可由类型键直接驱动；编辑时类型边界清晰。
- 备选：按大类合并 4 文件（更少文件但需额外映射）、文件夹+manifest（导出最稳但多一层索引）。选 10 文件因加载逻辑最直接，且 type 键已是现成清单。

**决策 2：加载策略 = VALID_TYPES 键驱动，而非目录扫描**
- 理由：`for key in VALID_TYPES: load "res://conf/items/%s.json" % key.to_lower()`。导出 PCK 后路径明确稳定，无需依赖 `DirAccess` 列目录（导出环境列目录有坑）。
- 备选：`DirAccess` 扫描目录（加文件零改代码，但导出列目录不可靠）；manifest 清单（多维护一份索引）。

**决策 3：保留每条记录的 `type` 字段**
- 理由：`_validate_entry` 的类型校验与 `get_items_by_type` 查询均依赖该字段；文件名仅作组织手段，不作唯一数据源。冗余可换取加载时的一致性校验（文件类型 vs 记录 type 可交叉验证）。

**决策 4：路径兼容 = 约定 + 启动校验，不做运行时转换**
- 理由：运行时本无 OS 路径问题，真实活跃风险仅为大小写漂移（mac/win 不敏感、导出/CI 敏感）。启动期遍历 `icon` 做 `FileAccess.file_exists` + 大小写精确匹配，可在开发期早暴露，成本低。

**决策 5：容错而非中断**
- 理由：`weapon_attachment.json` 当前无内容；缺文件/解析失败应跳过 + 告警，保证开发期增量推进不被阻断。

## Risks / Trade-offs

- [`FileAccess.file_exists` 对大小写不敏感于 mac/win] → 校验需额外用 `DirAccess` 列目录比对真实文件名大小写，或仅在 CI（Linux 敏感）兜底；开发期校验作为辅助手段。
- [拆分时手工搬运易漏条目/破坏总数] → 校验：拆分后 `get_all_items().size()` 必须等于拆分前数量（约 120）。
- [缺失类型文件静默] → 必须打印告警而非静默跳过，避免误以为加载完整。
- [JSON 缩进风格] → 原文件用 Tab 缩进；拆分文件沿用同风格，避免 diff 噪音。

## Migration Plan

1. 在 `conf/items/` 下按 type 生成 10 个文件，逐类搬运记录（保留 type 字段与原缩进）。
2. 改造 `item_db.gd`：新增/改造加载入口为类型键驱动 + 合并 + 容错 + icon 校验。
3. 更新 `boot.gd` 调用为新入口。
4. 校验：启动日志显示物品总数与原一致、无意外缺失告警。
5. 删除原 `conf/items.json`。
6. 回滚：保留原 `items.json` 直至验证通过后再删；如失败恢复单文件与原加载调用。

## Open Questions

- icon 校验是否需做严格大小写精确匹配（需 `DirAccess` 列目录），还是先只做存在性 + 依赖 CI 兜底？倾向先存在性校验，大小写匹配作为可选增强。
