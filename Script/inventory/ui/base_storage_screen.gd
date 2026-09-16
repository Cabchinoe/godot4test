class_name BaseStorageScreen
extends Control

func persist_storage() -> void:
	if SaveManager.current_data:
		SaveManager.save_current_or_create()


func return_to_command_center() -> void:
	persist_storage()
	get_tree().change_scene_to_file("res://CommandCenter.tscn")
