class_name BackpackContainer
extends ItemContainer

var backpack_uid: String


func _init(save_inventory: InventorySaveData, source_backpack_uid: String) -> void:
	super(save_inventory)
	backpack_uid = source_backpack_uid


func get_item(position: int) -> Dictionary:
	var item_uid := str(WarehouseService.get_backpack_items(inventory, backpack_uid).get(position, ""))
	return WarehouseService.get_item_by_uid(inventory, item_uid)


func get_capacity() -> int:
	var grid_size := WarehouseService.get_backpack_grid_size(inventory, backpack_uid)
	return grid_size.x * grid_size.y


func get_columns() -> int:
	return WarehouseService.get_backpack_grid_size(inventory, backpack_uid).x


func can_accept(item_uid: String, position: int) -> bool:
	return can_accept_replacing(item_uid, position) and get_item(position).is_empty()


func can_accept_replacing(item_uid: String, position: int) -> bool:
	if position < 0 or position >= get_capacity():
		return false
	var item := WarehouseService.get_item_by_uid(inventory, item_uid)
	if item.is_empty():
		return false
	var item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	return item_data is Dictionary and str((item_data as Dictionary).get("type", "")) != "BACKPACK"


func insert(item_uid: String, position: int) -> bool:
	if not can_accept(item_uid, position):
		return false
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	backpack_items[position] = item_uid
	WarehouseService._set_backpack_items(inventory, backpack_uid, backpack_items)
	WarehouseService._set_item_position(inventory, item_uid, -1)
	return true


func remove(position: int) -> String:
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	var item_uid := str(backpack_items.get(position, ""))
	if item_uid.is_empty():
		return ""
	backpack_items.erase(position)
	WarehouseService._set_backpack_items(inventory, backpack_uid, backpack_items)
	return item_uid


func swap(source_position: int, target_position: int) -> bool:
	if source_position == target_position:
		return false
	var backpack_items := WarehouseService.get_backpack_items(inventory, backpack_uid)
	var source_uid := str(backpack_items.get(source_position, ""))
	if source_uid.is_empty() or target_position < 0 or target_position >= get_capacity():
		return false
	var target_uid := str(backpack_items.get(target_position, ""))
	backpack_items[target_position] = source_uid
	if target_uid.is_empty():
		backpack_items.erase(source_position)
	else:
		backpack_items[source_position] = target_uid
	WarehouseService._set_backpack_items(inventory, backpack_uid, backpack_items)
	return true
