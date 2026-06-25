class_name EnemyAI

const DIRS := [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

func _init() -> void:
	pass

func run_turn(enemy: Unit) -> void:
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

	var path: Array[Dictionary] = _path_to_adjacent(enemy, target)
	if path.size() <= 1:
		return

	# path 包含起点；可走 ap 步 → 路径节点数 = ap + 1
	var ap: int = enemy.action_points
	var max_nodes: int = ap + 1
	var truncated: Array[Dictionary] = path.slice(0, min(path.size(), max_nodes))
	var steps: int = truncated.size() - 1
	if steps <= 0:
		return
	enemy.spend_ap(steps)
	enemy.set_move_path(truncated)
	if enemy.is_moving:
		await enemy.movement_finished

func _path_to_adjacent(enemy: Unit, target: Unit) -> Array[Dictionary]:
	var best: Array[Dictionary] = []
	for dir in DIRS:
		var goal: Vector2i = target.grid_pos + dir
		if not enemy.pathfinder.is_walkable(goal, target.current_level, enemy):
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
