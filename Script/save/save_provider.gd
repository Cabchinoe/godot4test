class_name SaveProvider
extends RefCounted

func write_to(data: SaveData) -> void:
	pass

func read_from(data: SaveData) -> void:
	pass

func get_provider_name() -> String:
	return "SaveProvider"
