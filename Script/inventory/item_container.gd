class_name ItemContainer
extends RefCounted

var inventory: InventorySaveData


func _init(save_inventory: InventorySaveData) -> void:
	inventory = save_inventory


func get_item(position: int) -> Dictionary:
	return {}


func get_capacity() -> int:
	return 0


func get_columns() -> int:
	return 1


func can_accept(item_uid: String, position: int) -> bool:
	return false


func can_accept_replacing(item_uid: String, position: int) -> bool:
	return can_accept(item_uid, position)


func insert(item_uid: String, position: int) -> bool:
	return false


func remove(position: int) -> String:
	return ""


func swap(source_position: int, target_position: int) -> bool:
	return false
