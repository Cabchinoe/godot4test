class_name Unit
extends Node2D

@export var move_range: int = 5

var grid_pos: Vector2i = Vector2i.ZERO
var move_path: Array[Vector2i] = []
var move_timer: float = 0.0
var move_interval: float = 0.15
var is_moving: bool = false

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
	var ground = get_parent().get_node("Ground10")
	var local = ground.map_to_local(next_grid)
	var world_pos = ground.to_global(local)
	# Account for Sprite2D offset scaled by Player's scale
	# Sprite2D position is (8, 8) in Player local space, Player scale is (4, 4)
	# So visual offset in world space is (32, 32)
	var sprite_offset = Vector2(8, 8) * scale
	global_position = world_pos - sprite_offset
	if move_path.size() == 0:
		is_moving = false

func set_move_path(path: Array[Vector2i]):
	move_path = path
	move_timer = 0.0
	is_moving = true
	# Remove current position from path
	if move_path.size() > 0 and move_path[0] == grid_pos:
		move_path.pop_front()
