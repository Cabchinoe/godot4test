class_name BattleContainerSpawner
extends RefCounted

const DEFAULT_CLOSED_TEXTURE := "res://Art/tilesets/urban_night/props/containers/supply_crate_closed_b.png"
const DEFAULT_OPENED_TEXTURE := "res://Art/tilesets/urban_night/props/containers/supply_crate_open_b.png"
const DEFAULT_EMPTY_TEXTURE := "res://Art/tilesets/urban_night/props/containers/supply_crate_empty_b.png"
const GROUND_PILE_TEXTURE := "res://Art/tilesets/urban_night/props/containers/dropped_loot_pile_a.png"

var level_manager: LevelManager


func _init(p_level_manager: LevelManager) -> void:
	level_manager = p_level_manager


func spawn(data: Dictionary) -> BattleContainer:
	var grid: Vector2i = data.get("grid", Vector2i.ZERO)
	var level := int(data.get("level", 1))
	var ground := level_manager.get_layer(level, "ground")
	var obstacle := level_manager.get_layer(level, "obstacle")
	if ground == null or obstacle == null or ground.get_cell_tile_data(grid) == null:
		push_warning("BattleContainerSpawner: invalid grid %s lv%d" % [grid, level])
		return null
	var pathfinder := Pathfinder.new(level_manager)
	if not bool(data.get("allow_occupied", false)) and not pathfinder.is_walkable(grid, level):
		push_warning("BattleContainerSpawner: grid %s lv%d is not available for a container" % [grid, level])
		return null

	var container := BattleContainer.new()
	container.name = "Container_%s" % str(data.get("resource_id", obstacle.get_child_count()))
	obstacle.add_child(container)
	container.configure(data)
	container.top_level = true
	container.z_as_relative = false
	container.z_index = obstacle.z_index
	var world_position := ground.to_global(ground.map_to_local(grid))
	world_position.y += level_manager.get_offset(level)
	container.global_position = world_position
	return container


func spawn_batch(entries: Array) -> Array[BattleContainer]:
	var result: Array[BattleContainer] = []
	for entry in entries:
		if not entry is Dictionary:
			continue
		var container := spawn(entry as Dictionary)
		if container:
			result.append(container)
	return result


func spawn_enemy_drop(enemy: Unit) -> BattleContainer:
	if enemy == null or enemy.loot_container_data.is_empty():
		return null
	var data := enemy.loot_container_data.duplicate(true)
	data["resource_id"] = "enemy_drop_%s_%d" % [enemy.name, enemy.get_instance_id()]
	data["display_name"] = str(data.get("display_name", "%s 的战利品" % enemy.unit_name))
	data["grid"] = enemy.grid_pos
	data["level"] = enemy.current_level
	data["can_walk"] = true
	data["closed_texture_path"] = str(data.get("closed_texture_path", DEFAULT_CLOSED_TEXTURE))
	data["opened_texture_path"] = str(data.get("opened_texture_path", DEFAULT_OPENED_TEXTURE))
	data["empty_texture_path"] = str(data.get("empty_texture_path", DEFAULT_EMPTY_TEXTURE))
	return spawn(data)


func spawn_ground_pile(grid: Vector2i, level: int, resource_id: String) -> BattleContainer:
	return spawn({
		"resource_id": resource_id,
		"display_name": "丢弃物",
		"grid": grid,
		"level": level,
		"open_ap_cost": 0,
		"capacity": 32,
		"columns": 4,
		"is_ground_pile": true,
		"requires_attack_range": false,
		"can_walk": true,
		"allow_occupied": true,
		"closed_texture_path": GROUND_PILE_TEXTURE,
		"opened_texture_path": GROUND_PILE_TEXTURE,
		"empty_texture_path": GROUND_PILE_TEXTURE,
	})
