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
@onready var hover_sprite2: Line2D = $HUD/CoverSprite2
@onready var camera: Camera2D = $Camera2D
@onready var ap_label: Label = $UILayer/UIRoot/StatusBar/APLabel
@onready var turn_label: Label = $UILayer/UIRoot/StatusBar/TurnLabel
@onready var end_turn_button: Button = $UILayer/UIRoot/StatusBar/EndTurnButton
@onready var context_menu: PopupMenu = $UILayer/UIRoot/ContextMenu

const DRAG_THRESHOLD: float = 5.0
const ATTACK_RANGE: int = 5

var level_manager: LevelManager
var turn_controller: TurnController
var bullet_range: BulletRange
var reachable_cells: Array[Dictionary] = []
var attack_cells: Array[Dictionary] = []
var player_selected: bool = false
var attack_mode: bool = false
var last_hover_node: Dictionary = {}

var is_dragging: bool = false
var press_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var pending_recalc_range: bool = false


func _ready():
	hover_sprite.visible = false
	hover_sprite2.visible = false

	level_manager = LevelManager.new()
	level_manager.add_level(1, ground_layer, obstacle_layer, hud_layer_1, 0)
	level_manager.add_level(2, ground_layer_2, obstacle_layer_2, hud_layer_2, -16)

	player.init_unit("Player", "player", 5, level_manager, 1)
	if SaveManager.has_current_data() and SaveManager.current_data.player:
		var player_provider = PlayerSaveProvider.new(player)
		SaveManager.register_provider(player_provider)
		player_provider.read_from(SaveManager.current_data)
	print("Player start grid: ", player.grid_pos, " level: ", player.current_level, " world: ", player.global_position)

	turn_controller = TurnController.new(10)
	turn_controller.turn_started.connect(_on_turn_started)
	turn_controller.game_over.connect(_on_game_over)
	turn_controller.start_game()

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	context_menu.id_pressed.connect(_on_context_menu_pressed)

	bullet_range = BulletRange.new(level_manager)

func _on_turn_started(_turn: int):
	player.start_turn()
	_update_hud()

func _on_game_over():
	_clear_selection()
	end_turn_button.disabled = true

func _on_end_turn_pressed():
	_clear_selection()
	turn_controller.end_turn()

func _on_context_menu_pressed(id: int):
	if id == 0:
		_enter_attack_mode()
	elif id == 1:
		_clear_selection()
		turn_controller.end_turn()

func _clear_selection():
	player_selected = false
	player_sprite.stop()
	pending_recalc_range = false
	_clear_all_highlights()
	hover_sprite.visible = false
	hover_sprite.clear_points()
	last_hover_node = {}

func _process(delta: float):
	if turn_controller.is_game_over:
		return

	if is_dragging:
		var current_mouse = get_global_mouse_position()
		var screen_mouse = get_viewport().get_mouse_position()
		camera.position -= (screen_mouse - last_mouse_pos)
		last_mouse_pos = screen_mouse
		return

	if player.is_moving:
		return

	if attack_mode:
		return

	if pending_recalc_range and player_selected:
		pending_recalc_range = false
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
	if turn_controller.is_game_over:
		return
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
			_handle_right_click()
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

	if attack_mode:
		if _is_in_attack_cells(click_node):
			var path = bullet_range.get_bullet_path(player.grid_pos, click_node["grid"])
			print("[Attack] origin=", player.grid_pos, " lv=", player.current_level, " target=", click_node)
			for step in path:
				print("  step: ", step)
			_draw_gun_line(click_node["grid"], click_node["level"])
		return

	var player_node = {"grid": player.grid_pos, "level": player.current_level}

	if player_selected and _is_same_node(click_node, player_node):
		_clear_selection()
	elif player_selected and _is_node_reachable(click_node):
		var path = player.pathfinder.find_path(
			player.grid_pos, player.current_level,
			click_node["grid"], click_node["level"]
		)
		if path.size() > 0:
			var steps = path.size() - 1
			if player.spend_ap(steps):
				player.set_move_path(path)
				_update_hud()
				_clear_all_highlights()
				hover_sprite.visible = false
				hover_sprite.clear_points()
				last_hover_node = {}
				if player.action_points > 0:
					pending_recalc_range = true
				else:
					player_selected = false
					player_sprite.stop()
	else:
		if _is_same_node(click_node, player_node):
			player_selected = true
			player_sprite.play("walk")
			_show_move_range()
		else:
			_clear_selection()

func _handle_right_click():
	if attack_mode:
		_exit_attack_mode()
	elif player_selected:
		_clear_selection()
	else:
		_show_context_menu()

func _show_context_menu():
	context_menu.clear()
	context_menu.add_item("攻击", 0)
	context_menu.add_item("结束回合", 1)
	var menu_pos = get_viewport().get_mouse_position()
	context_menu.position = Vector2i(menu_pos.x, menu_pos.y)
	context_menu.popup()

func _show_move_range():
	_clear_all_highlights()
	reachable_cells = player.pathfinder.bfs(player.grid_pos, player.current_level, player.action_points)
	print("Player at: ", player.grid_pos, " level: ", player.current_level, " Reachable: ", reachable_cells.size())
	for node in reachable_cells:
		if node["grid"] == player.grid_pos and node["level"] == player.current_level:
			continue
		var hud = level_manager.get_layer(node["level"], "hud")
		if hud == null:
			continue
		hud.set_cell(node["grid"], 0, Vector2i(0, 0))

func _enter_attack_mode():
	_clear_selection()
	attack_mode = true
	attack_cells = bullet_range.get_reachable_cells(player.grid_pos, player.current_level, ATTACK_RANGE)
	print("[Attack] enter mode, cells=", attack_cells.size())
	_clear_all_highlights()
	for cell in attack_cells:
		var hud = level_manager.get_layer(cell["level"], "hud")
		if hud == null:
			continue
		hud.set_cell(cell["grid"], 0, Vector2i(0, 0))

func _exit_attack_mode():
	attack_mode = false
	attack_cells = []
	_clear_all_highlights()
	hover_sprite2.visible = false
	hover_sprite2.clear_points()

func _draw_gun_line(target_grid: Vector2i, target_level: int):
	hover_sprite2.clear_points()
	var origin_ground := level_manager.get_layer(player.current_level, "ground")
	var origin_world := origin_ground.to_global(origin_ground.map_to_local(player.grid_pos))
	hover_sprite2.add_point(hover_layer.to_local(origin_world))
	var target_ground := level_manager.get_layer(target_level, "ground")
	var target_world := target_ground.to_global(target_ground.map_to_local(target_grid))
	hover_sprite2.add_point(hover_layer.to_local(target_world))
	hover_sprite2.visible = true

func _is_in_attack_cells(node: Dictionary) -> bool:
	if node.is_empty():
		return false
	for cell in attack_cells:
		if cell["grid"] == node["grid"] and cell["level"] == node["level"]:
			return true
	return false

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

func _update_hud():
	ap_label.text = "行动点: %d/%d" % [player.action_points, player.move_range]
	turn_label.text = "回合 %d/%d" % [turn_controller.current_turn, turn_controller.max_turns]
