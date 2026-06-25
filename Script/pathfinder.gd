class_name Pathfinder

const DIR_MASK = {
	Vector2i(0, -1): 1,
	Vector2i(1, 0): 2,
	Vector2i(0, 1): 4,
	Vector2i(-1, 0): 8
}

const DIRS = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

var level_manager: LevelManager

func _init(p_level_manager: LevelManager):
	level_manager = p_level_manager

func can_move(from: Vector2i, to: Vector2i, level: int, exclude_unit = null) -> bool:
	if not is_walkable(to, level, exclude_unit):
		return false

	var move_dir = to - from
	var enter_side = -move_dir
	var ground = level_manager.get_layer(level, "ground")
	var to_data = ground.get_cell_tile_data(to)
	if to_data:
		var wall_block = to_data.get_custom_data("wall_block")
		if wall_block > 0:
			var enter_mask = DIR_MASK.get(enter_side, 0)
			if (wall_block & enter_mask) != 0:
				return false

	var from_data = ground.get_cell_tile_data(from)
	if from_data:
		var wall_block = from_data.get_custom_data("wall_block")
		if wall_block > 0:
			var leave_mask = DIR_MASK.get(move_dir, 0)
			if (wall_block & leave_mask) != 0:
				return false

	return true

func is_walkable(grid: Vector2i, level: int, exclude_unit = null) -> bool:
	var ground = level_manager.get_layer(level, "ground")
	var obstacle = level_manager.get_layer(level, "obstacle")
	
	var ground_data = ground.get_cell_tile_data(grid)
	if ground_data == null:
		return false
	if ground_data.get_custom_data("terrain") != 0:
		return false

	if obstacle:
		var obstacle_data = obstacle.get_cell_tile_data(grid)
		if obstacle_data != null:
			if not obstacle_data.get_custom_data("can_walk"):
				return false

	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		for u in tree.get_nodes_in_group("units"):
			if u == exclude_unit:
				continue
			if u.grid_pos == grid and u.current_level == level:
				return false

	return true

func is_stairs(grid: Vector2i, level: int) -> bool:
	var obstacle = level_manager.get_layer(level, "obstacle")
	if obstacle == null:
		return false
	var data = obstacle.get_cell_tile_data(grid)
	if data == null:
		return false
	return data.get_custom_data("is_stairs")

func get_neighbors(grid: Vector2i, level: int, exclude_unit = null) -> Array[Dictionary]:
	var neighbors: Array[Dictionary] = []
	
	# 同层四方向移动（检查墙体阻挡）
	for dir in DIRS:
		var next_grid = grid + dir
		if can_move(grid, next_grid, level, exclude_unit):
			neighbors.append({"grid": next_grid, "level": level})
	
	# 上楼: 当前格是楼梯，周围上层可走
	if is_stairs(grid, level):
		var max_level = level_manager.get_max_level()
		if level < max_level:
			for dir in DIRS:
				var next_grid = grid + dir
				if is_walkable(next_grid, level + 1, exclude_unit):
					neighbors.append({"grid": next_grid, "level": level + 1})
	
	# 下楼: 周围下层是楼梯
	if level > 1:
		for dir in DIRS:
			var next_grid = grid + dir
			if is_stairs(next_grid, level - 1):
				neighbors.append({"grid": next_grid, "level": level - 1})
	
	return neighbors

func bfs(start: Vector2i, start_level: int, max_steps: int, self_unit = null) -> Array[Dictionary]:
	var visited: Dictionary = {}
	var queue: Array[Array] = []
	var result: Array[Dictionary] = []

	var start_node = {"grid": start, "level": start_level}
	queue.append([start_node, 0])
	visited[start_node] = true

	while queue.size() > 0:
		var current: Array = queue.pop_front()
		var node: Dictionary = current[0]
		var steps: int = current[1]

		result.append(node)

		if steps >= max_steps:
			continue

		for neighbor in get_neighbors(node["grid"], node["level"], self_unit):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			queue.append([neighbor, steps + 1])

	return result

func find_path(from: Vector2i, from_level: int, to: Vector2i, to_level: int, self_unit = null) -> Array[Dictionary]:
	var visited: Dictionary = {}
	var queue: Array = []
	var parent: Dictionary = {}

	var start_node = {"grid": from, "level": from_level}
	var end_node = {"grid": to, "level": to_level}
	
	queue.append(start_node)
	visited[start_node] = true
	parent[start_node] = null

	while queue.size() > 0:
		var node: Dictionary = queue.pop_front()

		if node["grid"] == to and node["level"] == to_level:
			var path: Array[Dictionary] = []
			var current = end_node
			while current != null:
				path.append(current)
				current = parent[current]
			path.reverse()
			return path

		for neighbor in get_neighbors(node["grid"], node["level"], self_unit):
			if visited.has(neighbor):
				continue
			visited[neighbor] = true
			parent[neighbor] = node
			queue.append(neighbor)

	return []
