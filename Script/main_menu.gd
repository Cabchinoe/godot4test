extends Control

@onready var save_load_ui = $SaveLoadUI

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Base.tscn")

func _on_continue_button_pressed() -> void:
	save_load_ui.read_only = true
	save_load_ui.visible = true
	save_load_ui.refresh_slots()

func _on_save_load_closed() -> void:
	save_load_ui.visible = false
	if SaveManager.has_current_data():
		get_tree().change_scene_to_file("res://Base.tscn")
