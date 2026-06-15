extends Node2D

@onready var player: Unit = $Player
@onready var ground_layer: TileMapLayer = $Ground10
@onready var obstacle_layer: TileMapLayer = $Ground11
@onready var highlight_layer: TileMapLayer = $Cover1
@onready var hover_sprite: Sprite2D = $Cover1/CoverSprite

var reachable_cells: Array[Vector2i] = []
var player_selected: bool = false

func _ready():
	hover_sprite.visible = false
	hover_sprite.modulate = Color(1, 1, 1, 0.5)
	print("Player start grid: ", player.grid_pos, " world: ", player.global_position)

func _process(delta: float):
	var mouse_world = get_global_mouse_position()
	var mouse_local = mouse_world / ground_layer.scale
	var mouse_grid = ground_layer.local_to_map(mouse_local)

	if reachable_cells.has(mouse_grid) and mouse_grid != player.grid_pos:
		var cell_local = ground_layer.map_to_local(mouse_grid)
		var cell_world = ground_layer.to_global(cell_local)
		# CoverSprite is child of Cover1, so use Cover1 local coords
		var cover_local = (cell_world - highlight_layer.global_position) / highlight_layer.scale
		hover_sprite.position = cover_local
		hover_sprite.visible = true
	else:
		hover_sprite.visible = false

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world = get_global_mouse_position()
		var click_local = mouse_world / ground_layer.scale
		var click_grid = ground_layer.local_to_map(click_local)
		print("click_grid: ", click_grid, " player_grid: ", player.grid_pos)

		if player_selected and reachable_cells.has(click_grid):
			var path = _find_path(player.grid_pos, click_grid)
			if path.size() > 0:
				player.set_move_path(path)
			player_selected = false
			highlight_layer.clear()
		else:
			if click_grid == player.grid_pos:
				player_selected = true
				_show_move_range()
			else:
				player_selected = false
				highlight_layer.clear()

func _show_move_range():
	highlight_layer.clear()
	reachable_cells = _bfs(player.grid_pos, player.move_range)
	print("Player at: ", player.grid_pos, " Reachable: ", reachable_cells.size())
	for cell in reachable_cells:
		if cell == player.grid_pos:
			continue
		highlight_layer.set_cell(cell, 0, Vector2i(0, 0))

func _bfs(start: Vector2i, max_steps: int) -> Array[Vector2i]:
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

		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next = pos + dir
			if visited.has(next):
				continue
			if not _is_walkable(next):
				continue
			visited[next] = true
			queue.append([next, steps + 1])

	return result

func _is_walkable(grid: Vector2i) -> bool:
	var ground_data = ground_layer.get_cell_tile_data(grid)
	if ground_data == null:
		return false
	if ground_data.get_custom_data("terrain") != 0:
		return false

	var obstacle_data = obstacle_layer.get_cell_tile_data(grid)
	if obstacle_data != null:
		if obstacle_data.get_custom_data("height") != 0:
			return false

	return true

func _find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	# BFS to find shortest path
	var visited: Dictionary = {}
	var queue: Array = []
	var parent: Dictionary = {}

	queue.append(from)
	visited[from] = true
	parent[from] = null

	while queue.size() > 0:
		var pos: Vector2i = queue.pop_front()

		if pos == to:
			# Reconstruct path
			var path: Array[Vector2i] = []
			var current = to
			while current != null:
				path.append(current)
				current = parent[current]
			path.reverse()
			print("Path found: ", path)
			return path

		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var next = pos + dir
			if visited.has(next):
				continue
			if not _is_walkable(next):
				continue
			visited[next] = true
			parent[next] = pos
			queue.append(next)

	print("No path found from ", from, " to ", to)
	return []
