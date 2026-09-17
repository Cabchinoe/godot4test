class_name TemporaryContainer
extends ItemContainer

var container_id: String


func _init(save_inventory: InventorySaveData, source_container_id: String) -> void:
	super(save_inventory)
	container_id = source_container_id


func get_item(position: int) -> Dictionary:
	var item_uid := str(WarehouseService.get_temporary_items(inventory, container_id).get(position, ""))
	return WarehouseService.get_item_by_uid(inventory, item_uid)


func get_capacity() -> int:
	return WarehouseService.get_temporary_capacity(inventory, container_id)


func get_columns() -> int:
	return WarehouseService.get_temporary_columns(inventory, container_id)


func can_accept(item_uid: String, position: int) -> bool:
	return can_accept_replacing(item_uid, position) and get_item(position).is_empty()


func can_accept_replacing(item_uid: String, position: int) -> bool:
	return position >= 0 and position < get_capacity() and not WarehouseService.get_item_by_uid(inventory, item_uid).is_empty()


func insert(item_uid: String, position: int) -> bool:
	if not can_accept(item_uid, position):
		return false
	var items := WarehouseService.get_temporary_items(inventory, container_id)
	items[position] = item_uid
	WarehouseService._set_temporary_items(inventory, container_id, items)
	WarehouseService._set_item_position(inventory, item_uid, -1)
	return true


func remove(position: int) -> String:
	var items := WarehouseService.get_temporary_items(inventory, container_id)
	var item_uid := str(items.get(position, ""))
	if item_uid.is_empty():
		return ""
	items.erase(position)
	WarehouseService._set_temporary_items(inventory, container_id, items)
	return item_uid


func swap(source_position: int, target_position: int) -> bool:
	if source_position == target_position:
		return false
	var items := WarehouseService.get_temporary_items(inventory, container_id)
	var source_uid := str(items.get(source_position, ""))
	if source_uid.is_empty() or target_position < 0 or target_position >= get_capacity():
		return false
	var target_uid := str(items.get(target_position, ""))
	items[target_position] = source_uid
	if target_uid.is_empty():
		items.erase(source_position)
	else:
		items[source_position] = target_uid
	WarehouseService._set_temporary_items(inventory, container_id, items)
	return true
