extends Node2D

@onready var player: Unit = $Player
@onready var player_sprite: AnimatedSprite2D = $Player/Sprite2D
@onready var ground_layer: TileMapLayer = $Ground10
@onready var obstacle_layer: TileMapLayer = $Ground10/obstacle
@onready var hud_layer_1: TileMapLayer = $Ground10/HUD
@onready var ground_layer_2: TileMapLayer = $Ground20
@onready var obstacle_layer_2: TileMapLayer = $Ground20/obstacle
@onready var hud_layer_2: TileMapLayer = $Ground20/HUD
@onready var hover_layer: TileMapLayer = $HUD
@onready var hover_sprite: Line2D = $HUD/CoverSprite
@onready var camera: Camera2D = $Camera2D
@onready var top_bar: HBoxContainer = $UILayer/UIRoot/TopBar
@onready var save_button: Button = $UILayer/UIRoot/TopBar/SaveButton
@onready var load_button: Button = $UILayer/UIRoot/TopBar/LoadButton
@onready var battle_button: Button = $UILayer/UIRoot/TopBar/BattleButton
@onready var menu_button: Button = $UILayer/UIRoot/TopBar/MenuButton
@onready var save_load_ui = $UILayer/UIRoot/SaveLoadUI

const DRAG_THRESHOLD: float = 5.0
const BASE_AP: int = 50

var level_manager: LevelManager
var reachable_cells: Array[Dictionary] = []
var player_selected: bool = false
var last_hover_node: Dictionary = {}

var is_dragging: bool = false
var press_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var pending_recalc_range: bool = false

func _ready():
	hover_sprite.visible = false

	level_manager = LevelManager.new()
	level_manager.add_level(1, ground_layer, obstacle_layer, hud_layer_1, 0)
	level_manager.add_level(2, ground_layer_2, obstacle_layer_2, hud_layer_2, -16)

	player.init_unit("Player", "player", BASE_AP, level_manager, 1)

	var player_provider = PlayerSaveProvider.new(player)
	SaveManager.register_provider(player_provider)

	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	battle_button.pressed.connect(_on_battle_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	save_load_ui.closed.connect(_on_save_load_closed)

func _on_save_pressed():
	save_load_ui.visible = true
	save_load_ui.refresh_slots()

func _on_load_pressed():
	save_load_ui.visible = true
	save_load_ui.refresh_slots()

func _on_save_load_closed():
	save_load_ui.visible = false

func _on_battle_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://MainMenu.tscn")

func _clear_selection():
	player_selected = false
	player_sprite.stop()
	pending_recalc_range = false
	_clear_all_highlights()
	hover_sprite.visible = false
	hover_sprite.clear_points()
	last_hover_node = {}
	top_bar.visible = true

func _process(delta: float):
	if is_dragging:
		var current_mouse = get_global_mouse_position()
		var screen_mouse = get_viewport().get_mouse_position()
		camera.position -= (screen_mouse - last_mouse_pos)
		last_mouse_pos = screen_mouse
		return

	if player.is_moving:
		return

	if pending_recalc_range and player_selected:
		pending_recalc_range = false
		player.action_points = BASE_AP
		_show_move_range()

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
	if player.is_moving:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				press_pos = event.position
				last_mouse_pos = event.position
				is_dragging = false
			else:
				var drag_dist = event.position.distance_to(press_pos)
				if drag_dist < DRAG_THRESHOLD:
					_handle_left_click()
				is_dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if player_selected:
				_clear_selection()
		return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var current_pos = event.position
			if not is_dragging and current_pos.distance_to(press_pos) >= DRAG_THRESHOLD:
				is_dragging = true
				last_mouse_pos = current_pos

func _handle_left_click():
	var mouse_world = get_global_mouse_position()
	var click_node = _get_closest_walkable_node(mouse_world)
	var player_node = {"grid": player.grid_pos, "level": player.current_level}

	if player_selected and _is_same_node(click_node, player_node):
		_clear_selection()
	elif player_selected and _is_node_reachable(click_node):
		var path = player.pathfinder.find_path(
			player.grid_pos, player.current_level,
			click_node["grid"], click_node["level"]
		)
		if path.size() > 0:
			player.set_move_path(path)
			_clear_all_highlights()
			hover_sprite.visible = false
			hover_sprite.clear_points()
			last_hover_node = {}
			pending_recalc_range = true
	else:
		if _is_same_node(click_node, player_node):
			player_selected = true
			player_sprite.play("walk")
			_show_move_range()
			top_bar.visible = false
		else:
			_clear_selection()

func _show_move_range():
	_clear_all_highlights()
	reachable_cells = player.pathfinder.bfs(player.grid_pos, player.current_level, player.action_points)
	for node in reachable_cells:
		if node["grid"] == player.grid_pos and node["level"] == player.current_level:
			continue
		var hud = level_manager.get_layer(node["level"], "hud")
		if hud == null:
			continue
		hud.set_cell(node["grid"], 0, Vector2i(0, 0))

func _draw_path(path: Array[Dictionary]):
	hover_sprite.clear_points()
	for node in path:
		var ground = level_manager.get_layer(node["level"], "ground")
		var cell_local = ground.map_to_local(node["grid"])
		var cell_world = ground.to_global(cell_local)
		var cover_local = hover_layer.to_local(cell_world)
		hover_sprite.add_point(cover_local)

func _get_closest_walkable_node(mouse_world: Vector2) -> Dictionary:
	var best_node = {}
	var best_dist = INF
	for level in level_manager.get_all_levels():
		var ground = level_manager.get_layer(level, "ground")
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
