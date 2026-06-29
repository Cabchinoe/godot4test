extends Node

func _ready() -> void:
	ItemDB.load_from_dir("res://conf/items")
	EnemyDB.load_from_file("res://conf/enemies.json")
	get_tree().change_scene_to_file("res://MainMenu.tscn")
