class_name WarehouseService
extends RefCounted

const OPERATOR_ID := "benny"
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "backpack"]
const TYPE_ORDER := ["WEAPON", "HELMET", "ARMOR", "BACKPACK", "WEAPON_ATTACHMENT", "CONSUMABLE", "MATERIAL", "COLLECTIBLE"]
const INVENTORY_INDEX_SCRIPT := preload("res://Script/inventory/inventory_index.gd")
const ITEM_LOCATION_SCRIPT := preload("res://Script/inventory/item_location.gd")
const WAREHOUSE_CONTAINER_SCRIPT := preload("res://Script/inventory/warehouse_container.gd")
const BACKPACK_CONTAINER_SCRIPT := preload("res://Script/inventory/backpack_container.gd")
const EQUIPMENT_CONTAINER_SCRIPT := preload("res://Script/inventory/equipment_container.gd")
const WEAPON_ATTACHMENT_CONTAINER_SCRIPT := preload("res://Script/inventory/weapon_attachment_container.gd")

static var _indexes: Dictionary = {}


static func ensure_data(save_data: SaveData) -> InventorySaveData:
	if save_data.inventory == null:
		save_data.inventory = InventorySaveData.new()
	var inventory := save_data.inventory
	inventory.warehouse_level = 1
	_import_pending_items(inventory)
	if not inventory.initial_content_created:
		_create_initial_content(inventory, save_data.player)
		_add_test_content(inventory)
		_add_high_level_test_content(inventory)
		_add_backpack_test_content(inventory)
		_add_varied_backpack_test_content(inventory)
		_add_armor_state_test_content(inventory)
		inventory.initial_content_created = true
		inventory.starter_content_version = 6
	elif inventory.starter_content_version < 2:
		_add_test_content(inventory)
		inventory.starter_content_version = 2
	if inventory.starter_content_version < 3:
		_add_high_level_test_content(inventory)
		inventory.starter_content_version = 3
	if inventory.starter_content_version < 4:
		_add_backpack_test_content(inventory)
		inventory.starter_content_version = 4
	if inventory.starter_content_version < 5:
		_add_varied_backpack_test_content(inventory)
		inventory.starter_content_version = 5
	if inventory.starter_content_version < 6:
		_add_armor_state_test_content(inventory)
		inventory.starter_content_version = 6
	_ensure_loadout(inventory, save_data.player)
	_ensure_armor_state(inventory)
	_normalize_positions(inventory)
	return inventory


static func get_grid_columns(inventory: InventorySaveData) -> int:
	return 10


static func get_grid_capacity(inventory: InventorySaveData) -> int:
	return 100


static func get_container(inventory: InventorySaveData, location: ItemLocation) -> ItemContainer:
	if location == null or not location.is_valid():
		return null
	match location.container_id:
		ItemLocation.WAREHOUSE:
			return WAREHOUSE_CONTAINER_SCRIPT.new(inventory)
		ItemLocation.BACKPACK:
			return BACKPACK_CONTAINER_SCRIPT.new(inventory, location.owner_id)
		ItemLocation.EQUIPMENT:
			return EQUIPMENT_CONTAINER_SCRIPT.new(inventory, location.owner_id, location.slot_id)
		ItemLocation.WEAPON_ATTACHMENT:
			return WEAPON_ATTACHMENT_CONTAINER_SCRIPT.new(inventory, location.owner_id, location.slot_id)
	return null


static func get_item_location(inventory: InventorySaveData, item_uid: String) -> ItemLocation:
	var item := get_item_by_uid(inventory, item_uid)
	var warehouse_position := int(item.get("position", -1))
	if warehouse_position >= 0:
		return ITEM_LOCATION_SCRIPT.warehouse(warehouse_position)
	for operator_id in inventory.operator_loadouts:
		var loadout: Dictionary = inventory.operator_loadouts[operator_id]
		for equipment_slot in (loadout.get("equipment", {}) as Dictionary):
			if str((loadout.get("equipment", {}) as Dictionary)[equipment_slot]) == item_uid:
				return ITEM_LOCATION_SCRIPT.equipment(str(operator_id), str(equipment_slot))
		for weapon_uid in (loadout.get("attachments", {}) as Dictionary):
			var attachments: Dictionary = (loadout.get("attachments", {}) as Dictionary)[weapon_uid]
			for attachment_slot in attachments:
				if str(attachments[attachment_slot]) == item_uid:
					return ITEM_LOCATION_SCRIPT.weapon_attachment(str(weapon_uid), str(attachment_slot))
		for backpack_uid in (loadout.get("backpack_items", {}) as Dictionary):
			var backpack_items: Dictionary = (loadout.get("backpack_items", {}) as Dictionary)[backpack_uid]
			for backpack_position in backpack_items:
				if str(backpack_items[backpack_position]) == item_uid:
					return ITEM_LOCATION_SCRIPT.backpack(str(backpack_uid), int(backpack_position))
	return null


static func get_item_by_uid(inventory: InventorySaveData, uid: String) -> Dictionary:
	return _get_index(inventory).items_by_uid.get(uid, {})


static func get_armor_state(item: Dictionary) -> Dictionary:
	var item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	if not (item_data is Dictionary):
		return {"tracks_armor": false, "max_armor": 0, "current_armor": 0, "is_damaged": false}
	var item_type := str((item_data as Dictionary).get("type", ""))
	if item_type not in ["ARMOR", "HELMET"]:
		return {"tracks_armor": false, "max_armor": 0, "current_armor": 0, "is_damaged": false}
	var max_armor := maxi(0, int(item.get("max_armor", (item_data as Dictionary).get("defense", 0))))
	var current_armor := clampi(int(item.get("current_armor", max_armor)), 0, max_armor)
	return {
		"tracks_armor": true,
		"max_armor": max_armor,
		"current_armor": current_armor,
		"is_damaged": max_armor > 0 and current_armor < max_armor,
	}


static func can_merge_item(item: Dictionary) -> bool:
	var armor_state := get_armor_state(item)
	return not bool(armor_state.get("tracks_armor", false)) or not bool(armor_state.get("is_damaged", false))


static func set_item_current_armor(inventory: InventorySaveData, item_uid: String, current_armor: int) -> bool:
	var index := get_item_array_index(inventory, item_uid)
	if index < 0:
		return false
	var item: Dictionary = inventory.warehouse_items[index]
	var armor_state := get_armor_state(item)
	if not bool(armor_state.get("tracks_armor", false)):
		return false
	item["max_armor"] = int(armor_state.get("max_armor", 0))
	item["current_armor"] = clampi(current_armor, 0, int(armor_state.get("max_armor", 0)))
	inventory.warehouse_items[index] = item
	_touch(inventory)
	return true


static func get_item_at_position(inventory: InventorySaveData, position: int) -> Dictionary:
	var item_uid := str(_get_index(inventory).warehouse_items_by_position.get(position, ""))
	return get_item_by_uid(inventory, item_uid)


static func get_warehouse_position_index(inventory: InventorySaveData) -> Dictionary:
	return _get_index(inventory).warehouse_items_by_position.duplicate(true)


static func get_item_array_index(inventory: InventorySaveData, item_uid: String) -> int:
	var cache: Variant = _get_index(inventory)
	return int(cache.item_indices_by_uid.get(item_uid, -1))


static func get_loadout(inventory: InventorySaveData, operator_id: String = OPERATOR_ID) -> Dictionary:
	if not inventory.operator_loadouts.has(operator_id):
		inventory.operator_loadouts[operator_id] = {"equipment": {}, "attachments": {}}
		_touch(inventory)
	return inventory.operator_loadouts[operator_id]


static func get_equipped_uid(inventory: InventorySaveData, slot: String, operator_id: String = OPERATOR_ID) -> String:
	var loadout := get_loadout(inventory, operator_id)
	return str((loadout.get("equipment", {}) as Dictionary).get(slot, ""))


static func get_weapon_attachments(inventory: InventorySaveData, weapon_uid: String, operator_id: String = OPERATOR_ID) -> Dictionary:
	var loadout := get_loadout(inventory, operator_id)
	var attachments: Dictionary = loadout.get("attachments", {})
	return attachments.get(weapon_uid, {})


static func get_backpack_items(inventory: InventorySaveData, backpack_uid: String, operator_id: String = OPERATOR_ID) -> Dictionary:
	var index: Variant = _get_index(inventory)
	if index.backpack_items_by_position.has(backpack_uid):
		return index.backpack_items_by_position[backpack_uid].duplicate(true)
	var loadout := get_loadout(inventory, operator_id)
	var backpack_items: Dictionary = loadout.get("backpack_items", {})
	return backpack_items.get(backpack_uid, {})


static func get_backpack_grid_size(inventory: InventorySaveData, backpack_uid: String) -> Vector2i:
	var backpack := get_item_by_uid(inventory, backpack_uid)
	var backpack_data: Variant = ItemDB.get_item(str(backpack.get("id", "")))
	if not (backpack_data is Dictionary):
		return Vector2i.ZERO
	var backpack_dictionary := backpack_data as Dictionary
	return Vector2i(int(backpack_dictionary.get("battle_grid_width", 0)), int(backpack_dictionary.get("battle_grid_height", 0)))


static func get_backpack_item_count(inventory: InventorySaveData, backpack_uid: String) -> int:
	return get_backpack_items(inventory, backpack_uid).size()


static func move_warehouse_item_to_backpack(inventory: InventorySaveData, backpack_uid: String, item_uid: String, target_position: int) -> bool:
	var source_location := get_item_location(inventory, item_uid)
	var target_location := ITEM_LOCATION_SCRIPT.backpack(backpack_uid, target_position)
	return _move_between_containers(inventory, source_location, target_location)


static func move_equipped_item_to_backpack(inventory: InventorySaveData, equipment_slot: String, backpack_uid: String, target_position: int, player_data: PlayerSaveData) -> bool:
	if equipment_slot == "backpack":
		return false
	var moved := _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, equipment_slot),
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, target_position)
	)
	if moved:
		_sync_player_equipment(inventory, player_data)
	return moved


static func swap_warehouse_and_backpack_item(inventory: InventorySaveData, backpack_uid: String, warehouse_position: int, backpack_position: int) -> bool:
	return _swap_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.warehouse(warehouse_position),
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, backpack_position)
	)


static func move_backpack_item(inventory: InventorySaveData, backpack_uid: String, source_position: int, target_position: int) -> bool:
	var backpack := get_container(inventory, ITEM_LOCATION_SCRIPT.backpack(backpack_uid, source_position))
	return backpack != null and backpack.swap(source_position, target_position)


static func move_backpack_item_to_warehouse(inventory: InventorySaveData, backpack_uid: String, source_position: int, warehouse_position: int) -> bool:
	return _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, source_position),
		ITEM_LOCATION_SCRIPT.warehouse(warehouse_position)
	)


static func remove_backpack_item(inventory: InventorySaveData, backpack_uid: String, source_position: int) -> String:
	var backpack := get_container(inventory, ITEM_LOCATION_SCRIPT.backpack(backpack_uid, source_position))
	return backpack.remove(source_position) if backpack != null else ""


static func equip_backpack_item(inventory: InventorySaveData, backpack_uid: String, source_position: int, equipment_slot: String, player_data: PlayerSaveData) -> bool:
	var moved := _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, source_position),
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, equipment_slot)
	)
	if moved:
		_sync_player_equipment(inventory, player_data)
	return moved


static func replace_equipped_item_from_backpack(inventory: InventorySaveData, backpack_uid: String, source_position: int, equipment_slot: String, player_data: PlayerSaveData) -> bool:
	var replaced := _replace_container_item(
		inventory,
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, source_position),
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, equipment_slot)
	)
	if replaced:
		_sync_player_equipment(inventory, player_data)
	return replaced


static func replace_equipped_item_from_warehouse(inventory: InventorySaveData, equipment_slot: String, item_uid: String, player_data: PlayerSaveData) -> bool:
	if equipment_slot == "backpack":
		return replace_equipped_backpack_from_warehouse(inventory, item_uid, player_data)
	var source_location := get_item_location(inventory, item_uid)
	if source_location == null or source_location.container_id != ItemLocation.WAREHOUSE:
		return false
	var replaced := _replace_container_item(
		inventory,
		source_location,
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, equipment_slot)
	)
	if replaced:
		_sync_player_equipment(inventory, player_data)
	return replaced


static func replace_equipped_backpack_from_warehouse(inventory: InventorySaveData, item_uid: String, player_data: PlayerSaveData) -> bool:
	var source_item := get_item_by_uid(inventory, item_uid)
	var source_location := get_item_location(inventory, item_uid)
	if source_location == null \
		or source_location.container_id != ItemLocation.WAREHOUSE \
		or not can_equip_in_slot(source_item, "backpack"):
		return false
	var previous_backpack_uid := get_equipped_uid(inventory, "backpack")
	if previous_backpack_uid.is_empty():
		return equip_item(inventory, "backpack", item_uid, player_data)
	if previous_backpack_uid == item_uid:
		return true
	var previous_backpack_items := get_backpack_items(inventory, previous_backpack_uid)
	var new_backpack_capacity := get_backpack_grid_size(inventory, item_uid)
	var capacity := new_backpack_capacity.x * new_backpack_capacity.y
	if capacity < previous_backpack_items.size():
		return false
	var migrated_items: Dictionary = {}
	var previous_positions: Array = previous_backpack_items.keys()
	previous_positions.sort()
	for index in previous_positions.size():
		migrated_items[index] = str(previous_backpack_items[previous_positions[index]])
	_set_item_position(inventory, previous_backpack_uid, source_location.position)
	_set_item_position(inventory, item_uid, -1)
	_set_equipped_uid(inventory, OPERATOR_ID, "backpack", item_uid)
	_clear_backpack_items(inventory, previous_backpack_uid)
	_set_backpack_items(inventory, item_uid, migrated_items)
	_sync_player_equipment(inventory, player_data)
	return true


static func move_attachment_to_backpack(inventory: InventorySaveData, source_weapon_uid: String, source_attachment_slot: String, backpack_uid: String, target_position: int) -> bool:
	return _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.weapon_attachment(source_weapon_uid, source_attachment_slot),
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, target_position)
	)


static func attach_backpack_item_to_weapon(inventory: InventorySaveData, backpack_uid: String, backpack_position: int, weapon_uid: String, attachment_slot: String) -> bool:
	return _replace_container_item(
		inventory,
		ITEM_LOCATION_SCRIPT.backpack(backpack_uid, backpack_position),
		ITEM_LOCATION_SCRIPT.weapon_attachment(weapon_uid, attachment_slot)
	)


static func unequip_backpack_to_warehouse(inventory: InventorySaveData, player_data: PlayerSaveData, warehouse_positions: Array[int]) -> bool:
	var backpack_uid := get_equipped_uid(inventory, "backpack")
	if backpack_uid.is_empty():
		return false
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	if warehouse_positions.size() < backpack_items.size() + 1:
		return false
	var warehouse := get_container(inventory, ITEM_LOCATION_SCRIPT.warehouse(0))
	var occupied_positions: Dictionary = {}
	for index in backpack_items.size() + 1:
		var warehouse_position := warehouse_positions[index]
		if occupied_positions.has(warehouse_position) or not warehouse.can_accept(backpack_uid, warehouse_position):
			return false
		occupied_positions[warehouse_position] = true
	var backpack_positions: Array = backpack_items.keys()
	for index in backpack_positions.size():
		if not _move_between_containers(
			inventory,
			ITEM_LOCATION_SCRIPT.backpack(backpack_uid, int(backpack_positions[index])),
			ITEM_LOCATION_SCRIPT.warehouse(warehouse_positions[index])
		):
			return false
	if not _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, "backpack"),
		ITEM_LOCATION_SCRIPT.warehouse(warehouse_positions[backpack_positions.size()])
	):
		return false
	_sync_player_equipment(inventory, player_data)
	return true


static func can_equip_in_slot(item: Dictionary, slot: String) -> bool:
	if item.is_empty():
		return false
	var item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	if not (item_data is Dictionary):
		return false
	var item_dictionary := item_data as Dictionary
	return bool(item_dictionary.get("can_equip", true)) and _type_to_equipment_slot(str(item_dictionary.get("type", ""))) == slot


static func equip_item(inventory: InventorySaveData, slot: String, item_uid: String, player_data: PlayerSaveData = null) -> bool:
	if get_equipped_uid(inventory, slot) == item_uid:
		return true
	var moved := _move_between_containers(
		inventory,
		get_item_location(inventory, item_uid),
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, slot)
	)
	if moved:
		_sync_player_equipment(inventory, player_data)
	return moved


static func unequip_item(inventory: InventorySaveData, slot: String, player_data: PlayerSaveData = null) -> bool:
	var warehouse_position := _find_open_position(inventory)
	if warehouse_position < 0:
		return false
	var moved := _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.equipment(OPERATOR_ID, slot),
		ITEM_LOCATION_SCRIPT.warehouse(warehouse_position)
	)
	if not moved:
		return false
	_sync_player_equipment(inventory, player_data)
	return true


static func can_attach(inventory: InventorySaveData, weapon_uid: String, attachment_uid: String, attachment_slot: String) -> bool:
	var weapon := get_item_by_uid(inventory, weapon_uid)
	var attachment := get_item_by_uid(inventory, attachment_uid)
	if weapon.is_empty() or attachment.is_empty():
		return false
	var weapon_data: Variant = ItemDB.get_item(str(weapon.get("id", "")))
	var attachment_data: Variant = ItemDB.get_item(str(attachment.get("id", "")))
	if not (weapon_data is Dictionary) or not (attachment_data is Dictionary):
		return false
	var weapon_dictionary := weapon_data as Dictionary
	var attachment_dictionary := attachment_data as Dictionary
	if str(weapon_dictionary.get("type", "")) != "WEAPON" or str(attachment_dictionary.get("type", "")) != "WEAPON_ATTACHMENT":
		return false
	if str(attachment_dictionary.get("slot", "")) != attachment_slot:
		return false
	if not (weapon_dictionary.get("attachment_slots", []) as Array).has(attachment_slot):
		return false
	return (attachment_dictionary.get("compatible_weapon_ids", []) as Array).has(str(weapon.get("id", "")))


static func attach_item(inventory: InventorySaveData, weapon_uid: String, attachment_uid: String, attachment_slot: String) -> bool:
	var source_location := get_item_location(inventory, attachment_uid)
	var target_location := ITEM_LOCATION_SCRIPT.weapon_attachment(weapon_uid, attachment_slot)
	if source_location == null:
		return false
	if target_location.matches(source_location):
		return true
	if source_location.container_id != ItemLocation.WAREHOUSE:
		var warehouse_position := _find_open_position(inventory)
		if warehouse_position < 0:
			return false
		return _replace_container_item(inventory, source_location, target_location, ITEM_LOCATION_SCRIPT.warehouse(warehouse_position))
	return _replace_container_item(inventory, source_location, target_location)


static func move_attachment(inventory: InventorySaveData, source_weapon_uid: String, source_attachment_slot: String, target_weapon_uid: String, target_attachment_slot: String) -> bool:
	var source_location := ITEM_LOCATION_SCRIPT.weapon_attachment(source_weapon_uid, source_attachment_slot)
	var target_location := ITEM_LOCATION_SCRIPT.weapon_attachment(target_weapon_uid, target_attachment_slot)
	if source_location.matches(target_location):
		return not get_container(inventory, source_location).get_item(0).is_empty()
	return _replace_container_item(inventory, source_location, target_location)


static func detach_attachment(inventory: InventorySaveData, weapon_uid: String, attachment_slot: String) -> bool:
	var warehouse_position := _find_open_position(inventory)
	if warehouse_position < 0:
		return false
	return _move_between_containers(
		inventory,
		ITEM_LOCATION_SCRIPT.weapon_attachment(weapon_uid, attachment_slot),
		ITEM_LOCATION_SCRIPT.warehouse(warehouse_position)
	)


static func move_item(inventory: InventorySaveData, source_position: int, target_position: int) -> bool:
	var warehouse := get_container(inventory, ITEM_LOCATION_SCRIPT.warehouse(source_position))
	return warehouse != null and warehouse.swap(source_position, target_position)


static func organize(inventory: InventorySaveData) -> void:
	var stored_items: Array[Dictionary] = []
	for item in inventory.warehouse_items:
		if int(item.get("position", -1)) >= 0:
			stored_items.append(item)
	stored_items.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var first_data := ItemDB.get_item(str(first.get("id", ""))) as Dictionary
		var second_data := ItemDB.get_item(str(second.get("id", ""))) as Dictionary
		var first_type := TYPE_ORDER.find(str(first_data.get("type", "")))
		var second_type := TYPE_ORDER.find(str(second_data.get("type", "")))
		if first_type != second_type:
			return first_type < second_type
		var first_level := get_merge_level(first_data)
		var second_level := get_merge_level(second_data)
		if first_level != second_level:
			return first_level > second_level
		return str(first_data.get("name", "")) < str(second_data.get("name", ""))
	)
	for index in stored_items.size():
		_set_item_position(inventory, str(stored_items[index].get("uid", "")), index)


static func get_merge_level(item_data: Dictionary) -> int:
	return maxi(1, int(item_data.get("merge_level", 1)))


static func _move_between_containers(inventory: InventorySaveData, source_location: ItemLocation, target_location: ItemLocation) -> bool:
	var source := get_container(inventory, source_location)
	var target := get_container(inventory, target_location)
	if source == null or target == null or source_location.matches(target_location):
		return false
	var item_uid := str(source.get_item(source_location.position).get("uid", ""))
	if item_uid.is_empty() or not target.can_accept(item_uid, target_location.position):
		return false
	if source.remove(source_location.position) != item_uid:
		return false
	if target.insert(item_uid, target_location.position):
		return true
	source.insert(item_uid, source_location.position)
	return false


static func _swap_between_containers(inventory: InventorySaveData, source_location: ItemLocation, target_location: ItemLocation) -> bool:
	return _replace_container_item(inventory, source_location, target_location)


static func _replace_container_item(
	inventory: InventorySaveData,
	source_location: ItemLocation,
	target_location: ItemLocation,
	replacement_location: ItemLocation = null
) -> bool:
	var source := get_container(inventory, source_location)
	var target := get_container(inventory, target_location)
	if source == null or target == null:
		return false
	if source_location.matches(target_location):
		return not source.get_item(source_location.position).is_empty()
	var source_uid := str(source.get_item(source_location.position).get("uid", ""))
	if source_uid.is_empty():
		return false
	var target_uid := str(target.get_item(target_location.position).get("uid", ""))
	if target_uid.is_empty():
		return _move_between_containers(inventory, source_location, target_location)
	var return_location := replacement_location if replacement_location != null else source_location
	var return_container := get_container(inventory, return_location)
	if return_container == null \
		or not target.can_accept_replacing(source_uid, target_location.position) \
		or not return_container.can_accept_replacing(target_uid, return_location.position):
		return false
	if source.remove(source_location.position) != source_uid:
		return false
	if target.remove(target_location.position) != target_uid:
		source.insert(source_uid, source_location.position)
		return false
	if not target.insert(source_uid, target_location.position):
		target.insert(target_uid, target_location.position)
		source.insert(source_uid, source_location.position)
		return false
	if return_container.insert(target_uid, return_location.position):
		return true
	target.remove(target_location.position)
	target.insert(target_uid, target_location.position)
	source.insert(source_uid, source_location.position)
	return false


static func _create_initial_content(inventory: InventorySaveData, player_data: PlayerSaveData) -> void:
	var starter_item_ids := [
		"weapon_benny_defender_9", "weapon_benny_hare_hopper", "attachment_reflex_sight_01",
		"attachment_compensator_01", "attachment_light_stock_01", "helmet_salvaged_shell_01",
		"armor_light_component_05", "backpack_basic_01", "consumable_medkit_01", "consumable_adrenaline_01",
		"material_metal_01", "material_metal_01", "material_textile_thread_01", "material_textile_thread_01",
		"material_filter_cotton_01", "material_seed_pack_01",
		"material_metal_01", "material_metal_01", "material_metal_01", "material_metal_01",
		"material_textile_thread_01", "material_textile_thread_01", "material_textile_thread_01", "material_textile_thread_01",
		"material_filter_cotton_01", "material_filter_cotton_01", "material_filter_cotton_01",
		"material_seed_pack_01", "material_seed_pack_01", "material_seed_pack_01",
		"consumable_medkit_01", "consumable_medkit_01", "consumable_medkit_01",
		"consumable_adrenaline_01", "consumable_adrenaline_01",
		"attachment_reflex_sight_01", "attachment_compensator_01", "attachment_light_stock_01",
	]
	if player_data and not player_data.equipped_item_ids.is_empty():
		var saved_weapon := str(player_data.equipped_item_ids.get("weapon", ""))
		if not saved_weapon.is_empty() and not starter_item_ids.has(saved_weapon):
			starter_item_ids.push_front(saved_weapon)
	for item_id in starter_item_ids:
		_add_item_instance(inventory, item_id)


static func _add_test_content(inventory: InventorySaveData) -> void:
	for item_id in [
		"material_metal_01", "material_metal_01", "material_metal_01", "material_metal_01",
		"material_textile_thread_01", "material_textile_thread_01", "material_textile_thread_01",
		"material_filter_cotton_01", "material_filter_cotton_01", "material_seed_pack_01",
		"consumable_medkit_01", "consumable_medkit_01", "consumable_adrenaline_01",
		"attachment_reflex_sight_01", "attachment_compensator_01", "attachment_light_stock_01",
	]:
		_add_item_instance(inventory, item_id)


static func _add_high_level_test_content(inventory: InventorySaveData) -> void:
	for item_id in [
		"weapon_benny_dawn_pulse", "weapon_benny_dawn_pulse", "weapon_benny_dawn_pulse", "weapon_benny_dawn_pulse",
		"weapon_benny_hare_hopper", "weapon_benny_hare_hopper", "weapon_benny_hare_hopper", "weapon_benny_hare_hopper",
		"attachment_benny_resonance_core_01", "attachment_benny_resonance_core_01", "attachment_benny_resonance_core_01", "attachment_benny_resonance_core_01", "attachment_benny_resonance_core_01",
		"helmet_reinforced_shell_04", "helmet_reinforced_shell_04", "helmet_reinforced_shell_04", "helmet_reinforced_shell_04", "helmet_reinforced_shell_04",
		"armor_modular_06", "armor_modular_06", "armor_modular_06", "armor_modular_06", "armor_modular_06", "armor_modular_06",
		"armor_light_component_05", "armor_light_component_05", "armor_light_component_05",
	]:
		_add_item_instance(inventory, item_id)


static func _add_backpack_test_content(inventory: InventorySaveData) -> void:
	for item_id in ["backpack_basic_01", "backpack_basic_01", "backpack_basic_01"]:
		_add_item_instance(inventory, item_id)


static func _add_varied_backpack_test_content(inventory: InventorySaveData) -> void:
	for item_id in ["backpack_expedition_07", "backpack_modular_frame_06", "backpack_tactical_pack_08"]:
		_add_item_instance(inventory, item_id)


static func _add_armor_state_test_content(inventory: InventorySaveData) -> void:
	for item_id in [
		"armor_outpost_defense_08", "armor_outpost_defense_08",
		"helmet_modular_tactical_06", "helmet_modular_tactical_06",
		"helmet_crystal_fiber_07", "helmet_outpost_defense_08",
	]:
		_add_item_instance(inventory, item_id)
	var damaged_armor := _add_item_instance(inventory, "armor_modular_06")
	set_item_current_armor(inventory, str(damaged_armor.get("uid", "")), 18)
	var damaged_helmet := _add_item_instance(inventory, "helmet_reinforced_shell_04")
	set_item_current_armor(inventory, str(damaged_helmet.get("uid", "")), 4)


static func _import_pending_items(inventory: InventorySaveData) -> void:
	for item_id in inventory.item_quantities:
		var count := int(inventory.item_quantities[item_id])
		for index in count:
			_add_item_instance(inventory, str(item_id))
	inventory.item_quantities = {}


static func _ensure_loadout(inventory: InventorySaveData, player_data: PlayerSaveData) -> void:
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	if equipment.is_empty() and player_data:
		for slot in EQUIPMENT_SLOTS:
			var legacy_id := str(player_data.equipped_item_ids.get(slot, ""))
			if legacy_id.is_empty():
				continue
			var item := _find_or_add_item(inventory, legacy_id)
			if not item.is_empty():
				equipment[slot] = str(item.get("uid", ""))
				_set_item_position(inventory, str(item.get("uid", "")), -1)
	if not equipment.has("weapon"):
		var weapon := _find_or_add_item(inventory, "weapon_benny_defender_9")
		equipment["weapon"] = str(weapon.get("uid", ""))
		_set_item_position(inventory, str(weapon.get("uid", "")), -1)
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_sync_player_equipment(inventory, player_data)


static func _normalize_positions(inventory: InventorySaveData) -> void:
	var used_positions := {}
	var next_position := 0
	for index in inventory.warehouse_items.size():
		var item: Dictionary = inventory.warehouse_items[index]
		var position := int(item.get("position", -1))
		if position < 0:
			continue
		if position >= get_grid_capacity(inventory) or used_positions.has(position):
			while used_positions.has(next_position):
				next_position += 1
			item["position"] = next_position
			position = next_position
		used_positions[position] = true
		inventory.warehouse_items[index] = item
	_touch(inventory)


static func _ensure_armor_state(inventory: InventorySaveData) -> void:
	var changed := false
	for index in inventory.warehouse_items.size():
		var item: Dictionary = inventory.warehouse_items[index]
		var armor_state := get_armor_state(item)
		if not bool(armor_state.get("tracks_armor", false)):
			continue
		var max_armor := int(armor_state.get("max_armor", 0))
		var current_armor := int(armor_state.get("current_armor", 0))
		if int(item.get("max_armor", -1)) == max_armor and int(item.get("current_armor", -1)) == current_armor:
			continue
		item["max_armor"] = max_armor
		item["current_armor"] = current_armor
		inventory.warehouse_items[index] = item
		changed = true
	if changed:
		_touch(inventory)


static func _add_item_instance(inventory: InventorySaveData, item_id: String) -> Dictionary:
	if not (ItemDB.get_item(item_id) is Dictionary):
		return {}
	var item := {"uid": _make_uid(), "id": item_id, "position": _find_open_position(inventory)}
	var armor_state := get_armor_state(item)
	if bool(armor_state.get("tracks_armor", false)):
		item["max_armor"] = int(armor_state.get("max_armor", 0))
		item["current_armor"] = int(armor_state.get("current_armor", 0))
	inventory.warehouse_items.append(item)
	_touch(inventory)
	return item


static func _find_or_add_item(inventory: InventorySaveData, item_id: String) -> Dictionary:
	for item in inventory.warehouse_items:
		if str(item.get("id", "")) == item_id:
			return item
	return _add_item_instance(inventory, item_id)


static func _find_open_position(inventory: InventorySaveData) -> int:
	var occupied: Dictionary = get_warehouse_position_index(inventory)
	for position in get_grid_capacity(inventory):
		if not occupied.has(position):
			return position
	return -1


static func _put_item_in_first_open_position(inventory: InventorySaveData, item_uid: String) -> bool:
	var open_position := _find_open_position(inventory)
	if open_position < 0:
		return false
	_set_item_position(inventory, item_uid, open_position)
	return true


static func _set_item_position(inventory: InventorySaveData, item_uid: String, position: int) -> void:
	var index: int = get_item_array_index(inventory, item_uid)
	if index < 0:
		return
	var item: Dictionary = inventory.warehouse_items[index]
	item["position"] = position
	inventory.warehouse_items[index] = item
	_touch(inventory)


static func _set_backpack_items(inventory: InventorySaveData, backpack_uid: String, backpack_items: Dictionary) -> void:
	var loadout := get_loadout(inventory)
	var all_backpack_items: Dictionary = loadout.get("backpack_items", {})
	all_backpack_items[backpack_uid] = backpack_items
	loadout["backpack_items"] = all_backpack_items
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_touch(inventory)


static func _set_equipped_uid(inventory: InventorySaveData, operator_id: String, equipment_slot: String, item_uid: String) -> void:
	var loadout := get_loadout(inventory, operator_id)
	var equipment: Dictionary = loadout.get("equipment", {})
	if item_uid.is_empty():
		equipment.erase(equipment_slot)
	else:
		equipment[equipment_slot] = item_uid
	loadout["equipment"] = equipment
	inventory.operator_loadouts[operator_id] = loadout
	_touch(inventory)


static func _set_attachment_uid(inventory: InventorySaveData, weapon_uid: String, attachment_slot: String, item_uid: String, operator_id: String = OPERATOR_ID) -> void:
	var loadout := get_loadout(inventory, operator_id)
	var attachments: Dictionary = loadout.get("attachments", {})
	var weapon_attachments: Dictionary = attachments.get(weapon_uid, {})
	if item_uid.is_empty():
		weapon_attachments.erase(attachment_slot)
	else:
		weapon_attachments[attachment_slot] = item_uid
	attachments[weapon_uid] = weapon_attachments
	loadout["attachments"] = attachments
	inventory.operator_loadouts[operator_id] = loadout
	_touch(inventory)


static func _clear_backpack_items(inventory: InventorySaveData, backpack_uid: String) -> void:
	var loadout := get_loadout(inventory)
	var all_backpack_items: Dictionary = loadout.get("backpack_items", {})
	all_backpack_items.erase(backpack_uid)
	loadout["backpack_items"] = all_backpack_items
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_touch(inventory)


static func _sync_player_equipment(inventory: InventorySaveData, player_data: PlayerSaveData) -> void:
	if player_data == null:
		return
	var equipment_ids := player_data.equipped_item_ids.duplicate(true)
	for slot in EQUIPMENT_SLOTS:
		var item := get_item_by_uid(inventory, get_equipped_uid(inventory, slot))
		if item.is_empty():
			equipment_ids.erase(slot)
		else:
			equipment_ids[slot] = str(item.get("id", ""))
	player_data.equipped_item_ids = equipment_ids


static func _type_to_equipment_slot(item_type: String) -> String:
	match item_type:
		"WEAPON": return "weapon"
		"HELMET": return "helmet"
		"ARMOR": return "armor"
		"BACKPACK": return "backpack"
	return ""


static func _make_uid() -> String:
	return "%s_%s" % [str(Time.get_ticks_usec()), str(randi())]


static func _get_index(inventory: InventorySaveData):
	var key := inventory.get_instance_id()
	var index: Variant = _indexes.get(key)
	if index == null:
		index = INVENTORY_INDEX_SCRIPT.new()
		_indexes[key] = index
	index.ensure(inventory)
	return index


static func _touch(inventory: InventorySaveData) -> void:
	inventory.runtime_revision += 1
