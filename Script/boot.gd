extends Node

func _ready() -> void:
	ItemDB.load_from_dir("res://conf/items")
	EnemyDB.load_from_file("res://conf/enemies.json")
	call_deferred("_open_main_menu")


func _open_main_menu() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
