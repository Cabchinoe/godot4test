## MODIFIED Requirements

### Requirement: 行动点初始化与重置
Unit SHALL 拥有 `action_points` 属性，初始值等于 `ap_max`。每回合开始时通过 `start_turn()` 方法将 `action_points` 重置为 `ap_max`。

#### Scenario: 单位初始化
- **WHEN** Unit 以 `ap_max = 5` 初始化
- **THEN** `action_points = 5`

#### Scenario: 回合开始重置 AP
- **WHEN** 单位当前 `action_points = 2`，调用 `start_turn()`
- **THEN** `action_points` 重置为 `ap_max`（5）

## ADDED Requirements

### Requirement: 字段命名 ap_max
Unit 表示 AP 上限的字段名 SHALL 为 `ap_max`（替换原 `move_range`）。`init_unit` 的对应形参 SHALL 同步命名为 `p_ap_max`。所有外部调用方（如 `main.gd` 的 HUD 文本）SHALL 引用 `ap_max` 而非 `move_range`。`move_range` 字段 SHALL 从 `Unit` 中完全移除，不保留兼容别名。

#### Scenario: Unit 字段名
- **WHEN** 访问 `Unit.ap_max`
- **THEN** 返回该 unit 的 AP 上限

#### Scenario: 原字段已移除
- **WHEN** 访问 `Unit.move_range`
- **THEN** Godot 报错（字段不存在）

#### Scenario: init_unit 参数语义
- **WHEN** 调用 `unit.init_unit("Player", "player", 5, level_manager, 1)`
- **THEN** 第三个参数 5 赋给 `ap_max`，`action_points = 5`

#### Scenario: HUD 显示读取 ap_max
- **WHEN** Player `action_points = 3`，`ap_max = 5`
- **THEN** HUD 显示 `"行动点: 3/5"`，文本通过 `player.ap_max` 读取上限
