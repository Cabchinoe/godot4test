class_name BattleVisibility
extends RefCounted

const DEFAULT_VISION_RANGE := 16
const MAX_FOG_OPACITY := 0.8
const ENEMY_VISIBLE_OPACITY := 0.7

var enabled := true
var vision_range := DEFAULT_VISION_RANGE
var show_blocking_containers := false
var base_cells: Dictionary = {}
var attack_cells: Dictionary = {}
var _bullet_range: BulletRange
var _sight_cells: Dictionary = {}
var _origin := Vector2i.ZERO


func _init(bullet_range: BulletRange, config: Dictionary = {}) -> void:
	_bullet_range = bullet_range
	configure(config)


func configure(config: Dictionary) -> void:
	enabled = bool(config.get("enabled", true))
	vision_range = maxi(0, int(config.get("vision_range", DEFAULT_VISION_RANGE)))
	show_blocking_containers = bool(config.get("show_blocking_containers", false))


func refresh_base(player: Player) -> void:
	_origin = player.grid_pos
	base_cells.clear()
	_sight_cells.clear()
	if not enabled:
		return
	for cell in _bullet_range.get_reachable_cells(
		player.grid_pos, player.current_level, vision_range + 3, [], true, false
	):
		var key := cell_key(cell["grid"], cell["level"])
		_sight_cells[key] = true
		if get_distance(cell["grid"]) <= vision_range:
			base_cells[key] = true
	base_cells[cell_key(player.grid_pos, player.current_level)] = true
	_sight_cells[cell_key(player.grid_pos, player.current_level)] = true


func set_attack_cells(cells: Array[Dictionary]) -> void:
	attack_cells.clear()
	for cell in cells:
		attack_cells[cell_key(cell["grid"], cell["level"])] = true


func is_base_visible(grid: Vector2i, level: int) -> bool:
	return not enabled or base_cells.has(cell_key(grid, level))


func is_visible(grid: Vector2i, level: int) -> bool:
	var key := cell_key(grid, level)
	return not enabled or base_cells.has(key) or attack_cells.has(key)


func get_distance(grid: Vector2i) -> int:
	var delta := grid - _origin
	return maxi(absi(delta.x), absi(delta.y))


func get_fog_opacity(grid: Vector2i, level: int) -> float:
	if is_visible(grid, level):
		return 0.0
	var excess := get_distance(grid) - vision_range
	if excess <= 0:
		return MAX_FOG_OPACITY
	return float(mini(8, 4 + excess)) / 10.0


func is_enemy_visible(grid: Vector2i, level: int) -> bool:
	if is_visible(grid, level):
		return true
	return (
		get_fog_opacity(grid, level) <= ENEMY_VISIBLE_OPACITY
		and _sight_cells.has(cell_key(grid, level))
	)


func is_container_exempt(container: BattleContainer) -> bool:
	return show_blocking_containers and not container.can_walk


func is_container_visible(container: BattleContainer) -> bool:
	return is_visible(container.grid_pos, container.current_level) or is_container_exempt(container)


static func cell_key(grid: Vector2i, level: int) -> Vector3i:
	return Vector3i(grid.x, grid.y, level)
