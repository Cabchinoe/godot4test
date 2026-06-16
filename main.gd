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
	player.init_unit("Player", "player", 5, [ground_layer], obstacle_layer)
	print("Player start grid: ", player.grid_pos, " world: ", player.global_position)

func _process(delta: float):
	var mouse_world = get_global_mouse_position()
	var mouse_local = mouse_world / ground_layer.scale
	var mouse_grid = ground_layer.local_to_map(mouse_local)

	if player_selected and reachable_cells.has(mouse_grid) and mouse_grid != player.grid_pos:
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
			var path = player.pathfinder.find_path(player.grid_pos, click_grid)
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
	reachable_cells = player.pathfinder.bfs(player.grid_pos, player.move_range)
	print("Player at: ", player.grid_pos, " Reachable: ", reachable_cells.size())
	for cell in reachable_cells:
		if cell == player.grid_pos:
			continue
		highlight_layer.set_cell(cell, 0, Vector2i(0, 0))
