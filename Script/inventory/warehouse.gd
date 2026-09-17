class_name WarehouseScreen
extends BaseStorageScreen

const OPERATOR_ID := "benny"
const OPERATOR_EQUIPMENT_SLOT_SCRIPT := preload("res://Script/inventory/ui/operator_equipment_slot.gd")
const WEAPON_ATTACHMENT_SLOT_SCRIPT := preload("res://Script/inventory/ui/weapon_attachment_slot.gd")
const INVENTORY_GRID_SCRIPT := preload("res://Script/inventory/ui/inventory_grid.gd")
const TRANSFER_POLICY_SCRIPT := preload("res://Script/inventory/transfer_policy.gd")

var inventory: InventorySaveData
var _grid
var _storage_panel: PanelContainer
var _operator_content: VBoxContainer
var _attachment_content: VBoxContainer
var _attachment_panel: PanelContainer
var _backpack_content: VBoxContainer
var _backpack_panel: PanelContainer
var _info_panel: ItemInfoPanel
var _status_label: Label
var _capacity_label: Label
var _organize_button: Button
var _filter_option: OptionButton
var _selected_uid := ""
var _selected_position := -1
var _selected_equip_slot := ""
var _selected_weapon_uid := ""
var _selected_backpack_uid := ""
var _attachment_target_slot := ""
var _pending_detach_attachment_slot := ""
var _filter_type := ""
var _equipment_slot_nodes: Array = []
var _attachment_slot_nodes: Array = []
var _backpack_slot_nodes: Array = []
var _backpack_grid: InventoryGrid
var _grid_slot_nodes: Array = []
var _active_drag_data: Dictionary = {}
var _position_index: Dictionary = {}
var _stored_item_count := 0
var _last_drag_target_position := -1
var _last_drag_mouse_position := Vector2.INF
var _drag_drop_received := false
var _last_backpack_drag_target := -1
var _transfer_policy


func _ready() -> void:
	_ensure_save_data()
	inventory = WarehouseService.ensure_data(SaveManager.current_data)
	_selected_weapon_uid = WarehouseService.get_equipped_uid(inventory, "weapon", OPERATOR_ID)
	_selected_backpack_uid = WarehouseService.get_equipped_uid(inventory, "backpack", OPERATOR_ID)
	_transfer_policy = TRANSFER_POLICY_SCRIPT.new()
	_transfer_policy.configure({
		"warehouse": {
			"WEAPON": [{"target": "equipment", "slot": "weapon"}],
			"HELMET": [{"target": "equipment", "slot": "helmet"}],
			"ARMOR": [{"target": "equipment", "slot": "armor"}],
			"BACKPACK": [{"target": "equipment", "slot": "backpack"}],
			"*": [{"target": "backpack"}],
		},
		"backpack": {"*": [{"target": "warehouse"}]},
		"equipment": {"*": [{"target": "warehouse"}]},
	}, {
		"warehouse": {"columns": 10, "capacity": 100, "allows_swap": true},
		"backpack": {"columns_key": "battle_grid_width", "rows_key": "battle_grid_height", "allows_swap": true},
		"equipment": {"allows_swap": false},
	})
	_build_layout()
	_refresh_all()


func _process(_delta: float) -> void:
	if _active_drag_data.is_empty():
		return
	var mouse_position := get_viewport().get_mouse_position()
	if mouse_position == _last_drag_mouse_position:
		return
	_last_drag_mouse_position = mouse_position
	_update_drag_targets(mouse_position)


func _input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or event.pressed or _active_drag_data.is_empty():
		return
	var data := _active_drag_data.duplicate(true)
	var mouse_position := get_viewport().get_mouse_position()
	var is_in_storage := _storage_panel.get_global_rect().has_point(mouse_position)
	var is_in_backpack := _backpack_panel.get_global_rect().has_point(mouse_position)
	call_deferred("_apply_drag_drop_fallback", data, _last_drag_target_position, _last_backpack_drag_target, is_in_storage, is_in_backpack, _selected_backpack_uid)


func _exit_tree() -> void:
	persist_storage()


func _ensure_save_data() -> void:
	if SaveManager.current_data == null:
		SaveManager.create_new_game()
	if SaveManager.current_data.player == null:
		SaveManager.current_data.player = PlayerSaveData.new()
	if SaveManager.current_data.inventory == null:
		SaveManager.current_data.inventory = InventorySaveData.new()


func _build_layout() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color(0.012, 0.035, 0.06, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 15)
	margin.add_child(page)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 54)
	header.add_theme_constant_override("separation", 14)
	page.add_child(header)
	var title := Label.new()
	title.text = "仓库 · 物资与装备管理"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title)
	_capacity_label = Label.new()
	_capacity_label.custom_minimum_size = Vector2(150, 0)
	_capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_capacity_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_capacity_label.add_theme_font_size_override("font_size", 16)
	_capacity_label.add_theme_color_override("font_color", Color(0.43, 0.83, 0.98, 1.0))
	header.add_child(_capacity_label)
	var back_button := _create_button("返回指挥中心", Vector2(145, 42))
	back_button.pressed.connect(return_to_command_center)
	header.add_child(back_button)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 15)
	page.add_child(body)

	var operator_panel := _create_panel(Vector2(238, 0))
	body.add_child(operator_panel)
	_operator_content = VBoxContainer.new()
	_operator_content.add_theme_constant_override("separation", 10)
	operator_panel.add_child(_operator_content)

	_storage_panel = _create_panel(Vector2(0, 0))
	_storage_panel.custom_minimum_size = Vector2(600, 0)
	_storage_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_storage_panel.size_flags_stretch_ratio = 0.8
	body.add_child(_storage_panel)
	var storage_content := VBoxContainer.new()
	storage_content.add_theme_constant_override("separation", 10)
	_storage_panel.add_child(storage_content)
	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 9)
	storage_content.add_child(controls)
	_filter_option = OptionButton.new()
	_filter_option.custom_minimum_size = Vector2(145, 38)
	_filter_option.add_item("全部品类")
	for item_type in ItemDB.VALID_TYPES:
		_filter_option.add_item(str(ItemDB.VALID_TYPES[item_type]))
	_filter_option.item_selected.connect(_on_filter_selected)
	controls.add_child(_filter_option)
	_organize_button = _create_button("自动整理", Vector2(104, 38))
	_organize_button.pressed.connect(_organize_items)
	controls.add_child(_organize_button)
	var hint := Label.new()
	hint.text = "拖拽物品可移动、装配或安装配件"
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.48, 0.63, 0.71, 1.0))
	controls.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	storage_content.add_child(scroll)
	_grid = INVENTORY_GRID_SCRIPT.new()
	_grid.add_theme_constant_override("h_separation", 5)
	_grid.add_theme_constant_override("v_separation", 5)
	_grid.gap_dropped.connect(_on_grid_gap_dropped)
	scroll.add_child(_grid)
	_status_label = Label.new()
	_status_label.custom_minimum_size = Vector2(0, 26)
	_status_label.add_theme_font_size_override("font_size", 14)
	_status_label.add_theme_color_override("font_color", Color(0.92, 0.76, 0.39, 1.0))
	storage_content.add_child(_status_label)

	var detail_column := VBoxContainer.new()
	detail_column.custom_minimum_size = Vector2(470, 0)
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_column.size_flags_stretch_ratio = 1.2
	detail_column.add_theme_constant_override("separation", 12)
	body.add_child(detail_column)
	_info_panel = ItemInfoPanel.new()
	_info_panel.action_requested.connect(_on_info_action)
	detail_column.add_child(_info_panel)
	var equipment_panels := HBoxContainer.new()
	equipment_panels.size_flags_vertical = Control.SIZE_EXPAND_FILL
	equipment_panels.add_theme_constant_override("separation", 10)
	detail_column.add_child(equipment_panels)
	_attachment_panel = _create_panel(Vector2(0, 0))
	_attachment_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_attachment_panel.size_flags_stretch_ratio = 1.0
	equipment_panels.add_child(_attachment_panel)
	_attachment_content = VBoxContainer.new()
	_attachment_content.add_theme_constant_override("separation", 8)
	_attachment_panel.add_child(_attachment_content)
	_backpack_panel = _create_panel(Vector2(0, 0))
	_backpack_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_backpack_panel.size_flags_stretch_ratio = 2.0
	equipment_panels.add_child(_backpack_panel)
	_backpack_content = VBoxContainer.new()
	_backpack_content.add_theme_constant_override("separation", 8)
	_backpack_panel.add_child(_backpack_content)
	body.move_child(detail_column, 1)


func _refresh_all() -> void:
	_render_operator_panel()
	_render_grid()
	_render_attachment_panel()
	_render_backpack_panel()
	_update_header()


func _refresh_grid_and_header() -> void:
	_render_grid()
	_update_header()


func _render_operator_panel() -> void:
	_clear_children(_operator_content)
	_equipment_slot_nodes.clear()
	var title := _create_label("干员选择", 20, Color(0.86, 0.96, 1.0, 1.0))
	_operator_content.add_child(title)
	var benny_button := _create_button("贝妮  ·  Lv.1", Vector2(0, 44))
	benny_button.disabled = false
	benny_button.add_theme_stylebox_override("normal", _make_button_style(true))
	benny_button.pressed.connect(func() -> void:
		_selected_equip_slot = ""
		_status_label.text = "已选择干员：贝妮"
	)
	_operator_content.add_child(benny_button)
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(0, 178)
	portrait.texture = load("res://Art/characters/benny/benny_base_01.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_operator_content.add_child(portrait)
	_operator_content.add_child(_create_label("装备栏", 18, Color(0.43, 0.83, 0.98, 1.0)))
	for slot in WarehouseService.EQUIPMENT_SLOTS:
		var uid := WarehouseService.get_equipped_uid(inventory, slot, OPERATOR_ID)
		var item := WarehouseService.get_item_by_uid(inventory, uid)
		var item_data := _get_item_data(item)
		var equipment_slot := OPERATOR_EQUIPMENT_SLOT_SCRIPT.new()
		equipment_slot.configure(slot, uid, item_data, slot == _selected_equip_slot)
		equipment_slot.slot_activated.connect(_on_equipment_slot_pressed)
		equipment_slot.item_dropped.connect(_on_equipment_item_dropped)
		equipment_slot.item_double_clicked.connect(_on_equipment_item_double_clicked)
		equipment_slot.drag_started.connect(_on_drag_started)
		equipment_slot.drag_ended.connect(_on_drag_ended)
		_equipment_slot_nodes.append(equipment_slot)
		_operator_content.add_child(equipment_slot)
	var unload_hint := _create_label("点击查看装备详情；从仓库拖拽物品到对应装备栏即可装配。", 12, Color(0.48, 0.63, 0.71, 1.0))
	unload_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_operator_content.add_child(unload_hint)


func _render_grid() -> void:
	_grid.columns = int(_transfer_policy.get_container_setting("warehouse", "columns", WarehouseService.get_grid_columns(inventory)))
	var capacity := WarehouseService.get_grid_capacity(inventory)
	while _grid_slot_nodes.size() < capacity:
		var new_slot := InventorySlot.new()
		new_slot.slot_activated.connect(_on_slot_activated)
		new_slot.item_dropped.connect(_on_inventory_item_dropped)
		new_slot.item_double_clicked.connect(_on_inventory_item_double_clicked)
		new_slot.drag_started.connect(_on_drag_started)
		new_slot.drag_ended.connect(_on_drag_ended)
		new_slot.drop_hovered.connect(_on_grid_drop_hovered)
		new_slot.drop_unhovered.connect(_on_grid_drop_unhovered)
		_grid_slot_nodes.append(new_slot)
		_grid.add_child(new_slot)
	_position_index = _build_position_index()
	_stored_item_count = _position_index.size()
	var display_items: Array[Dictionary] = []
	if _is_reordering_locked():
		display_items = _get_display_items()
	for position in capacity:
		var item := {}
		var actual_position := position
		if _is_reordering_locked():
			if position < display_items.size():
				item = display_items[position]
			actual_position = -1
		else:
			item = _position_index.get(position, {})
		var slot: InventorySlot = _grid_slot_nodes[position]
		slot.configure(actual_position, item, str(item.get("uid", "")) == _selected_uid)


func _render_attachment_panel() -> void:
	_clear_children(_attachment_content)
	_attachment_slot_nodes.clear()
	if _selected_weapon_uid.is_empty():
		_attachment_panel.visible = true
		_attachment_content.add_child(_create_label("未装备武器", 18, Color(0.48, 0.63, 0.71, 1.0)))
		return
	_attachment_panel.visible = true
	_attachment_content.add_child(_create_label("武器配件", 19, Color(0.86, 0.96, 1.0, 1.0)))
	var weapon := WarehouseService.get_item_by_uid(inventory, _selected_weapon_uid)
	var weapon_data := _get_item_data(weapon)
	if weapon_data.is_empty():
		_selected_weapon_uid = ""
		_attachment_content.add_child(_create_label("未装备武器", 18, Color(0.48, 0.63, 0.71, 1.0)))
		return
	var weapon_header := HBoxContainer.new()
	weapon_header.add_theme_constant_override("separation", 10)
	_attachment_content.add_child(weapon_header)
	var weapon_icon := TextureRect.new()
	weapon_icon.custom_minimum_size = Vector2(58, 58)
	var icon_path := str(weapon_data.get("icon", ""))
	weapon_icon.texture = load(icon_path) if not icon_path.is_empty() else null
	weapon_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	weapon_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	weapon_header.add_child(weapon_icon)
	var weapon_name := _create_label(str(weapon_data.get("name", "武器")), 24, Color(0.78, 0.94, 1.0, 1.0))
	weapon_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weapon_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_header.add_child(weapon_name)
	var slots: Array = weapon_data.get("attachment_slots", [])
	var equipped := WarehouseService.get_weapon_attachments(inventory, _selected_weapon_uid, OPERATOR_ID)
	for attachment_slot in slots:
		var attachment_uid := str(equipped.get(attachment_slot, ""))
		var attachment := WarehouseService.get_item_by_uid(inventory, attachment_uid)
		var attachment_data := _get_item_data(attachment)
		var attachment_slot_node := WEAPON_ATTACHMENT_SLOT_SCRIPT.new()
		attachment_slot_node.configure(str(attachment_slot), attachment_uid, _selected_weapon_uid, str(weapon.get("id", "")), attachment_data, str(attachment_slot) == _attachment_target_slot)
		attachment_slot_node.slot_activated.connect(_on_attachment_slot_pressed)
		attachment_slot_node.item_dropped.connect(_on_attachment_item_dropped)
		attachment_slot_node.item_double_clicked.connect(_on_attachment_item_double_clicked)
		attachment_slot_node.drag_started.connect(_on_drag_started)
		attachment_slot_node.drag_ended.connect(_on_drag_ended)
		_attachment_slot_nodes.append(attachment_slot_node)
		_attachment_content.add_child(attachment_slot_node)


func _render_backpack_panel() -> void:
	_clear_children(_backpack_content)
	_backpack_slot_nodes.clear()
	_backpack_grid = null
	_selected_backpack_uid = WarehouseService.get_equipped_uid(inventory, "backpack", OPERATOR_ID)
	var backpack_uid := _selected_backpack_uid
	var grid_size := WarehouseService.get_backpack_grid_size(inventory, backpack_uid)
	if grid_size.x <= 0 or grid_size.y <= 0:
		_selected_backpack_uid = ""
		_backpack_panel.visible = true
		_backpack_content.add_child(_create_label("未装备背包", 18, Color(0.48, 0.63, 0.71, 1.0)))
		return
	_backpack_panel.visible = true
	_backpack_content.add_child(_create_label("战场背包", 19, Color(0.86, 0.96, 1.0, 1.0)))
	_backpack_content.add_child(_create_label("携行空间：%d × %d" % [grid_size.x, grid_size.y], 14, Color(0.43, 0.83, 0.98, 1.0)))
	_backpack_grid = INVENTORY_GRID_SCRIPT.new()
	_backpack_grid.columns = grid_size.x
	_backpack_grid.add_theme_constant_override("h_separation", 5)
	_backpack_grid.add_theme_constant_override("v_separation", 5)
	_backpack_grid.gap_dropped.connect(_on_backpack_grid_gap_dropped.bind(backpack_uid))
	_backpack_content.add_child(_backpack_grid)
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	for position in grid_size.x * grid_size.y:
		var item_uid := str(backpack_items.get(position, ""))
		var item := WarehouseService.get_item_by_uid(inventory, item_uid)
		var slot := InventorySlot.new()
		slot.configure(position, item, str(item.get("uid", "")) == _selected_uid, true, {"kind": "backpack_item", "source_backpack_uid": backpack_uid, "source_backpack_position": position})
		slot.slot_activated.connect(_on_backpack_slot_activated.bind(backpack_uid))
		slot.item_dropped.connect(_on_backpack_item_dropped.bind(backpack_uid))
		slot.item_double_clicked.connect(_on_backpack_item_double_clicked.bind(backpack_uid))
		slot.drag_started.connect(_on_drag_started)
		slot.drag_ended.connect(_on_drag_ended)
		slot.drop_hovered.connect(_on_backpack_drop_hovered)
		slot.drop_unhovered.connect(_on_backpack_drop_unhovered)
		_backpack_slot_nodes.append(slot)
		_backpack_grid.add_child(slot)


func _update_header() -> void:
	_capacity_label.text = "仓库 Lv.%d  ·  %d / %d" % [inventory.warehouse_level, _stored_item_count, WarehouseService.get_grid_capacity(inventory)]
	_organize_button.disabled = _is_reordering_locked()


func _on_slot_activated(position: int, item_uid: String) -> void:
	if item_uid.is_empty():
		_selected_uid = ""
		_selected_position = -1
		_selected_equip_slot = ""
		_info_panel.show_empty()
		_refresh_all()
		return
	_select_item(item_uid, position if not _is_reordering_locked() else -1)


func _on_inventory_item_double_clicked(item_uid: String) -> void:
	var item := WarehouseService.get_item_by_uid(inventory, item_uid)
	var item_data := _get_item_data(item)
	for target in _transfer_policy.get_double_click_targets("warehouse", str(item_data.get("type", ""))):
		var target_type := str(target.get("target", ""))
		if target_type == "equipment":
			var equipment_slot := str(target.get("slot", ""))
			if equipment_slot.is_empty() or not WarehouseService.get_equipped_uid(inventory, equipment_slot, OPERATOR_ID).is_empty():
				continue
			if WarehouseService.equip_item(inventory, equipment_slot, item_uid, SaveManager.current_data.player):
				call_deferred("_focus_equipped_item", equipment_slot, item_uid, true)
			return
		if target_type == "backpack":
			var backpack_uid := WarehouseService.get_equipped_uid(inventory, "backpack", OPERATOR_ID)
			var backpack_position := _get_first_empty_backpack_position(backpack_uid)
			if backpack_position >= 0 and WarehouseService.move_warehouse_item_to_backpack(inventory, backpack_uid, item_uid, backpack_position):
				_status_label.text = "物品已放入已装备背包。"
				_refresh_all()
			return


func _on_backpack_slot_activated(position: int, item_uid: String, backpack_uid: String) -> void:
	if item_uid.is_empty():
		_selected_uid = ""
		_info_panel.show_empty()
		return
	_selected_uid = item_uid
	_selected_position = position
	_selected_backpack_uid = backpack_uid
	_selected_equip_slot = ""
	var item_data := _get_item_data(WarehouseService.get_item_by_uid(inventory, item_uid))
	if str(item_data.get("type", "")) == "WEAPON":
		_selected_weapon_uid = item_uid
		_attachment_target_slot = ""
	_show_item_info(item_uid)
	_refresh_all()


func _on_backpack_item_double_clicked(item_uid: String, backpack_uid: String) -> void:
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	var source_position := -1
	for position in backpack_items:
		if str(backpack_items[position]) == item_uid:
			source_position = int(position)
			break
	if source_position < 0:
		return
	for target in _transfer_policy.get_double_click_targets("backpack", str(_get_item_data(WarehouseService.get_item_by_uid(inventory, item_uid)).get("type", ""))):
		if str(target.get("target", "")) == "warehouse":
			var free_positions := _get_free_warehouse_positions(1)
			if free_positions.is_empty():
				_status_label.text = "仓库实际空位不足，无法从背包取出物品。"
				return
			if WarehouseService.move_backpack_item_to_warehouse(inventory, backpack_uid, source_position, free_positions[0]):
				_selected_backpack_uid = backpack_uid
				_status_label.text = "背包物品已放回仓库。"
				_refresh_all()
			return


func _on_backpack_item_dropped(data: Dictionary, _target_uid: String, target_position: int, backpack_uid: String) -> void:
	_drag_drop_received = true
	var source_kind := str(data.get("kind", ""))
	if source_kind == "inventory_item":
		var source_uid := str(data.get("uid", ""))
		var source_item := WarehouseService.get_item_by_uid(inventory, source_uid)
		var source_data := _get_item_data(source_item)
		var target_item := WarehouseService.get_item_by_uid(inventory, _target_uid)
		var target_data := _get_item_data(target_item)
		if str(source_data.get("type", "")) == "WEAPON_ATTACHMENT" and str(target_data.get("type", "")) == "WEAPON":
			if WarehouseService.attach_item(inventory, _target_uid, source_uid, str(source_data.get("slot", ""))):
				_focus_attachment_target_weapon(_target_uid, "配件已装入背包中的武器。")
				return
			_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
			return
		var source_position := int(source_item.get("position", -1))
		var moved := WarehouseService.move_warehouse_item_to_backpack(inventory, backpack_uid, source_uid, target_position) if _target_uid.is_empty() else WarehouseService.swap_warehouse_and_backpack_item(inventory, backpack_uid, source_position, target_position)
		if moved:
			_status_label.text = "物品已放入背包。"
			_refresh_all()
		return
	if source_kind == "equipped_item":
		if WarehouseService.move_equipped_item_to_backpack(inventory, str(data.get("source_slot", "")), backpack_uid, target_position, SaveManager.current_data.player):
			_selected_equip_slot = ""
			_status_label.text = "装备已放入背包。"
			_refresh_all()
		return
	if source_kind == "backpack_item":
		var source_backpack_uid := str(data.get("source_backpack_uid", ""))
		var source_position := int(data.get("source_backpack_position", -1))
		var source_item := WarehouseService.get_item_by_uid(inventory, str(data.get("uid", "")))
		var source_data := _get_item_data(source_item)
		var target_item := WarehouseService.get_item_by_uid(inventory, _target_uid)
		var target_data := _get_item_data(target_item)
		if source_backpack_uid == backpack_uid and str(source_data.get("type", "")) == "WEAPON_ATTACHMENT" and str(target_data.get("type", "")) == "WEAPON":
			if WarehouseService.attach_backpack_item_to_weapon(inventory, backpack_uid, source_position, _target_uid, str(source_data.get("slot", ""))):
				_focus_attachment_target_weapon(_target_uid, "背包配件已装入背包中的武器。")
				return
			_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
			return
		if source_backpack_uid == backpack_uid and WarehouseService.move_backpack_item(inventory, backpack_uid, source_position, target_position):
			_refresh_backpack_slots(backpack_uid, [source_position, target_position])
		return
	if source_kind == "weapon_attachment":
		var source_weapon_uid := str(data.get("source_weapon_uid", ""))
		var source_attachment_slot := str(data.get("source_attachment_slot", ""))
		var target_item := WarehouseService.get_item_by_uid(inventory, _target_uid)
		var target_data := _get_item_data(target_item)
		if str(target_data.get("type", "")) == "WEAPON":
			if WarehouseService.move_attachment(inventory, source_weapon_uid, source_attachment_slot, _target_uid, source_attachment_slot):
				_focus_attachment_target_weapon(_target_uid, "配件已装入背包中的武器。")
				return
			_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
			return
		if WarehouseService.move_attachment_to_backpack(inventory, source_weapon_uid, source_attachment_slot, backpack_uid, target_position):
			_status_label.text = "配件已放入背包。"
			_refresh_all()


func _on_inventory_item_dropped(data: Dictionary, target_uid: String, target_position: int) -> void:
	_drag_drop_received = true
	var source_kind := str(data.get("kind", ""))
	var source_uid := str(data.get("uid", ""))
	if source_uid.is_empty():
		return
	if source_kind == "equipped_item":
		_return_equipment_to_warehouse(str(data.get("source_slot", "")), source_uid, target_position)
		return
	if source_kind == "backpack_item":
		var source_backpack_uid := str(data.get("source_backpack_uid", ""))
		var source_backpack_position := int(data.get("source_backpack_position", -1))
		var source_backpack_item := WarehouseService.get_item_by_uid(inventory, source_uid)
		var source_backpack_data := _get_item_data(source_backpack_item)
		var backpack_target_item := WarehouseService.get_item_by_uid(inventory, target_uid)
		var backpack_target_data := _get_item_data(backpack_target_item)
		if str(source_backpack_data.get("type", "")) == "WEAPON_ATTACHMENT" and str(backpack_target_data.get("type", "")) == "WEAPON":
			if WarehouseService.attach_backpack_item_to_weapon(inventory, source_backpack_uid, source_backpack_position, target_uid, str(source_backpack_data.get("slot", ""))):
				_focus_attachment_target_weapon(target_uid, "背包配件已装入目标武器。")
				return
			_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
			return
		_move_backpack_item_to_warehouse(source_backpack_uid, source_backpack_position, target_position)
		return
	if source_kind == "weapon_attachment":
		var source_weapon_uid := str(data.get("source_weapon_uid", ""))
		var source_attachment_slot := str(data.get("source_attachment_slot", ""))
		var attached_target := WarehouseService.get_item_by_uid(inventory, target_uid)
		var attached_target_data := _get_item_data(attached_target)
		if str(attached_target_data.get("type", "")) == "WEAPON":
			if WarehouseService.move_attachment(inventory, source_weapon_uid, source_attachment_slot, target_uid, source_attachment_slot):
				_selected_weapon_uid = target_uid
				_attachment_target_slot = source_attachment_slot
				_select_item(target_uid, -1)
				_status_label.text = "配件已迁移至 %s。" % str(attached_target_data.get("name", "目标武器"))
				return
			_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
			return
		_return_attachment_to_warehouse(source_weapon_uid, source_attachment_slot, target_position)
		return
	if source_kind != "inventory_item" or source_uid == target_uid:
		return
	var source_item := WarehouseService.get_item_by_uid(inventory, source_uid)
	var source_data := _get_item_data(source_item)
	var target_item := WarehouseService.get_item_by_uid(inventory, target_uid)
	var target_data := _get_item_data(target_item)
	if str(source_data.get("type", "")) == "WEAPON_ATTACHMENT" and str(target_data.get("type", "")) == "WEAPON":
		var attachment_slot := str(source_data.get("slot", ""))
		if WarehouseService.attach_item(inventory, target_uid, source_uid, attachment_slot):
			_selected_weapon_uid = target_uid
			_attachment_target_slot = attachment_slot
			_select_item(target_uid, -1)
			_status_label.text = "%s 已装入 %s。" % [str(source_data.get("name", "配件")), str(target_data.get("name", "武器"))]
			return
		_status_label.text = "该配件与目标武器不兼容。"
		return
	if _is_reordering_locked():
		_status_label.text = "筛选或排序展示中不能调整仓库格位。"
		return
	var source_position := int(source_item.get("position", -1))
	if source_position >= 0 and target_position >= 0 and WarehouseService.move_item(inventory, source_position, target_position):
		_selected_uid = source_uid
		_selected_position = target_position
		_selected_weapon_uid = source_uid if str(source_data.get("type", "")) == "WEAPON" else ""
		_show_item_info(source_uid)
		_status_label.text = "已拖拽移动物品，格位布局将在离开仓库时保存。"
		_refresh_grid_and_header()


func _on_equipment_item_dropped(slot: String, data: Dictionary) -> void:
	var source_kind := str(data.get("kind", ""))
	if source_kind == "backpack_item":
		var backpack_uid := str(data.get("source_backpack_uid", ""))
		var backpack_position := int(data.get("source_backpack_position", -1))
		var backpack_item := WarehouseService.get_item_by_uid(inventory, str(data.get("uid", "")))
		var backpack_item_data := _get_item_data(backpack_item)
		if str(backpack_item_data.get("type", "")) == "WEAPON_ATTACHMENT":
			var equipped_weapon_uid := WarehouseService.get_equipped_uid(inventory, "weapon", OPERATOR_ID)
			if slot == "weapon" and WarehouseService.attach_backpack_item_to_weapon(inventory, backpack_uid, backpack_position, equipped_weapon_uid, str(backpack_item_data.get("slot", ""))):
				_focus_attachment_target_weapon(equipped_weapon_uid, "背包配件已装入当前武器。")
				return
			_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
			return
		var replaced := _type_to_slot(str(backpack_item_data.get("type", ""))) == slot and not WarehouseService.get_equipped_uid(inventory, slot, OPERATOR_ID).is_empty() and WarehouseService.replace_equipped_item_from_backpack(inventory, backpack_uid, backpack_position, slot, SaveManager.current_data.player)
		if replaced or WarehouseService.equip_backpack_item(inventory, backpack_uid, backpack_position, slot, SaveManager.current_data.player):
			var item_uid := str(data.get("uid", ""))
			_on_equipment_slot_pressed(slot, item_uid)
			_status_label.text = "背包物品已装配至%s。" % _get_slot_name(slot)
			return
		_status_label.text = "该背包物品无法装配到%s。" % _get_slot_name(slot)
		return
	if source_kind == "weapon_attachment":
		var target_weapon_uid := WarehouseService.get_equipped_uid(inventory, "weapon", OPERATOR_ID)
		var source_weapon_uid := str(data.get("source_weapon_uid", ""))
		var source_attachment_slot := str(data.get("source_attachment_slot", ""))
		if slot == "weapon" and WarehouseService.move_attachment(inventory, source_weapon_uid, source_attachment_slot, target_weapon_uid, source_attachment_slot):
			_focus_attachment_target_weapon(target_weapon_uid, "配件已装入干员当前武器。")
			return
		_status_label.text = "无法替换：目标接口不兼容或仓库没有空位。"
		return
	if source_kind != "inventory_item":
		return
	var item_uid := str(data.get("uid", ""))
	if item_uid.is_empty():
		return
	var item := WarehouseService.get_item_by_uid(inventory, item_uid)
	var item_data := _get_item_data(item)
	if str(item_data.get("type", "")) == "WEAPON_ATTACHMENT":
		var equipped_weapon_uid := WarehouseService.get_equipped_uid(inventory, "weapon", OPERATOR_ID)
		var attachment_slot := str(item_data.get("slot", ""))
		if slot == "weapon" and WarehouseService.attach_item(inventory, equipped_weapon_uid, item_uid, attachment_slot):
			_focus_attachment_target_weapon(equipped_weapon_uid, "%s 已装入当前武器。" % str(item_data.get("name", "配件")))
			return
		_status_label.text = "请将配件拖到武器或武器装备栏。"
		return
	var has_equipped_item := not WarehouseService.get_equipped_uid(inventory, slot, OPERATOR_ID).is_empty()
	var is_matching_equipment_type := _type_to_slot(str(item_data.get("type", ""))) == slot
	var replaced: bool = is_matching_equipment_type and has_equipped_item and WarehouseService.replace_equipped_item_from_warehouse(inventory, slot, item_uid, SaveManager.current_data.player)
	if replaced or WarehouseService.equip_item(inventory, slot, item_uid, SaveManager.current_data.player):
		_on_equipment_slot_pressed(slot, item_uid)
		_status_label.text = "%s 已装配至%s。" % [str(item_data.get("name", "物品")), _get_slot_name(slot)]
		return
	if slot == "backpack" and is_matching_equipment_type and has_equipped_item:
		_status_label.text = "新背包空间不足，无法迁移当前背包中的物品。"
		return
	_status_label.text = "%s 不能装配到%s。" % [str(item_data.get("name", "该物品")), _get_slot_name(slot)]


func _on_equipment_item_double_clicked(slot: String) -> void:
	_return_equipment_to_warehouse(slot, WarehouseService.get_equipped_uid(inventory, slot, OPERATOR_ID), -1)


func _on_attachment_item_dropped(attachment_slot: String, data: Dictionary) -> void:
	if _selected_weapon_uid.is_empty():
		return
	var source_kind := str(data.get("kind", ""))
	var moved := false
	if source_kind == "inventory_item":
		moved = WarehouseService.attach_item(inventory, _selected_weapon_uid, str(data.get("uid", "")), attachment_slot)
	elif source_kind == "backpack_item":
		var backpack_uid := str(data.get("source_backpack_uid", ""))
		var backpack_position := int(data.get("source_backpack_position", -1))
		moved = WarehouseService.attach_backpack_item_to_weapon(inventory, backpack_uid, backpack_position, _selected_weapon_uid, attachment_slot)
	elif source_kind == "weapon_attachment":
		moved = WarehouseService.move_attachment(inventory, str(data.get("source_weapon_uid", "")), str(data.get("source_attachment_slot", "")), _selected_weapon_uid, attachment_slot)
	if moved:
		_focus_attachment_target_weapon(_selected_weapon_uid, "配件已装入%s接口。" % _get_attachment_slot_name(attachment_slot))
		return
	_status_label.text = "无法替换：接口不兼容或仓库没有空位。"


func _on_attachment_item_double_clicked(attachment_slot: String) -> void:
	_return_attachment_to_warehouse(_selected_weapon_uid, attachment_slot, -1)


func _return_equipment_to_warehouse(slot: String, item_uid: String, target_position: int) -> void:
	if item_uid.is_empty():
		_status_label.text = "该装备不存在。"
		return
	if slot == "backpack":
		var backpack_positions := _get_free_warehouse_positions(WarehouseService.get_backpack_item_count(inventory, item_uid) + 1)
		if backpack_positions.is_empty() or not WarehouseService.unequip_backpack_to_warehouse(inventory, SaveManager.current_data.player, backpack_positions):
			_status_label.text = "仓库实际空位不足，无法卸下背包及其内容物。"
			return
	elif not WarehouseService.unequip_item(inventory, slot, SaveManager.current_data.player):
		_status_label.text = "仓库空间不足，无法卸下%s。" % _get_slot_name(slot)
		return
	_move_returned_item_to_target(item_uid, target_position)
	_selected_uid = item_uid
	_selected_equip_slot = ""
	if slot == "weapon":
		_selected_weapon_uid = ""
	if slot == "backpack":
		_selected_backpack_uid = ""
	_status_label.text = "%s 已放回仓库。" % _get_slot_name(slot)
	if not _filter_type.is_empty():
		_status_label.text += " 当前筛选未包含该物品时不会显示。"
	_show_item_info(item_uid)
	_refresh_all()


func _return_attachment_to_warehouse(weapon_uid: String, attachment_slot: String, target_position: int) -> void:
	if weapon_uid.is_empty():
		_status_label.text = "未选择武器。"
		return
	var attachments := WarehouseService.get_weapon_attachments(inventory, weapon_uid, OPERATOR_ID)
	var item_uid := str(attachments.get(attachment_slot, ""))
	if not WarehouseService.detach_attachment(inventory, weapon_uid, attachment_slot):
		_status_label.text = "仓库空间不足，无法卸下配件。"
		return
	_move_returned_item_to_target(item_uid, target_position)
	_selected_uid = item_uid
	_attachment_target_slot = ""
	_status_label.text = "配件已放回仓库。"
	if not _filter_type.is_empty():
		_status_label.text += " 当前筛选未包含该配件时不会显示。"
	_show_item_info(item_uid)
	_refresh_all()


func _move_backpack_item_to_warehouse(backpack_uid: String, source_position: int, target_position: int) -> void:
	if backpack_uid.is_empty() or source_position < 0:
		return
	var destination_position := target_position
	if destination_position < 0:
		var free_positions := _get_free_warehouse_positions(1)
		if free_positions.is_empty():
			_status_label.text = "仓库实际空位不足，无法取出背包物品。"
			return
		destination_position = free_positions[0]
	var moved := WarehouseService.move_backpack_item_to_warehouse(inventory, backpack_uid, source_position, destination_position) if not _position_index.has(destination_position) else WarehouseService.swap_warehouse_and_backpack_item(inventory, backpack_uid, destination_position, source_position)
	if moved:
		_selected_backpack_uid = backpack_uid
		_status_label.text = "背包物品已放回仓库。"
		_refresh_all()
	else:
		_status_label.text = "目标仓库格不可用。"


func _move_returned_item_to_target(item_uid: String, target_position: int) -> void:
	if target_position < 0:
		return
	var item := WarehouseService.get_item_by_uid(inventory, item_uid)
	var source_position := int(item.get("position", -1))
	if source_position >= 0 and source_position != target_position:
		WarehouseService.move_item(inventory, source_position, target_position)


func _get_free_warehouse_positions(required_count: int) -> Array[int]:
	if required_count <= 0:
		return []
	if WarehouseService.get_grid_capacity(inventory) - _stored_item_count < required_count:
		return []
	var positions: Array[int] = []
	for position in WarehouseService.get_grid_capacity(inventory):
		if not _position_index.has(position):
			positions.append(position)
			if positions.size() == required_count:
				return positions
	return []


func _get_first_empty_backpack_position(backpack_uid: String) -> int:
	if backpack_uid.is_empty():
		return -1
	var grid_size := WarehouseService.get_backpack_grid_size(inventory, backpack_uid)
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	for position in grid_size.x * grid_size.y:
		if not backpack_items.has(position):
			return position
	return -1


func _on_drag_started(data: Dictionary) -> void:
	_active_drag_data = data.duplicate(true)
	_drag_drop_received = false
	_last_drag_target_position = -1
	_last_backpack_drag_target = -1
	_last_drag_mouse_position = Vector2.INF
	_update_drag_target_highlights()


func _on_drag_ended() -> void:
	_active_drag_data.clear()
	_set_grid_drag_target(-1)
	_set_backpack_drag_target(-1)
	_update_drag_target_highlights()


func _update_drag_target_highlights() -> void:
	for equipment_slot in _equipment_slot_nodes:
		if is_instance_valid(equipment_slot):
			equipment_slot.set_drop_highlight(not _active_drag_data.is_empty() and equipment_slot.can_accept_data(_active_drag_data))
	for attachment_slot in _attachment_slot_nodes:
		if is_instance_valid(attachment_slot):
			attachment_slot.set_drop_highlight(not _active_drag_data.is_empty() and attachment_slot.can_accept_data(_active_drag_data))


func _on_grid_drop_hovered(position: int) -> void:
	if _is_reordering_locked():
		return
	_set_grid_drag_target(position)


func _on_grid_drop_unhovered(position: int) -> void:
	if position < 0 or _last_drag_target_position != position:
		return


func _on_backpack_drop_hovered(position: int) -> void:
	if _active_drag_data.is_empty():
		return
	_set_backpack_drag_target(position)


func _on_backpack_drop_unhovered(position: int) -> void:
	if position < 0 or _last_backpack_drag_target != position:
		return


func _on_grid_gap_dropped(data: Dictionary) -> void:
	_drag_drop_received = true
	_drop_at_grid_target(data, _last_drag_target_position)


func _on_backpack_grid_gap_dropped(data: Dictionary, backpack_uid: String) -> void:
	_drag_drop_received = true
	_drop_at_backpack_target(data, _last_backpack_drag_target, backpack_uid)


func _apply_drag_drop_fallback(data: Dictionary, grid_target_position: int, backpack_target_position: int, is_in_storage: bool, is_in_backpack: bool, backpack_uid: String) -> void:
	if _drag_drop_received:
		return
	if is_in_storage:
		_drop_at_grid_target(data, grid_target_position)
		return
	if is_in_backpack:
		_drop_at_backpack_target(data, backpack_target_position, backpack_uid)


func _drop_at_grid_target(data: Dictionary, target_position: int) -> void:
	if target_position < 0:
		return
	var target_item: Dictionary = _position_index.get(target_position, {})
	_on_inventory_item_dropped(data, str(target_item.get("uid", "")), target_position)


func _drop_at_backpack_target(data: Dictionary, target_position: int, backpack_uid: String) -> void:
	if target_position < 0 or backpack_uid.is_empty():
		return
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	var target_item := WarehouseService.get_item_by_uid(inventory, str(backpack_items.get(target_position, "")))
	_on_backpack_item_dropped(data, str(target_item.get("uid", "")), target_position, backpack_uid)


func _update_drag_targets(mouse_position: Vector2) -> void:
	_update_grid_drag_target(mouse_position)
	_update_backpack_drag_target(mouse_position)


func _update_grid_drag_target(mouse_position: Vector2) -> void:
	if _is_reordering_locked():
		_set_grid_drag_target(-1)
		return
	if not _storage_panel.get_global_rect().has_point(mouse_position):
		_set_grid_drag_target(-1)
		return
	var target_position := _get_grid_position_from_mouse(mouse_position)
	if target_position >= 0:
		_set_grid_drag_target(target_position)


func _update_backpack_drag_target(mouse_position: Vector2) -> void:
	if _backpack_grid == null or not is_instance_valid(_backpack_grid):
		_set_backpack_drag_target(-1)
		return
	if not _backpack_panel.get_global_rect().has_point(mouse_position):
		_set_backpack_drag_target(-1)
		return
	var target_position := _get_backpack_position_from_mouse(mouse_position)
	if target_position >= 0:
		_set_backpack_drag_target(target_position)


func _get_grid_position_from_mouse(mouse_position: Vector2) -> int:
	if _grid_slot_nodes.is_empty() or not _grid.get_global_rect().has_point(mouse_position):
		return -1
	var first_slot: InventorySlot = _grid_slot_nodes[0]
	var slot_size := first_slot.size
	var pitch := slot_size + Vector2(_grid.get_theme_constant("h_separation"), _grid.get_theme_constant("v_separation"))
	if pitch.x <= 0.0 or pitch.y <= 0.0:
		return -1
	var relative_position := mouse_position - first_slot.get_global_rect().position
	var column := clampi(roundi(relative_position.x / pitch.x), 0, WarehouseService.get_grid_columns(inventory) - 1)
	var row := clampi(roundi(relative_position.y / pitch.y), 0, 9)
	var position := row * WarehouseService.get_grid_columns(inventory) + column
	return position if position < WarehouseService.get_grid_capacity(inventory) else -1


func _get_backpack_position_from_mouse(mouse_position: Vector2) -> int:
	if _backpack_grid == null or _backpack_slot_nodes.is_empty() or not _backpack_grid.get_global_rect().has_point(mouse_position):
		return -1
	var first_slot: InventorySlot = _backpack_slot_nodes[0]
	var slot_size := first_slot.size
	var pitch := slot_size + Vector2(_backpack_grid.get_theme_constant("h_separation"), _backpack_grid.get_theme_constant("v_separation"))
	if pitch.x <= 0.0 or pitch.y <= 0.0:
		return -1
	var grid_size := WarehouseService.get_backpack_grid_size(inventory, _selected_backpack_uid)
	var relative_position := mouse_position - first_slot.get_global_rect().position
	var column := clampi(roundi(relative_position.x / pitch.x), 0, grid_size.x - 1)
	var row := clampi(roundi(relative_position.y / pitch.y), 0, grid_size.y - 1)
	var position := row * grid_size.x + column
	return position if position < _backpack_slot_nodes.size() else -1


func _set_grid_drag_target(target_position: int) -> void:
	if target_position == _last_drag_target_position:
		return
	if _last_drag_target_position >= 0 and _last_drag_target_position < _grid_slot_nodes.size():
		_grid_slot_nodes[_last_drag_target_position].set_drop_highlight(false)
	_last_drag_target_position = target_position
	if target_position >= 0 and target_position < _grid_slot_nodes.size():
		var target_slot: InventorySlot = _grid_slot_nodes[target_position]
		target_slot.set_drop_highlight(not target_slot.is_occupied)


func _set_backpack_drag_target(target_position: int) -> void:
	if target_position == _last_backpack_drag_target:
		return
	if _last_backpack_drag_target >= 0 and _last_backpack_drag_target < _backpack_slot_nodes.size():
		_backpack_slot_nodes[_last_backpack_drag_target].set_drop_highlight(false)
	_last_backpack_drag_target = target_position
	if target_position >= 0 and target_position < _backpack_slot_nodes.size():
		var target_slot: InventorySlot = _backpack_slot_nodes[target_position]
		target_slot.set_drop_highlight(not target_slot.is_occupied)


func _refresh_backpack_slots(backpack_uid: String, positions: Array[int]) -> void:
	if backpack_uid != _selected_backpack_uid or _backpack_slot_nodes.is_empty():
		_refresh_all()
		return
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	for position in positions:
		if position < 0 or position >= _backpack_slot_nodes.size():
			continue
		var item := WarehouseService.get_item_by_uid(inventory, str(backpack_items.get(position, "")))
		var slot: InventorySlot = _backpack_slot_nodes[position]
		slot.configure(position, item, str(item.get("uid", "")) == _selected_uid, true, {"kind": "backpack_item", "source_backpack_uid": backpack_uid, "source_backpack_position": position})


func _select_item(item_uid: String, position: int) -> void:
	_selected_uid = item_uid
	_selected_position = position
	_selected_equip_slot = ""
	_pending_detach_attachment_slot = ""
	var item := WarehouseService.get_item_by_uid(inventory, item_uid)
	var item_data := _get_item_data(item)
	if str(item_data.get("type", "")) == "WEAPON":
		_selected_weapon_uid = item_uid
		_attachment_target_slot = ""
	_show_item_info(item_uid)
	_status_label.text = "已选中 %s。拖拽可移动、装备或装配配件。" % str(item_data.get("name", "物品"))
	_refresh_all()


func _show_item_info(item_uid: String) -> void:
	var item := WarehouseService.get_item_by_uid(inventory, item_uid)
	var item_data := _get_item_data(item)
	if item_data.is_empty():
		_info_panel.show_empty()
		return
	_info_panel.show_item(item_data, _get_item_action_text(item_data), item)


func _focus_attachment_target_weapon(weapon_uid: String, status_text: String) -> void:
	_selected_weapon_uid = weapon_uid
	_selected_uid = weapon_uid
	_selected_position = -1
	_selected_equip_slot = "weapon" if WarehouseService.get_equipped_uid(inventory, "weapon", OPERATOR_ID) == weapon_uid else ""
	_attachment_target_slot = ""
	_show_item_info(weapon_uid)
	_refresh_all()
	_status_label.text = status_text


func _get_item_action_text(item_data: Dictionary) -> String:
	var item_type := str(item_data.get("type", ""))
	if item_type == "WEAPON_ATTACHMENT" and not _selected_weapon_uid.is_empty():
		return "装入当前武器"
	var slot := _type_to_slot(item_type)
	if slot.is_empty():
		return ""
	if not _selected_equip_slot.is_empty() and _selected_equip_slot == slot:
		return "装备到%s" % _get_slot_name(slot)
	return "装备至贝妮"


func _on_info_action() -> void:
	if _selected_uid.is_empty():
		if not _pending_detach_attachment_slot.is_empty():
			if WarehouseService.detach_attachment(inventory, _selected_weapon_uid, _pending_detach_attachment_slot):
				_status_label.text = "已卸下配件。"
				_pending_detach_attachment_slot = ""
				_refresh_all()
			return
		if not _selected_equip_slot.is_empty():
			_return_equipment_to_warehouse(_selected_equip_slot, WarehouseService.get_equipped_uid(inventory, _selected_equip_slot, OPERATOR_ID), -1)
		return
	var item := WarehouseService.get_item_by_uid(inventory, _selected_uid)
	var item_data := _get_item_data(item)
	if str(item_data.get("type", "")) == "WEAPON_ATTACHMENT":
		_attach_selected_item()
		return
	var slot := _type_to_slot(str(item_data.get("type", "")))
	if slot.is_empty():
		return
	var backpack_items := WarehouseService.get_backpack_items(inventory, _selected_backpack_uid)
	var is_backpack_source := not _selected_backpack_uid.is_empty() and str(backpack_items.get(_selected_position, "")) == _selected_uid
	var has_equipped_item := not WarehouseService.get_equipped_uid(inventory, slot, OPERATOR_ID).is_empty()
	var equipped := false
	if has_equipped_item:
		equipped = WarehouseService.replace_equipped_item_from_backpack(inventory, _selected_backpack_uid, _selected_position, slot, SaveManager.current_data.player) if is_backpack_source else WarehouseService.replace_equipped_item_from_warehouse(inventory, slot, _selected_uid, SaveManager.current_data.player)
	if not equipped:
		equipped = WarehouseService.equip_backpack_item(inventory, _selected_backpack_uid, _selected_position, slot, SaveManager.current_data.player) if is_backpack_source else WarehouseService.equip_item(inventory, slot, _selected_uid, SaveManager.current_data.player)
	if equipped:
		_status_label.text = "%s 已装配至%s。" % [str(item_data.get("name", "物品")), _get_slot_name(slot)]
		call_deferred("_focus_equipped_item", slot, _selected_uid, false)
	elif slot == "backpack" and has_equipped_item:
		_status_label.text = "新背包空间不足，无法迁移当前背包中的物品。"


func _attach_selected_item() -> void:
	if _selected_weapon_uid.is_empty() or _selected_uid.is_empty():
		return
	var attachment := WarehouseService.get_item_by_uid(inventory, _selected_uid)
	var attachment_data := _get_item_data(attachment)
	var attachment_slot := _attachment_target_slot if not _attachment_target_slot.is_empty() else str(attachment_data.get("slot", ""))
	var backpack_items := WarehouseService.get_backpack_items(inventory, _selected_backpack_uid)
	var is_backpack_source := not _selected_backpack_uid.is_empty() and str(backpack_items.get(_selected_position, "")) == _selected_uid
	var attached := WarehouseService.attach_backpack_item_to_weapon(inventory, _selected_backpack_uid, _selected_position, _selected_weapon_uid, attachment_slot) if is_backpack_source else WarehouseService.attach_item(inventory, _selected_weapon_uid, _selected_uid, attachment_slot)
	if attached:
		_status_label.text = "%s 已装入武器。" % str(attachment_data.get("name", "配件"))
		_selected_position = -1
		_refresh_all()
	else:
		_status_label.text = "该配件与当前武器接口不兼容。"


func _on_equipment_slot_pressed(slot: String, item_uid: String) -> void:
	_selected_equip_slot = slot
	_selected_position = -1
	_selected_uid = ""
	if slot == "weapon" and not item_uid.is_empty():
		_selected_weapon_uid = item_uid
		_attachment_target_slot = ""
	elif slot == "backpack" and not item_uid.is_empty():
		_selected_backpack_uid = item_uid
	else:
		if slot == "backpack":
			_selected_backpack_uid = ""
	_pending_detach_attachment_slot = ""
	if item_uid.is_empty():
		_info_panel.show_empty()
		_status_label.text = "已选择%s；从仓库拖拽物品到此处即可装配。" % _get_slot_name(slot)
	else:
		_show_item_info(item_uid)
		_info_panel.set_action("卸下%s" % _get_slot_name(slot))
		_status_label.text = "已选中%s；点击信息面板按钮可卸下。" % _get_slot_name(slot)
	_refresh_all()


func _focus_equipped_item(slot: String, item_uid: String, show_auto_equip_message: bool) -> void:
	_on_equipment_slot_pressed(slot, item_uid)
	if show_auto_equip_message:
		var item_data := _get_item_data(WarehouseService.get_item_by_uid(inventory, item_uid))
		_status_label.text = "%s 已自动装配至%s。" % [str(item_data.get("name", "物品")), _get_slot_name(slot)]


func _on_attachment_slot_pressed(attachment_slot: String, attachment_uid: String) -> void:
	_attachment_target_slot = attachment_slot
	_pending_detach_attachment_slot = attachment_slot if not attachment_uid.is_empty() else ""
	_selected_position = -1
	_selected_uid = ""
	_selected_equip_slot = ""
	if not attachment_uid.is_empty():
		_show_item_info(attachment_uid)
		_info_panel.set_action("卸下配件")
	_status_label.text = "已选中%s接口；可拖拽兼容配件到武器或点击信息面板装入。" % _get_attachment_slot_name(attachment_slot)
	_refresh_all()


func _on_filter_selected(index: int) -> void:
	_filter_type = "" if index == 0 else str(ItemDB.VALID_TYPES.keys()[index - 1])
	_selected_uid = ""
	_selected_position = -1
	_selected_equip_slot = ""
	_status_label.text = "筛选展示时已锁定仓库格位拖拽；仍可装配装备和配件。" if _is_reordering_locked() else "已恢复手动布局。"
	_refresh_all()


func _organize_items() -> void:
	WarehouseService.organize(inventory)
	_selected_uid = ""
	_selected_position = -1
	_selected_equip_slot = ""
	_status_label.text = "已按品类归组，并按等级从高到低自动整理。"
	_refresh_all()


func _get_display_items() -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	for item in inventory.warehouse_items:
		if int(item.get("position", -1)) < 0:
			continue
		var item_data := _get_item_data(item)
		if not _filter_type.is_empty() and str(item_data.get("type", "")) != _filter_type:
			continue
		items.append(item)
	if _filter_type.is_empty():
		return items
	items.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_data := _get_item_data(first)
		var second_data := _get_item_data(second)
		var first_level := WarehouseService.get_merge_level(first_data)
		var second_level := WarehouseService.get_merge_level(second_data)
		if first_level != second_level:
			return first_level > second_level
		return str(first_data.get("name", "")) < str(second_data.get("name", ""))
	)
	return items


func _is_reordering_locked() -> bool:
	return not _filter_type.is_empty()


func _type_to_slot(item_type: String) -> String:
	match item_type:
		"WEAPON": return "weapon"
		"HELMET": return "helmet"
		"ARMOR": return "armor"
		"BACKPACK": return "backpack"
	return ""


func _get_slot_name(slot: String) -> String:
	return {"weapon": "武器", "helmet": "头盔", "armor": "护甲", "backpack": "背包"}.get(slot, slot)


func _get_attachment_slot_name(slot: String) -> String:
	return {"SCOPE": "瞄具", "BARREL": "枪口", "STOCK": "枪托", "RESONANCE_CORE": "共鸣核心"}.get(slot, slot)


func _get_item_data(item: Dictionary) -> Dictionary:
	return _get_item_data_by_id(str(item.get("id", "")))


func _get_item_data_by_id(item_id: String) -> Dictionary:
	var item_data: Variant = ItemDB.get_item(item_id)
	return item_data as Dictionary if item_data is Dictionary else {}


func _build_position_index() -> Dictionary:
	var position_index := {}
	var warehouse_positions := WarehouseService.get_warehouse_position_index(inventory)
	for position in warehouse_positions:
		var item_uid := str(warehouse_positions[position])
		position_index[position] = WarehouseService.get_item_by_uid(inventory, item_uid)
	return position_index


func _create_panel(minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.add_theme_stylebox_override("panel", _make_panel_style())
	return panel


func _create_button(text_value: String, minimum_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum_size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_color_override("font_color", Color(0.84, 0.95, 1.0, 1.0))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_stylebox_override("normal", _make_button_style(false))
	button.add_theme_stylebox_override("hover", _make_button_style(true))
	button.add_theme_stylebox_override("pressed", _make_button_style(true))
	return button


func _create_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.11, 0.94)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.17, 0.43, 0.58, 0.9)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func _make_button_style(active: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.21, 0.29, 1.0) if active else Color(0.04, 0.13, 0.19, 1.0)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.36, 0.88, 1.0, 1.0) if active else Color(0.2, 0.48, 0.63, 0.85)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()
