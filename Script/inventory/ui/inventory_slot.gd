class_name InventorySlot
extends Button

signal slot_activated(position_index: int, item_uid: String)
signal item_dropped(data: Dictionary, target_uid: String, target_position: int)
signal item_double_clicked(item_uid: String)
signal item_right_clicked(item_uid: String, screen_position: Vector2)
signal drag_started(data: Dictionary)
signal drag_ended
signal drop_hovered(position_index: int)
signal drop_unhovered(position_index: int)

var position_index: int = -1
var item_uid: String = ""
var drag_enabled := true
var item_data: Dictionary = {}
var is_selected := false
var is_occupied := false
var drop_highlighted := false
var _style_cache: Dictionary = {}
var _drag_data_overrides: Dictionary = {}
var _armor_status_dot: Panel


func configure(p_position_index: int, item: Dictionary, selected: bool, p_drag_enabled: bool = true, p_drag_data_overrides: Dictionary = {}) -> void:
	position_index = p_position_index
	item_uid = str(item.get("uid", ""))
	drag_enabled = p_drag_enabled
	_drag_data_overrides = p_drag_data_overrides.duplicate(true)
	item_data = {}
	is_occupied = not item.is_empty()
	is_selected = selected and is_occupied
	custom_minimum_size = Vector2(54, 54)
	tooltip_text = ""
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 10)
	add_theme_color_override("font_color", Color(0.88, 0.96, 1.0, 1.0))
	_ensure_armor_status_dot()
	_update_armor_status_dot(item)
	_refresh_style()
	if item.is_empty():
		text = ""
		icon = null
		return
	var loaded_item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	if not (loaded_item_data is Dictionary):
		text = "?"
		icon = null
		return
	item_data = loaded_item_data as Dictionary
	text = "L%d" % WarehouseService.get_merge_level(item_data)
	var icon_path := str(item_data.get("icon", ""))
	icon = load(icon_path) if not icon_path.is_empty() else null
	expand_icon = true
	tooltip_text = str(item_data.get("name", "未知物品"))


func _ready() -> void:
	pressed.connect(func() -> void: slot_activated.emit(position_index, item_uid))
	gui_input.connect(_on_gui_input)
	mouse_exited.connect(func() -> void: drop_unhovered.emit(position_index))


func _ensure_armor_status_dot() -> void:
	if is_instance_valid(_armor_status_dot):
		return
	_armor_status_dot = Panel.new()
	_armor_status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_armor_status_dot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_armor_status_dot.offset_left = -13.0
	_armor_status_dot.offset_top = -13.0
	_armor_status_dot.offset_right = -3.0
	_armor_status_dot.offset_bottom = -3.0
	add_child(_armor_status_dot)


func _update_armor_status_dot(item: Dictionary) -> void:
	var armor_state := WarehouseService.get_armor_state(item)
	var max_armor := int(armor_state.get("max_armor", 0))
	_armor_status_dot.visible = bool(armor_state.get("tracks_armor", false)) and max_armor > 0
	if not _armor_status_dot.visible:
		return
	var color := Color(0.4, 0.92, 0.56, 1.0) if not bool(armor_state.get("is_damaged", false)) else Color(0.92, 0.76, 0.39, 1.0)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.02, 0.06, 0.09, 0.95)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	_armor_status_dot.add_theme_stylebox_override("panel", style)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_uid.is_empty() or not drag_enabled:
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(48, 48)
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	var data := _build_drag_data()
	drag_started.emit(data)
	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var source_kind := str(data.get("kind", ""))
	var accepted := source_kind in ["inventory_item", "equipped_item", "weapon_attachment", "backpack_item", "temporary_item"]
	if accepted:
		drop_hovered.emit(position_index)
	return accepted


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data, item_uid, position_index)


func set_drop_highlight(enabled: bool) -> void:
	drop_highlighted = enabled
	_refresh_style()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _build_drag_data() -> Dictionary:
	var data := {
		"kind": "inventory_item",
		"uid": item_uid,
		"item_type": str(item_data.get("type", "")),
		"attachment_slot": str(item_data.get("slot", "")),
		"compatible_weapon_ids": item_data.get("compatible_weapon_ids", []),
	}
	for key in _drag_data_overrides:
		data[key] = _drag_data_overrides[key]
	return data


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click and not item_uid.is_empty():
		item_double_clicked.emit(item_uid)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed and not item_uid.is_empty():
		accept_event()
		item_right_clicked.emit(item_uid, get_viewport().get_mouse_position())


func _refresh_style() -> void:
	add_theme_stylebox_override("normal", _get_style(is_selected or drop_highlighted, false, is_occupied))
	add_theme_stylebox_override("hover", _get_style(is_selected or drop_highlighted, true, is_occupied))
	add_theme_stylebox_override("pressed", _get_style(is_selected or drop_highlighted, true, is_occupied))


func _get_style(selected: bool, hovered: bool, occupied: bool) -> StyleBoxFlat:
	var key := "%s_%s_%s" % [selected, hovered, occupied]
	if not _style_cache.has(key):
		_style_cache[key] = _make_style(selected, hovered, occupied)
	return _style_cache[key]


func _make_style(selected: bool, hovered: bool, occupied: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if not occupied:
		style.bg_color = Color(0.035, 0.09, 0.13, 0.78)
		var border_width := 2 if selected else (1 if hovered else 0)
		style.border_width_left = border_width
		style.border_width_top = border_width
		style.border_width_right = border_width
		style.border_width_bottom = border_width
		style.border_color = Color(0.36, 0.88, 1.0, 1.0) if selected else Color(0.2, 0.48, 0.63, 0.85)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		return style
	style.bg_color = Color(0.055, 0.12, 0.17, 0.98) if not hovered else Color(0.07, 0.2, 0.27, 1.0)
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = Color(0.32, 0.9, 1.0, 1.0) if selected else Color(0.2, 0.46, 0.58, 0.8)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	return style
