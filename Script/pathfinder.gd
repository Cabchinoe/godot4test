class_name Pathfinder

const DIR_MASK = {
	Vector2i(0, -1): 1,
	Vector2i(1, 0): 2,
	Vector2i(0, 1): 4,
	Vector2i(-1, 0): 8
}

const DIRS = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]

var ground_layer: TileMapLayer
var obstacle_layer: TileMapLayer

func _init(ground: TileMapLayer, obstacle: TileMapLayer = null):
	ground_layer = ground
	obstacle_layer = obstacle

func can_move(from: Vector2i, to: Vector2i) -> bool:
	if not is_walkable(to):
		return false

	var move_dir = to - from
	var enter_side = -move_dir
	var to_data = ground_layer.get_cell_tile_data(to)
	if to_data:
		var wall_block = to_data.get_custom_data("wall_block")
		if wall_block > 0:
			var enter_mask = DIR_MASK.get(enter_side, 0)
			if (wall_block & enter_mask) != 0:
				return false

	var from_data = ground_layer.get_cell_tile_data(from)
	if from_data:
		var wall_block = from_data.get_custom_data("wall_block")
		if wall_block > 0:
			var leave_mask = DIR_MASK.get(move_dir, 0)
			if (wall_block & leave_mask) != 0:
				return false

	return true

func is_walkable(grid: Vector2i) -> bool:
	var ground_data = ground_layer.get_cell_tile_data(grid)
	if ground_data == null:
		return false
	if ground_data.get_custom_data("terrain") != 0:
		return false

	if obstacle_layer:
		var obstacle_data = obstacle_layer.get_cell_tile_data(grid)
		if obstacle_data != null:
			if not obstacle_data.get_custom_data("can_walk"):
				return false

	return true

func bfs(start: Vector2i, max_steps: int) -> Array[Vector2i]:
	var visited: Dictionary = {}
	var queue: Array[Array] = []
	var result: Array[Vector2i] = []

	queue.append([start, 0])
	visited[start] = true

	while queue.size() > 0:
		var current: Array = queue.pop_front()
		var pos: Vector2i = current[0]
		var steps: int = current[1]

		result.append(pos)

		if steps >= max_steps:
			continue

		for dir in DIRS:
			var next = pos + dir
			if visited.has(next):
				continue
			if not can_move(pos, next):
				continue
			visited[next] = true
			queue.append([next, steps + 1])

	return result

func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var visited: Dictionary = {}
	var queue: Array = []
	var parent: Dictionary = {}

	queue.append(from)
	visited[from] = true
	parent[from] = null

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front()

		if pos == to:
			var path: Array[Vector2i] = []
			var current = to
			while current != null:
				path.append(current)
				current = parent[current]
			path.reverse()
			return path

		for dir in DIRS:
			var next = pos + dir
			if visited.has(next):
				continue
			if not can_move(pos, next):
				continue
			visited[next] = true
			parent[next] = pos
			queue.append(next)

	return []
