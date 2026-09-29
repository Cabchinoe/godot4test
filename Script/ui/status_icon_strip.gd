class_name StatusIconStrip
extends HBoxContainer

const ICONS := {
	"bleeding": preload("res://HUD/status_icons/bleeding.png"),
	"fractured": preload("res://HUD/status_icons/fractured.png"),
}

@export var icon_size := 28.0

var _badges: Dictionary = {}


func set_effects(effects: Array) -> void:
	var active_ids: Dictionary = {}
	for effect_variant in effects:
		var effect := effect_variant as BattleStatusEffect
		if effect == null or not ICONS.has(effect.effect_id):
			continue
		active_ids[effect.effect_id] = true
		var badge := _get_or_create_badge(effect.effect_id)
		var stacks := badge.get_node("Stacks") as Label
		stacks.text = "×%d" % effect.stack_count if effect.stack_count > 1 else ""
		badge.visible = true
	for effect_id in _badges:
		if not active_ids.has(effect_id):
			(_badges[effect_id] as Control).visible = false


func pulse(effect_id: String) -> void:
	var badge := _badges.get(effect_id) as Control
	if badge == null or not badge.visible:
		return
	badge.pivot_offset = badge.size * 0.5
	badge.scale = Vector2(0.68, 0.68)
	badge.modulate = Color(1.0, 0.78, 1.0, 1.0)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(badge, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(badge, "modulate", Color.WHITE, 0.22)


func _get_or_create_badge(effect_id: String) -> Control:
	if _badges.has(effect_id):
		return _badges[effect_id] as Control
	var badge := Control.new()
	badge.custom_minimum_size = Vector2(icon_size, icon_size)
	badge.size = Vector2(icon_size, icon_size)
	var icon := TextureRect.new()
	icon.texture = ICONS[effect_id] as Texture2D
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(icon)
	var stacks := Label.new()
	stacks.name = "Stacks"
	stacks.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	stacks.position = Vector2(-2, icon_size - 18)
	stacks.size = Vector2(icon_size + 2, 18)
	stacks.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stacks.add_theme_font_size_override("font_size", 13)
	stacks.add_theme_color_override("font_color", Color.WHITE)
	stacks.add_theme_color_override("font_outline_color", Color(0.08, 0.03, 0.12, 1.0))
	stacks.add_theme_constant_override("outline_size", 4)
	stacks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(stacks)
	add_child(badge)
	_badges[effect_id] = badge
	return badge
