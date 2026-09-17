class_name BattleDiscardZone
extends PanelContainer

signal discard_requested(data: Dictionary)

var _drag_active := false
var _hovering := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_TOP_RIGHT)
	anchor_left = 1.0
	anchor_right = 1.0
	offset_left = -108.0
	offset_right = 0.0
	offset_top = 0.0
	offset_bottom = get_viewport().get_visible_rect().size.y
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 12)
	add_child(content)
	var icon_label := Label.new()
	icon_label.text = "🗑"
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", 36)
	icon_label.add_theme_color_override("font_color", Color(0.56, 0.84, 0.94, 1.0))
	content.add_child(icon_label)
	var label := Label.new()
	label.text = "丢弃"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.78, 0.92, 1.0, 1.0))
	content.add_child(label)
	_refresh_style()


func set_drag_active(active: bool) -> void:
	_drag_active = active
	if not active:
		_hovering = false
	visible = active
	_refresh_style()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not _drag_active or not (data is Dictionary):
		return false
	var kind := str((data as Dictionary).get("kind", ""))
	_hovering = kind in ["inventory_item", "equipped_item", "weapon_attachment", "backpack_item", "temporary_item"]
	_refresh_style()
	return _hovering


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	_hovering = false
	_refresh_style()
	if data is Dictionary:
		discard_requested.emit((data as Dictionary).duplicate(true))


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_hovering = false
		_refresh_style()


func _refresh_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.04, 0.055, 0.96) if _hovering else Color(0.012, 0.055, 0.085, 0.96)
	style.border_width_left = 2
	style.border_color = Color(1.0, 0.25, 0.32, 1.0) if _hovering else Color(0.2, 0.6, 0.78, 0.92)
	style.content_margin_left = 8
	style.content_margin_right = 8
	add_theme_stylebox_override("panel", style)
