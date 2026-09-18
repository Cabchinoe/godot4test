class_name BattleContainerActionMenu
extends PopupPanel

signal search_requested

const BASE_MIN_SIZE := Vector2i(260, 94)
const LIST_MIN_WIDTH := 320
const LIST_MAX_WIDTH := 560
const COST_LABEL_WIDTH := 82
const CONTENT_PADDING := 34
const ROW_STEP := 42

var _title: Label
var _search_button: Button
var _cost_label: Label
var _list_content: VBoxContainer
var _selected_index: int = 0


func _ready() -> void:
	min_size = BASE_MIN_SIZE
	add_theme_stylebox_override("panel", _make_style())
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	add_child(content)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 14)
	_title.add_theme_color_override("font_color", Color(0.76, 0.92, 1.0, 1.0))
	content.add_child(_title)
	_search_button = Button.new()
	_search_button.custom_minimum_size = Vector2(0, 38)
	_search_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_search_button.pressed.connect(func() -> void:
		_selected_index = 0
		hide()
		search_requested.emit()
	)
	content.add_child(_search_button)
	_cost_label = _make_cost_label()
	_search_button.add_child(_cost_label)
	_list_content = VBoxContainer.new()
	_list_content.add_theme_constant_override("separation", 4)
	_list_content.visible = false
	content.add_child(_list_content)


func show_search(container_name: String, verb: String, ap_cost: int, enabled: bool, reason: String, screen_position: Vector2i) -> void:
	_clear_rows()
	_title.text = container_name
	_search_button.visible = true
	_search_button.text = verb
	_search_button.disabled = not enabled
	_search_button.tooltip_text = reason if not enabled else ""
	_apply_cost(_cost_label, ap_cost, enabled)
	_list_content.visible = false
	min_size = Vector2i(_required_width([container_name, verb], BASE_MIN_SIZE.x), BASE_MIN_SIZE.y)
	_selected_index = 0
	position = screen_position
	popup()


# 同格多个容器时使用：每行一个候选，行序即优先级序，第一行为默认目标
func show_search_list(title_text: String, entries: Array[Dictionary], screen_position: Vector2i) -> void:
	_clear_rows()
	_title.text = title_text
	_search_button.visible = false
	_list_content.visible = true
	for index in entries.size():
		_list_content.add_child(_make_row(index, entries[index]))
	var texts: Array = [title_text]
	for entry in entries:
		texts.append(_row_text(entry))
	min_size = Vector2i(
		_required_width(texts, LIST_MIN_WIDTH),
		BASE_MIN_SIZE.y + ROW_STEP * maxi(0, entries.size() - 1)
	)
	_selected_index = 0
	position = screen_position
	popup()


func get_selected_index() -> int:
	return _selected_index


func _make_row(index: int, entry: Dictionary) -> Button:
	var row := Button.new()
	row.custom_minimum_size = Vector2(0, 38)
	row.alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.text = _row_text(entry)
	var enabled := bool(entry.get("enabled", false))
	row.disabled = not enabled
	row.tooltip_text = str(entry.get("reason", "")) if not enabled else ""
	var cost_label := _make_cost_label()
	_apply_cost(cost_label, int(entry.get("ap_cost", 0)), enabled)
	row.add_child(cost_label)
	row.pressed.connect(func() -> void:
		_selected_index = index
		hide()
		search_requested.emit()
	)
	return row


func _make_cost_label() -> Label:
	var cost_label := Label.new()
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cost_label.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	cost_label.offset_left = -82.0
	cost_label.offset_right = -8.0
	return cost_label


func _apply_cost(cost_label: Label, ap_cost: int, enabled: bool) -> void:
	cost_label.text = "%d AP" % maxi(0, ap_cost)
	cost_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.28, 0.3, 1.0) if not enabled else Color(0.42, 0.94, 0.72, 1.0)
	)


func _row_text(entry: Dictionary) -> String:
	return "%s · %s" % [str(entry.get("name", "")), str(entry.get("verb", ""))]


# 按最宽一行文字撑开菜单，避免长名称被截断
func _required_width(texts: Array, floor_width: int) -> int:
	var font := get_theme_font("font", "Button")
	var font_size := get_theme_font_size("font_size", "Button")
	var width := maxi(floor_width, BASE_MIN_SIZE.x)
	for text in texts:
		var text_width := maxi(
			int(font.get_string_size(str(text), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x),
			_estimate_text_width(str(text), font_size)
		)
		width = maxi(width, text_width + COST_LABEL_WIDTH + CONTENT_PADDING)
	return mini(width, LIST_MAX_WIDTH)


# 字体缺失或无字形的中日韩字符会被量成 0 宽，用字符数兜底估算
func _estimate_text_width(text: String, font_size: int) -> int:
	var width := 0.0
	for character in text:
		width += float(font_size) if character.unicode_at(0) >= 0x2E80 else float(font_size) * 0.55
	return int(width)


func _clear_rows() -> void:
	for child in _list_content.get_children():
		_list_content.remove_child(child)
		child.queue_free()


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
	style.content_margin_bottom = 7
	style.content_margin_right = 7
	return style
