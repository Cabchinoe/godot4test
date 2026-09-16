class_name EquipmentContainer
extends ItemContainer

var operator_id: String
var equipment_slot: String


func _init(save_inventory: InventorySaveData, source_operator_id: String, slot: String) -> void:
	super(save_inventory)
	operator_id = source_operator_id
	equipment_slot = slot


func get_item(position: int = 0) -> Dictionary:
	if position != 0:
		return {}
	return WarehouseService.get_item_by_uid(inventory, WarehouseService.get_equipped_uid(inventory, equipment_slot, operator_id))


func get_capacity() -> int:
	return 1


func can_accept(item_uid: String, position: int = 0) -> bool:
	return can_accept_replacing(item_uid, position) and get_item(position).is_empty()


func can_accept_replacing(item_uid: String, position: int = 0) -> bool:
	return position == 0 \
		and WarehouseService.can_equip_in_slot(WarehouseService.get_item_by_uid(inventory, item_uid), equipment_slot)


func insert(item_uid: String, position: int = 0) -> bool:
	if not can_accept(item_uid, position):
		return false
	WarehouseService._set_equipped_uid(inventory, operator_id, equipment_slot, item_uid)
	WarehouseService._set_item_position(inventory, item_uid, -1)
	return true


func remove(position: int = 0) -> String:
	var item_uid := str(WarehouseService.get_equipped_uid(inventory, equipment_slot, operator_id))
	if position != 0 or item_uid.is_empty():
		return ""
	WarehouseService._set_equipped_uid(inventory, operator_id, equipment_slot, "")
	return item_uid
