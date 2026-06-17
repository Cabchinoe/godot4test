extends Node2D

@onready var player: Unit = $Player
@onready var ground_layer: TileMapLayer = $Ground10
@onready var obstacle_layer: TileMapLayer = $Ground10/obstacle
@onready var hud_layer_1: TileMapLayer = $Ground10/HUD
@onready var ground_layer_2: TileMapLayer = $Ground20
@onready var obstacle_layer_2: TileMapLayer = $Ground20/obstacle
@onready var hud_layer_2: TileMapLayer = $Ground20/HUD
@onready var hover_layer: TileMapLayer = $HUD
@onready var hover_sprite: Line2D = $HUD/CoverSprite

var level_manager: LevelManager
var reachable_cells: Array[Dictionary] = []
var player_selected: bool = false
var last_hover_node: Dictionary = {}

func _ready():
	hover_sprite.visible = false

	# 初始化 LevelManager
	level_manager = LevelManager.new()
	level_manager.add_level(1, ground_layer, obstacle_layer, hud_layer_1, 0)
	level_manager.add_level(2, ground_layer_2, obstacle_layer_2, hud_layer_2, -16)

	# 初始化 Player
	player.init_unit("Player", "player", 5, level_manager, 1)
	print("Player start grid: ", player.grid_pos, " level: ", player.current_level, " world: ", player.global_position)

func _process(delta: float):
	var mouse_world = get_global_mouse_position()
	var hover_node = _get_closest_walkable_node(mouse_world)

	if player_selected and _is_node_reachable(hover_node) and not _is_same_node(hover_node, {"grid": player.grid_pos, "level": player.current_level}):
		hover_sprite.visible = true

		if hover_node != last_hover_node:
			last_hover_node = hover_node
			var path = player.pathfinder.find_path(
				player.grid_pos, player.current_level,
				hover_node["grid"], hover_node["level"]
			)
			_draw_path(path)
	else:
		hover_sprite.visible = false
		if last_hover_node != {}:
			last_hover_node = {}
			hover_sprite.clear_points()

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world = get_global_mouse_position()
		var click_node = _get_closest_walkable_node(mouse_world)
		print("click_node: ", click_node, " player_node: ", {"grid": player.grid_pos, "level": player.current_level})

		var player_node = {"grid": player.grid_pos, "level": player.current_level}

		if player_selected and _is_node_reachable(click_node):
			var path = player.pathfinder.find_path(
				player.grid_pos, player.current_level,
				click_node["grid"], click_node["level"]
			)
			if path.size() > 0:
				player.set_move_path(path)
			player_selected = false
			_clear_all_highlights()
			hover_sprite.visible = false
			hover_sprite.clear_points()
			last_hover_node = {}
		else:
			if _is_same_node(click_node, player_node):
				player_selected = true
				_show_move_range()
			else:
				player_selected = false
				_clear_all_highlights()
				hover_sprite.visible = false
				hover_sprite.clear_points()
				last_hover_node = {}

func _show_move_range():
	_clear_all_highlights()
	reachable_cells = player.pathfinder.bfs(player.grid_pos, player.current_level, player.move_range)
	print("Player at: ", player.grid_pos, " level: ", player.current_level, " Reachable: ", reachable_cells.size())
	for node in reachable_cells:
		if node["grid"] == player.grid_pos and node["level"] == player.current_level:
			continue
		var hud = level_manager.get_layer(node["level"], "hud")
		if hud == null:
			continue
		# HUD 和 ground 的 grid 坐标一致，直接用 node["grid"]
		hud.set_cell(node["grid"], 0, Vector2i(0, 0))

func _draw_path(path: Array[Dictionary]):
	hover_sprite.clear_points()
	for node in path:
		var ground = level_manager.get_layer(node["level"], "ground")
		var cell_local = ground.map_to_local(node["grid"])
		var cell_world = ground.to_global(cell_local)
		# hover_sprite 在 $HUD/CoverSprite 下，转换到 hover_layer 的本地坐标
		var cover_local = hover_layer.to_local(cell_world)
		hover_sprite.add_point(cover_local)

func _get_closest_walkable_node(mouse_world: Vector2) -> Dictionary:
	var best_node = {}
	var best_dist = INF

	for level in level_manager.get_all_levels():
		var ground = level_manager.get_layer(level, "ground")

		# ground.to_global 已经包含 ground 节点的 position.y 偏移
		var mouse_local = ground.to_local(mouse_world)
		var grid = ground.local_to_map(mouse_local)

		if player.pathfinder.is_walkable(grid, level):
			var cell_local = ground.map_to_local(grid)
			var cell_world = ground.to_global(cell_local)
			var dist = abs(mouse_world.y - cell_world.y)
			if dist < best_dist:
				best_dist = dist
				best_node = {"grid": grid, "level": level}

	return best_node

func _is_node_reachable(node: Dictionary) -> bool:
	if node.is_empty():
		return false
	for reachable in reachable_cells:
		if reachable["grid"] == node["grid"] and reachable["level"] == node["level"]:
			return true
	return false

func _is_same_node(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return false
	return a["grid"] == b["grid"] and a["level"] == b["level"]

func _clear_all_highlights():
	for level in level_manager.get_all_levels():
		var hud = level_manager.get_layer(level, "hud")
		if hud:
			hud.clear()
