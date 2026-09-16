class_name WarehouseContainer
extends ItemContainer


func get_item(position: int) -> Dictionary:
	return WarehouseService.get_item_at_position(inventory, position)


func get_capacity() -> int:
	return WarehouseService.get_grid_capacity(inventory)


func get_columns() -> int:
	return WarehouseService.get_grid_columns(inventory)


func can_accept(item_uid: String, position: int) -> bool:
	return can_accept_replacing(item_uid, position) and get_item(position).is_empty()


func can_accept_replacing(item_uid: String, position: int) -> bool:
	return position >= 0 \
		and position < get_capacity() \
		and not WarehouseService.get_item_by_uid(inventory, item_uid).is_empty()


func insert(item_uid: String, position: int) -> bool:
	if not can_accept(item_uid, position):
		return false
	WarehouseService._set_item_position(inventory, item_uid, position)
	return true


func remove(position: int) -> String:
	var item := get_item(position)
	var item_uid := str(item.get("uid", ""))
	if item_uid.is_empty():
		return ""
	WarehouseService._set_item_position(inventory, item_uid, -1)
	return item_uid


func swap(source_position: int, target_position: int) -> bool:
	if source_position == target_position:
		return false
	var source_uid := str(get_item(source_position).get("uid", ""))
	if source_uid.is_empty() or target_position < 0 or target_position >= get_capacity():
		return false
	var target_uid := str(get_item(target_position).get("uid", ""))
	WarehouseService._set_item_position(inventory, source_uid, target_position)
	if not target_uid.is_empty():
		WarehouseService._set_item_position(inventory, target_uid, source_position)
	return true
