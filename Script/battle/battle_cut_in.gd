class_name BattleCutIn
extends CanvasLayer

const PRESENTATION_CONFIG_PATH := "res://conf/battle/presentation.json"

@onready var _root: Control = $Root
@onready var _stage: Control = $Root/Stage
@onready var _attacker_portrait: TextureRect = $Root/Stage/AttackerPortrait
@onready var _defender_portrait: TextureRect = $Root/Stage/DefenderPortrait
@onready var _attacker_name: Label = $Root/Stage/AttackerPanel/Content/Name
@onready var _attacker_hp: ProgressBar = $Root/Stage/AttackerPanel/Content/Hp
@onready var _attacker_armor: Label = $Root/Stage/AttackerPanel/Content/Armor
@onready var _defender_name: Label = $Root/Stage/DefenderPanel/Content/Name
@onready var _defender_hp: ProgressBar = $Root/Stage/DefenderPanel/Content/Hp
@onready var _defender_armor: Label = $Root/Stage/DefenderPanel/Content/Armor
@onready var _damage_labels: Control = $Root/DamageLabels

var _config: Dictionary = {}
var _sfx: BattleSfx
var _attacker: Unit
var _defender: Unit
var _portrait_layouts: Dictionary = {}
var _stage_origin := Vector2.ZERO


func _ready() -> void:
	_config = _load_json(PRESENTATION_CONFIG_PATH)
	_sfx = BattleSfx.new(
		bool(_config.get("debug_sfx", false)),
		self,
		StringName(str(_config.get("audio_bus", "SFX")))
	)
	_root.visible = false
	_stage_origin = _stage.position
	_portrait_layouts = {
		_attacker_portrait: Rect2(_attacker_portrait.position, _attacker_portrait.size),
		_defender_portrait: Rect2(_defender_portrait.position, _defender_portrait.size),
	}
	_style_panel($Root/Stage/AttackerPanel, Color(0.08, 0.36, 0.46, 0.92), HORIZONTAL_ALIGNMENT_LEFT)
	_style_panel($Root/Stage/DefenderPanel, Color(0.48, 0.16, 0.12, 0.92), HORIZONTAL_ALIGNMENT_RIGHT)


func begin_session(attacker: Unit) -> void:
	_attacker = attacker
	_defender = null
	_clear_damage_labels()
	_set_unit_visuals(_attacker, _attacker_portrait, false)
	_refresh_attacker(true)
	_attacker_portrait.modulate.a = 1.0
	_defender_portrait.modulate.a = 0.0
	_root.modulate.a = 0.0
	_root.visible = true
	_sfx.play(&"battle_cutin_in", _sfx_context(&"battle_cutin_in"))
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_root, "modulate:a", 1.0, _seconds("session_in_seconds", 0.2))
	await tween.finished


func set_defender(defender: Unit) -> void:
	if defender == _defender:
		return
	_defender = defender
	_set_unit_visuals(_defender, _defender_portrait, true)
	_refresh_defender(true)
	var tween := create_tween()
	tween.tween_property(_defender_portrait, "modulate:a", 1.0, 0.12)
	await tween.finished


func play_attack_lead_in(_roll: Dictionary) -> void:
	_clear_damage_labels()
	await get_tree().create_timer(_seconds("lead_in_seconds", 0.32)).timeout
	_sfx.play(&"attack_fire", _sfx_context(&"attack_fire"))


func show_result(applied: Dictionary, instantly: bool = false) -> void:
	if _defender == null or not is_instance_valid(_defender):
		return
	_refresh_attacker(instantly)
	_refresh_defender(instantly)
	_show_result_labels(applied, instantly)
	if bool(applied.get("hit", false)):
		_shake(float(_config.get("shake_strength", 14.0)), instantly)
		if int(applied.get("absorbed", 0)) > 0:
			_sfx.play(&"hit_armor", _sfx_context(&"hit_armor"))
		elif int(applied.get("damage", 0)) > 0:
			_sfx.play(&"hit_flesh", _sfx_context(&"hit_flesh"))
		if bool(applied.get("defeated", false)):
			_sfx.play(&"unit_down", _sfx_context(&"unit_down"))
	else:
		_sfx.play(&"miss", _sfx_context(&"miss"))


func finish_round() -> void:
	await get_tree().create_timer(_seconds("result_hold_seconds", 0.62)).timeout


func end_session() -> void:
	if not _root.visible:
		return
	_sfx.play(&"battle_cutin_out", _sfx_context(&"battle_cutin_out"))
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_root, "modulate:a", 0.0, _seconds("session_out_seconds", 0.18))
	await tween.finished
	_stage.position = _stage_origin
	_clear_damage_labels()
	_root.visible = false
	_attacker = null
	_defender = null


func is_open() -> bool:
	return _root.visible


func _refresh_attacker(instantly: bool) -> void:
	_refresh_unit_panel(_attacker, _attacker_name, _attacker_hp, _attacker_armor, instantly)


func _refresh_defender(instantly: bool) -> void:
	_refresh_unit_panel(_defender, _defender_name, _defender_hp, _defender_armor, instantly)


func _refresh_unit_panel(unit: Unit, name_label: Label, hp_bar: ProgressBar, armor_label: Label, instantly: bool) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	name_label.text = "%s  HP %d / %d" % [unit.unit_name, unit.current_hp, unit.max_hp]
	hp_bar.max_value = maxi(1, unit.max_hp)
	var target_hp := float(unit.current_hp)
	if instantly:
		hp_bar.value = target_hp
	else:
		var tween := create_tween()
		tween.tween_property(hp_bar, "value", target_hp, _seconds("value_tween_seconds", 0.18))
	var armor_total := unit.head_armor + unit.body_armor
	armor_label.text = "护甲 %d" % armor_total
	armor_label.modulate = Color(0.55, 0.62, 0.72, 1.0) if armor_total > 0 else Color(0.42, 0.42, 0.46, 1.0)


func _set_unit_visuals(unit: Unit, portrait: TextureRect, is_defender: bool) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var texture := load(unit.cutin_art_path) as Texture2D if not unit.cutin_art_path.is_empty() else null
	if texture == null:
		push_warning("BattleCutIn: missing art for %s" % unit.cutin_art_key)
		return
	portrait.texture = texture
	var base_layout: Rect2 = _portrait_layouts.get(portrait, Rect2())
	var ratio := clampf(unit.cutin_art_height_ratio, 0.2, 1.0)
	var offset := unit.cutin_art_offset
	portrait.size = Vector2(base_layout.size.x, base_layout.size.y * ratio)
	portrait.position = base_layout.position + Vector2(offset.x, base_layout.size.y - portrait.size.y + offset.y)
	portrait.flip_h = unit.cutin_art_flip != is_defender


func _show_result_labels(applied: Dictionary, instantly: bool) -> void:
	var texts: Array[Dictionary] = []
	if not bool(applied.get("hit", false)):
		texts.append({"text": "MISS", "color": Color("9cb1c7")})
	else:
		var absorbed := int(applied.get("absorbed", 0))
		var damage := int(applied.get("damage", 0))
		if absorbed > 0:
			texts.append({"text": "护甲 -%d" % absorbed, "color": Color("7dc8ff")})
		if damage > 0:
			texts.append({"text": "-%d" % damage, "color": Color("ff525d")})
		for status_variant in applied.get("statuses", []):
			if status_variant is Dictionary:
				texts.append({"text": str((status_variant as Dictionary).get("name", "异常")), "color": Color("d18cff")})
	if bool(applied.get("defeated", false)):
		texts.append({"text": "击倒", "color": Color("ffb44c")})
	for index in texts.size():
		_show_label(texts[index], index, instantly)


func _show_label(data: Dictionary, index: int, instantly: bool) -> void:
	var label := Label.new()
	label.text = str(data.get("text", ""))
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", data.get("color", Color.WHITE) as Color)
	label.add_theme_constant_override("outline_size", 7)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05, 0.95))
	var viewport_size := get_viewport().get_visible_rect().size
	var x := viewport_size.x * 0.69
	label.position = Vector2(x, viewport_size.y * 0.45 + float(index) * 42.0)
	_damage_labels.add_child(label)
	if instantly:
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position", label.position + Vector2(0, -48), _seconds("damage_label_seconds", 0.55))
	tween.tween_property(label, "modulate:a", 0.0, _seconds("damage_label_seconds", 0.55))
	tween.finished.connect(label.queue_free)


func _shake(strength: float, instantly: bool) -> void:
	if instantly:
		_stage.position = _stage_origin
		return
	var duration := _seconds("shake_duration_seconds", 0.14)
	var tween := create_tween()
	tween.tween_property(_stage, "position", _stage_origin + Vector2(strength, -strength * 0.35), duration * 0.25)
	tween.tween_property(_stage, "position", _stage_origin + Vector2(-strength, strength * 0.35), duration * 0.5)
	tween.tween_property(_stage, "position", _stage_origin, duration * 0.25)


func _clear_damage_labels() -> void:
	for child in _damage_labels.get_children():
		child.queue_free()


func _style_panel(panel: PanelContainer, color: Color, alignment: HorizontalAlignment) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.74, 0.86, 0.96, 0.35)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	var content := panel.get_node("Content") as VBoxContainer
	for child in content.get_children():
		if child is Label:
			(child as Label).horizontal_alignment = alignment


func _sfx_context(cue: StringName = &"") -> Dictionary:
	var weapon_id := ""
	if _attacker and _attacker.has_method("get_equipped_item_id"):
		weapon_id = str(_attacker.get_equipped_item_id(&"weapon"))
	# 受击侧(hurt / hit / miss / unit_down)的"按角色绑"语义:被打的人是谁 → 谁就叫。
	# 把 defender 作为 victim 喂进 context,BattleSfx.resolve_binding 会用 victim.cutin_art_key
	# 查 units。开火/横幅类不传 victim,继续走 weapons / default。
	var ctx := {"attacker": _attacker, "defender": _defender, "weapon_id": weapon_id}
	if _is_victim_cue(cue):
		ctx["victim"] = _defender
	return ctx


func _is_victim_cue(cue: StringName) -> bool:
	var s := str(cue)
	return s == "hit_armor" or s == "hit_flesh" or s == "miss" or s == "unit_down" or s == "hurt"


func _seconds(key: String, fallback: float) -> float:
	return maxf(0.0, float(_config.get(key, fallback)))


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).duplicate(true) if parsed is Dictionary else {}
