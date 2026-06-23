## Context

当前游戏是一个回合制战术游戏，包含主菜单（MainMenu）、对局场景（Main）。玩家单位在多层 TileMap 上移动，使用 Pathfinder 寻路，TurnController 管理回合。游戏无存档系统，每次启动从头开始。

需要新增：
1. 通用存档框架（SaveManager + Provider 注册制）
2. 基地场景（Base）作为对局外的中枢
3. 存档 UI

## Goals / Non-Goals

**Goals:**
- 建立可扩展的存档框架，未来新增系统只需添加 Provider
- 10 个存档槽位，Resource 格式持久化
- 基地场景提供自由移动 + 寻路高亮 + 存档管理入口
- 存档 UI 支持保存、读取、删除操作

**Non-Goals:**
- 不实现仓库系统、任务系统、剧情系统的具体逻辑（仅预留 SaveData 结构）
- 不在对局中存档
- 不实现云存档
- 不实现自动存档

## Decisions

### 1. 存档格式：Resource (.res)

**选择**: Godot Resource 二进制格式

**理由**:
- 类型安全，GDScript 有补全
- 子 Resource 自动嵌套序列化
- 未来加字段向后兼容容易
- 不需要手动处理 JSON 类型转换

**替代方案**: JSON — 可读可调试，但需手动序列化，类型管理麻烦

### 2. Provider 注册制

**选择**: SaveProvider 基类 + SaveManager.register_provider()

**理由**:
- SaveManager 不硬编码依赖任何游戏系统
- 新增系统只需写 Provider + 注册，SaveManager 零改动
- 各 Provider 独立测试

**替代方案**: 硬编码 — 简单但耦合高，扩展需改 SaveManager

### 3. 存档目录结构

**选择**: `user://saves/slot_<id>/save.res`，每槽位独立目录

**理由**:
- 未来可扩展（槽位目录内加截图、元数据等）
- 删除槽位 = 删目录，干净

### 4. Base 场景复用 main 的移动逻辑

**选择**: base.gd 复制 main.gd 的移动/寻路/高亮逻辑，去掉回合控制

**理由**:
- 避免 main.gd 引入条件判断（if in_base_scene）
- 两个场景职责清晰分离
- 移动逻辑代码量不大，重复可接受

**替代方案**: 抽取公共基类 — 增加复杂度，当前规模不值得

### 5. Base 场景 AP = 50

**选择**: 玩家初始化时 action_points = 50

**理由**: 足够大等于无限，不需要改 Unit 逻辑，不需要特殊处理"无限 AP"

### 6. 场景流转

**选择**: MainMenu → Base → Main，通过 `change_scene_to_file()` 切换

**理由**: 场景间无状态传递需求（除存档数据），Autoload 的 SaveManager 已全局可用

## Risks / Trade-offs

- **[Resource 二进制不可读]** → 调试时可额外导出 JSON 预览，或打印 SaveData 内容
- **[base.gd 与 main.gd 代码重复]** → 移动逻辑约 100 行，重复可接受。若未来逻辑变复杂，可抽取 MovementController
- **[Provider 注册顺序]** → Provider 间无依赖，注册顺序不影响结果
- **[Resource 版本迁移]** → SaveData 保留 version 字段，SaveManager 预留 _migrate() 入口，当前不实现具体迁移逻辑
