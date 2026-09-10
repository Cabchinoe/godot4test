extends Control

@onready var local_time_label: Label = $LocalTimeLabel

var _last_time_text := ""

func _ready() -> void:
	_update_local_time()

func _process(_delta: float) -> void:
	_update_local_time()

func _on_battle_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

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
