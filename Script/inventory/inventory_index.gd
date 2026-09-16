class_name InventoryIndex
extends RefCounted

var revision: int = -1
var items_by_uid: Dictionary = {}
var item_indices_by_uid: Dictionary = {}
var warehouse_items_by_position: Dictionary = {}
var backpack_items_by_position: Dictionary = {}


func ensure(inventory: InventorySaveData) -> void:
	if revision == inventory.runtime_revision:
		return
	rebuild(inventory)


func rebuild(inventory: InventorySaveData) -> void:
	items_by_uid.clear()
	item_indices_by_uid.clear()
	warehouse_items_by_position.clear()
	backpack_items_by_position.clear()
	for index in inventory.warehouse_items.size():
		var item: Dictionary = inventory.warehouse_items[index]
		var item_uid := str(item.get("uid", ""))
		if item_uid.is_empty():
			continue
		items_by_uid[item_uid] = item
		item_indices_by_uid[item_uid] = index
		var position := int(item.get("position", -1))
		if position >= 0:
			warehouse_items_by_position[position] = item_uid
	for operator_id in inventory.operator_loadouts:
		var loadout: Dictionary = inventory.operator_loadouts[operator_id]
		var backpacks: Dictionary = loadout.get("backpack_items", {})
		for backpack_uid in backpacks:
			backpack_items_by_position[backpack_uid] = backpacks[backpack_uid].duplicate(true)
	revision = inventory.runtime_revision
