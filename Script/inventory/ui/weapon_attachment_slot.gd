class_name WeaponAttachmentSlot
extends Button

signal slot_activated(attachment_slot: String, attachment_uid: String)
signal item_dropped(attachment_slot: String, data: Dictionary)
signal item_double_clicked(attachment_slot: String)
signal drag_started(data: Dictionary)
signal drag_ended

var attachment_slot := ""
var attachment_uid := ""
var weapon_uid := ""
var weapon_id := ""
var item_data: Dictionary = {}
var is_selected := false
var drop_highlighted := false


func configure(p_attachment_slot: String, p_attachment_uid: String, p_weapon_uid: String, p_weapon_id: String, p_item_data: Dictionary, selected: bool) -> void:
	attachment_slot = p_attachment_slot
	attachment_uid = p_attachment_uid
	weapon_uid = p_weapon_uid
	weapon_id = p_weapon_id
	item_data = p_item_data.duplicate(true)
	is_selected = selected
	custom_minimum_size = Vector2(0, 72)
	text = "%s\n%s\n%s" % [_get_slot_label(), str(item_data.get("name", "空接口")), _get_effect_text()]
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	expand_icon = true
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_font_size_override("font_size", 13)
	add_theme_color_override("font_color", Color(0.86, 0.96, 1.0, 1.0))
	var icon_path := str(item_data.get("icon", ""))
	icon = load(icon_path) if not icon_path.is_empty() else null
	_refresh_style()


func _ready() -> void:
	pressed.connect(func() -> void: slot_activated.emit(attachment_slot, attachment_uid))
	gui_input.connect(_on_gui_input)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if attachment_uid.is_empty():
		return null
	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(50, 50)
	preview.texture = icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	var data := {
		"kind": "weapon_attachment",
		"uid": attachment_uid,
		"source_weapon_uid": weapon_uid,
		"source_attachment_slot": attachment_slot,
		"item_type": "WEAPON_ATTACHMENT",
		"attachment_slot": attachment_slot,
		"compatible_weapon_ids": item_data.get("compatible_weapon_ids", []),
	}
	drag_started.emit(data)
	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return can_accept_data(data)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	item_dropped.emit(attachment_slot, data)


func set_drop_highlight(enabled: bool) -> void:
	drop_highlighted = enabled
	_refresh_style()


func can_accept_data(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	var source_kind := str(data.get("kind", ""))
	if source_kind not in ["inventory_item", "weapon_attachment", "backpack_item", "temporary_item"]:
		return false
	if str(data.get("item_type", "")) != "WEAPON_ATTACHMENT" or str(data.get("attachment_slot", "")) != attachment_slot:
		return false
	return (data.get("compatible_weapon_ids", []) as Array).has(weapon_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		drag_ended.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.double_click and not attachment_uid.is_empty():
		item_double_clicked.emit(attachment_slot)


func _refresh_style() -> void:
	add_theme_stylebox_override("normal", _make_style(is_selected or drop_highlighted, false))
	add_theme_stylebox_override("hover", _make_style(is_selected or drop_highlighted, true))
	add_theme_stylebox_override("pressed", _make_style(is_selected or drop_highlighted, true))


func _get_slot_label() -> String:
	return {"SCOPE": "瞄具", "BARREL": "枪口", "STOCK": "枪托", "RESONANCE_CORE": "共鸣核心"}.get(attachment_slot, attachment_slot)


func _get_effect_text() -> String:
	if item_data.is_empty():
		return "可拖入兼容配件"
	var modifiers: Dictionary = item_data.get("stat_modifiers", {})
	var effects: Array[String] = []
	for modifier in modifiers:
		effects.append("%s +%s" % [_get_modifier_name(str(modifier)), str(modifiers[modifier])])
	if not effects.is_empty():
		return "  ·  ".join(effects)
	return str(item_data.get("special_effect", "无额外数值效果"))


func _get_modifier_name(modifier: String) -> String:
	return {
		"accuracy": "命中率",
		"attack_range": "攻击距离",
		"attack_power": "攻击力",
	}.get(modifier, modifier)


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
