## 1. Unit 字段改名与 Group 标签

- [x] 1.1 `Script/unit.gd`：将 `move_range` 字段重命名为 `ap_max`
- [x] 1.2 `Script/unit.gd`：将 `init_unit` 形参 `p_move_range` 改名为 `p_ap_max`
- [x] 1.3 `Script/unit.gd`：`start_turn()` 中 `action_points = ap_max`
- [x] 1.4 `Script/unit.gd`：`init_unit` 末尾追加 `add_to_group("units")` + `add_to_group(faction)`
- [x] 1.5 `Script/unit.gd`：新增 `signal movement_finished`
- [x] 1.6 `Script/unit.gd`：`_step_to_next` 在 `is_moving` 由 true 变 false 时 `emit_signal("movement_finished")`
- [x] 1.7 `Script/unit.gd`：`set_move_path` 接到空路径时立即 `is_moving = false` 并发 `movement_finished`
- [x] 1.8 `Script/main.gd`：HUD `_update_hud` 中 `player.move_range` → `player.ap_max`
- [x] 1.9 验证：运行 main 场景，HUD 显示 `行动点: 5/5`，移动后 AP 正常扣除

## 2. Pathfinder 占格检查

- [x] 2.1 `Script/pathfinder.gd`：`is_walkable(grid, level, exclude_unit = null)` 增加可选参数
- [x] 2.2 `Script/pathfinder.gd`：`is_walkable` 内部用 `Engine.get_main_loop() as SceneTree` 获取 tree，遍历 `units` group 检查 `(grid_pos, current_level)` 冲突；tree 为 null 时跳过该检查
- [x] 2.3 `Script/pathfinder.gd`：`can_move(from, to, level, exclude_unit = null)` 增加参数并向下透传
- [x] 2.4 `Script/pathfinder.gd`：`get_neighbors(grid, level, exclude_unit = null)` 增加参数并向下透传
- [x] 2.5 `Script/pathfinder.gd`：`bfs(start, level, max_steps, self_unit = null)` 增加参数并向下透传
- [x] 2.6 `Script/pathfinder.gd`：`find_path(from, fl, to, tl, self_unit = null)` 增加参数并向下透传
- [x] 2.7 `Script/main.gd`：所有调用 `player.pathfinder.bfs / find_path` 处传 `player` 作为 `self_unit`
- [x] 2.8 `Script/main.gd`：`_get_closest_walkable_node` 调用 `is_walkable(grid, level, player)`
- [x] 2.9 验证：手动测试 player 不能走到 player 占据的格上（自我占格不挡自己）

## 3. 兵种数据 EnemyDB

- [x] 3.1 新建 `conf/enemies.json`，至少定义 1 个兵种 `goblin`（字段：`name`, `ap_max`, `sprite_frames_path`）
- [x] 3.2 新建 `Script/enemy_db.gd`：单例风格，`static func get(id) -> Dictionary`，懒加载 JSON
- [x] 3.3 `Script/enemy_db.gd`：未定义 id 时返回空字典 + push_warning
- [x] 3.4 验证：在 main `_ready` 末尾 print `EnemyDB.get("goblin")` 确认输出正确

## 4. main.tscn 添加 Enemies 容器

- [x] 4.1 `main.tscn`：在 `Main` 下新增 `Node2D` 节点命名 `Enemies`，无子节点
- [x] 4.2 `Script/main.gd`：新增 `@onready var enemies_container: Node2D = $Enemies`
- [x] 4.3 验证：场景树打印有 `Enemies` 节点

## 5. EnemySpawner

- [x] 5.1 新建 `Script/enemy_spawner.gd`：`class_name EnemySpawner`
- [x] 5.2 `EnemySpawner` 接收 `level_manager`, `enemies_container`，构造函数注入
- [x] 5.3 `spawn(id, grid, level) -> Unit`：从 EnemyDB 读数据，`Unit.new()` + `AnimatedSprite2D.new()` 命名 `Sprite2D`，设 `sprite_frames` / `animation = "walk"` / `offset = Vector2(32,32)`
- [x] 5.4 `spawn` 末尾：`enemies_container.add_child(enemy)`，调 `init_unit(name, "enemy", ap_max, level_manager, level)`
- [x] 5.5 `spawn` 末尾：设 `enemy.grid_pos = grid`，按 `_step_to_next` 公式计算 `global_position` 并赋值（可抽 helper）
- [x] 5.6 `spawn_batch(rules: Array) -> Array[Unit]`：按规则批量生成，过滤掉与已生成或 player 重合、地形不可走的格
- [x] 5.7 `Script/main.gd._ready` 中调用 `EnemySpawner.spawn_batch` 生成至少 2 个 goblin（位置先固定写死）
- [x] 5.8 验证：进入 main 看到敌人 sprite 在指定格上，HUD 不受影响

## 6. _collect_targetable_cells 接入 enemy

- [x] 6.1 `Script/main.gd._collect_targetable_cells`：改为遍历 `get_tree().get_nodes_in_group("enemy")` 返回 `{grid: e.grid_pos, level: e.current_level}` 数组
- [x] 6.2 验证：进入攻击模式，红色高亮覆盖敌人所在格（可被射击）

## 7. TurnController 阶段切换

- [x] 7.1 `Script/turn_controller.gd`：新增 `signal phase_changed(phase)`
- [x] 7.2 `Script/turn_controller.gd`：`end_turn()` 改为：仅在 `current_phase == PLAYER_PHASE` 且 `!is_game_over` 时生效，切到 `ENEMY_PHASE`，emit `phase_changed(ENEMY_PHASE)`，不再 turn++
- [x] 7.3 `Script/turn_controller.gd`：新增 `end_enemy_phase()`：守卫 `!is_game_over` 且 `current_phase == ENEMY_PHASE`；执行 `turn_ended.emit`、`current_turn++`、game_over 判定（达 max 则 emit game_over 不切回）、切回 `PLAYER_PHASE`、emit `phase_changed(PLAYER_PHASE)` + `turn_started(current_turn)`
- [x] 7.4 `Script/turn_controller.gd`：删除 `_enter_player_phase`（功能并入 `end_enemy_phase`）；`start_game()` 不动（仍 emit `turn_started(1)`，不 emit phase_changed）

## 8. EnemyAI

- [x] 8.1 新建 `Script/enemy_ai.gd`：`class_name EnemyAI`，构造函数无参或接收 level_manager
- [x] 8.2 `run_turn(enemy: Unit) -> void`（注意 Godot 4 中 await 函数自动可 await）：
  - 找 `player` group 中曼哈顿距离最近的 unit；不存在则 return
  - 求 `find_path(enemy.grid_pos, enemy.current_level, target.grid_pos, target.current_level, enemy)`
  - 路径空则 return
  - 截取前 `enemy.action_points + 1` 个节点
  - `enemy.spend_ap(steps)` + `enemy.set_move_path(truncated)`
  - `await enemy.movement_finished`
- [x] 8.3 验证：单元手动调用 `await ai.run_turn(enemy)` 能正常返回

## 9. main.gd 阶段协调

- [x] 9.1 `Script/main.gd._ready`：`turn_controller.phase_changed.connect(_on_phase_changed)`
- [x] 9.2 `Script/main.gd._ready`：实例化 `enemy_ai = EnemyAI.new()`
- [x] 9.3 `Script/main.gd`：新增 `_on_phase_changed(phase)`：
  - PLAYER_PHASE → `player.start_turn()` + `_update_hud()`（注意 `_on_turn_started` 信号也会触发同样逻辑，去重）
  - ENEMY_PHASE → `await _run_enemy_phase()` + `turn_controller.end_enemy_phase()`
- [x] 9.4 `Script/main.gd`：新增 `_run_enemy_phase()`：遍历 `get_tree().get_nodes_in_group("enemy")`，每个 enemy `start_turn()` + `await enemy_ai.run_turn(enemy)`
- [x] 9.5 `Script/main.gd._unhandled_input` 开头：`if turn_controller.current_phase != TurnController.Phase.PLAYER_PHASE: return`
- [x] 9.6 `Script/main.gd._process` 开头：相同守卫，避免 ENEMY_PHASE 期间响应鼠标
- [x] 9.7 验证：点"结束回合"后看到敌人依次移动，结束后回合数 +1，HUD 更新

## 10. 动画跳过加速

- [x] 10.1 `Script/main.gd._process`：检测 `Input.is_key_pressed(KEY_SPACE)` 状态变化（用上一帧状态对比）
- [x] 10.2 仅在 `current_phase == ENEMY_PHASE` 时生效：按下 → 遍历 `units` group 把 `move_interval = 0.01`；松开/退出阶段 → 恢复 `0.15`
- [x] 10.3 退出 ENEMY_PHASE 时（phase_changed 回 PLAYER_PHASE）强制恢复 `move_interval = 0.15`，防止粘连
- [x] 10.4 验证：ENEMY_PHASE 按住空格敌人显著加速，松开恢复，回到 PLAYER_PHASE 后空格无效

## 11. 端到端验证

- [x] 11.1 启动游戏 → main 场景出现 Player + 2 个 goblin
- [x] 11.2 Player 不能点击 goblin 所在格作为移动目标
- [x] 11.3 BFS 高亮自动避开 goblin
- [x] 11.4 点"结束回合" → 进入 ENEMY_PHASE，goblin 依次朝 Player 移动
- [x] 11.5 按住空格期间 goblin 移动明显加速
- [x] 11.6 所有 goblin 行动完 → 回合数 +1，回到 PLAYER_PHASE，Player AP 重置
- [x] 11.7 攻击模式下 goblin 所在格被标红可瞄准
- [x] 11.8 达到 max_turns 后 ENEMY_PHASE 结束时 game_over 信号触发，UI 不再响应
