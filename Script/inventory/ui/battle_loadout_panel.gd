class_name BattleLoadoutPanel
extends PanelContainer

const OPERATOR_EQUIPMENT_SLOT_SCRIPT := preload("res://Script/inventory/ui/operator_equipment_slot.gd")
const WEAPON_ATTACHMENT_SLOT_SCRIPT := preload("res://Script/inventory/ui/weapon_attachment_slot.gd")
const INVENTORY_GRID_SCRIPT := preload("res://Script/inventory/ui/inventory_grid.gd")
const TRANSFER_POLICY_SCRIPT := preload("res://Script/inventory/transfer_policy.gd")
const DEFAULT_PANEL_RIGHT := 1000.0
const SEARCH_PANEL_RIGHT := 1314.0

var inventory: InventorySaveData
var player: Player
var player_data: PlayerSaveData
var operator_id := WarehouseService.OPERATOR_ID
var _temporary_container_id := ""
var _temporary_container_name := ""
var _transfer_policy: TransferPolicy
var _selected_uid := ""
var _selected_weapon_uid := ""
var _attachment_target_slot := ""
var _status_label: Label
var _character_content: VBoxContainer
var _attachment_content: VBoxContainer
var _backpack_content: VBoxContainer
var _temporary_content: VBoxContainer
var _attachment_panel: PanelContainer
var _backpack_panel: PanelContainer
var _temporary_panel: PanelContainer
var _temporary_title: Label
var _equipment_slot_nodes: Array = []
var _attachment_slot_nodes: Array = []
var _active_drag_data: Dictionary = {}
var _backpack_grid: InventoryGrid
var _backpack_slot_nodes: Array = []
var _temporary_grid: InventoryGrid
var _temporary_slot_nodes: Array = []
var _last_backpack_drag_target := -1
var _last_temporary_drag_target := -1


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	offset_left = 24.0
	offset_top = 82.0
	offset_right = DEFAULT_PANEL_RIGHT
	offset_bottom = 1040.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_stylebox_override("panel", _make_panel_style(Color(0.012, 0.04, 0.065, 0.98), Color(0.2, 0.6, 0.78, 0.95)))
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 10)
	add_child(page)
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 38)
	header.add_theme_constant_override("separation", 10)
	page.add_child(header)
	var title := Label.new()
	title.text = "干员战术面板"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.82, 0.96, 1.0, 1.0))
	header.add_child(title)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.52, 0.8, 0.9, 1.0))
	header.add_child(_status_label)
	var close_button := Button.new()
	close_button.text = "收起"
	close_button.custom_minimum_size = Vector2(72, 32)
	close_button.pressed.connect(hide_panel)
	header.add_child(close_button)
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	page.add_child(body)
	_character_content = _add_section(body, "干员与装备", 238.0)
	var loadout_column := VBoxContainer.new()
	loadout_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	loadout_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	loadout_column.add_theme_constant_override("separation", 10)
	body.add_child(loadout_column)
	_attachment_content = _add_section(loadout_column, "武器配件")
	_attachment_panel = _attachment_content.get_parent() as PanelContainer
	_attachment_panel.custom_minimum_size = Vector2(0, 246)
	_attachment_panel.size_flags_vertical = Control.SIZE_FILL
	_backpack_content = _add_section(loadout_column, "战场背包")
	_backpack_panel = _backpack_content.get_parent() as PanelContainer
	_backpack_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_temporary_content = _add_section(body, "临时物资", 340.0)
	_temporary_panel = _temporary_content.get_parent() as PanelContainer
	_temporary_title = _temporary_content.get_node("SectionTitle") as Label
	_temporary_panel.visible = false
	visible = false
	_refresh()


func configure(source_inventory: InventorySaveData, source_player: Player, source_player_data: PlayerSaveData, source_operator_id: String = WarehouseService.OPERATOR_ID) -> void:
	inventory = source_inventory
	player = source_player
	player_data = source_player_data
	operator_id = source_operator_id
	_selected_weapon_uid = WarehouseService.get_equipped_uid(inventory, "weapon", operator_id) if inventory else ""
	_attachment_target_slot = ""
	_transfer_policy = TRANSFER_POLICY_SCRIPT.new()
	_transfer_policy.configure({
		"temporary": {
			"WEAPON": [{"target": "equipment", "slot": "weapon"}, {"target": "backpack"}],
			"HELMET": [{"target": "equipment", "slot": "helmet"}, {"target": "backpack"}],
			"ARMOR": [{"target": "equipment", "slot": "armor"}, {"target": "backpack"}],
			"BACKPACK": [{"target": "equipment", "slot": "backpack"}, {"target": "backpack"}],
			"*": [{"target": "backpack"}],
		},
		"backpack": {
			"WEAPON": [{"target": "equipment", "slot": "weapon"}, {"target": "temporary"}],
			"*": [{"target": "temporary"}],
		},
		"equipment": {"*": [{"target": "temporary"}]},
		"weapon_attachment": {"*": [{"target": "temporary"}]},
	}, {
		"temporary": {"columns": 4, "capacity": 16, "allows_swap": true},
		"backpack": {"allows_swap": true},
		"equipment": {"allows_swap": false},
	})
	if is_node_ready():
		_refresh()


func show_for_operator() -> void:
	visible = true
	_refresh()


func hide_panel() -> void:
	visible = false


func is_item_drag_active() -> bool:
	return not _active_drag_data.is_empty()


func _process(_delta: float) -> void:
	if _active_drag_data.is_empty():
		return
	var mouse_position := get_viewport().get_mouse_position()
	if _backpack_grid == null or not _backpack_grid.get_global_rect().has_point(mouse_position):
		_set_backpack_drag_target(-1)
	if _temporary_grid == null or not _temporary_grid.get_global_rect().has_point(mouse_position):
		_set_temporary_drag_target(-1)


func open_search_container(resource_id: String, resource_name: String, capacity: int = 16, columns: int = 4) -> void:
	if inventory == null or resource_id.is_empty() or resource_name.is_empty():
		return
	_temporary_container_id = "search:%s" % resource_id
	_temporary_container_name = resource_name
	WarehouseService.create_temporary_container(inventory, _temporary_container_id, capacity, columns)
	show_for_operator()
	_status_label.text = "正在搜索：%s" % resource_name


func close_temporary_container(discard_items: bool = true) -> void:
	if inventory == null or _temporary_container_id.is_empty():
		return
	WarehouseService.clear_temporary_container(inventory, _temporary_container_id, discard_items)
	_temporary_container_id = ""
	_temporary_container_name = ""
	_refresh()


func add_search_item(item_id: String, position: int = -1) -> bool:
	if inventory == null or _temporary_container_id.is_empty():
		return false
	var added := WarehouseService.add_temporary_item(inventory, _temporary_container_id, item_id, position)
	if added:
		_refresh()
	return added


func _add_section(parent: Container, title_text: String, width: float = 0.0) -> VBoxContainer:
	var panel := PanelContainer.new()
	if width > 0.0:
		panel.custom_minimum_size = Vector2(width, 0)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.022, 0.08, 0.12, 0.96), Color(0.14, 0.36, 0.48, 0.92)))
	parent.add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)
	var title := Label.new()
	title.name = "SectionTitle"
	title.text = title_text
	title.add_theme_font_size_override("font_size", 17)
	title.add_theme_color_override("font_color", Color(0.49, 0.86, 1.0, 1.0))
	content.add_child(title)
	return content


func _refresh() -> void:
	if not is_node_ready() or inventory == null:
		return
	if _selected_weapon_uid.is_empty():
		_selected_weapon_uid = WarehouseService.get_equipped_uid(inventory, "weapon", operator_id)
	_render_character()
	_render_attachments()
	_render_backpack()
	_render_temporary()


func _render_character() -> void:
	_clear_section(_character_content)
	_equipment_slot_nodes.clear()
	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(0, 142)
	portrait.texture = load("res://Art/characters/benny/benny_base_01.png")
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_character_content.add_child(portrait)
	var name_label := _make_label(player.unit_name if player else "贝妮", 20, Color(0.88, 0.97, 1.0, 1.0))
	_character_content.add_child(name_label)
	var hp_text := "%d / %d HP" % [player.current_hp, player.max_hp] if player else "HP --"
	_character_content.add_child(_make_label(hp_text, 15, _get_hp_color(player.current_hp, player.max_hp) if player else Color(0.5, 0.96, 0.63, 1.0)))
	_character_content.add_child(_make_label("装备栏", 16, Color(0.55, 0.83, 0.96, 1.0)))
	for slot in WarehouseService.EQUIPMENT_SLOTS:
		var item_uid := WarehouseService.get_equipped_uid(inventory, slot, operator_id)
		var item := WarehouseService.get_item_by_uid(inventory, item_uid)
		var slot_node := OPERATOR_EQUIPMENT_SLOT_SCRIPT.new()
		slot_node.configure(slot, item_uid, _item_data(item), not item_uid.is_empty() and item_uid == _selected_uid, item)
		slot_node.slot_activated.connect(_on_equipment_slot_activated)
		slot_node.item_dropped.connect(_on_equipment_item_dropped)
		slot_node.item_double_clicked.connect(_on_equipment_item_double_clicked)
		slot_node.drag_started.connect(_on_drag_started)
		slot_node.drag_ended.connect(_on_drag_ended)
		_equipment_slot_nodes.append(slot_node)
		_character_content.add_child(slot_node)


func _render_attachments() -> void:
	_clear_section(_attachment_content)
	_attachment_slot_nodes.clear()
	var weapon := WarehouseService.get_item_by_uid(inventory, _selected_weapon_uid)
	var weapon_data := _item_data(weapon)
	if weapon_data.is_empty():
		_attachment_content.add_child(_make_label("未装备武器", 15, Color(0.52, 0.66, 0.74, 1.0)))
		return
	_attachment_content.add_child(_make_label(str(weapon_data.get("name", "武器")), 17, Color(0.88, 0.96, 1.0, 1.0)))
	var attachment_slots: Array = weapon_data.get("attachment_slots", [])
	for attachment_slot in attachment_slots:
		var attachment_uid := str(WarehouseService.get_weapon_attachments(inventory, _selected_weapon_uid, operator_id).get(attachment_slot, ""))
		var attachment := WarehouseService.get_item_by_uid(inventory, attachment_uid)
		var slot_node := WEAPON_ATTACHMENT_SLOT_SCRIPT.new()
		slot_node.configure(str(attachment_slot), attachment_uid, _selected_weapon_uid, str(weapon.get("id", "")), _item_data(attachment), str(attachment_slot) == _attachment_target_slot)
		slot_node.slot_activated.connect(_on_attachment_slot_activated)
		slot_node.item_dropped.connect(_on_attachment_item_dropped)
		slot_node.item_double_clicked.connect(_on_attachment_item_double_clicked)
		slot_node.drag_started.connect(_on_drag_started)
		slot_node.drag_ended.connect(_on_drag_ended)
		_attachment_slot_nodes.append(slot_node)
		_attachment_content.add_child(slot_node)


func _render_backpack() -> void:
	_clear_section(_backpack_content)
	_backpack_slot_nodes.clear()
	_backpack_grid = null
	var backpack_uid := WarehouseService.get_equipped_uid(inventory, "backpack", operator_id)
	var size := WarehouseService.get_backpack_grid_size(inventory, backpack_uid)
	if size.x <= 0 or size.y <= 0:
		_backpack_content.add_child(_make_label("未装备背包", 15, Color(0.52, 0.66, 0.74, 1.0)))
		return
	_backpack_content.add_child(_make_label("携行空间：%d × %d" % [size.x, size.y], 14, Color(0.52, 0.8, 0.94, 1.0)))
	var grid := INVENTORY_GRID_SCRIPT.new()
	_backpack_grid = grid
	grid.columns = size.x
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	_backpack_content.add_child(grid)
	var items := WarehouseService.get_backpack_items(inventory, backpack_uid, operator_id)
	for position in size.x * size.y:
		var item := WarehouseService.get_item_by_uid(inventory, str(items.get(position, "")))
		var slot := InventorySlot.new()
		slot.configure(position, item, str(item.get("uid", "")) == _selected_uid, true, {"kind": "backpack_item", "source_backpack_uid": backpack_uid, "source_backpack_position": position})
		slot.slot_activated.connect(_on_backpack_slot_activated.bind(backpack_uid))
		slot.item_dropped.connect(_on_backpack_item_dropped.bind(backpack_uid))
		slot.item_double_clicked.connect(_on_backpack_item_double_clicked.bind(backpack_uid, position))
		slot.drag_started.connect(_on_drag_started)
		slot.drag_ended.connect(_on_drag_ended)
		slot.drop_hovered.connect(_on_backpack_drop_hovered)
		slot.drop_unhovered.connect(_on_backpack_drop_unhovered)
		_backpack_slot_nodes.append(slot)
		grid.add_child(slot)


func _render_temporary() -> void:
	_clear_section(_temporary_content)
	_temporary_slot_nodes.clear()
	_temporary_grid = null
	if _temporary_container_id.is_empty():
		_temporary_panel.visible = false
		offset_right = DEFAULT_PANEL_RIGHT
		return
	_temporary_panel.visible = true
	offset_right = SEARCH_PANEL_RIGHT
	_temporary_title.text = _temporary_container_name
	var capacity := WarehouseService.get_temporary_capacity(inventory, _temporary_container_id)
	var grid := INVENTORY_GRID_SCRIPT.new()
	_temporary_grid = grid
	grid.columns = WarehouseService.get_temporary_columns(inventory, _temporary_container_id)
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	_temporary_content.add_child(grid)
	var items := WarehouseService.get_temporary_items(inventory, _temporary_container_id)
	for position in capacity:
		var item := WarehouseService.get_item_by_uid(inventory, str(items.get(position, "")))
		var slot := InventorySlot.new()
		slot.configure(position, item, str(item.get("uid", "")) == _selected_uid, true, {"kind": "temporary_item", "source_temporary_id": _temporary_container_id, "source_temporary_position": position})
		slot.slot_activated.connect(_on_temporary_slot_activated)
		slot.item_dropped.connect(_on_temporary_item_dropped.bind(position))
		slot.item_double_clicked.connect(_on_temporary_item_double_clicked.bind(position))
		slot.drag_started.connect(_on_drag_started)
		slot.drag_ended.connect(_on_drag_ended)
		slot.drop_hovered.connect(_on_temporary_drop_hovered)
		slot.drop_unhovered.connect(_on_temporary_drop_unhovered)
		_temporary_slot_nodes.append(slot)
		grid.add_child(slot)


func _on_equipment_slot_activated(slot: String, item_uid: String) -> void:
	if item_uid.is_empty():
		_selected_uid = ""
		_status_label.text = "已选择%s。" % _slot_name(slot)
		_refresh()
		return
	_select_item(item_uid, "%s已选择。" % _slot_name(slot))


func _on_backpack_slot_activated(position: int, item_uid: String, _backpack_uid: String) -> void:
	if item_uid.is_empty():
		_selected_uid = ""
		_status_label.text = "背包格 %d 已选择。" % (position + 1)
		_refresh()
		return
	_select_item(item_uid, "背包格 %d 已选择。" % (position + 1))


func _on_temporary_slot_activated(position: int, item_uid: String) -> void:
	if item_uid.is_empty():
		_selected_uid = ""
		_status_label.text = "临时物资格 %d 已选择。" % (position + 1)
		_refresh()
		return
	_select_item(item_uid, "临时物资格 %d 已选择。" % (position + 1))


func _on_attachment_slot_activated(_slot: String, item_uid: String) -> void:
	_attachment_target_slot = _slot
	_selected_uid = item_uid
	_refresh()


func _on_backpack_item_dropped(data: Dictionary, target_uid: String, target_position: int, backpack_uid: String) -> void:
	var target_item := WarehouseService.get_item_by_uid(inventory, target_uid)
	if _is_attachment(data) and str(_item_data(target_item).get("type", "")) == "WEAPON":
		_try_transfer(_source_location(data), ItemLocation.weapon_attachment(target_uid, str(data.get("attachment_slot", ""))))
		return
	if str(data.get("kind", "")) == "weapon_attachment" and not target_uid.is_empty():
		_status_label.text = "配件只能放入空背包格，不能与普通物品交换。"
		return
	var source := _source_location(data)
	if source != null and source.container_id == ItemLocation.BACKPACK and source.owner_id == backpack_uid:
		if WarehouseService.move_backpack_item(inventory, backpack_uid, source.position, target_position):
			_complete_transfer("背包物品已调整。")
		return
	_try_transfer(source, ItemLocation.backpack(backpack_uid, target_position))


func _on_temporary_item_dropped(data: Dictionary, target_uid: String, target_position: int, _bound_position: int) -> void:
	var target_item := WarehouseService.get_item_by_uid(inventory, target_uid)
	if _is_attachment(data) and str(_item_data(target_item).get("type", "")) == "WEAPON":
		_try_transfer(_source_location(data), ItemLocation.weapon_attachment(target_uid, str(data.get("attachment_slot", ""))))
		return
	if str(data.get("kind", "")) == "weapon_attachment" and not target_uid.is_empty():
		_status_label.text = "配件只能放入空物资格，不能与普通物品交换。"
		return
	var source := _source_location(data)
	if source != null and source.container_id == ItemLocation.TEMPORARY and source.owner_id == _temporary_container_id:
		if WarehouseService.move_temporary_item(inventory, _temporary_container_id, source.position, target_position):
			_complete_transfer("临时物资已调整。")
		return
	_try_transfer(source, ItemLocation.temporary(_temporary_container_id, target_position))


func _on_equipment_item_dropped(slot: String, data: Dictionary) -> void:
	var source := _source_location(data)
	if source == null:
		return
	if _is_attachment(data):
		if slot != "weapon":
			_status_label.text = "配件只能安装到武器。"
			return
		var weapon_uid := WarehouseService.get_equipped_uid(inventory, "weapon", operator_id)
		_try_transfer(source, ItemLocation.weapon_attachment(weapon_uid, str(data.get("attachment_slot", ""))))
		return
	if slot == "backpack" and not WarehouseService.get_equipped_uid(inventory, "backpack", operator_id).is_empty() and WarehouseService.get_backpack_item_count(inventory, WarehouseService.get_equipped_uid(inventory, "backpack", operator_id)) > 0:
		_status_label.text = "战斗中不能替换装有物资的背包。"
		return
	_try_transfer(source, ItemLocation.equipment(operator_id, slot))


func _on_attachment_item_dropped(slot: String, data: Dictionary) -> void:
	_try_transfer(_source_location(data), ItemLocation.weapon_attachment(_selected_weapon_uid, slot))


func _on_temporary_item_double_clicked(item_uid: String, position: int) -> void:
	_double_click_transfer(ItemLocation.temporary(_temporary_container_id, position), "temporary", item_uid)


func _on_backpack_item_double_clicked(item_uid: String, backpack_uid: String, position: int) -> void:
	_double_click_transfer(ItemLocation.backpack(backpack_uid, position), "backpack", item_uid)


func _on_equipment_item_double_clicked(slot: String) -> void:
	var item_uid := WarehouseService.get_equipped_uid(inventory, slot, operator_id)
	_double_click_transfer(ItemLocation.equipment(operator_id, slot), "equipment", item_uid)


func _on_attachment_item_double_clicked(slot: String) -> void:
	var item_uid := str(WarehouseService.get_weapon_attachments(inventory, _selected_weapon_uid, operator_id).get(slot, ""))
	_double_click_transfer(ItemLocation.weapon_attachment(_selected_weapon_uid, slot), "weapon_attachment", item_uid)


func _double_click_transfer(source: ItemLocation, source_container: String, item_uid: String) -> void:
	if source == null or item_uid.is_empty():
		return
	var item_type := str(_item_data(WarehouseService.get_item_by_uid(inventory, item_uid)).get("type", ""))
	for target in _transfer_policy.get_double_click_targets(source_container, item_type):
		var target_type := str(target.get("target", ""))
		if target_type == "equipment":
			var slot := str(target.get("slot", ""))
			if WarehouseService.get_equipped_uid(inventory, slot, operator_id).is_empty() and _try_transfer(source, ItemLocation.equipment(operator_id, slot), false):
				_complete_transfer("物品已装配。")
				return
		if target_type == "backpack":
			var backpack_uid := WarehouseService.get_equipped_uid(inventory, "backpack", operator_id)
			var backpack_position := _first_empty_backpack_position(backpack_uid)
			if backpack_position >= 0 and _try_transfer(source, ItemLocation.backpack(backpack_uid, backpack_position), false):
				_complete_transfer("物品已放入背包。")
				return
		if target_type == "temporary":
			var temporary_position := _first_empty_temporary_position()
			if temporary_position >= 0 and _try_transfer(source, ItemLocation.temporary(_temporary_container_id, temporary_position), false):
				_complete_transfer("物品已移入临时面板。")
				return
	_status_label.text = "没有可用的优先目标。"


func _try_transfer(source: ItemLocation, target: ItemLocation, refresh_after: bool = true) -> bool:
	if source == null or target == null or source.matches(target):
		return false
	if target.container_id == ItemLocation.WEAPON_ATTACHMENT and _selected_weapon_uid.is_empty():
		_status_label.text = "未装备可安装配件的武器。"
		return false
	if WarehouseService.transfer_item(inventory, source, target, player_data):
		if target.container_id == ItemLocation.WEAPON_ATTACHMENT:
			_selected_weapon_uid = target.owner_id
			_selected_uid = target.owner_id
			_attachment_target_slot = target.slot_id
		if refresh_after:
			_complete_transfer("物品已转移。")
		return true
	_status_label.text = "无法转移：目标不兼容、空间不足或替换条件不满足。"
	return false


func _complete_transfer(message: String) -> void:
	if player and player_data:
		player.sync_equipment_from_save(player_data)
	if WarehouseService.get_item_by_uid(inventory, _selected_weapon_uid).is_empty():
		_selected_weapon_uid = WarehouseService.get_equipped_uid(inventory, "weapon", operator_id)
	_status_label.text = message
	_refresh()


func _select_item(item_uid: String, status_text: String) -> void:
	_selected_uid = item_uid
	var item_data := _item_data(WarehouseService.get_item_by_uid(inventory, item_uid))
	if str(item_data.get("type", "")) == "WEAPON":
		_selected_weapon_uid = item_uid
		_attachment_target_slot = ""
	_status_label.text = status_text
	_refresh()


func _on_drag_started(data: Dictionary) -> void:
	_active_drag_data = data.duplicate(true)
	_last_backpack_drag_target = -1
	_last_temporary_drag_target = -1
	_update_drag_target_highlights()


func _on_drag_ended() -> void:
	_active_drag_data.clear()
	_set_backpack_drag_target(-1)
	_set_temporary_drag_target(-1)
	_update_drag_target_highlights()


func _update_drag_target_highlights() -> void:
	for equipment_slot in _equipment_slot_nodes:
		if is_instance_valid(equipment_slot):
			equipment_slot.set_drop_highlight(not _active_drag_data.is_empty() and equipment_slot.can_accept_data(_active_drag_data))
	for attachment_slot in _attachment_slot_nodes:
		if is_instance_valid(attachment_slot):
			attachment_slot.set_drop_highlight(not _active_drag_data.is_empty() and attachment_slot.can_accept_data(_active_drag_data))


func _on_backpack_drop_hovered(position: int) -> void:
	if not _active_drag_data.is_empty():
		_set_backpack_drag_target(position)


func _on_backpack_drop_unhovered(position: int) -> void:
	if position < 0 or position != _last_backpack_drag_target:
		return


func _on_temporary_drop_hovered(position: int) -> void:
	if not _active_drag_data.is_empty():
		_set_temporary_drag_target(position)


func _on_temporary_drop_unhovered(position: int) -> void:
	if position < 0 or position != _last_temporary_drag_target:
		return


func _set_backpack_drag_target(target_position: int) -> void:
	if target_position == _last_backpack_drag_target:
		return
	if _last_backpack_drag_target >= 0 and _last_backpack_drag_target < _backpack_slot_nodes.size():
		_backpack_slot_nodes[_last_backpack_drag_target].set_drop_highlight(false)
	_last_backpack_drag_target = target_position
	if target_position >= 0 and target_position < _backpack_slot_nodes.size():
		var target_slot: InventorySlot = _backpack_slot_nodes[target_position]
		target_slot.set_drop_highlight(not target_slot.is_occupied)


func _set_temporary_drag_target(target_position: int) -> void:
	if target_position == _last_temporary_drag_target:
		return
	if _last_temporary_drag_target >= 0 and _last_temporary_drag_target < _temporary_slot_nodes.size():
		_temporary_slot_nodes[_last_temporary_drag_target].set_drop_highlight(false)
	_last_temporary_drag_target = target_position
	if target_position >= 0 and target_position < _temporary_slot_nodes.size():
		var target_slot: InventorySlot = _temporary_slot_nodes[target_position]
		target_slot.set_drop_highlight(not target_slot.is_occupied)


func _source_location(data: Dictionary) -> ItemLocation:
	if data.is_empty():
		return null
	match str(data.get("kind", "")):
		"backpack_item":
			return ItemLocation.backpack(str(data.get("source_backpack_uid", "")), int(data.get("source_backpack_position", -1)))
		"temporary_item":
			return ItemLocation.temporary(str(data.get("source_temporary_id", "")), int(data.get("source_temporary_position", -1)))
		"equipped_item":
			return ItemLocation.equipment(operator_id, str(data.get("source_slot", "")))
		"weapon_attachment":
			return ItemLocation.weapon_attachment(str(data.get("source_weapon_uid", "")), str(data.get("source_attachment_slot", "")))
		"inventory_item":
			return WarehouseService.get_item_location(inventory, str(data.get("uid", "")))
	return null


func _first_empty_backpack_position(backpack_uid: String) -> int:
	var size := WarehouseService.get_backpack_grid_size(inventory, backpack_uid)
	var items := WarehouseService.get_backpack_items(inventory, backpack_uid, operator_id)
	for position in size.x * size.y:
		if not items.has(position):
			return position
	return -1


func _first_empty_temporary_position() -> int:
	if _temporary_container_id.is_empty():
		return -1
	var items := WarehouseService.get_temporary_items(inventory, _temporary_container_id)
	for position in WarehouseService.get_temporary_capacity(inventory, _temporary_container_id):
		if not items.has(position):
			return position
	return -1


func _is_attachment(data: Dictionary) -> bool:
	return str(data.get("item_type", "")) == "WEAPON_ATTACHMENT"


func _item_data(item: Dictionary) -> Dictionary:
	var data: Variant = ItemDB.get_item(str(item.get("id", "")))
	return data as Dictionary if data is Dictionary else {}


func _slot_name(slot: String) -> String:
	return {"weapon": "武器", "helmet": "头盔", "armor": "护甲", "backpack": "背包"}.get(slot, slot)


func _get_hp_color(current_hp: int, max_hp: int) -> Color:
	var ratio := float(current_hp) / float(maxi(1, max_hp))
	if ratio <= 0.3:
		return Color(1.0, 0.32, 0.34, 1.0)
	if ratio <= 0.6:
		return Color(1.0, 0.78, 0.28, 1.0)
	return Color(0.5, 0.96, 0.63, 1.0)


func _clear_section(section: VBoxContainer) -> void:
	for child in section.get_children():
		if child.name == "SectionTitle":
			continue
		section.remove_child(child)
		child.queue_free()


func _make_label(value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _make_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = border
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	return style
