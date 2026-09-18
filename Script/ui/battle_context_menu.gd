class_name BattleContextMenu
extends PopupPanel

signal attack_requested
signal search_requested
signal end_turn_requested
signal properties_requested

var _attack_button: Button
var _cost_label: Label
var _search_button: Button
var _search_cost_label: Label

const BASE_MIN_SIZE := Vector2i(186, 186)
const MAX_WIDTH := 420
const COST_LABEL_WIDTH := 70
const CONTENT_PADDING := 34


func _ready() -> void:
	min_size = BASE_MIN_SIZE
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
	_search_button = Button.new()
	_search_button.custom_minimum_size = Vector2(0, 38)
	_search_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_search_button.pressed.connect(func() -> void:
		search_requested.emit()
		hide()
	)
	content.add_child(_search_button)
	_search_cost_label = Label.new()
	_search_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_search_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_search_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_search_cost_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	_search_cost_label.offset_left = -70.0
	_search_cost_label.offset_right = -8.0
	_search_button.add_child(_search_cost_label)
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


func show_actions(
	attack_cost: int,
	attack_enabled: bool,
	attack_reason: String,
	has_search_target: bool,
	search_label: String,
	search_cost: int,
	search_enabled: bool,
	search_reason: String,
	screen_position: Vector2i
) -> void:
	_attack_button.disabled = not attack_enabled
	_attack_button.tooltip_text = attack_reason if not attack_enabled else ""
	_cost_label.text = "%d AP" % attack_cost
	_cost_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.3, 1.0) if not attack_enabled else Color(0.42, 0.94, 0.72, 1.0))
	_search_button.visible = has_search_target
	_search_button.text = search_label
	_search_button.disabled = not search_enabled
	_search_button.tooltip_text = search_reason if not search_enabled else ""
	_search_cost_label.text = "%d AP" % maxi(0, search_cost)
	_search_cost_label.add_theme_color_override("font_color", Color(1.0, 0.28, 0.3, 1.0) if not search_enabled else Color(0.42, 0.94, 0.72, 1.0))
	var width := BASE_MIN_SIZE.x
	if has_search_target:
		width = _required_width(search_label)
	min_size = Vector2i(width, BASE_MIN_SIZE.y)
	position = screen_position
	popup()


# 按搜索项文案撑开菜单，避免“搜索…（同格 N 个）”被截断
func _required_width(text: String) -> int:
	var font := get_theme_font("font", "Button")
	var font_size := get_theme_font_size("font_size", "Button")
	var text_width := maxi(
		int(font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x),
		_estimate_text_width(text, font_size)
	)
	return clampi(text_width + COST_LABEL_WIDTH + CONTENT_PADDING, BASE_MIN_SIZE.x, MAX_WIDTH)


# 字体缺失或无字形的中日韩字符会被量成 0 宽，用字符数兜底估算
func _estimate_text_width(text: String, font_size: int) -> int:
	var width := 0.0
	for character in text:
		width += float(font_size) if character.unicode_at(0) >= 0x2E80 else float(font_size) * 0.55
	return int(width)


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
