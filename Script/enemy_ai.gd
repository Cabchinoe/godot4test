class_name EnemyAI

var bullet_range: BulletRange
var combat_resolver: BattleCombatResolver

func _init(p_bullet_range: BulletRange, p_combat_resolver: BattleCombatResolver) -> void:
	bullet_range = p_bullet_range
	combat_resolver = p_combat_resolver

func run_turn(enemy: Unit) -> void:
	if enemy == null or enemy.is_defeated:
		return
	var tree := enemy.get_tree()
	if tree == null:
		return
	var players: Array = tree.get_nodes_in_group("player")
	if players.is_empty():
		return

	var target: Unit = null
	var best_dist: int = 0x7fffffff
	for p in players:
		var dx: int = absi(p.grid_pos.x - enemy.grid_pos.x)
		var dy: int = absi(p.grid_pos.y - enemy.grid_pos.y)
		var d: int = dx + dy
		if d < best_dist:
			best_dist = d
			target = p
	if target == null:
		return
	if _try_attack(enemy, target):
		return

	var path: Array[Dictionary] = _path_to_attack_position(enemy, target)
	if path.size() <= 1:
		return

	# 预留一次攻击所需 AP；路径包含起点，因此可走 n 步时节点数为 n + 1。
	var move_budget := maxi(0, enemy.action_points - enemy.get_attack_cost())
	var max_nodes: int = move_budget + 1
	var truncated: Array[Dictionary] = path.slice(0, min(path.size(), max_nodes))
	var steps: int = truncated.size() - 1
	if steps <= 0:
		return
	enemy.spend_ap(steps)
	enemy.set_move_path(truncated)
	if enemy.is_moving:
		await enemy.movement_finished
	if not enemy.is_defeated:
		_try_attack(enemy, target)

func _try_attack(enemy: Unit, target: Unit) -> bool:
	if enemy.action_points < enemy.get_attack_cost() or target.is_defeated:
		return false
	if bullet_range == null or combat_resolver == null:
		return false
	if not bullet_range.can_reach_cell(
		enemy.grid_pos,
		enemy.current_level,
		target.grid_pos,
		target.current_level,
		enemy.get_attack_range()
	):
		return false
	if not enemy.spend_ap(enemy.get_attack_cost()):
		return false
	var result := combat_resolver.resolve_attack(enemy, target)
	print(BattleCombatLogFormatter.format_attack(result))
	print("[敌方攻击 JSON] ", result)
	return true

func _path_to_attack_position(enemy: Unit, target: Unit) -> Array[Dictionary]:
	var best: Array[Dictionary] = []
	for dy in range(-enemy.get_attack_range(), enemy.get_attack_range() + 1):
		for dx in range(-enemy.get_attack_range(), enemy.get_attack_range() + 1):
			if dx == 0 and dy == 0:
				continue
			var goal := target.grid_pos + Vector2i(dx, dy)
			if not enemy.pathfinder.is_walkable(goal, target.current_level, enemy):
				continue
			if not bullet_range.can_reach_cell(goal, target.current_level, target.grid_pos, target.current_level, enemy.get_attack_range()):
				continue
			var path: Array[Dictionary] = enemy.pathfinder.find_path(
				enemy.grid_pos, enemy.current_level,
				goal, target.current_level,
				enemy
			)
			if path.is_empty():
				continue
			if best.is_empty() or path.size() < best.size():
				best = path
	return best
