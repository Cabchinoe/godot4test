extends Node2D

@onready var player: Benny = $Player
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
@onready var hp_label: Label = $UILayer/UIRoot/StatusBar/HPLabel
@onready var turn_label: Label = $UILayer/UIRoot/StatusBar/TurnLabel
@onready var end_turn_button: Button = $UILayer/UIRoot/StatusBar/EndTurnButton
@onready var context_menu: BattleContextMenu = $UILayer/UIRoot/ContextMenu
@onready var enemies_container: Node2D = $Enemies

const BATTLE_LOADOUT_PANEL_SCRIPT := preload("res://Script/inventory/ui/battle_loadout_panel.gd")
const BATTLE_COMBAT_RESOLVER_SCRIPT := preload("res://Script/battle_combat_resolver.gd")
const BATTLE_CONTAINER_SPAWNER_SCRIPT := preload("res://Script/battle_container_spawner.gd")
const BATTLE_CONTAINER_ACTION_MENU_SCRIPT := preload("res://Script/ui/battle_container_action_menu.gd")

const DRAG_THRESHOLD: float = 5.0
const MOVE_RANGE_SOURCE_ID: int = 0
const ATTACK_RANGE_SOURCE_ID: int = 1
const ATTACK_GRAY_ATLAS := Vector2i(0, 0)
const ATTACK_GREEN_ATLAS := Vector2i(1, 0)

var level_manager: LevelManager
var turn_controller: TurnController
var bullet_range: BulletRange
var combat_resolver: BattleCombatResolver
var container_spawner: BattleContainerSpawner
enum State { IDLE, MOVE_STATE, MENU_STATE, ATTACK_STATE }
var current_state: int = State.IDLE
var enemy_spawner: EnemySpawner
var enemy_ai: EnemyAI
var player_save_provider: PlayerSaveProvider
var inventory: InventorySaveData
var battle_loadout_panel: BattleLoadoutPanel
var container_action_menu: BattleContainerActionMenu
var reachable_cells: Array[Dictionary] = []
var attack_cells: Array[Dictionary] = []
var attack_unit_cells: Array = []
var last_hover_node: Dictionary = {}

var is_dragging: bool = false
var press_pos: Vector2 = Vector2.ZERO
var last_mouse_pos: Vector2 = Vector2.ZERO
var pending_recalc_range: bool = false

const DEFAULT_MOVE_INTERVAL: float = 0.3
const FAST_MOVE_INTERVAL: float = 0.01
var skip_held: bool = false
var _pending_container: BattleContainer
var _context_search_container: BattleContainer


func _ready():
	hover_sprite.visible = false
	hover_sprite2.visible = false

	if ItemDB.get_all_items().is_empty():
		ItemDB.load_from_dir("res://conf/items")
	if EnemyDB.get_all_ids().is_empty():
		EnemyDB.load_from_file("res://conf/enemies.json")

	level_manager = LevelManager.new()
	level_manager.add_level(1, ground_layer, obstacle_layer, hud_layer_1, 0)
	level_manager.add_level(2, ground_layer_2, obstacle_layer_2, hud_layer_2, -16)

	player.initialize_player(level_manager)
	player.movement_finished.connect(_on_player_movement_finished)
	player_save_provider = PlayerSaveProvider.new(player)
	SaveManager.register_provider(player_save_provider)
	SaveManager.reload_current()
	if SaveManager.current_data == null:
		SaveManager.create_new_game()
	inventory = WarehouseService.ensure_data(SaveManager.current_data)
	player.sync_equipment_from_save(SaveManager.current_data.player)
	player.sync_battle_equipment(inventory)
	battle_loadout_panel = BATTLE_LOADOUT_PANEL_SCRIPT.new()
	$UILayer/UIRoot.add_child(battle_loadout_panel)
	battle_loadout_panel.configure(inventory, player, SaveManager.current_data.player)
	battle_loadout_panel.consumable_use_requested.connect(_on_consumable_use_requested)
	battle_loadout_panel.discard_requested.connect(_on_discard_requested)
	battle_loadout_panel.temporary_container_changed.connect(_on_temporary_container_changed)
	container_action_menu = BATTLE_CONTAINER_ACTION_MENU_SCRIPT.new()
	$UILayer/UIRoot.add_child(container_action_menu)
	container_action_menu.search_requested.connect(_on_container_search_requested)
	player.defeated.connect(_on_unit_defeated)
	player.damaged.connect(_on_player_damaged)
	_configure_hud()
	print("Player start grid: ", player.grid_pos, " level: ", player.current_level, " world: ", player.global_position)

	bullet_range = BulletRange.new(level_manager)
	combat_resolver = BATTLE_COMBAT_RESOLVER_SCRIPT.new()
	container_spawner = BATTLE_CONTAINER_SPAWNER_SCRIPT.new(level_manager)
	_spawn_map_containers()

	turn_controller = TurnController.new(10)
	turn_controller.turn_started.connect(_on_turn_started)
	turn_controller.game_over.connect(_on_game_over)
	turn_controller.phase_changed.connect(_on_phase_changed)
	turn_controller.start_game()

	end_turn_button.pressed.connect(_on_end_turn_pressed)
	context_menu.attack_requested.connect(_on_attack_requested)
	context_menu.search_requested.connect(_on_context_menu_search_requested)
	context_menu.end_turn_requested.connect(_on_end_turn_pressed)
	context_menu.properties_requested.connect(_on_properties_requested)
	context_menu.popup_hide.connect(_on_context_menu_hide)

	enemy_spawner = EnemySpawner.new(level_manager, enemies_container)
	for enemy in enemy_spawner.spawn_batch([
		{"id": "infantry", "grid": Vector2i(5, 3), "level": 1},
		{"id": "raider_scout", "grid": Vector2i(7, 5), "level": 1},
		{"id": "raider_bulwark", "grid": Vector2i(9, 3), "level": 1},
		{"id": "pyroxene_hound", "grid": Vector2i(3, 7), "level": 1},
		{"id": "pyroxene_sentry", "grid": Vector2i(10, 7), "level": 1},
	]):
		enemy.defeated.connect(_on_unit_defeated)
	enemy_ai = EnemyAI.new(bullet_range, combat_resolver)

func _exit_tree() -> void:
	if inventory:
		WarehouseService.clear_all_temporary_containers(inventory)
	if player_save_provider:
		SaveManager.unregister_provider(player_save_provider)

func _on_turn_started(_turn: int):
	_log_turn_events(combat_resolver.begin_turn(player))
	_update_hud()
	_update_player_animation()

func _on_player_movement_finished() -> void:
	_update_player_animation()

# 状态机 → 动画：取消选中停所有；选中：攻击→aim，AP>0→walk，否则→idle
func _update_player_animation() -> void:
	if current_state == State.IDLE:
		player.stop_all()
		return
	if current_state == State.ATTACK_STATE:
		player.play_aim()
	elif player.action_points > 0:
		player.play_walk()
	else:
		player.play_idle()

func _on_game_over():
	_change_state(State.IDLE)
	end_turn_button.disabled = true

func _on_phase_changed(phase):
	if phase == TurnController.Phase.ENEMY_PHASE:
		await _run_enemy_phase()
		turn_controller.end_enemy_phase()
	else:
		_set_all_units_move_interval(DEFAULT_MOVE_INTERVAL)
		skip_held = false

func _run_enemy_phase() -> void:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.is_defeated:
			continue
		_log_turn_events(combat_resolver.begin_turn(e))
		if e.is_defeated:
			continue
		await enemy_ai.run_turn(e)
		_update_hud()

func _set_all_units_move_interval(interval: float) -> void:
	for u in get_tree().get_nodes_in_group("units"):
		u.move_interval = interval

func _update_skip_input() -> void:
	if turn_controller.current_phase != TurnController.Phase.ENEMY_PHASE:
		if skip_held:
			skip_held = false
			_set_all_units_move_interval(DEFAULT_MOVE_INTERVAL)
		return
	var pressed: bool = Input.is_key_pressed(KEY_SPACE)
	if pressed and not skip_held:
		skip_held = true
		_set_all_units_move_interval(FAST_MOVE_INTERVAL)
	elif not pressed and skip_held:
		skip_held = false
		_set_all_units_move_interval(DEFAULT_MOVE_INTERVAL)

func _on_end_turn_pressed():
	_change_state(State.IDLE)
	_hide_all_battle_panels()
	turn_controller.end_turn()


func _hide_all_battle_panels() -> void:
	if context_menu.visible:
		context_menu.hide()
	if container_action_menu and container_action_menu.visible:
		container_action_menu.hide()
	if battle_loadout_panel:
		battle_loadout_panel.hide_all_panels()
	_pending_container = null
	_context_search_container = null

func _on_attack_requested() -> void:
	if not player.has_equipped_weapon():
		return
	battle_loadout_panel.hide_panel()
	_change_state(State.ATTACK_STATE)


func _on_properties_requested() -> void:
	_change_state(State.IDLE)
	battle_loadout_panel.show_for_operator()


func _on_consumable_use_requested(source: ItemLocation, item_uid: String) -> void:
	if turn_controller.is_game_over or turn_controller.current_phase != TurnController.Phase.PLAYER_PHASE:
		return
	var source_container := WarehouseService.get_container(inventory, source)
	if source_container == null:
		return
	var item := source_container.get_item(source.position)
	if str(item.get("uid", "")) != item_uid:
		return
	var item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	if not (item_data is Dictionary):
		return
	var use_data := item_data as Dictionary
	if not BattleItemUseResolver.can_use(player, use_data):
		battle_loadout_panel.refresh_after_battle_action(BattleItemUseResolver.get_unavailable_reason(player, use_data))
		return
	var ap_cost := BattleItemUseResolver.get_ap_cost(use_data)
	if not player.spend_ap(ap_cost):
		battle_loadout_panel.refresh_after_battle_action("行动点不足。")
		return
	if not WarehouseService.consume_item(inventory, source, SaveManager.current_data.player):
		player.action_points += ap_cost
		battle_loadout_panel.refresh_after_battle_action("物品已不在背包中。")
		return
	var use_result := BattleItemUseResolver.apply(player, use_data)
	var messages: Array[String] = []
	if int(use_result.get("healed", 0)) > 0:
		messages.append("恢复 %d HP" % int(use_result.get("healed", 0)))
	if int(use_result.get("restored_ap", 0)) > 0:
		messages.append("恢复 %d AP" % int(use_result.get("restored_ap", 0)))
	for removed_status in use_result.get("removed_statuses", []):
		if not (removed_status is Dictionary):
			continue
		var status_data := removed_status as Dictionary
		var status_id := str(status_data.get("id", ""))
		var status_name: String = str({"bleeding": "流血", "fractured": "骨折"}.get(status_id, status_id))
		var removed_stacks := int(status_data.get("stacks", -1))
		messages.append(
			"移除%s" % status_name if removed_stacks < 0 else "移除%s %d 层" % [status_name, removed_stacks]
		)
	var detail := "；".join(messages)
	battle_loadout_panel.refresh_after_battle_action("已使用%s%s。" % [
		str(use_data.get("name", "物品")),
		"：" + detail if not detail.is_empty() else "",
	])
	_update_hud()

func _on_context_menu_hide():
	_context_search_container = null
	if current_state == State.MENU_STATE:
		_change_state(State.IDLE)

func _change_state(new_state: int):
	current_state = new_state
	reachable_cells = []
	attack_cells = []
	attack_unit_cells = []
	pending_recalc_range = false
	last_hover_node = {}
	hover_sprite.visible = false
	hover_sprite.clear_points()
	hover_sprite2.visible = false
	hover_sprite2.clear_points()
	_clear_all_highlights()
	if context_menu.visible:
		context_menu.hide()
	if container_action_menu and container_action_menu.visible:
		container_action_menu.hide()

	match new_state:
		State.IDLE:
			pass
		State.MOVE_STATE:
			if player.action_points > 0:
				_show_move_range()
		State.MENU_STATE:
			_show_context_menu()
		State.ATTACK_STATE:
			_enter_attack()
	_update_player_animation()

func _process(delta: float):
	if turn_controller.is_game_over:
		return

	_update_skip_input()
	if battle_loadout_panel and battle_loadout_panel.is_item_drag_active():
		return

	if turn_controller.current_phase != TurnController.Phase.PLAYER_PHASE:
		return

	if is_dragging:
		var current_mouse = get_global_mouse_position()
		var screen_mouse = get_viewport().get_mouse_position()
		camera.position -= (screen_mouse - last_mouse_pos)
		last_mouse_pos = screen_mouse
		return

	if player.is_moving:
		return

	if current_state == State.ATTACK_STATE:
		var attack_mouse_world = get_global_mouse_position()
		var attack_hover = _get_closest_attack_node(attack_mouse_world)
		if _is_in_attack_cells(attack_hover) and _is_in_unit_cells(attack_hover):
			if attack_hover != last_hover_node:
				last_hover_node = attack_hover
				_draw_gun_line(attack_hover["grid"], attack_hover["level"])
		else:
			if last_hover_node != {}:
				last_hover_node = {}
				hover_sprite2.visible = false
				hover_sprite2.clear_points()
		return

	if current_state == State.MENU_STATE:
		return

	if pending_recalc_range and current_state == State.MOVE_STATE:
		pending_recalc_range = false
		_show_move_range()

	if current_state == State.MOVE_STATE:
		var mouse_world = get_global_mouse_position()
		var hover_node = _get_closest_walkable_node(mouse_world)

		if _is_node_reachable(hover_node) and not _is_same_node(hover_node, {"grid": player.grid_pos, "level": player.current_level}):
			hover_sprite.visible = true
			if hover_node != last_hover_node:
				last_hover_node = hover_node
				var path = player.pathfinder.find_path(
					player.grid_pos, player.current_level,
					hover_node["grid"], hover_node["level"],
					player
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
	if turn_controller.current_phase != TurnController.Phase.PLAYER_PHASE:
		return
	if battle_loadout_panel and battle_loadout_panel.is_item_drag_active():
		return
	if player.is_moving:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if container_action_menu.visible:
				container_action_menu.hide()
				return
			if context_menu.visible:
				_change_state(State.IDLE)
				return
			_handle_right_click(event)
			return
		if container_action_menu.visible:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				container_action_menu.hide()
			return
		if context_menu.visible:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				_change_state(State.IDLE)
			return
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
			return

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			var current_pos = event.position
			if not is_dragging and current_pos.distance_to(press_pos) >= DRAG_THRESHOLD:
				is_dragging = true
				last_mouse_pos = current_pos

func _handle_left_click():
	var mouse_world = get_global_mouse_position()

	if current_state == State.ATTACK_STATE:
		var attack_click_node = _get_closest_attack_node(mouse_world)
		var target := _get_enemy_at_node(attack_click_node)
		if _is_in_attack_cells(attack_click_node) and target and player.spend_ap(player.get_attack_cost()):
			var result := combat_resolver.resolve_attack(player, target)
			print(BattleCombatLogFormatter.format_attack(result))
			print("[攻击结算 JSON] ", result)
			_update_hud()
			_change_state(State.IDLE)
		return

	var click_node = _get_closest_walkable_node(mouse_world)
	var player_node = {"grid": player.grid_pos, "level": player.current_level}

	if current_state == State.MOVE_STATE:
		if _is_node_reachable(click_node) and not _is_same_node(click_node, player_node):
			var path = player.pathfinder.find_path(
				player.grid_pos, player.current_level,
				click_node["grid"], click_node["level"],
				player
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
						reachable_cells = []
		else:
			_change_state(State.IDLE)
		return

	if current_state == State.IDLE:
		if _is_same_node(click_node, player_node):
			battle_loadout_panel.hide_panel()
			_change_state(State.MOVE_STATE)

func _handle_right_click(event: InputEvent):
	var mouse_world = get_global_mouse_position()
	if current_state == State.IDLE:
		var click_node := _get_closest_walkable_node(mouse_world)
		var player_node := {"grid": player.grid_pos, "level": player.current_level}
		if _is_same_node(click_node, player_node):
			battle_loadout_panel.hide_panel()
			_change_state(State.MENU_STATE)
			return
	var container := _get_container_at(mouse_world)
	if container:
		if current_state != State.IDLE:
			_change_state(State.IDLE)
		_show_container_action_menu(container, Vector2i(event.position.x, event.position.y))
		return
	if current_state == State.ATTACK_STATE:
		_change_state(State.IDLE)
		return
	if current_state == State.MOVE_STATE:
		_change_state(State.IDLE)
		return
	if current_state == State.IDLE:
		var click_node = _get_closest_walkable_node(mouse_world)
		var player_node = {"grid": player.grid_pos, "level": player.current_level}
		if _is_same_node(click_node, player_node):
			battle_loadout_panel.hide_panel()
			_change_state(State.MENU_STATE)

func _show_context_menu():
	var menu_pos = get_viewport().get_mouse_position()
	var attack_cost := player.get_attack_cost()
	var has_weapon := player.has_equipped_weapon()
	var attack_enabled := has_weapon and player.action_points >= attack_cost
	var attack_reason := ""
	if not has_weapon:
		attack_reason = "未装备武器。"
	elif player.action_points < attack_cost:
		attack_reason = "行动点不足。"
	var standing_container := _get_container_at_grid(player.grid_pos, player.current_level)
	_context_search_container = standing_container
	var has_search_target := standing_container != null
	var search_label := ""
	var search_cost := 0
	var search_enabled := false
	var search_reason := ""
	if standing_container:
		search_label = "继续搜索" if standing_container.is_opened else "搜索"
		search_cost = standing_container.get_search_ap_cost()
		var has_loot := standing_container.has_remaining_loot(inventory)
		var in_range := standing_container.can_be_searched_by(player, bullet_range)
		search_enabled = has_loot and in_range and player.action_points >= search_cost
		if not has_loot:
			search_reason = "容器已搜空。"
		elif not in_range:
			search_reason = "当前无法搜索该容器。"
		elif player.action_points < search_cost:
			search_reason = "行动点不足。"
	context_menu.show_actions(
		attack_cost,
		attack_enabled,
		attack_reason,
		has_search_target,
		search_label,
		search_cost,
		search_enabled,
		search_reason,
		Vector2i(menu_pos.x, menu_pos.y)
	)

func _show_move_range():
	_clear_all_highlights()
	reachable_cells = player.pathfinder.bfs(player.grid_pos, player.current_level, player.action_points, player)
	print("Player at: ", player.grid_pos, " level: ", player.current_level, " Reachable: ", reachable_cells.size())
	for node in reachable_cells:
		if node["grid"] == player.grid_pos and node["level"] == player.current_level:
			continue
		var hud = level_manager.get_layer(node["level"], "hud")
		if hud == null:
			continue
		hud.set_cell(node["grid"], MOVE_RANGE_SOURCE_ID, Vector2i(0, 0))

func _enter_attack():
	if not player.has_equipped_weapon():
		_change_state(State.IDLE)
		return
	attack_unit_cells = _collect_targetable_cells()
	attack_cells = bullet_range.get_reachable_cells(player.grid_pos, player.current_level, player.get_attack_range(), attack_unit_cells)
	print("[Attack] enter mode, cells=", attack_cells.size())
	for cell in attack_cells:
		var hud = level_manager.get_layer(cell["level"], "hud")
		if hud == null:
			continue
		var atlas: Vector2i = ATTACK_GREEN_ATLAS if _is_in_unit_cells(cell) else ATTACK_GRAY_ATLAS
		hud.set_cell(cell["grid"], ATTACK_RANGE_SOURCE_ID, atlas)

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

func _is_in_unit_cells(node: Dictionary) -> bool:
	if node.is_empty():
		return false
	for cell in attack_unit_cells:
		if cell["grid"] == node["grid"] and cell["level"] == node["level"]:
			return true
	return false

func _collect_targetable_cells() -> Array:
	var cells: Array = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if not e.is_defeated:
			cells.append({"grid": e.grid_pos, "level": e.current_level})
	return cells

func _get_enemy_at_node(node: Dictionary) -> Unit:
	if node.is_empty():
		return null
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_defeated and enemy.grid_pos == node["grid"] and enemy.current_level == node["level"]:
			return enemy
	return null

func _get_container_at(mouse_world: Vector2) -> BattleContainer:
	var closest: BattleContainer
	var closest_distance := INF
	for node in get_tree().get_nodes_in_group("battle_containers"):
		var container := node as BattleContainer
		if container == null:
			continue
		var distance := mouse_world.distance_to(container.global_position)
		if distance <= container.interaction_radius and distance < closest_distance:
			closest = container
			closest_distance = distance
	return closest


func _get_container_at_grid(grid: Vector2i, level: int) -> BattleContainer:
	for node in get_tree().get_nodes_in_group("battle_containers"):
		var container := node as BattleContainer
		if container and container.grid_pos == grid and container.current_level == level:
			return container
	return null

func _show_container_action_menu(container: BattleContainer, screen_position: Vector2i) -> void:
	if container == null:
		return
	_pending_container = container
	var in_range := container.can_be_searched_by(player, bullet_range)
	var has_loot := container.has_remaining_loot(inventory)
	container.set_depleted(not has_loot and container.has_seeded_loot())
	var ap_cost := container.get_search_ap_cost()
	var enough_ap := player.action_points >= ap_cost
	var enabled := in_range and has_loot and enough_ap
	var reason := ""
	if not in_range:
		reason = "需要位于 1 格攻击射线内。"
	elif not has_loot:
		reason = "容器已搜空。"
	elif not enough_ap:
		reason = "行动点不足。"
	container_action_menu.show_search(
		container.display_name,
		container.is_opened,
		ap_cost,
		enabled,
		reason,
		screen_position
	)


func _on_container_search_requested() -> void:
	if _pending_container == null or not is_instance_valid(_pending_container):
		return
	var container := _pending_container
	_pending_container = null
	_search_container(container)


func _on_context_menu_search_requested() -> void:
	if _context_search_container == null or not is_instance_valid(_context_search_container):
		return
	var container := _context_search_container
	_context_search_container = null
	_search_container(container)


func _search_container(container: BattleContainer) -> void:
	if container == null:
		return
	if not container.has_remaining_loot(inventory):
		return
	container.set_depleted(false)
	var search_result := container.begin_search(player, bullet_range)
	if search_result.is_empty():
		return
	battle_loadout_panel.open_search_container(
		container.resource_id,
		container.display_name,
		container.capacity,
		container.columns
	)
	if not container.has_seeded_loot():
		for item_id in container.loot_item_ids:
			battle_loadout_panel.add_search_item(item_id)
		container.mark_loot_seeded()
	var ap_cost := int(search_result.get("ap_cost", 0))
	battle_loadout_panel.refresh_after_battle_action(
		"正在搜索：%s%s" % [
			container.display_name,
			"（免费）" if ap_cost <= 0 else "（%d AP）" % ap_cost,
		]
	)
	_update_hud()


func _on_discard_requested(source: ItemLocation, item_uid: String) -> void:
	var source_container := WarehouseService.get_container(inventory, source)
	if source_container == null or str(source_container.get_item(source.position).get("uid", "")) != item_uid:
		return
	var pile := _get_or_create_ground_pile()
	if pile == null:
		battle_loadout_panel.refresh_after_battle_action("当前格无法放置丢弃物。")
		return
	var temporary_id := pile.get_temporary_container_id()
	WarehouseService.create_temporary_container(inventory, temporary_id, pile.capacity, pile.columns)
	var target_position := _first_empty_temporary_position(temporary_id)
	if target_position < 0:
		battle_loadout_panel.refresh_after_battle_action("丢弃物堆已满。")
		return
	if not WarehouseService.transfer_item(
		inventory,
		source,
		ItemLocation.temporary(temporary_id, target_position),
		SaveManager.current_data.player
	):
		battle_loadout_panel.refresh_after_battle_action("无法丢弃该物品。")
		return
	pile.mark_loot_seeded()
	battle_loadout_panel.refresh_after_battle_action("物品已丢弃到当前格。")


func _get_or_create_ground_pile() -> BattleContainer:
	for node in get_tree().get_nodes_in_group("battle_containers"):
		var container := node as BattleContainer
		if container and container.is_ground_pile and container.grid_pos == player.grid_pos and container.current_level == player.current_level:
			return container
	var resource_id := "discarded_%d_%d_%d" % [player.current_level, player.grid_pos.x, player.grid_pos.y]
	var pile := container_spawner.spawn_ground_pile(player.grid_pos, player.current_level, resource_id)
	if pile:
		WarehouseService.create_temporary_container(inventory, pile.get_temporary_container_id(), pile.capacity, pile.columns)
		pile.mark_loot_seeded()
	return pile


func _first_empty_temporary_position(container_id: String) -> int:
	var items := WarehouseService.get_temporary_items(inventory, container_id)
	for position in WarehouseService.get_temporary_capacity(inventory, container_id):
		if not items.has(position):
			return position
	return -1


func _on_temporary_container_changed(container_id: String) -> void:
	if container_id.is_empty():
		return
	for node in get_tree().get_nodes_in_group("battle_containers"):
		var container := node as BattleContainer
		if container == null or container.get_temporary_container_id() != container_id:
			continue
		if container.has_remaining_loot(inventory):
			container.set_depleted(false)
			return
		if not container.is_ground_pile:
			container.set_depleted(true)
			return
		WarehouseService.clear_temporary_container(inventory, container_id, false)
		container.queue_free()
		battle_loadout_panel.close_temporary_container(false)
		return

func _spawn_map_containers() -> void:
	container_spawner.spawn_batch([
		{
			"resource_id": "map_supply_crate_01",
			"display_name": "街角补给箱",
			"grid": Vector2i(3, 5),
			"level": 1,
			"open_ap_cost": 1,
			"capacity": 8,
				"columns": 4,
				"loot": ["material_metal_01", "consumable_dried_medicine_02"],
				"closed_texture_path": "res://Art/tilesets/urban_night/props/containers/supply_crate_closed_b.png",
				"opened_texture_path": "res://Art/tilesets/urban_night/props/containers/supply_crate_open_b.png",
				"empty_texture_path": "res://Art/tilesets/urban_night/props/containers/supply_crate_empty_b.png",
			},
			{
				"resource_id": "map_medical_locker_01",
				"display_name": "废车旁医疗柜",
				"grid": Vector2i(8, 7),
				"level": 1,
				"open_ap_cost": 2,
				"capacity": 8,
				"columns": 4,
				"loot": ["consumable_medkit_01", "consumable_sterile_bandage_04"],
				"closed_texture_path": "res://Art/tilesets/urban_night/props/containers/medical_locker_closed_b.png",
				"opened_texture_path": "res://Art/tilesets/urban_night/props/containers/medical_locker_open_b.png",
				"empty_texture_path": "res://Art/tilesets/urban_night/props/containers/medical_locker_empty_b.png",
			},
			{
				"resource_id": "map_trash_bin_01",
				"display_name": "路边垃圾桶",
				"grid": Vector2i(1, 8),
				"level": 1,
				"open_ap_cost": 1,
				"capacity": 4,
				"columns": 2,
				"can_walk": true,
				"loot": ["material_frayed_fiber_00", "material_metal_01"],
				"closed_texture_path": "res://Art/tilesets/urban_night/props/containers/trash_bin_closed_b.png",
				"opened_texture_path": "res://Art/tilesets/urban_night/props/containers/trash_bin_open_b.png",
				"empty_texture_path": "res://Art/tilesets/urban_night/props/containers/trash_bin_empty_b.png",
			},
			{
				"resource_id": "map_vending_machine_01",
				"display_name": "破损售货机",
				"grid": Vector2i(9, 5),
				"level": 1,
				"open_ap_cost": 2,
				"capacity": 4,
				"columns": 2,
				"loot": ["consumable_compressed_ration_04", "consumable_adrenaline_01"],
				"closed_texture_path": "res://Art/tilesets/urban_night/props/containers/vending_machine_closed_b.png",
				"opened_texture_path": "res://Art/tilesets/urban_night/props/containers/vending_machine_breached_b.png",
				"empty_texture_path": "res://Art/tilesets/urban_night/props/containers/vending_machine_empty_b.png",
			},
	])

func _on_unit_defeated(unit: Unit) -> void:
	if unit == player:
		turn_controller.end_game()
		return
	if unit.faction != "enemy":
		return
	unit.remove_from_group("enemy")
	unit.remove_from_group("units")
	if container_spawner:
		container_spawner.spawn_enemy_drop(unit)
	unit.queue_free()

func _on_player_damaged(_result: Dictionary) -> void:
	if turn_controller:
		_update_hud()

func _log_turn_events(events: Array[Dictionary]) -> void:
	for event in events:
		print("[Status] ", event)

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
		if player.pathfinder.is_walkable(grid, level, player):
			var cell_local = ground.map_to_local(grid)
			var cell_world = ground.to_global(cell_local)
			var dist = abs(mouse_world.y - cell_world.y)
			if dist < best_dist:
				best_dist = dist
				best_node = {"grid": grid, "level": level}
	return best_node

func _get_closest_attack_node(mouse_world: Vector2) -> Dictionary:
	var best_node = {}
	for level in level_manager.get_all_levels():
		var ground = level_manager.get_layer(level, "ground")
		if ground == null:
			continue
		var mouse_local = ground.to_local(mouse_world)
		var grid = ground.local_to_map(mouse_local)
		for cell in attack_cells:
			if cell["grid"] == grid and cell["level"] == level:
				return cell
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
	ap_label.text = "AP  %d / %d" % [player.action_points, player.ap_max]
	hp_label.text = "HP  %d / %d" % [player.current_hp, player.max_hp]
	hp_label.add_theme_color_override("font_color", _get_hp_color(player.current_hp, player.max_hp))
	turn_label.text = "回合 %d/%d" % [turn_controller.current_turn, turn_controller.max_turns]


func _configure_hud() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC", "Hiragino Sans GB", "Arial"])
	for label in [ap_label, hp_label, turn_label]:
		label.add_theme_font_override("font", font)
	ap_label.add_theme_font_size_override("font_size", 24)
	ap_label.add_theme_color_override("font_color", Color(0.36, 0.93, 1.0, 1.0))
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color(0.5, 0.96, 0.63, 1.0))
	turn_label.add_theme_font_size_override("font_size", 24)
	turn_label.add_theme_color_override("font_color", Color(0.92, 0.76, 0.39, 1.0))


func _get_hp_color(current_hp: int, max_hp: int) -> Color:
	var ratio := float(current_hp) / float(maxi(1, max_hp))
	if ratio <= 0.3:
		return Color(1.0, 0.32, 0.34, 1.0)
	if ratio <= 0.6:
		return Color(1.0, 0.78, 0.28, 1.0)
	return Color(0.5, 0.96, 0.63, 1.0)
