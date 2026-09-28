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
@onready var status_bar: BattleStatusBar = $UILayer/UIRoot/StatusBar
@onready var context_menu: BattleContextMenu = $UILayer/UIRoot/ContextMenu
@onready var enemies_container: Node2D = $Enemies

const BATTLE_LOADOUT_PANEL_SCRIPT := preload("res://Script/inventory/ui/battle_loadout_panel.gd")
const BATTLE_COMBAT_RESOLVER_SCRIPT := preload("res://Script/battle_combat_resolver.gd")
const BATTLE_CONTAINER_SPAWNER_SCRIPT := preload("res://Script/battle_container_spawner.gd")
const BATTLE_CONTAINER_ACTION_MENU_SCRIPT := preload("res://Script/ui/battle_container_action_menu.gd")
const SIGNAL_FLARE_SPRITES := preload("res://Art/tilesets/urban_night/props/markers/signal_flare/signal_flare_sprites.tres")
const LEVEL_CONFIG_PATH := "res://conf/levels/beginner_urban.json"

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
var _pending_containers: Array[BattleContainer] = []
var _context_search_container: BattleContainer
var _context_search_candidates: Array[BattleContainer] = []
var battle_config: Dictionary = {}
var evacuation_confirmation: ConfirmationDialog
var failure_overlay: Control
var failure_reason_label: Label
var _battle_finished := false
var evacuation_grid := Vector2i(-1, -1)
var evacuation_level := 1
var evacuation_marker: AnimatedSprite2D
var evacuation_pending := false


func _ready():
	hover_sprite.visible = false
	hover_sprite2.visible = false

	if ItemDB.get_all_items().is_empty():
		ItemDB.load_from_dir("res://conf/items")
	if EnemyDB.get_all_ids().is_empty():
		EnemyDB.load_from_file("res://conf/enemies.json")
	battle_config = _load_level_config()

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
	_setup_evacuation_controls()
	_setup_failure_overlay()
	print("Player start grid: ", player.grid_pos, " level: ", player.current_level, " world: ", player.global_position)

	bullet_range = BulletRange.new(level_manager)
	combat_resolver = BATTLE_COMBAT_RESOLVER_SCRIPT.new()
	container_spawner = BATTLE_CONTAINER_SPAWNER_SCRIPT.new(level_manager)
	_spawn_map_containers()
	_spawn_evacuation_point()

	turn_controller = TurnController.new(_get_max_turns())
	turn_controller.turn_started.connect(_on_turn_started)
	turn_controller.game_over.connect(_on_game_over)
	turn_controller.phase_changed.connect(_on_phase_changed)
	status_bar.bind(player, turn_controller)
	turn_controller.start_game()

	status_bar.end_turn_pressed.connect(_on_end_turn_pressed)
	status_bar.force_evacuation_pressed.connect(_on_force_evacuation_pressed)
	context_menu.attack_requested.connect(_on_attack_requested)
	context_menu.search_requested.connect(_on_context_menu_search_requested)
	context_menu.end_turn_requested.connect(_on_end_turn_pressed)
	context_menu.properties_requested.connect(_on_properties_requested)
	context_menu.popup_hide.connect(_on_context_menu_hide)

	enemy_spawner = EnemySpawner.new(level_manager, enemies_container)
	for enemy in enemy_spawner.spawn_batch(_get_enemy_spawn_entries()):
		enemy.defeated.connect(_on_unit_defeated)
	enemy_ai = EnemyAI.new(bullet_range, combat_resolver)

func _exit_tree() -> void:
	if inventory:
		WarehouseService.clear_all_temporary_containers(inventory)
	if player_save_provider:
		SaveManager.unregister_provider(player_save_provider)


func _load_level_config() -> Dictionary:
	if not FileAccess.file_exists(LEVEL_CONFIG_PATH):
		push_error("Battlefield: missing level config %s" % LEVEL_CONFIG_PATH)
		return {}
	var file := FileAccess.open(LEVEL_CONFIG_PATH, FileAccess.READ)
	if file == null:
		push_error("Battlefield: failed to read level config %s" % LEVEL_CONFIG_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		push_error("Battlefield: invalid level config %s" % LEVEL_CONFIG_PATH)
		return {}
	return (parsed as Dictionary).duplicate(true)


func _get_max_turns() -> int:
	return maxi(1, int(battle_config.get("max_turns", 10)))


func _spawn_evacuation_point() -> void:
	var evacuation_data: Variant = battle_config.get("evacuation", {})
	if not (evacuation_data is Dictionary):
		push_warning("Battlefield: missing evacuation config")
		return
	var data := evacuation_data as Dictionary
	var grid := _to_grid(data.get("grid", []))
	var level := maxi(1, int(data.get("level", 1)))
	if grid.x < 0 or grid.y < 0 or not player.pathfinder.is_walkable(grid, level, player):
		push_warning("Battlefield: invalid evacuation grid %s lv%d" % [grid, level])
		return
	var obstacle := level_manager.get_layer(level, "obstacle")
	var ground := level_manager.get_layer(level, "ground")
	if obstacle == null or ground == null:
		push_warning("Battlefield: missing layer for evacuation point")
		return
	evacuation_grid = grid
	evacuation_level = level
	evacuation_marker = AnimatedSprite2D.new()
	evacuation_marker.name = "EvacuationSignalFlare"
	evacuation_marker.sprite_frames = SIGNAL_FLARE_SPRITES
	evacuation_marker.animation = &"signal_flare"
	evacuation_marker.scale = Vector2(1.0 / 32.0, 1.0 / 32.0)
	evacuation_marker.position = ground.map_to_local(grid)
	evacuation_marker.z_as_relative = true
	evacuation_marker.add_to_group("evacuation_point")
	obstacle.add_child(evacuation_marker)
	evacuation_marker.play()
	print("[Evacuation] placed at %s lv%d" % [evacuation_grid, evacuation_level])


func _get_container_entries() -> Array:
	var result: Array = []
	var entries: Variant = battle_config.get("containers", [])
	if not (entries is Array):
		return result
	for entry_variant in entries:
		if not (entry_variant is Dictionary):
			continue
		var entry := (entry_variant as Dictionary).duplicate(true)
		var grid := _to_grid(entry.get("grid", []))
		if grid == Vector2i.ZERO:
			push_warning("Battlefield: skipped container with invalid grid")
			continue
		entry["grid"] = grid
		entry["level"] = maxi(1, int(entry.get("level", 1)))
		result.append(entry)
	return result


func _get_enemy_spawn_entries() -> Array:
	var result: Array = []
	var groups: Variant = battle_config.get("enemy_groups", [])
	if not (groups is Array):
		return result
	for group_variant in groups:
		if not (group_variant is Dictionary):
			continue
		var group := group_variant as Dictionary
		var enemy_id := str(group.get("id", ""))
		var spawns: Variant = group.get("spawns", [])
		if enemy_id.is_empty() or not (spawns is Array):
			push_warning("Battlefield: skipped invalid enemy group")
			continue
		var count := maxi(0, int(group.get("count", (spawns as Array).size())))
		if count > (spawns as Array).size():
			push_warning("Battlefield: enemy group %s count exceeds configured spawn points" % enemy_id)
		for index in mini(count, (spawns as Array).size()):
			var spawn_variant: Variant = (spawns as Array)[index]
			if not (spawn_variant is Dictionary):
				continue
			var spawn := spawn_variant as Dictionary
			var grid := _to_grid(spawn.get("grid", []))
			if grid == Vector2i.ZERO:
				push_warning("Battlefield: skipped %s with invalid grid" % enemy_id)
				continue
			result.append({
				"id": enemy_id,
				"grid": grid,
				"level": maxi(1, int(spawn.get("level", 1))),
			})
	return result


func _to_grid(value: Variant) -> Vector2i:
	if value is Array and (value as Array).size() >= 2:
		var coordinates := value as Array
		return Vector2i(int(coordinates[0]), int(coordinates[1]))
	return Vector2i.ZERO


func _setup_evacuation_controls() -> void:
	evacuation_confirmation = ConfirmationDialog.new()
	evacuation_confirmation.title = "确认强制撤离"
	evacuation_confirmation.dialog_text = "强制撤离将按撤离失败处理，并永久失去所有已装备、配件和背包内物品。确认继续？"
	evacuation_confirmation.ok_button_text = "确认撤离"
	evacuation_confirmation.cancel_button_text = "取消"
	$UILayer/UIRoot.add_child(evacuation_confirmation)
	evacuation_confirmation.confirmed.connect(_on_force_evacuation_confirmed)


func _setup_failure_overlay() -> void:
	failure_overlay = Control.new()
	failure_overlay.name = "FailureOverlay"
	failure_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	failure_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	failure_overlay.visible = false
	$UILayer/UIRoot.add_child(failure_overlay)

	var dimmer := ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.01, 0.015, 0.025, 0.88)
	failure_overlay.add_child(dimmer)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -270.0
	panel.offset_top = -170.0
	panel.offset_right = 270.0
	panel.offset_bottom = 170.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.105, 0.98)
	panel_style.border_color = Color(0.88, 0.28, 0.24, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel.add_theme_stylebox_override("panel", panel_style)
	failure_overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	panel.add_child(content)
	var title := Label.new()
	title.text = "撤离失败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.38, 0.32, 1.0))
	content.add_child(title)
	failure_reason_label = Label.new()
	failure_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	failure_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	failure_reason_label.add_theme_font_size_override("font_size", 19)
	content.add_child(failure_reason_label)
	var return_button := Button.new()
	return_button.text = "返回指挥中心"
	return_button.custom_minimum_size = Vector2(190, 48)
	return_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return_button.pressed.connect(_on_return_to_command_center_pressed)
	content.add_child(return_button)


func _on_force_evacuation_pressed() -> void:
	if _battle_finished:
		return
	evacuation_confirmation.popup_centered()


func _on_force_evacuation_confirmed() -> void:
	_end_battle_as_failure("已执行强制撤离。")


func _end_battle_as_failure(reason: String) -> void:
	if _battle_finished:
		return
	_battle_finished = true
	_change_state(State.IDLE)
	_hide_all_battle_panels()
	status_bar.set_actions_enabled(false)
	if turn_controller and not turn_controller.is_game_over:
		turn_controller.end_game()
	if inventory:
		WarehouseService.clear_all_temporary_containers(inventory, true)
		WarehouseService.discard_operator_loadout(inventory, WarehouseService.OPERATOR_ID, SaveManager.current_data.player)
		player.sync_equipment_from_save(SaveManager.current_data.player)
		player.sync_battle_equipment(inventory)
	_record_battle_result("failure", reason)
	if not SaveManager.save_current_or_create():
		push_warning("Battlefield: failed to save evacuation failure result")
	failure_reason_label.text = "%s\n已遗失所有随身物资。" % reason
	failure_overlay.visible = true


func _on_return_to_command_center_pressed() -> void:
	get_tree().change_scene_to_file("res://CommandCenter.tscn")

func _on_turn_started(_turn: int):
	_log_turn_events(combat_resolver.begin_turn(player))
	if evacuation_pending:
		if not player.is_defeated and _is_player_at_evacuation_point():
			_end_battle_as_success()
			return
		evacuation_pending = false
		print("[Evacuation] 已中断：干员未停留在撤离点。")
	status_bar.refresh()
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
	_end_battle_as_failure("行动时限耗尽，未能在规定回合内撤离。")

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
		status_bar.refresh()

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
	if _battle_finished:
		return
	evacuation_pending = _is_player_at_evacuation_point()
	if evacuation_pending:
		print("[Evacuation] 撤离倒计时开始：撑到下一个玩家回合。")
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
	_pending_containers = []
	_context_search_container = null
	_context_search_candidates = []

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
	status_bar.refresh()

func _on_context_menu_hide():
	_context_search_container = null
	_context_search_candidates = []
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

	# 相机拖拽是观看操作，敌方回合与单位移动中同样生效，因此放在阶段判断之前
	if is_dragging:
		var screen_mouse = get_viewport().get_mouse_position()
		camera.position -= (screen_mouse - last_mouse_pos)
		last_mouse_pos = screen_mouse
		return

	if turn_controller.current_phase != TurnController.Phase.PLAYER_PHASE:
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
	if battle_loadout_panel and battle_loadout_panel.is_item_drag_active():
		return
	# 相机拖拽不受回合阶段限制；被拖拽消费的事件不再进入玩家阶段交互
	if _handle_camera_drag_input(event):
		return
	if turn_controller.current_phase != TurnController.Phase.PLAYER_PHASE:
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
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_handle_left_click()
			return

# 追踪相机拖拽：菜单打开时交回原逻辑，返回 true 表示事件已被拖拽消费
func _handle_camera_drag_input(event: InputEvent) -> bool:
	if container_action_menu.visible or context_menu.visible:
		return false
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			press_pos = event.position
			last_mouse_pos = event.position
			is_dragging = false
			return true
		var drag_dist: float = event.position.distance_to(press_pos)
		is_dragging = false
		return drag_dist >= DRAG_THRESHOLD
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var current_pos: Vector2 = event.position
		if not is_dragging and current_pos.distance_to(press_pos) >= DRAG_THRESHOLD:
			is_dragging = true
			last_mouse_pos = current_pos
		return true
	return false

func _handle_left_click():
	var mouse_world = get_global_mouse_position()

	if current_state == State.ATTACK_STATE:
		var attack_click_node = _get_closest_attack_node(mouse_world)
		var target := _get_enemy_at_node(attack_click_node)
		if _is_in_attack_cells(attack_click_node) and target and player.spend_ap(player.get_attack_cost()):
			var result := combat_resolver.resolve_attack(player, target)
			print(BattleCombatLogFormatter.format_attack(result))
			print("[攻击结算 JSON] ", result)
			status_bar.refresh()
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
					status_bar.refresh()
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
	var containers := _get_containers_near(mouse_world)
	if not containers.is_empty():
		if current_state != State.IDLE:
			_change_state(State.IDLE)
		_show_container_action_menu(containers, Vector2i(event.position.x, event.position.y))
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
	var standing_candidates := _get_containers_at_grid(player.grid_pos, player.current_level)
	var sorted_candidates := _sorted_containers(standing_candidates)
	_context_search_candidates = sorted_candidates
	_context_search_container = _pick_container(standing_candidates)
	_reorder_containers_at_grid(player.grid_pos, player.current_level)
	var has_search_target := not sorted_candidates.is_empty()
	var search_label := ""
	var search_cost := 0
	var search_enabled := false
	var search_reason := ""
	if has_search_target:
		var infos: Array[Dictionary] = []
		for container in sorted_candidates:
			infos.append(_describe_container(container))
		var default_info: Dictionary = infos[0]
		search_cost = int(default_info["ap_cost"])
		if sorted_candidates.size() >= 2:
			# 多目标时只要有一个可搜就允许打开列表，具体目标由玩家在列表里选
			search_label = "搜索…（同格 %d 个）" % sorted_candidates.size()
			for info in infos:
				if bool(info["enabled"]):
					search_enabled = true
					break
			search_reason = "" if search_enabled else str(default_info["reason"])
		else:
			search_label = str(default_info["verb"])
			search_enabled = bool(default_info["enabled"])
			search_reason = str(default_info["reason"])
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

func _get_containers_near(mouse_world: Vector2) -> Array[BattleContainer]:
	var result: Array[BattleContainer] = []
	var closest_distance := INF
	for node in get_tree().get_nodes_in_group("battle_containers"):
		var container := node as BattleContainer
		if container == null:
			continue
		var distance := mouse_world.distance_to(container.global_position)
		if distance > container.interaction_radius:
			continue
		if distance < closest_distance:
			closest_distance = distance
			result.clear()
			result.append(container)
		elif is_equal_approx(distance, closest_distance):
			result.append(container)
	return result


func _get_containers_at_grid(grid: Vector2i, level: int) -> Array[BattleContainer]:
	var result: Array[BattleContainer] = []
	for node in get_tree().get_nodes_in_group("battle_containers"):
		var container := node as BattleContainer
		if container and container.grid_pos == grid and container.current_level == level:
			result.append(container)
	return result


# 优先级升序（没搜过 > 搜过，丢弃物恒定最前）；同档让树序靠后者排在前面，与绘制最上层一致
func _sorted_containers(candidates: Array[BattleContainer]) -> Array[BattleContainer]:
	var result: Array[BattleContainer] = []
	for container in candidates:
		var priority := container.get_search_priority()
		var insert_at := result.size()
		for index in result.size():
			if priority <= result[index].get_search_priority():
				insert_at = index
				break
		result.insert(insert_at, container)
	return result


func _pick_container(candidates: Array[BattleContainer]) -> BattleContainer:
	var sorted := _sorted_containers(candidates)
	return sorted[0] if not sorted.is_empty() else null


# 按优先级重排同格容器的兄弟顺序：优先级最高者排到最后，即绘制在最上层
func _reorder_containers_at_grid(grid: Vector2i, level: int) -> void:
	var containers := _get_containers_at_grid(grid, level)
	if containers.size() < 2:
		return
	var parent := containers[0].get_parent()
	if parent == null:
		return
	var ordered := _sorted_containers(containers)
	for index in range(ordered.size() - 1, -1, -1):
		var container := ordered[index]
		if container.get_parent() == parent:
			parent.move_child(container, parent.get_child_count() - 1)


func _describe_container(container: BattleContainer) -> Dictionary:
	var same_level := container.current_level == player.current_level
	var in_range := container.can_be_searched_by(player, bullet_range)
	var has_loot := container.has_remaining_loot(inventory)
	container.set_depleted(not has_loot and container.has_seeded_loot())
	var ap_cost := container.get_search_ap_cost()
	var enough_ap := player.action_points >= ap_cost
	# 0 AP 的容器即使已搜空也允许打开面板查看，只有同层、射程与 AP 能拦住
	var enabled := same_level and in_range and enough_ap and (has_loot or ap_cost <= 0)
	var reason := ""
	if not same_level:
		reason = "需要与角色位于同一层。"
	elif not in_range:
		reason = "需要位于 1 格攻击射线内。"
	elif not enough_ap:
		reason = "行动点不足。"
	elif not has_loot:
		reason = "容器已搜空。"
	var verb := "搜索"
	if container.is_opened:
		verb = "继续搜索" if has_loot else "查看（已空）"
	return {
		"same_level": same_level,
		"in_range": in_range,
		"has_loot": has_loot,
		"ap_cost": ap_cost,
		"enabled": enabled,
		"reason": reason,
		"verb": verb,
	}


func _show_container_action_menu(candidates: Array[BattleContainer], screen_position: Vector2i) -> void:
	var sorted := _sorted_containers(candidates)
	if sorted.is_empty():
		return
	_pending_containers = sorted
	_pending_container = sorted[0]
	_reorder_containers_at_grid(sorted[0].grid_pos, sorted[0].current_level)
	if sorted.size() == 1:
		var container := sorted[0]
		var info := _describe_container(container)
		container_action_menu.show_search(
			container.display_name,
			str(info["verb"]),
			int(info["ap_cost"]),
			bool(info["enabled"]),
			str(info["reason"]),
			screen_position
		)
		return
	var entries: Array[Dictionary] = []
	for container in sorted:
		var info := _describe_container(container)
		entries.append({
			"name": container.display_name,
			"verb": str(info["verb"]),
			"ap_cost": int(info["ap_cost"]),
			"enabled": bool(info["enabled"]),
			"reason": str(info["reason"]),
		})
	container_action_menu.show_search_list("同格 %d 个目标" % sorted.size(), entries, screen_position)


func _on_container_search_requested() -> void:
	var index := container_action_menu.get_selected_index()
	if index >= 0 and index < _pending_containers.size():
		_pending_container = _pending_containers[index]
	_pending_containers = []
	if _pending_container == null or not is_instance_valid(_pending_container):
		return
	var container := _pending_container
	_pending_container = null
	_search_container(container)


func _on_context_menu_search_requested() -> void:
	var candidates := _context_search_candidates
	_context_search_candidates = []
	if candidates.size() >= 2:
		var screen_position := Vector2i(get_viewport().get_mouse_position())
		context_menu.hide()
		# 延迟到本帧末尾再弹出，避免行动菜单关闭时的窗口失焦把列表菜单一起带走
		_show_container_action_menu.call_deferred(candidates, screen_position)
		return
	if _context_search_container == null or not is_instance_valid(_context_search_container):
		return
	var container := _context_search_container
	_context_search_container = null
	_search_container(container)


func _search_container(container: BattleContainer) -> void:
	if container == null:
		return
	var had_loot := container.has_remaining_loot(inventory)
	container.set_depleted(not had_loot and container.has_seeded_loot())
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
	var message := "正在搜索：%s%s" % [
		container.display_name,
		"（%d AP）" % ap_cost,
	]
	if not had_loot:
		message = "%s 已搜空，仅查看。" % container.display_name
	battle_loadout_panel.refresh_after_battle_action(message)
	_reorder_containers_at_grid(container.grid_pos, container.current_level)
	status_bar.refresh()


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
		_reorder_containers_at_grid(pile.grid_pos, pile.current_level)
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
			_reorder_containers_at_grid(container.grid_pos, container.current_level)
			return
		if not container.is_ground_pile:
			container.set_depleted(true)
			_reorder_containers_at_grid(container.grid_pos, container.current_level)
			return
		WarehouseService.clear_temporary_container(inventory, container_id, false)
		container.queue_free()
		battle_loadout_panel.close_temporary_container(false)
		return

func _spawn_map_containers() -> void:
	for container in container_spawner.spawn_batch(_get_container_entries()):
		_reorder_containers_at_grid(container.grid_pos, container.current_level)

func _on_unit_defeated(unit: Unit) -> void:
	if unit == player:
		_end_battle_as_failure("干员生命归零，撤离失败。")
		return
	if unit.faction != "enemy":
		return
	unit.remove_from_group("enemy")
	unit.remove_from_group("units")
	if container_spawner:
		var drop := container_spawner.spawn_enemy_drop(unit)
		if drop:
			_reorder_containers_at_grid(drop.grid_pos, drop.current_level)
	unit.queue_free()

func _on_player_damaged(result: Dictionary) -> void:
	if evacuation_pending and int(result.get("damage", 0)) > 0:
		evacuation_pending = false
		print("[Evacuation] 撤离倒计时中断：干员受到伤害。")
	if turn_controller:
		status_bar.refresh()


func _is_player_at_evacuation_point() -> bool:
	return evacuation_grid.x >= 0 and player.grid_pos == evacuation_grid and player.current_level == evacuation_level


func _end_battle_as_success() -> void:
	if _battle_finished:
		return
	_battle_finished = true
	_change_state(State.IDLE)
	_hide_all_battle_panels()
	status_bar.set_actions_enabled(false)
	if turn_controller and not turn_controller.is_game_over:
		turn_controller.end_game()
	var extracted_items := _get_carried_item_count()
	_record_battle_result("success", "已在撤离点停留至下一个玩家回合。", extracted_items)
	if not SaveManager.save_current_or_create():
		push_warning("Battlefield: failed to save successful evacuation result")
	get_tree().change_scene_to_file("res://CommandCenter.tscn")


func _get_carried_item_count() -> int:
	if inventory == null:
		return 0
	var count := 0
	var weapon_uid := WarehouseService.get_equipped_uid(inventory, "weapon", WarehouseService.OPERATOR_ID)
	for slot in WarehouseService.EQUIPMENT_SLOTS:
		if not WarehouseService.get_equipped_uid(inventory, slot, WarehouseService.OPERATOR_ID).is_empty():
			count += 1
	if not weapon_uid.is_empty():
		count += WarehouseService.get_weapon_attachments(inventory, weapon_uid, WarehouseService.OPERATOR_ID).size()
	var backpack_uid := WarehouseService.get_equipped_uid(inventory, "backpack", WarehouseService.OPERATOR_ID)
	if not backpack_uid.is_empty():
		count += WarehouseService.get_backpack_item_count(inventory, backpack_uid)
	return count


func _record_battle_result(outcome: String, reason: String, extracted_items: int = 0) -> void:
	print("[BattleResult] ", {
		"timestamp": Time.get_datetime_string_from_system(),
		"level_id": str(battle_config.get("id", "unknown")),
		"outcome": outcome,
		"reason": reason,
		"turn": turn_controller.current_turn if turn_controller else 0,
		"extracted_items": extracted_items,
	})

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

