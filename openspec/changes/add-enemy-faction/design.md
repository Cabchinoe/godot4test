## Context

当前对局只有玩家一方，`TurnController.ENEMY_PHASE` 是空壳直接跳过。`Unit` 类已有 `faction` 字段但全部填 `"player"`，未真正用于阵营区分。`Pathfinder.is_walkable` 只检查地形与障碍，对 unit 占格无感知。

本次变更涉及 5 个 capability、6 个脚本文件、1 个新数据文件、1 个场景节点变动 —— 属于跨模块改造，且引入数据驱动模式（兵种）与异步阶段切换，需要设计文档统一约束。

## Goals / Non-Goals

**Goals:**
- 在 `Unit` 类不分裂的前提下支持多兵种（数据驱动）
- 阶段切换异步化但调用方简单（信号 + await）
- 占格规则做到 BFS / 寻路 / 高亮统一一致
- 命名债（`move_range` → `ap_max`）一次清掉
- AI 行为骨架最小但可演进（追击 → 后续接攻击/巡逻）

**Non-Goals:**
- 多 player faction 单位
- 敌人入存档（每局重生）
- 复杂 AI（A* 评估、视野、隐蔽机制等）
- 敌人独有素材（暂复用 player sprite）
- 占格对 attack mode 的射线遮挡（已由 `bullet_range` 处理障碍）

## Decisions

### D1: 兵种用 JSON + EnemyDB，不用 Resource

**选择**: `conf/enemies.json` + `Script/enemy_db.gd`，模仿现有 `item_db.gd` + `conf/items.json` 模式。

**JSON schema**:
```json
{
  "goblin": {
    "name": "Goblin",
    "ap_max": 4,
    "sprite_frames_path": "res://Unit/player2_sprites.tres"
  }
}
```

**理由**: 项目已有相同模式（item 系统），保持一致；文本编辑无需打开 Godot 编辑器。

**否定**: `.tres` Resource → 优势是类型安全，但与现有 item 模式不一致。

### D2: 敌人节点纯代码创建，挂 `$Enemies`

**选择**: `Unit.new()` + `AnimatedSprite2D.new()` 子节点，无 .tscn 模板。`$Enemies` 是 main.tscn 中的空 `Node2D`。

**约束**: AnimatedSprite2D 子节点必须命名 `Sprite2D`（`Unit._step_to_next` 用 `get_node("Sprite2D")`）。

**否定**: 每个兵种一个 .tscn → 字段重复，维护成本高。

### D3: 阵营用 Godot group，节点层级仅做容器

**选择**:
- 节点层级：`Main/Player`（不动） + `Main/Enemies/<dyn>`（新增）
- 逻辑标签：`Unit.init_unit` 末尾自动 `add_to_group("units")` + `add_to_group(faction)`

**理由**: 节点层级不动 Player，存档/`@onready` 全部保持；group 查询解耦于树形结构。

**否定**:
- 把 Player 搬进 `$Units` → 改 `@onready` 路径 + 触动 save provider，收益小
- 不用 group 只遍历容器 → 跨容器查询（如"所有 unit"）麻烦

### D4: 占格检查放 Pathfinder，通过 group 查询

**选择**: `Pathfinder.is_walkable(grid, level, exclude_unit = null)` 增加可选参数；内部遍历 `units` group。

```gdscript
func is_walkable(grid, level, exclude_unit = null) -> bool:
    # ...原有地形/障碍检查...
    var tree = Engine.get_main_loop() as SceneTree
    for u in tree.get_nodes_in_group("units"):
        if u == exclude_unit: continue
        if u.grid_pos == grid and u.current_level == level:
            return false
    return true
```

**为什么 `exclude_unit`**: 自己当前格必须算 walkable，否则 BFS 起点直接被否、`_get_closest_walkable_node` 选自己时返回空。

**调用方**:
- `bfs(start, level, max_steps, self_unit)` → 内部 `is_walkable(g, l, self_unit)`
- `find_path(from, fl, to, tl, self_unit)` → 同上
- `can_move(from, to, level, self_unit)` → 同上
- main.gd 的 `_get_closest_walkable_node` 也传 `player` 排除

**否定**:
- Unit 上维护 occupied set → 增删时机难保证
- main.gd 维护 occupied dict → Pathfinder 依赖上层

### D5: 阶段切换用信号 + main.gd 协调 + await 动画

**选择**:
- `TurnController` 新增 `phase_changed(phase: Phase)` 信号、`end_enemy_phase()` 方法
- `end_turn()` 改为：从 PLAYER_PHASE 切到 ENEMY_PHASE，发 `phase_changed(ENEMY_PHASE)`，**不**立刻 turn++
- `end_enemy_phase()` 做：`current_turn++`（含 game_over 判定）、切回 PLAYER_PHASE、发 `phase_changed(PLAYER_PHASE)` + `turn_started(current_turn)`
- `Unit` 新增 `movement_finished` 信号（`_step_to_next` 走到 `is_moving = false` 时发）

**main.gd 协调**:
```gdscript
turn_controller.phase_changed.connect(_on_phase_changed)

func _on_phase_changed(phase):
    if phase == TurnController.Phase.PLAYER_PHASE:
        player.start_turn()
        _update_hud()
    else:
        await _run_enemy_phase()
        turn_controller.end_enemy_phase()

func _run_enemy_phase():
    for e in get_tree().get_nodes_in_group("enemy"):
        e.start_turn()
        await enemy_ai.run_turn(e)   # 内部 await e.movement_finished
```

**理由**: Godot 习惯 + await 调用方线性可读。

**否定**:
- TurnController 内部 await unit → 控制器反向依赖 unit，违反单向
- _process 轮询 `is_moving` → 状态机复杂、易竞态

### D6: 动画跳过 = 全局加速因子

**选择**:
- main.gd 检测按键（暂 `KEY_SPACE`），按下时遍历所有 unit 把 `move_interval` 降到 0.01s
- 松开恢复默认 0.15s
- 实现：在 `_process` 检测 `Input.is_key_pressed(KEY_SPACE)` 状态变化时统一刷新

**理由**: 改一个数最简单；最小可用。

**否定**:
- 一键传送到终点 → AI 行为视觉上完全跳过
- 暂停整个 _process → 不直观

### D7: `move_range` → `ap_max` 改名安全

**调查**:
- `PlayerSaveProvider` 不引用 `move_range`（只读不存在的 `_unit.level` 字段）→ 存档无破坏
- `Script/main.gd` 引用 1 处（HUD：`player.move_range`）→ 改 `player.ap_max`
- `Script/unit.gd` 4 处（声明 / init 参数 / `start_turn` reset / `init_unit` 形参）
- `openspec/specs/action-points/spec.md` 文本引用 → 走 delta spec 同步

**决定**: 不做兼容别名（如保留 `move_range` 作为 getter），一次性改干净。

### D8: EnemyAI 独立类，无状态

**选择**: `Script/enemy_ai.gd` 提供 `run_turn(enemy: Unit) -> void`，内部循环：
1. 找最近 player faction unit（曼哈顿距离）
2. 用 `find_path` 求路径
3. 截取前 `ap_max` 步（实际能走的）
4. `enemy.spend_ap(steps)`、`enemy.set_move_path(...)`
5. `await enemy.movement_finished`

**理由**: 无状态便于测试；后续可扩展为继承体系（PatrolAI / RangedAI）。

**否定**: AI 写在 Unit 内部 → Player 也会带 AI 接口，污染。

## Risks / Trade-offs

| Risk | Mitigation |
|---|---|
| `Pathfinder` 通过 `Engine.get_main_loop()` 拿 SceneTree，在测试/无树环境会崩 | 容错：tree 为 null 时跳过 unit 检查，仅当地形判定 |
| `Sprite2D` 子节点命名约束容易遗漏 | 在 `Unit._step_to_next` 用 `find_child` 容错 + 文档明示 |
| ENEMY_PHASE 期间玩家点击/拖拽误操作 | main.gd `_unhandled_input` 增加 `if turn_controller.current_phase != PLAYER_PHASE: return` |
| 敌人 AI 找不到路径（被堵死） | AI 内部短路：path 为空时直接结束该 unit 回合，不阻塞 |
| 占格检查每次 BFS 都遍历 group，BFS 节点数 × unit 数 = O(n*m) | 当前规模（unit < 20，BFS 节点 < 200）可接受；优化推迟到出现性能问题 |
| 改名 `ap_max` 漏改导致运行时报错 | 配合 spec delta 全文搜索 `move_range` 一次性替换 |
| 跳过加速期间存在 unit 已 emit `movement_finished` 而 await 还没绑定的竞态 | 信号设为 `one_shot` 风险更大；改为在 set_move_path 前先 connect，move_interval = 0.01 仍走帧循环不会瞬时完成 |

## Open Questions

- 敌人生成规则的随机种子是否要存档？（用于 deterministic replay）→ 暂不做，可在后续 change 加
- 敌人攻击玩家是否本 change 范围？→ **否**，AI 只做追击，攻击留给独立 change
- 同回合多敌人是否并行行动？→ **否**，串行 await，视觉清晰
- 敌人死亡是否本 change 范围？→ **否**，无血量/伤害，AI 永远活
