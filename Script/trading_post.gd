extends Control

const SHOP_ITEM_IDS := [
	"material_metal_01",
	"material_textile_thread_01",
	"material_filter_cotton_01",
	"material_seed_pack_01",
]

@onready var credits_label: Label = $Header/CreditsLabel
@onready var goods_container: VBoxContainer = $Content/Layout/GoodsContainer
@onready var feedback_label: Label = $Content/Layout/FeedbackLabel


func _ready() -> void:
	_ensure_trade_data()
	_refresh_credits()
	_populate_goods()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://CommandCenter.tscn")


func _populate_goods() -> void:
	for child in goods_container.get_children():
		child.queue_free()
	for item_id in SHOP_ITEM_IDS:
		var item_data = ItemDB.get_item(item_id)
		if item_data is Dictionary:
			goods_container.add_child(_create_goods_card(item_data))


func _create_goods_card(item_data: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 78)
	card.add_theme_stylebox_override("panel", _create_card_style())

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	card.add_child(row)

	var name_label := Label.new()
	name_label.custom_minimum_size = Vector2(180, 0)
	name_label.add_theme_color_override("font_color", Color(0.91, 0.97, 1, 1))
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.text = str(item_data.get("name", "未知物资"))
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(name_label)

	var description_label := Label.new()
	description_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description_label.add_theme_color_override("font_color", Color(0.56, 0.72, 0.81, 1))
	description_label.add_theme_font_size_override("font_size", 14)
	description_label.text = str(item_data.get("description", ""))
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(description_label)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(124, 42)
	buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	buy_button.add_theme_color_override("font_color", Color(0.92, 0.98, 1, 1))
	buy_button.add_theme_font_size_override("font_size", 17)
	buy_button.add_theme_stylebox_override("normal", _create_buy_button_style(false))
	buy_button.add_theme_stylebox_override("hover", _create_buy_button_style(true))
	buy_button.add_theme_stylebox_override("pressed", _create_buy_button_style(true))
	buy_button.text = "购买  %d" % int(item_data.get("price", 0))
	buy_button.pressed.connect(_buy_item.bind(str(item_data.get("id", ""))))
	row.add_child(buy_button)
	return card


func _buy_item(item_id: String) -> void:
	var item_data = ItemDB.get_item(item_id)
	if not item_data is Dictionary:
		feedback_label.text = "该物资暂时无法交易。"
		return
	var price := int(item_data.get("price", 0))
	var player_data := SaveManager.current_data.player
	if player_data.credits < price:
		feedback_label.text = "信用点不足，先从战区或居民订单中补充资金。"
		return
	player_data.credits -= price
	var quantities := SaveManager.current_data.inventory.item_quantities
	quantities[item_id] = int(quantities.get(item_id, 0)) + 1
	SaveManager.current_data.inventory.item_quantities = quantities
	SaveManager.save_current()
	_refresh_credits()
	feedback_label.text = "%s 已送入仓库。" % str(item_data.get("name", "物资"))


func _ensure_trade_data() -> void:
	if SaveManager.current_data == null:
		SaveManager.create_new_game()
	if SaveManager.current_data.player == null:
		SaveManager.current_data.player = PlayerSaveData.new()
	if SaveManager.current_data.inventory == null:
		SaveManager.current_data.inventory = InventorySaveData.new()


func _refresh_credits() -> void:
	credits_label.text = "信用点  %s" % _format_number(SaveManager.current_data.player.credits)


func _format_number(value: int) -> String:
	var text_value := str(maxi(value, 0))
	var formatted := ""
	for index in text_value.length():
		if index > 0 and (text_value.length() - index) % 3 == 0:
			formatted += ","
		formatted += text_value.substr(index, 1)
	return formatted


func _create_card_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.075, 0.11, 0.92)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.19, 0.47, 0.62, 0.7)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_right = 6
	style.corner_radius_bottom_left = 6
	style.content_margin_left = 20
	style.content_margin_right = 16
	return style


func _create_buy_button_style(is_hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.36, 0.48, 1) if is_hovered else Color(0.05, 0.22, 0.31, 1)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.42, 0.82, 0.98, 1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_right = 5
	style.corner_radius_bottom_left = 5
	return style
