class_name BattleHudTheme

const THEME_PATH := "res://conf/themes/battle_hud.tres"

static var _cached: Theme


static func get_theme() -> Theme:
	if _cached != null:
		return _cached
	if ResourceLoader.exists(THEME_PATH):
		_cached = load(THEME_PATH) as Theme
	if _cached == null:
		_cached = build()
	return _cached


static func build() -> Theme:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["PingFang SC", "Hiragino Sans GB", "Arial"])
	theme.default_font = font
	theme.default_font_size = 18

	theme.set_type_variation("BattleStatLabel", "Label")
	theme.set_font_size("font_size", "BattleStatLabel", 18)

	theme.set_type_variation("BattleApLabel", "Label")
	theme.set_font_size("font_size", "BattleApLabel", 24)
	theme.set_color("font_color", "BattleApLabel", Color(0.36, 0.93, 1.0, 1.0))

	theme.set_type_variation("BattleTurnLabel", "Label")
	theme.set_font_size("font_size", "BattleTurnLabel", 24)
	theme.set_color("font_color", "BattleTurnLabel", Color(0.92, 0.76, 0.39, 1.0))

	theme.set_type_variation("BattlePanel", "PanelContainer")
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.035, 0.075, 0.105, 0.94)
	panel_style.border_color = Color(0.36, 0.93, 1.0, 0.4)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(8)
	panel_style.set_content_margin_all(10)
	theme.set_stylebox("panel", "BattlePanel", panel_style)
	return theme


static func ratio_color(current: int, maximum: int) -> Color:
	var ratio := float(current) / float(maxi(1, maximum))
	if ratio <= 0.3:
		return Color(1.0, 0.32, 0.34, 1.0)
	if ratio <= 0.6:
		return Color(1.0, 0.78, 0.28, 1.0)
	return Color(0.5, 0.96, 0.63, 1.0)
