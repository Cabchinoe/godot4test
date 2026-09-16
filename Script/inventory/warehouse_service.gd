class_name WarehouseService
extends RefCounted

const OPERATOR_ID := "benny"
const EQUIPMENT_SLOTS := ["weapon", "helmet", "armor", "backpack"]
const TYPE_ORDER := ["WEAPON", "HELMET", "ARMOR", "BACKPACK", "WEAPON_ATTACHMENT", "CONSUMABLE", "MATERIAL", "COLLECTIBLE"]
const INVENTORY_INDEX_SCRIPT := preload("res://Script/inventory/inventory_index.gd")

static var _indexes: Dictionary = {}


static func ensure_data(save_data: SaveData) -> InventorySaveData:
	if save_data.inventory == null:
		save_data.inventory = InventorySaveData.new()
	var inventory := save_data.inventory
	inventory.warehouse_level = 1
	_import_pending_items(inventory)
	if not inventory.initial_content_created:
		_create_initial_content(inventory, save_data.player)
		inventory.initial_content_created = true
		inventory.starter_content_version = 2
	elif inventory.starter_content_version < 2:
		_add_test_content(inventory)
		inventory.starter_content_version = 2
	_ensure_loadout(inventory, save_data.player)
	_normalize_positions(inventory)
	return inventory


static func get_grid_columns(inventory: InventorySaveData) -> int:
	return 10


static func get_grid_capacity(inventory: InventorySaveData) -> int:
	return 100


static func get_item_by_uid(inventory: InventorySaveData, uid: String) -> Dictionary:
	return _get_index(inventory).items_by_uid.get(uid, {})


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
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	if target_position < 0 or backpack_items.has(target_position):
		return false
	var item := get_item_by_uid(inventory, item_uid)
	if item.is_empty() or int(item.get("position", -1)) < 0:
		return false
	var item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	if not (item_data is Dictionary) or str((item_data as Dictionary).get("type", "")) == "BACKPACK":
		return false
	var grid_size := get_backpack_grid_size(inventory, backpack_uid)
	if target_position >= grid_size.x * grid_size.y:
		return false
	backpack_items[target_position] = item_uid
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	_set_item_position(inventory, item_uid, -1)
	return true


static func move_equipped_item_to_backpack(inventory: InventorySaveData, equipment_slot: String, backpack_uid: String, target_position: int, player_data: PlayerSaveData) -> bool:
	if equipment_slot == "backpack":
		return false
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	if target_position < 0 or backpack_items.has(target_position):
		return false
	var grid_size := get_backpack_grid_size(inventory, backpack_uid)
	if target_position >= grid_size.x * grid_size.y:
		return false
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	var item_uid := str(equipment.get(equipment_slot, ""))
	if item_uid.is_empty():
		return false
	equipment.erase(equipment_slot)
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	backpack_items[target_position] = item_uid
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	_set_item_position(inventory, item_uid, -1)
	_sync_player_equipment(inventory, player_data)
	return true


static func swap_warehouse_and_backpack_item(inventory: InventorySaveData, backpack_uid: String, warehouse_position: int, backpack_position: int) -> bool:
	var warehouse_item := get_item_at_position(inventory, warehouse_position)
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	var backpack_item_uid := str(backpack_items.get(backpack_position, ""))
	if warehouse_item.is_empty() or backpack_item_uid.is_empty():
		return false
	var warehouse_item_data: Variant = ItemDB.get_item(str(warehouse_item.get("id", "")))
	if not (warehouse_item_data is Dictionary) or str((warehouse_item_data as Dictionary).get("type", "")) == "BACKPACK":
		return false
	backpack_items[backpack_position] = str(warehouse_item.get("uid", ""))
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	_set_item_position(inventory, backpack_item_uid, warehouse_position)
	_set_item_position(inventory, str(warehouse_item.get("uid", "")), -1)
	return true


static func move_backpack_item(inventory: InventorySaveData, backpack_uid: String, source_position: int, target_position: int) -> bool:
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	if not backpack_items.has(source_position) or source_position == target_position:
		return false
	var grid_size := get_backpack_grid_size(inventory, backpack_uid)
	if target_position < 0 or target_position >= grid_size.x * grid_size.y:
		return false
	var source_uid: String = str(backpack_items[source_position])
	var target_uid: String = str(backpack_items.get(target_position, ""))
	backpack_items[target_position] = source_uid
	if str(target_uid).is_empty():
		backpack_items.erase(source_position)
	else:
		backpack_items[source_position] = target_uid
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	return true


static func move_backpack_item_to_warehouse(inventory: InventorySaveData, backpack_uid: String, source_position: int, warehouse_position: int) -> bool:
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	var item_uid := str(backpack_items.get(source_position, ""))
	if item_uid.is_empty() or warehouse_position < 0 or not get_item_at_position(inventory, warehouse_position).is_empty():
		return false
	backpack_items.erase(source_position)
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	_set_item_position(inventory, item_uid, warehouse_position)
	return true


static func remove_backpack_item(inventory: InventorySaveData, backpack_uid: String, source_position: int) -> String:
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	var item_uid := str(backpack_items.get(source_position, ""))
	if item_uid.is_empty():
		return ""
	backpack_items.erase(source_position)
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	return item_uid


static func equip_backpack_item(inventory: InventorySaveData, backpack_uid: String, source_position: int, equipment_slot: String, player_data: PlayerSaveData) -> bool:
	if not get_equipped_uid(inventory, equipment_slot).is_empty():
		return false
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	var item_uid := str(backpack_items.get(source_position, ""))
	if item_uid.is_empty() or not can_equip_in_slot(get_item_by_uid(inventory, item_uid), equipment_slot):
		return false
	backpack_items.erase(source_position)
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	if equip_item(inventory, equipment_slot, item_uid, player_data):
		return true
	backpack_items[source_position] = item_uid
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	return false


static func replace_equipped_item_from_backpack(inventory: InventorySaveData, backpack_uid: String, source_position: int, equipment_slot: String, player_data: PlayerSaveData) -> bool:
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	var item_uid := str(backpack_items.get(source_position, ""))
	if item_uid.is_empty() or not can_equip_in_slot(get_item_by_uid(inventory, item_uid), equipment_slot):
		return false
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	var previous_uid := str(equipment.get(equipment_slot, ""))
	if previous_uid.is_empty():
		return equip_backpack_item(inventory, backpack_uid, source_position, equipment_slot, player_data)
	backpack_items[source_position] = previous_uid
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	equipment[equipment_slot] = item_uid
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_set_item_position(inventory, item_uid, -1)
	_sync_player_equipment(inventory, player_data)
	return true


static func replace_equipped_item_from_warehouse(inventory: InventorySaveData, equipment_slot: String, item_uid: String, player_data: PlayerSaveData) -> bool:
	var source_item := get_item_by_uid(inventory, item_uid)
	var source_position := int(source_item.get("position", -1))
	if source_position < 0 or not can_equip_in_slot(source_item, equipment_slot):
		return false
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	var previous_uid := str(equipment.get(equipment_slot, ""))
	if previous_uid.is_empty():
		return equip_item(inventory, equipment_slot, item_uid, player_data)
	_set_item_position(inventory, previous_uid, source_position)
	_set_item_position(inventory, item_uid, -1)
	equipment[equipment_slot] = item_uid
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_sync_player_equipment(inventory, player_data)
	return true


static func move_attachment_to_backpack(inventory: InventorySaveData, source_weapon_uid: String, source_attachment_slot: String, backpack_uid: String, target_position: int) -> bool:
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	if backpack_items.has(target_position):
		return false
	var attachments := get_weapon_attachments(inventory, source_weapon_uid)
	var attachment_uid := str(attachments.get(source_attachment_slot, ""))
	if attachment_uid.is_empty():
		return false
	var grid_size := get_backpack_grid_size(inventory, backpack_uid)
	if target_position < 0 or target_position >= grid_size.x * grid_size.y:
		return false
	var loadout := get_loadout(inventory)
	var all_attachments: Dictionary = loadout.get("attachments", {})
	var weapon_attachments: Dictionary = all_attachments.get(source_weapon_uid, {})
	weapon_attachments.erase(source_attachment_slot)
	all_attachments[source_weapon_uid] = weapon_attachments
	loadout["attachments"] = all_attachments
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	backpack_items[target_position] = attachment_uid
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	return true


static func attach_backpack_item_to_weapon(inventory: InventorySaveData, backpack_uid: String, backpack_position: int, weapon_uid: String, attachment_slot: String) -> bool:
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	var attachment_uid := str(backpack_items.get(backpack_position, ""))
	if attachment_uid.is_empty() or not can_attach(inventory, weapon_uid, attachment_uid, attachment_slot):
		return false
	var loadout := get_loadout(inventory)
	var attachments: Dictionary = loadout.get("attachments", {})
	var equipped_attachments: Dictionary = attachments.get(weapon_uid, {})
	var replaced_uid := str(equipped_attachments.get(attachment_slot, ""))
	if replaced_uid == attachment_uid:
		return true
	if replaced_uid.is_empty():
		backpack_items.erase(backpack_position)
	else:
		backpack_items[backpack_position] = replaced_uid
	equipped_attachments[attachment_slot] = attachment_uid
	attachments[weapon_uid] = equipped_attachments
	loadout["attachments"] = attachments
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_set_backpack_items(inventory, backpack_uid, backpack_items)
	_set_item_position(inventory, attachment_uid, -1)
	return true


static func unequip_backpack_to_warehouse(inventory: InventorySaveData, player_data: PlayerSaveData, warehouse_positions: Array[int]) -> bool:
	var backpack_uid := get_equipped_uid(inventory, "backpack")
	if backpack_uid.is_empty():
		return false
	var backpack_items := get_backpack_items(inventory, backpack_uid)
	if warehouse_positions.size() < backpack_items.size() + 1:
		return false
	var index := 0
	for backpack_position in backpack_items:
		_set_item_position(inventory, str(backpack_items[backpack_position]), warehouse_positions[index])
		index += 1
	_clear_backpack_items(inventory, backpack_uid)
	_set_item_position(inventory, backpack_uid, warehouse_positions[index])
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	equipment.erase("backpack")
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
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
	var item := get_item_by_uid(inventory, item_uid)
	if not can_equip_in_slot(item, slot):
		return false
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	var previous_uid := str(equipment.get(slot, ""))
	if slot == "backpack" and not previous_uid.is_empty() and previous_uid != item_uid:
		return false
	if not previous_uid.is_empty() and previous_uid != item_uid:
		return false
	if previous_uid == item_uid:
		return true
	if not previous_uid.is_empty():
		_put_item_in_first_open_position(inventory, previous_uid)
	equipment[slot] = item_uid
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_set_item_position(inventory, item_uid, -1)
	_sync_player_equipment(inventory, player_data)
	return true


static func unequip_item(inventory: InventorySaveData, slot: String, player_data: PlayerSaveData = null) -> bool:
	var loadout := get_loadout(inventory)
	var equipment: Dictionary = loadout.get("equipment", {})
	var item_uid := str(equipment.get(slot, ""))
	if item_uid.is_empty():
		return false
	if not _put_item_in_first_open_position(inventory, item_uid):
		return false
	equipment.erase(slot)
	loadout["equipment"] = equipment
	inventory.operator_loadouts[OPERATOR_ID] = loadout
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
	if not can_attach(inventory, weapon_uid, attachment_uid, attachment_slot):
		return false
	var loadout := get_loadout(inventory)
	var attachments: Dictionary = loadout.get("attachments", {})
	var equipped_attachments: Dictionary = attachments.get(weapon_uid, {})
	var previous_uid := str(equipped_attachments.get(attachment_slot, ""))
	if previous_uid == attachment_uid:
		return true
	if not previous_uid.is_empty():
		var attachment_position := int(get_item_by_uid(inventory, attachment_uid).get("position", -1))
		if attachment_position >= 0:
			_set_item_position(inventory, previous_uid, attachment_position)
		elif not _put_item_in_first_open_position(inventory, previous_uid):
			return false
	equipped_attachments[attachment_slot] = attachment_uid
	attachments[weapon_uid] = equipped_attachments
	loadout["attachments"] = attachments
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_set_item_position(inventory, attachment_uid, -1)
	return true


static func move_attachment(inventory: InventorySaveData, source_weapon_uid: String, source_attachment_slot: String, target_weapon_uid: String, target_attachment_slot: String) -> bool:
	var loadout := get_loadout(inventory)
	var attachments: Dictionary = loadout.get("attachments", {})
	var source_equipped: Dictionary = attachments.get(source_weapon_uid, {}).duplicate(true)
	var attachment_uid := str(source_equipped.get(source_attachment_slot, ""))
	if attachment_uid.is_empty() or not can_attach(inventory, target_weapon_uid, attachment_uid, target_attachment_slot):
		return false
	if source_weapon_uid == target_weapon_uid and source_attachment_slot == target_attachment_slot:
		return true
	var target_equipped: Dictionary = attachments.get(target_weapon_uid, {}).duplicate(true)
	var replaced_uid := str(target_equipped.get(target_attachment_slot, ""))
	if source_weapon_uid == target_weapon_uid:
		if replaced_uid.is_empty():
			source_equipped.erase(source_attachment_slot)
		else:
			source_equipped[source_attachment_slot] = replaced_uid
		source_equipped[target_attachment_slot] = attachment_uid
		attachments[source_weapon_uid] = source_equipped
	else:
		if replaced_uid.is_empty():
			source_equipped.erase(source_attachment_slot)
		else:
			source_equipped[source_attachment_slot] = replaced_uid
		target_equipped[target_attachment_slot] = attachment_uid
		attachments[source_weapon_uid] = source_equipped
		attachments[target_weapon_uid] = target_equipped
	loadout["attachments"] = attachments
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	_touch(inventory)
	return true


static func detach_attachment(inventory: InventorySaveData, weapon_uid: String, attachment_slot: String) -> bool:
	var loadout := get_loadout(inventory)
	var attachments: Dictionary = loadout.get("attachments", {})
	var equipped_attachments: Dictionary = attachments.get(weapon_uid, {})
	var attachment_uid := str(equipped_attachments.get(attachment_slot, ""))
	if attachment_uid.is_empty() or not _put_item_in_first_open_position(inventory, attachment_uid):
		return false
	equipped_attachments.erase(attachment_slot)
	attachments[weapon_uid] = equipped_attachments
	loadout["attachments"] = attachments
	inventory.operator_loadouts[OPERATOR_ID] = loadout
	return true


static func move_item(inventory: InventorySaveData, source_position: int, target_position: int) -> bool:
	if source_position == target_position:
		return false
	var source := get_item_at_position(inventory, source_position)
	if source.is_empty():
		return false
	var target := get_item_at_position(inventory, target_position)
	_set_item_position(inventory, str(source.get("uid", "")), target_position)
	if not target.is_empty():
		_set_item_position(inventory, str(target.get("uid", "")), source_position)
	return true


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


static func _add_item_instance(inventory: InventorySaveData, item_id: String) -> Dictionary:
	if not (ItemDB.get_item(item_id) is Dictionary):
		return {}
	var item := {"uid": _make_uid(), "id": item_id, "position": _find_open_position(inventory)}
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
