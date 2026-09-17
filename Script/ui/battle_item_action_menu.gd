class_name BattleItemActionMenu
extends PopupPanel

signal use_requested

var _title: Label
var _use_button: Button
var _cost_label: Label


func _ready() -> void:
	min_size = Vector2i(216, 94)
	add_theme_stylebox_override("panel", _make_style())
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	add_child(content)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color(0.76, 0.92, 1.0, 1.0))
	content.add_child(_title)
	_use_button = Button.new()
	_use_button.custom_minimum_size = Vector2(0, 38)
	_use_button.text = "使用"
	_use_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_use_button.pressed.connect(func() -> void:
		hide()
		use_requested.emit()
	)
	content.add_child(_use_button)
	_cost_label = Label.new()
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_cost_label.offset_left = -74.0
	_cost_label.offset_right = -8.0
	_use_button.add_child(_cost_label)


func show_use(item_name: String, ap_cost: int, enabled: bool, reason: String, screen_position: Vector2i) -> void:
	_title.text = item_name
	_use_button.disabled = not enabled
	_use_button.tooltip_text = reason if not enabled else ""
	_cost_label.text = "%d AP" % ap_cost
	_cost_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.28, 0.3, 1.0) if not enabled else Color(0.42, 0.94, 0.72, 1.0)
	)
	position = screen_position
	popup()


func _make_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.065, 0.1, 0.98)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.24, 0.66, 0.84, 0.96)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 7
	style.content_margin_top = 7
	style.content_margin_right = 7
	style.content_margin_bottom = 7
	return style
