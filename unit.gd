class_name Unit
extends Node2D

var unit_name: String = ""
var faction: String = ""
var move_range: int = 5
var pathfinder: Pathfinder

var grid_pos: Vector2i = Vector2i.ZERO
var move_path: Array[Vector2i] = []
var move_timer: float = 0.0
var move_interval: float = 0.15
var is_moving: bool = false

func init_unit(p_name: String, p_faction: String, p_move_range: int, p_ground_layers: Array, p_obstacle_layer: TileMapLayer = null):
	unit_name = p_name
	faction = p_faction
	move_range = p_move_range
	var ground_layer = p_ground_layers[0] if p_ground_layers.size() > 0 else null
	pathfinder = Pathfinder.new(ground_layer, p_obstacle_layer)

func _process(delta: float):
	if is_moving and move_path.size() > 0:
		move_timer += delta
		if move_timer >= move_interval:
			move_timer = 0.0
			_step_to_next()

func _step_to_next():
	if move_path.size() == 0:
		is_moving = false
		return
	var next_grid = move_path.pop_front()
	grid_pos = next_grid
	var ground = pathfinder.ground_layer
	var local = ground.map_to_local(next_grid)
	var world_pos = ground.to_global(local)
	var sprite_offset = Vector2(8, 8) * scale
	global_position = world_pos - sprite_offset
	if move_path.size() == 0:
		is_moving = false

func set_move_path(path: Array[Vector2i]):
	move_path = path
	move_timer = 0.0
	is_moving = true
	if move_path.size() > 0 and move_path[0] == grid_pos:
		move_path.pop_front()
