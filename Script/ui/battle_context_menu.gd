class_name BattleContextMenu
extends PopupPanel

signal attack_requested
signal end_turn_requested
signal properties_requested

var _attack_button: Button
var _cost_label: Label


func _ready() -> void:
	min_size = Vector2i(186, 143)
	add_theme_stylebox_override("panel", _make_style())
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 5)
	add_child(content)
	_attack_button = Button.new()
	_attack_button.custom_minimum_size = Vector2(0, 38)
	_attack_button.text = "攻击"
	_attack_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_attack_button.pressed.connect(func() -> void:
		hide()
		attack_requested.emit()
	)
	content.add_child(_attack_button)
	_cost_label = Label.new()
	_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cost_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_cost_label.offset_left = -70.0
	_cost_label.offset_right = -8.0
	_attack_button.add_child(_cost_label)
	var end_turn_button := Button.new()
	end_turn_button.custom_minimum_size = Vector2(0, 38)
	end_turn_button.text = "结束回合"
	end_turn_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	end_turn_button.pressed.connect(func() -> void:
		hide()
		end_turn_requested.emit()
	)
	content.add_child(end_turn_button)
	var properties_button := Button.new()
	properties_button.custom_minimum_size = Vector2(0, 38)
	properties_button.text = "属性"
	properties_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	properties_button.pressed.connect(func() -> void:
		hide()
		properties_requested.emit()
	)
	content.add_child(properties_button)


func show_actions(attack_cost: int, has_enough_ap: bool, screen_position: Vector2i) -> void:
	_attack_button.disabled = not has_enough_ap
	_attack_button.tooltip_text = "行动点不足" if not has_enough_ap else ""
	_cost_label.text = "%d AP" % attack_cost
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.3, 1.0) if not has_enough_ap else Color(0.42, 0.94, 0.72, 1.0))
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
