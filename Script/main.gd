extends Node2D

@onready var player: Unit = $Player
@onready var ground_layer: TileMapLayer = $Ground10
@onready var obstacle_layer: TileMapLayer = $Ground11
@onready var highlight_layer: TileMapLayer = $HUD
@onready var hover_sprite: Line2D = $HUD/CoverSprite

var reachable_cells: Array[Vector2i] = []
var player_selected: bool = false
var last_hover_grid: Vector2i = Vector2i(-999999, -999999)

func _ready():
	hover_sprite.visible = false
	player.init_unit("Player", "player", 5, [ground_layer], obstacle_layer)
	print("Player start grid: ", player.grid_pos, " world: ", player.global_position)

func _process(delta: float):
	var mouse_world = get_global_mouse_position()
	var mouse_local = mouse_world / ground_layer.scale
	var mouse_grid = ground_layer.local_to_map(mouse_local)

	if player_selected and reachable_cells.has(mouse_grid) and mouse_grid != player.grid_pos:
		hover_sprite.visible = true

		if mouse_grid != last_hover_grid:
			last_hover_grid = mouse_grid
			var path = player.pathfinder.find_path(player.grid_pos, mouse_grid)
			_draw_path(path)
	else:
		hover_sprite.visible = false
		if last_hover_grid != Vector2i(-999999, -999999):
			last_hover_grid = Vector2i(-999999, -999999)
			hover_sprite.clear_points()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world = get_global_mouse_position()
		var click_local = mouse_world / ground_layer.scale
		var click_grid = ground_layer.local_to_map(click_local)
		print("click_grid: ", click_grid, " player_grid: ", player.grid_pos)

		if player_selected and reachable_cells.has(click_grid):
			var path = player.pathfinder.find_path(player.grid_pos, click_grid)
			if path.size() > 0:
				player.set_move_path(path)
			player_selected = false
			highlight_layer.clear()
			hover_sprite.visible = false
			hover_sprite.clear_points()
			last_hover_grid = Vector2i(-999999, -999999)
		else:
			if click_grid == player.grid_pos:
				player_selected = true
				_show_move_range()
			else:
				player_selected = false
				highlight_layer.clear()
				hover_sprite.visible = false
				hover_sprite.clear_points()
				last_hover_grid = Vector2i(-999999, -999999)

func _show_move_range():
	highlight_layer.clear()
	reachable_cells = player.pathfinder.bfs(player.grid_pos, player.move_range)
	print("Player at: ", player.grid_pos, " Reachable: ", reachable_cells.size())
	for cell in reachable_cells:
		if cell == player.grid_pos:
			continue
		highlight_layer.set_cell(cell, 0, Vector2i(0, 0))

func _draw_path(path: Array[Vector2i]):
	hover_sprite.clear_points()
	for cell in path:
		var cell_local = ground_layer.map_to_local(cell)
		var cell_world = ground_layer.to_global(cell_local)
		var cover_local = (cell_world - highlight_layer.global_position) / highlight_layer.scale
		hover_sprite.add_point(cover_local)
