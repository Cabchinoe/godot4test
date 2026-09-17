class_name OperatorEquipmentSlot
extends Button

signal slot_activated(slot_name: String, item_uid: String)
signal item_dropped(slot_name: String, data: Dictionary)
signal item_double_clicked(slot_name: String)
signal drag_started(data: Dictionary)
signal drag_ended

var slot_name := ""
var item_uid := ""
var item_data: Dictionary = {}
var is_selected := false
var drop_highlighted := false
var _armor_status_dot: Panel


func configure(p_slot_name: String, p_item_uid: String, item_data: Dictionary, selected: bool, item_instance: Dictionary = {}) -> void:
	slot_name = p_slot_name
	item_uid = p_item_uid
	self.item_data = item_data.duplicate(true)
	is_selected = selected
	custom_minimum_size = Vector2(0, 62)
	text = "%s\n%s" % [_get_slot_label(), str(self.item_data.get("name", "未装备"))]
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 14)
	add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	var icon_path := str(self.item_data.get("icon", ""))
	icon = load(icon_path) if not icon_path.is_empty() else null
	_ensure_armor_status_dot()
	_update_armor_status_dot(item_instance)
	_refresh_style()


func _ready() -> void:
	pressed.connect(func() -> void: slot_activated.emit(slot_name, item_uid))
	gui_input.connect(_on_gui_input)


func _ensure_armor_status_dot() -> void:
	if is_instance_valid(_armor_status_dot):
		return
	_armor_status_dot = Panel.new()
	_armor_status_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_armor_status_dot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_armor_status_dot.offset_left = -17.0
	_armor_status_dot.offset_top = -17.0
	_armor_status_dot.offset_right = -5.0
	_armor_status_dot.offset_bottom = -5.0
	add_child(_armor_status_dot)


func _update_armor_status_dot(item_instance: Dictionary) -> void:
	var armor_state := WarehouseService.get_armor_state(item_instance)
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
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	_armor_status_dot.add_theme_stylebox_override("panel", style)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return can_accept_data(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(slot_name, data)


func set_drop_highlight(enabled: bool) -> void:
	drop_highlighted = enabled
	_refresh_style()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item_uid.is_empty():
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(54, 54)
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	var data := {
		"kind": "equipped_item",
		"uid": item_uid,
		"source_slot": slot_name,
		"item_type": str(item_data.get("type", "")),
		"weapon_id": str(item_data.get("id", "")),
	}
	drag_started.emit(data)
	return data


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click and not item_uid.is_empty():
		item_double_clicked.emit(slot_name)


func can_accept_data(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var source_kind := str(data.get("kind", ""))
	var item_type := str(data.get("item_type", ""))
	if slot_name == "weapon":
		if source_kind == "inventory_item" or source_kind == "temporary_item":
			return item_type == "WEAPON" or (item_type == "WEAPON_ATTACHMENT" and not item_uid.is_empty())
		if source_kind == "backpack_item":
			return item_type == "WEAPON" or (item_type == "WEAPON_ATTACHMENT" and not item_uid.is_empty())
		return source_kind == "weapon_attachment" and not item_uid.is_empty()
	return source_kind in ["inventory_item", "backpack_item", "temporary_item"] and item_type == {"helmet": "HELMET", "armor": "ARMOR", "backpack": "BACKPACK"}.get(slot_name, "")


func _refresh_style() -> void:
	add_theme_stylebox_override("normal", _make_style(is_selected or drop_highlighted, false))
	add_theme_stylebox_override("hover", _make_style(is_selected or drop_highlighted, true))
	add_theme_stylebox_override("pressed", _make_style(is_selected or drop_highlighted, true))


func _get_slot_label() -> String:
	return {"weapon": "武器", "helmet": "头盔", "armor": "护甲", "backpack": "背包"}.get(slot_name, slot_name)


func _make_style(selected: bool, hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.065, 0.21, 0.29, 1.0) if hovered else Color(0.04, 0.13, 0.19, 1.0)
	style.border_width_left = 2 if selected else 1
	style.border_width_top = 2 if selected else 1
	style.border_width_right = 2 if selected else 1
	style.border_width_bottom = 2 if selected else 1
	style.border_color = Color(0.36, 0.88, 1.0, 1.0) if selected else Color(0.2, 0.48, 0.63, 0.85)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	return style
