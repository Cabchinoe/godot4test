class_name UnitStatusWidget
extends PanelContainer

const HIDDEN_RATIO := "??? / ???"
const HIDDEN_VALUE := "???"
const PANEL_OFFSET := Vector2(36.0, -92.0)
const SCREEN_MARGIN := 8.0
const ROW_DEFS: Array[Array] = [
	["hp", "生命"],
	["head_armor", "头甲"],
	["body_armor", "身甲"],
	["ap", "AP"],
]

@onready var _name_label: Label = $Content/Header/NameLabel
@onready var _close_button: Button = $Content/Header/CloseButton
@onready var _rows_container: VBoxContainer = $Content/Rows

var _unit: Unit
var _intel: UnitIntelTracker
var _rows: Dictionary = {}
var _read_only := false


static func mount(parent: Control) -> UnitStatusWidget:
	var widget: UnitStatusWidget = preload("res://HUD/unit_status_widget.tscn").instantiate()
	parent.add_child(widget)
	return widget


func _ready() -> void:
	theme = BattleHudTheme.get_theme()
	_close_button.add_theme_font_size_override("font_size", 14)
	_close_button.pressed.connect(hide_panel)
	for row_def in ROW_DEFS:
		_rows[row_def[0]] = _make_row(str(row_def[1]))


func set_intel_tracker(tracker: UnitIntelTracker) -> void:
	if _intel and _intel.intel_changed.is_connected(_on_intel_changed):
		_intel.intel_changed.disconnect(_on_intel_changed)
	_intel = tracker
	if _intel:
		_intel.intel_changed.connect(_on_intel_changed)


func show_for(unit: Unit) -> void:
	if unit == null or not is_instance_valid(unit):
		hide_panel()
		return
	if _unit == unit and visible:
		refresh()
		return
	_detach_unit()
	_unit = unit
	_unit.damaged.connect(_on_unit_damaged)
	_unit.defeated.connect(_on_unit_defeated)
	visible = true
	refresh()


func set_read_only(value: bool) -> void:
	_read_only = value
	_close_button.visible = not _read_only


func hide_panel() -> void:
	_detach_unit()
	_unit = null
	visible = false


func refresh() -> void:
	if _unit == null or not is_instance_valid(_unit):
		hide_panel()
		return
	_name_label.text = _unit.unit_name
	var revealed := _intel == null or _intel.is_revealed(_unit)
	var protection := _get_protection_data()
	_rows["hp"].text = ("%d / %d" % [_unit.current_hp, _unit.max_hp]) if revealed else HIDDEN_RATIO
	_rows["head_armor"].text = _armor_text("helmet", _unit.head_armor, protection, revealed)
	_rows["body_armor"].text = _armor_text("armor", _unit.body_armor, protection, revealed)
	_rows["ap"].text = str(_unit.ap_max)


func _process(_delta: float) -> void:
	if not visible or _unit == null or not is_instance_valid(_unit):
		return
	var viewport := get_viewport()
	var screen_pos: Vector2 = viewport.get_canvas_transform() * _unit.global_position
	var viewport_size := viewport.get_visible_rect().size
	var target := screen_pos + PANEL_OFFSET
	target.x = clampf(target.x, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.x - size.x - SCREEN_MARGIN))
	target.y = clampf(target.y, SCREEN_MARGIN, maxf(SCREEN_MARGIN, viewport_size.y - size.y - SCREEN_MARGIN))
	global_position = target


func _make_row(title: String) -> Label:
	var row := HBoxContainer.new()
	var title_label := Label.new()
	title_label.text = title
	title_label.custom_minimum_size = Vector2(56, 0)
	title_label.add_theme_color_override("font_color", Color(0.62, 0.72, 0.85, 1.0))
	var value_label := Label.new()
	value_label.set_theme_type_variation(&"BattleStatLabel")
	row.add_child(title_label)
	row.add_child(value_label)
	_rows_container.add_child(row)
	return value_label


func _get_protection_data() -> Dictionary:
	if _unit.has_method("get_protection_status"):
		return _unit.get_protection_status()
	return {}


func _armor_text(slot: String, current_armor: int, protection: Dictionary, revealed: bool) -> String:
	var slot_data: Variant = protection.get(slot, {})
	if slot_data is Dictionary and not (slot_data as Dictionary).is_empty():
		if not bool((slot_data as Dictionary).get("equipped", false)):
			return "—"
		return "%d / %d" % [
			int((slot_data as Dictionary).get("current_armor", 0)),
			int((slot_data as Dictionary).get("max_armor", 0)),
		]
	if not revealed:
		return HIDDEN_VALUE
	return str(current_armor)


func _detach_unit() -> void:
	if _unit == null or not is_instance_valid(_unit):
		return
	if _unit.damaged.is_connected(_on_unit_damaged):
		_unit.damaged.disconnect(_on_unit_damaged)
	if _unit.defeated.is_connected(_on_unit_defeated):
		_unit.defeated.disconnect(_on_unit_defeated)


func _on_unit_damaged(_result: Dictionary) -> void:
	refresh()


func _on_unit_defeated(_unit_param: Unit) -> void:
	hide_panel()


func _on_intel_changed(unit: Unit) -> void:
	if unit == _unit:
		refresh()
