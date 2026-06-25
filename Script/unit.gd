class_name Unit
extends Node2D

signal movement_finished

var unit_name: String = ""
var faction: String = ""
var ap_max: int = 5
var pathfinder: Pathfinder
var level_manager: LevelManager

var grid_pos: Vector2i = Vector2i.ZERO
var current_level: int = 1
var move_path: Array[Dictionary] = []
var move_timer: float = 0.0
var move_interval: float = 0.15
var is_moving: bool = false
var action_points: int = 0

func init_unit(p_name: String, p_faction: String, p_ap_max: int, p_level_manager: LevelManager, p_start_level: int = 1):
	unit_name = p_name
	faction = p_faction
	ap_max = p_ap_max
	action_points = ap_max
	level_manager = p_level_manager
	current_level = p_start_level
	pathfinder = Pathfinder.new(level_manager)
	_update_z_index()
	add_to_group("units")
	add_to_group(faction)

func _update_z_index():
	var obstacle = level_manager.get_layer(current_level, "obstacle")
	if obstacle:
		z_index = obstacle.z_index + 1

func start_turn():
	action_points = ap_max

func spend_ap(cost: int) -> bool:
	if action_points >= cost:
		action_points -= cost
		return true
	return false

func _process(delta: float):
	if is_moving and move_path.size() > 0:
		move_timer += delta
		if move_timer >= move_interval:
			move_timer = 0.0
			_step_to_next()

func _step_to_next():
	if move_path.size() == 0:
		if is_moving:
			is_moving = false
			movement_finished.emit()
		return
	var next_node = move_path.pop_front()
	grid_pos = next_node["grid"]
	current_level = next_node["level"]
	
	var ground = level_manager.get_layer(current_level, "ground")
	var local = ground.map_to_local(grid_pos)
	var world_pos = ground.to_global(local)
	world_pos.y += level_manager.get_offset(current_level)
	var sprite = get_node("Sprite2D")
	var sprite_offset = sprite.offset * scale
	global_position = world_pos - sprite_offset
	_update_z_index()
	if move_path.size() == 0:
		is_moving = false
		movement_finished.emit()

func set_move_path(path: Array[Dictionary]):
	move_path = path
	move_timer = 0.0
	if move_path.size() > 0 and move_path[0]["grid"] == grid_pos and move_path[0]["level"] == current_level:
		move_path.pop_front()
	if move_path.size() == 0:
		is_moving = false
		movement_finished.emit()
		return
	is_moving = true
