class_name ItemInfoPanel
extends PanelContainer

signal action_requested

const DETAIL_COLOR := Color(0.92, 0.76, 0.39, 1.0)
const INTACT_ARMOR_COLOR := Color(0.4, 0.92, 0.56, 1.0)

var _icon: TextureRect
var _title: Label
var _type_label: Label
var _description: Label
var _details: Label
var _action_button: Button


func _ready() -> void:
	custom_minimum_size = Vector2(310, 240)
	add_theme_stylebox_override("panel", _make_style())
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)
	_icon = TextureRect.new()
	_icon.custom_minimum_size = Vector2(68, 68)
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	top.add_child(_icon)
	var labels := VBoxContainer.new()
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(labels)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 21)
	_title.add_theme_color_override("font_color", Color(0.91, 0.98, 1.0, 1.0))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	labels.add_child(_title)
	_type_label = Label.new()
	_type_label.add_theme_font_size_override("font_size", 13)
	_type_label.add_theme_color_override("font_color", Color(0.43, 0.83, 0.98, 1.0))
	labels.add_child(_type_label)
	_description = Label.new()
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.add_theme_font_size_override("font_size", 14)
	_description.add_theme_color_override("font_color", Color(0.72, 0.82, 0.88, 1.0))
	content.add_child(_description)
	_details = Label.new()
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_theme_font_size_override("font_size", 14)
	_details.add_theme_color_override("font_color", DETAIL_COLOR)
	content.add_child(_details)
	_action_button = Button.new()
	_action_button.visible = false
	_action_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_action_button.pressed.connect(func() -> void: action_requested.emit())
	content.add_child(_action_button)
	show_empty()


func show_item(item_data: Dictionary, action_text: String = "", item_instance: Dictionary = {}) -> void:
	var icon_path := str(item_data.get("icon", ""))
	_icon.texture = load(icon_path) if not icon_path.is_empty() else null
	_title.text = str(item_data.get("name", "未知物品"))
	_type_label.text = "%s · 等级 L%d" % [ItemDB.VALID_TYPES.get(str(item_data.get("type", "")), "物品"), WarehouseService.get_merge_level(item_data)]
	_description.text = str(item_data.get("description", "暂无说明"))
	var armor_state := WarehouseService.get_armor_state(item_instance if not item_instance.is_empty() else item_data)
	_details.add_theme_color_override("font_color", INTACT_ARMOR_COLOR if bool(armor_state.get("tracks_armor", false)) and not bool(armor_state.get("is_damaged", false)) else DETAIL_COLOR)
	_details.text = _get_detail_text(item_data, item_instance)
	_action_button.text = action_text
	_action_button.visible = not action_text.is_empty()


func show_empty() -> void:
	_icon.texture = null
	_title.text = "物品信息"
	_type_label.text = "点击查看详情"
	_description.text = "点击仓库物品、干员装备或武器配件槽，可查看对应的属性与用途。"
	_details.text = ""
	_details.add_theme_color_override("font_color", DETAIL_COLOR)
	_action_button.visible = false


func set_action(action_text: String) -> void:
	_action_button.text = action_text
	_action_button.visible = not action_text.is_empty()


func _get_detail_text(item_data: Dictionary, item_instance: Dictionary = {}) -> String:
	match str(item_data.get("type", "")):
		"WEAPON":
			return "射程 %d  ·  攻击 %d  ·  行动消耗 %d" % [int(item_data.get("range", 0)), int(item_data.get("attack_power", 0)), int(item_data.get("attack_cost", 0))]
		"WEAPON_ATTACHMENT":
			var modifiers: Dictionary = item_data.get("stat_modifiers", {})
			var modifier_text: Array[String] = []
			for stat in modifiers:
				modifier_text.append("%s +%s" % [_get_modifier_name(str(stat)), str(modifiers[stat])])
			var effect_text := "  ·  ".join(modifier_text)
			if effect_text.is_empty():
				effect_text = str(item_data.get("special_effect", "无额外数值效果"))
			return "接口：%s\n%s" % [_get_attachment_slot_name(str(item_data.get("slot", ""))), effect_text]
		"CONSUMABLE":
			return "战斗效果：%s" % str(item_data.get("battle_effect_id", "基础补给"))
		"MATERIAL":
			return "用于合成与基地生产。"
		"HELMET", "ARMOR":
			var armor_state := WarehouseService.get_armor_state(item_instance if not item_instance.is_empty() else item_data)
			var current_armor := int(armor_state.get("current_armor", 0))
			var max_armor := int(armor_state.get("max_armor", 0))
			var status_text := "破损 · 不可参与二合" if bool(armor_state.get("is_damaged", false)) else "完好"
			return "护甲值 %d / %d\n状态：%s" % [current_armor, max_armor, status_text]
		"BACKPACK":
			return "战场携行空间：%d × %d" % [int(item_data.get("battle_grid_width", 0)), int(item_data.get("battle_grid_height", 0))]
	return "信用点估值：%d" % int(item_data.get("price", 0))


func _get_attachment_slot_name(slot_name: String) -> String:
	return {"SCOPE": "瞄具", "BARREL": "枪口", "STOCK": "枪托", "RESONANCE_CORE": "共鸣核心"}.get(slot_name, slot_name)


func _get_modifier_name(modifier: String) -> String:
	return {
		"attack_range": "攻击距离",
		"attack_power": "攻击力",
		"move_fire_accuracy": "移动射击精度",
		"accuracy": "命中率",
		"pyroxene_resistance": "辉石抗性",
	}.get(modifier, modifier)


func _make_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.11, 0.97)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.24, 0.61, 0.78, 0.85)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style
