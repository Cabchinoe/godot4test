extends Control

@onready var local_time_label: Label = $LocalTimeLabel

var _last_time_text := ""
var _feedback_tweens: Dictionary = {}


func _ready() -> void:
	_update_local_time()
	_setup_button_feedback($BattleButton, $BattleCard, $BattleCard/Highlight)
	_setup_button_feedback($GreenhouseButton, $GreenhouseCard, $GreenhouseCard/Highlight)
	_setup_button_feedback($SpecialOpsButton, $SpecialOpsCard, $SpecialOpsCard/Highlight)
	_setup_button_feedback($WarehouseButton, $WarehouseCard, $WarehouseCard/Highlight)
	_setup_button_feedback($FactoryButton, $FactoryCard, $FactoryCard/Highlight)


func _process(_delta: float) -> void:
	_update_local_time()


func _on_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")


func _setup_button_feedback(button: TextureButton, card: Panel, highlight: ColorRect) -> void:
	button.pivot_offset = button.size / 2.0
	card.pivot_offset = card.size / 2.0
	button.mouse_entered.connect(_set_card_hovered.bind(button, card, highlight, true))
	button.mouse_exited.connect(_set_card_hovered.bind(button, card, highlight, false))
	button.button_down.connect(_set_card_pressed.bind(button, card, highlight, true))
	button.button_up.connect(_set_card_pressed.bind(button, card, highlight, false))


func _set_card_hovered(button: TextureButton, card: Panel, highlight: ColorRect, is_hovered: bool) -> void:
	var target_scale := Vector2(1.018, 1.018) if is_hovered else Vector2.ONE
	var target_alpha := 1.0 if is_hovered else 0.0
	_animate_card_feedback(button, card, highlight, target_scale, target_alpha, 0.16)


func _set_card_pressed(button: TextureButton, card: Panel, highlight: ColorRect, is_pressed: bool) -> void:
	var target_scale := Vector2(0.985, 0.985) if is_pressed else (Vector2(1.018, 1.018) if button.is_hovered() else Vector2.ONE)
	var target_alpha := 1.0 if button.is_hovered() else 0.0
	_animate_card_feedback(button, card, highlight, target_scale, target_alpha, 0.08)


func _animate_card_feedback(button: TextureButton, card: Panel, highlight: ColorRect, target_scale: Vector2, target_alpha: float, duration: float) -> void:
	var active_tween := _feedback_tweens.get(button) as Tween
	if active_tween:
		active_tween.kill()

	var tween := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_feedback_tweens[button] = tween
	tween.parallel().tween_property(card, "scale", target_scale, duration)
	tween.parallel().tween_property(button, "scale", target_scale, duration)
	tween.parallel().tween_property(highlight, "modulate:a", target_alpha, duration)


func _update_local_time() -> void:
	var date_time := Time.get_datetime_dict_from_system()
	var weekdays := ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
	var time_text := "%04d.%02d.%02d %s  %02d:%02d" % [
		date_time["year"],
		date_time["month"],
		date_time["day"],
		weekdays[date_time["weekday"]],
		date_time["hour"],
		date_time["minute"],
	]
	if time_text == _last_time_text:
		return
	_last_time_text = time_text
	local_time_label.text = time_text
