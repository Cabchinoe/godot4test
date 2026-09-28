class_name BattleStatusBar
extends Control

signal end_turn_pressed
signal force_evacuation_pressed

@export var show_protection := true
@export var show_turn := true
@export var show_force_evacuation_button := false

@onready var ap_label: Label = $APLabel
@onready var hp_label: Label = $HPLabel
@onready var turn_label: Label = $TurnLabel
@onready var end_turn_button: Button = $EndTurnButton
@onready var force_evacuation_button: Button = $ForceEvacuationButton

const PROTECTION_SLOTS: Array[Dictionary] = [
	{"slot": "helmet", "title": "头盔", "label": NodePath("HelmetLabel")},
	{"slot": "armor", "title": "护甲", "label": NodePath("ArmorLabel")},
]

var _unit: Unit
var _turn_controller: TurnController
var _protection_labels: Array[Dictionary] = []


func _ready() -> void:
	for entry in PROTECTION_SLOTS:
		var slot_label := get_node_or_null(entry["label"]) as Label
		if slot_label:
			_protection_labels.append({
				"slot": str(entry["slot"]),
				"title": str(entry["title"]),
				"label": slot_label,
			})
	_configure_fonts()
	force_evacuation_button.visible = show_force_evacuation_button
	end_turn_button.pressed.connect(func() -> void: end_turn_pressed.emit())
	force_evacuation_button.pressed.connect(func() -> void: force_evacuation_pressed.emit())


func bind(unit: Unit, turn_controller: TurnController) -> void:
	unbind()
	_unit = unit
	_turn_controller = turn_controller
	if _unit:
		if _unit.has_signal("profile_changed"):
			_unit.connect("profile_changed", refresh)
		_unit.damaged.connect(_on_unit_damaged)
	if _turn_controller:
		_turn_controller.turn_started.connect(_on_turn_started)
	refresh()


func unbind() -> void:
	if _unit:
		if _unit.has_signal("profile_changed") and _unit.is_connected("profile_changed", refresh):
			_unit.disconnect("profile_changed", refresh)
		if _unit.damaged.is_connected(_on_unit_damaged):
			_unit.damaged.disconnect(_on_unit_damaged)
	if _turn_controller and _turn_controller.turn_started.is_connected(_on_turn_started):
		_turn_controller.turn_started.disconnect(_on_turn_started)
	_unit = null
	_turn_controller = null


func refresh() -> void:
	_refresh_unit_stats()
	_refresh_turn()
	_refresh_protection()


func set_actions_enabled(enabled: bool) -> void:
	end_turn_button.disabled = not enabled
	force_evacuation_button.disabled = not enabled


func _on_unit_damaged(_result: Dictionary) -> void:
	refresh()


func _on_turn_started(_turn: int) -> void:
	refresh()


func _refresh_unit_stats() -> void:
	if _unit == null:
		return
	ap_label.text = "AP  %d / %d" % [_unit.action_points, _unit.ap_max]
	hp_label.text = "HP  %d / %d" % [_unit.current_hp, _unit.max_hp]
	hp_label.add_theme_color_override("font_color", _get_ratio_color(_unit.current_hp, _unit.max_hp))


func _refresh_turn() -> void:
	turn_label.visible = show_turn and _turn_controller != null
	if _turn_controller:
		turn_label.text = "回合 %d/%d" % [_turn_controller.current_turn, _turn_controller.max_turns]


func _refresh_protection() -> void:
	var protection := {}
	if show_protection and _unit != null and _unit.has_method("get_protection_status"):
		protection = _unit.get_protection_status()
	for entry in _protection_labels:
		_apply_protection_label(entry["label"], protection.get(entry["slot"], {}), entry["title"])


func _apply_protection_label(label: Label, data: Variant, title: String) -> void:
	if not show_protection or not (data is Dictionary) or not bool((data as Dictionary).get("equipped", false)):
		label.visible = false
		return
	var current_armor := int((data as Dictionary).get("current_armor", 0))
	var max_armor := int((data as Dictionary).get("max_armor", 0))
	label.visible = true
	label.text = "%s  %d / %d" % [title, current_armor, max_armor]
	label.add_theme_color_override("font_color", _get_ratio_color(current_armor, max_armor))


func _get_ratio_color(current: int, maximum: int) -> Color:
	var ratio := float(current) / float(maxi(1, maximum))
	if ratio <= 0.3:
		return Color(1.0, 0.32, 0.34, 1.0)
	if ratio <= 0.6:
		return Color(1.0, 0.78, 0.28, 1.0)
	return Color(0.5, 0.96, 0.63, 1.0)


func _configure_fonts() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC", "Hiragino Sans GB", "Arial"])
	var labels: Array[Label] = [ap_label, hp_label, turn_label]
	for entry in _protection_labels:
		labels.append(entry["label"])
	for label in labels:
		label.add_theme_font_override("font", font)
	ap_label.add_theme_font_size_override("font_size", 24)
	ap_label.add_theme_color_override("font_color", Color(0.36, 0.93, 1.0, 1.0))
	hp_label.add_theme_font_size_override("font_size", 18)
	hp_label.add_theme_color_override("font_color", Color(0.5, 0.96, 0.63, 1.0))
	for entry in _protection_labels:
		(entry["label"] as Label).add_theme_font_size_override("font_size", 18)
	turn_label.add_theme_font_size_override("font_size", 24)
	turn_label.add_theme_color_override("font_color", Color(0.92, 0.76, 0.39, 1.0))
