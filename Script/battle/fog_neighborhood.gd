class_name FogNeighborhood
extends RefCounted

const OFFSETS: Array[Vector2i] = [
	Vector2i(0, -1), Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1),
	Vector2i(0, 1), Vector2i(-1, 1), Vector2i(-1, 0), Vector2i(-1, -1),
]
const VALID_DENSITIES := [0, 5, 6, 7, 8]

static var _tables: Array[Dictionary] = []


static func normalize_mask(mask: int) -> int:
	var normalized := mask
	for diagonal in [1, 3, 5, 7]:
		if not (mask & (1 << ((diagonal + 7) % 8))) or not (mask & (1 << ((diagonal + 1) % 8))):
			normalized &= ~(1 << diagonal)
	return normalized


static func transform_direction(direction: int, transform_index: int) -> int:
	var mirrored := -direction if transform_index >= 4 else direction
	return posmod(mirrored + (transform_index % 4) * 2, 8)


static func inverse_transform(transform_index: int) -> int:
	return transform_index if transform_index >= 4 else posmod(-transform_index, 4)


static func compose_transforms(outer: int, inner: int) -> int:
	for candidate in 8:
		if (
			transform_direction(0, candidate) == transform_direction(transform_direction(0, inner), outer)
			and transform_direction(2, candidate) == transform_direction(transform_direction(2, inner), outer)
		):
			return candidate
	return 0


static func transform_mask(mask: int, transform_index: int) -> int:
	var transformed := 0
	for direction in 8:
		if mask & (1 << direction):
			transformed |= 1 << transform_direction(direction, transform_index)
	return transformed


static func mask_code(mask: int) -> String:
	var code := ""
	for direction in 8:
		code += "1" if mask & (1 << direction) else "0"
	return code


static func transform_samples(samples: PackedByteArray, transform_index: int) -> PackedByteArray:
	var transformed := PackedByteArray()
	transformed.resize(9)
	transformed[0] = samples[0]
	for direction in 8:
		transformed[1 + transform_direction(direction, transform_index)] = samples[1 + direction]
	return transformed


static func transform_alpha(alpha: PackedByteArray, transform_index: int, size: int = 64) -> PackedByteArray:
	if transform_index == 0:
		return alpha
	var result := PackedByteArray()
	result.resize(alpha.size())
	for row in size:
		for column in size:
			var target_x := size - 1 - column if transform_index >= 4 else column
			var target_y := row
			for quarter_turn in transform_index % 4:
				var previous_x := target_x
				target_x = size - 1 - target_y
				target_y = previous_x
			result[target_y * size + target_x] = alpha[row * size + column]
	return result


static func _ensure_tables() -> void:
	if not _tables.is_empty():
		return
	for mask in 256:
		var normalized := normalize_mask(mask)
		var best_code := "22222222"
		var canonical_mask := 0
		var transforms := PackedByteArray()
		for transform_index in 8:
			var transformed := transform_mask(normalized, transform_index)
			var code := mask_code(transformed)
			if code < best_code:
				best_code = code
				canonical_mask = transformed
				transforms.clear()
			if code == best_code:
				transforms.append(transform_index)
		_tables.append({"mask": canonical_mask, "code": best_code, "transforms": transforms})


static func canonicalize(samples: PackedByteArray) -> Dictionary:
	if samples.size() != 9 or samples[0] not in [5, 6, 7, 8]:
		return {}
	var mask := 0
	var uniform := true
	for index in 9:
		if samples[index] not in VALID_DENSITIES:
			return {}
		if index > 0 and samples[index] > 0:
			mask |= 1 << (index - 1)
			uniform = uniform and samples[index] == samples[0]
	_ensure_tables()
	var table := _tables[mask]
	var best_values := "999999999"
	var best_samples := PackedByteArray()
	var best_transform := 0
	for transform_index in table["transforms"]:
		var transformed := transform_samples(samples, transform_index)
		var values := ""
		for value in transformed:
			values += str(value)
		if values < best_values:
			best_values = values
			best_samples = transformed
			best_transform = transform_index
	var key := "u:%s:%d" % [table["code"], samples[0]] if uniform else "m:%s:%s" % [table["code"], best_values]
	return {
		"key": key, "shape_mask": table["mask"], "samples": best_samples,
		"transform": best_transform, "uniform": uniform,
	}


static func collect_samples(densities: Dictionary, cell: Vector3i) -> PackedByteArray:
	var samples := PackedByteArray([int(densities.get(cell, 0))])
	for offset in OFFSETS:
		samples.append(int(densities.get(Vector3i(cell.x + offset.x, cell.y + offset.y, cell.z), 0)))
	return samples


static func dirty_neighborhood(previous: Dictionary, current: Dictionary) -> Dictionary:
	var dirty: Dictionary = {}
	var candidates := previous.duplicate()
	candidates.merge(current, true)
	for cell in candidates:
		if int(previous.get(cell, 0)) == int(current.get(cell, 0)):
			continue
		dirty[cell] = true
		for offset in OFFSETS:
			dirty[Vector3i(cell.x + offset.x, cell.y + offset.y, cell.z)] = true
	return dirty


static func build_render_densities(manager: LevelManager, visibility: BattleVisibility, tree: SceneTree) -> Dictionary:
	var densities: Dictionary = {}
	var immediate_clear: Dictionary = {}
	if tree and visibility.show_blocking_containers:
		for container in tree.get_nodes_in_group("battle_containers"):
			if container is BattleContainer and not container.is_queued_for_deletion() and visibility.is_container_exempt(container):
				immediate_clear[Vector3i(container.grid_pos.x, container.grid_pos.y, container.current_level)] = true
	for level in manager.get_all_levels():
		var ground := manager.get_layer(level, "ground")
		var obstacle := manager.get_layer(level, "obstacle")
		for grid in ground.get_used_cells():
			var cell := Vector3i(grid.x, grid.y, level)
			var ground_data := ground.get_cell_tile_data(grid)
			var obstacle_data := obstacle.get_cell_tile_data(grid) if obstacle else null
			var can_hold_unit := ground_data != null and int(ground_data.get_custom_data("terrain")) == 0
			if obstacle_data and not bool(obstacle_data.get_custom_data("can_walk")):
				can_hold_unit = false
			if not can_hold_unit:
				immediate_clear[cell] = true
			var density := 0
			if can_hold_unit and not immediate_clear.has(cell):
				density = roundi(visibility.get_fog_opacity(grid, level) * 10.0)
			densities[cell] = density
	return {"densities": densities, "immediate_clear": immediate_clear}
