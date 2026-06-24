class_name BulletRange

const DIR_MASK := {
	Vector2i(0, -1): 1,
	Vector2i(1, 0): 2,
	Vector2i(0, 1): 4,
	Vector2i(-1, 0): 8
}

const EPSILON := 0.0001

var level_manager: LevelManager

func _init(p_level_manager: LevelManager) -> void:
	level_manager = p_level_manager

func get_level_at(grid: Vector2i) -> int:
	for level in level_manager.get_all_levels():
		var ground := level_manager.get_layer(level, "ground")
		if ground == null:
			continue
		if ground.get_cell_tile_data(grid) != null:
			return level
	return -1

func _has_wall(grid: Vector2i, dir: Vector2i, level: int) -> bool:
	var ground := level_manager.get_layer(level, "ground")
	if ground == null:
		return false
	var data := ground.get_cell_tile_data(grid)
	if data == null:
		return false
	var wall_block: int = data.get_custom_data("wall_block")
	if wall_block <= 0:
		return false
	var mask: int = DIR_MASK.get(dir, 0)
	return (wall_block & mask) != 0

func _has_obstacle_block(grid: Vector2i, level: int) -> bool:
	var obstacle := level_manager.get_layer(level, "obstacle")
	if obstacle == null:
		return false
	var data := obstacle.get_cell_tile_data(grid)
	if data == null:
		return false
	return not data.get_custom_data("can_walk")

func _dda_path(origin: Vector2i, target: Vector2i) -> Array:
	var steps: Array = []
	if origin == target:
		return steps

	var dir := Vector2(target - origin)
	var step_x := int(sign(dir.x))
	var step_y := int(sign(dir.y))

	var t_delta_x: float = INF if dir.x == 0.0 else 1.0 / abs(dir.x)
	var t_delta_y: float = INF if dir.y == 0.0 else 1.0 / abs(dir.y)

	var t_max_x: float = INF if dir.x == 0.0 else 0.5 / abs(dir.x)
	var t_max_y: float = INF if dir.y == 0.0 else 0.5 / abs(dir.y)

	var current := origin
	var safety := 0
	var max_iter: int = abs(target.x - origin.x) + abs(target.y - origin.y) + 4

	while current != target:
		safety += 1
		if safety > max_iter:
			break

		var cross_v := false
		var cross_h := false
		var next_grid := current
		var both_finite := not is_inf(t_max_x) and not is_inf(t_max_y)

		if both_finite and abs(t_max_x - t_max_y) < EPSILON:
			cross_v = true
			cross_h = true
			next_grid = Vector2i(current.x + step_x, current.y + step_y)
			t_max_x += t_delta_x
			t_max_y += t_delta_y
		elif t_max_x < t_max_y:
			cross_v = true
			next_grid = Vector2i(current.x + step_x, current.y)
			t_max_x += t_delta_x
		else:
			cross_h = true
			next_grid = Vector2i(current.x, current.y + step_y)
			t_max_y += t_delta_y

		steps.append({
			"from": current,
			"to": next_grid,
			"cross_v": cross_v,
			"cross_h": cross_h
		})
		current = next_grid

	return steps

func _is_path_clear(path: Array, travel_level: int) -> bool:
	for step in path:
		var from_grid: Vector2i = step["from"]
		var to_grid: Vector2i = step["to"]
		var cross_v: bool = step["cross_v"]
		var cross_h: bool = step["cross_h"]
		var move := to_grid - from_grid
		var step_x := move.x
		var step_y := move.y

		if cross_v:
			var exit_dir := Vector2i(step_x, 0)
			var enter_dir := Vector2i(-step_x, 0)
			var from_lv := get_level_at(from_grid)
			if from_lv != -1 and _has_wall(from_grid, exit_dir, from_lv):
				return false
			var to_lv_v := get_level_at(to_grid)
			if to_lv_v != -1 and _has_wall(to_grid, enter_dir, to_lv_v):
				return false

		if cross_h:
			var exit_dir := Vector2i(0, step_y)
			var enter_dir := Vector2i(0, -step_y)
			var from_lv := get_level_at(from_grid)
			if from_lv != -1 and _has_wall(from_grid, exit_dir, from_lv):
				return false
			var to_lv_h := get_level_at(to_grid)
			if to_lv_h != -1 and _has_wall(to_grid, enter_dir, to_lv_h):
				return false

		var to_lv := get_level_at(to_grid)
		if to_lv == -1:
			continue
		if to_lv > travel_level:
			return false
		if _has_obstacle_block(to_grid, to_lv):
			return false

	return true

func get_bullet_path(origin: Vector2i, target: Vector2i) -> Array:
	return _dda_path(origin, target)

func get_reachable_cells(origin: Vector2i, origin_level: int, max_range: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []

	for dy in range(-max_range, max_range + 1):
		for dx in range(-max_range, max_range + 1):
			if dx == 0 and dy == 0:
				continue
			var target := Vector2i(origin.x + dx, origin.y + dy)
			var target_level := get_level_at(target)
			if target_level == -1:
				continue

			if target_level > origin_level:
				if abs(dx) > 1 or abs(dy) > 1:
					continue
				if dx != 0 and dy != 0:
					var v_dir := Vector2i(dx, 0)
					var h_dir := Vector2i(0, dy)
					if _has_wall(origin, v_dir, origin_level):
						continue
					if _has_wall(origin, h_dir, origin_level):
						continue
					if _has_wall(target, -v_dir, target_level):
						continue
					if _has_wall(target, -h_dir, target_level):
						continue
				else:
					var move_dir := Vector2i(dx, dy)
					if _has_wall(origin, move_dir, origin_level):
						continue
					if _has_wall(target, -move_dir, target_level):
						continue
				if _has_obstacle_block(target, target_level):
					continue
				result.append({"grid": target, "level": target_level})
			else:
				var path := _dda_path(origin, target)
				if path.is_empty():
					continue
				if _is_path_clear(path, target_level):
					result.append({"grid": target, "level": target_level})

	return result
