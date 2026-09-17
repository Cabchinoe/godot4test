class_name Player
extends Unit

signal profile_changed

@export var character_definition: CharacterDefinition

var operator_level: int = 1
var experience: int = 0
var pyroxene_resistance: int = 0
var unlocked_equipment_slots: PackedStringArray = []
var owned_item_ids: PackedStringArray = []
var equipped_item_ids: Dictionary = {}
var unlocked_flags: Dictionary = {}
var _battle_inventory: InventorySaveData

func initialize_player(p_level_manager: LevelManager) -> void:
	if character_definition == null:
		push_error("Player is missing a CharacterDefinition.")
		return
	load_base_data()
	super.init_unit(character_definition.display_name, "player", ap_max, p_level_manager, 1)
	load_appearance()
	current_hp = max_hp
	_ensure_default_loadout()

func load_appearance() -> void:
	if character_definition == null:
		return
	configure_appearance(
		character_definition.sprite_frames,
		character_definition.animation_idle,
		character_definition.animation_walk,
		character_definition.animation_aim
	)

func load_base_data() -> void:
	if character_definition == null:
		return
	operator_level = clampi(operator_level, character_definition.get_min_level(), character_definition.get_max_level())
	var level_data := character_definition.get_level_data(operator_level)
	if level_data.is_empty():
		return
	max_hp = int(level_data.get("max_hp", 1))
	pyroxene_resistance = int(level_data.get("pyroxene_resistance", 0))
	ap_max = int(level_data.get("base_ap", 1))
	unlocked_equipment_slots = PackedStringArray(level_data.get("equipment_slots", []))
	current_hp = clampi(current_hp, 1, max_hp)

func apply_save_data(data: PlayerSaveData) -> void:
	if data == null:
		load_base_data()
		_ensure_default_loadout()
		return
	operator_level = data.operator_level
	experience = data.experience
	owned_item_ids = data.owned_item_ids.duplicate()
	equipped_item_ids = data.equipped_item_ids.duplicate(true)
	unlocked_flags = data.unlocked_flags.duplicate(true)
	load_base_data()
	current_hp = max_hp
	_ensure_default_loadout()

func write_save_data(data: PlayerSaveData) -> void:
	data.operator_id = character_definition.character_id
	data.operator_level = operator_level
	data.level = operator_level
	data.experience = experience
	data.owned_item_ids = owned_item_ids.duplicate()
	data.equipped_item_ids = equipped_item_ids.duplicate(true)
	data.unlocked_flags = unlocked_flags.duplicate(true)


func sync_equipment_from_save(data: PlayerSaveData) -> void:
	if data == null:
		return
	equipped_item_ids = data.equipped_item_ids.duplicate(true)
	profile_changed.emit()


func sync_battle_equipment(inventory: InventorySaveData) -> void:
	_battle_inventory = inventory
	profile_changed.emit()

func upgrade_to(target_level: int) -> bool:
	if character_definition == null:
		return false
	var new_level := clampi(target_level, operator_level, character_definition.get_max_level())
	if new_level == operator_level:
		return false
	operator_level = new_level
	load_base_data()
	_commit_profile_change()
	return true

func add_owned_item(item_id: String) -> bool:
	if item_id.is_empty() or owned_item_ids.has(item_id):
		return false
	owned_item_ids.append(item_id)
	_commit_profile_change()
	return true

func equip_item(slot: StringName, item_id: String) -> bool:
	if not unlocked_equipment_slots.has(slot):
		return false
	if item_id.is_empty():
		equipped_item_ids.erase(slot)
		_commit_profile_change()
		return true
	if not owned_item_ids.has(item_id):
		return false
	if slot == &"weapon" and not character_definition.is_weapon_allowed(item_id):
		return false
	equipped_item_ids[slot] = item_id
	_commit_profile_change()
	return true

func get_equipped_item_id(slot: StringName) -> String:
	return str(equipped_item_ids.get(slot, ""))

func get_attack_range() -> int:
	return maxi(1, int(_get_equipped_weapon_data().get("range", base_attack_range)))

func get_attack_cost() -> int:
	return maxi(0, int(_get_equipped_weapon_data().get("attack_cost", base_attack_cost)))


func get_attack_power() -> int:
	var total := int(_get_equipped_weapon_data().get("attack_power", base_attack_power)) + int(_get_combat_profile().get("damage_flat", 0))
	for attachment_data in _get_equipped_attachment_data():
		total += int((attachment_data.get("stat_modifiers", {}) as Dictionary).get("attack_power", 0))
	return maxi(1, total + get_status_modifier("attack_power"))


func get_attack_accuracy() -> int:
	var total := int(_get_combat_profile().get("accuracy_bonus", 0))
	for attachment_data in _get_equipped_attachment_data():
		total += int((attachment_data.get("stat_modifiers", {}) as Dictionary).get("accuracy", 0))
	return total + get_status_modifier("accuracy")


func get_attack_distance_profile(distance: int) -> Dictionary:
	var weapon_data := _get_equipped_weapon_data()
	for band_variant in weapon_data.get("distance_bands", []):
		if not (band_variant is Dictionary):
			continue
		var band := band_variant as Dictionary
		var min_distance := maxi(1, int(band.get("min", 1)))
		var max_distance := maxi(min_distance, int(band.get("max", min_distance)))
		if distance >= min_distance and distance <= max_distance:
			return {
				"distance": distance,
				"damage_multiplier": float(band.get("damage_multiplier", 1.0)),
				"accuracy": int(band.get("accuracy", 0)) + get_attack_accuracy(),
				"base_accuracy": int(band.get("accuracy", 0)),
				"accuracy_bonus": get_attack_accuracy(),
			}
	return super.get_attack_distance_profile(distance)


func get_hit_location_indices() -> Dictionary:
	var result := {"head": 0, "body": 0, "limb": 0}
	_add_hit_location_indices(result, _get_combat_profile().get("hit_location_indices", {}))
	_add_hit_location_indices(result, _get_equipped_weapon_data().get("hit_location_indices", {}))
	for attachment_data in _get_equipped_attachment_data():
		_add_hit_location_indices(result, attachment_data.get("hit_location_indices", {}))
	return result


func get_unprotected_debuffs() -> Array[Dictionary]:
	var sources: Array = [
		_get_combat_profile().get("unprotected_debuffs", []),
		_get_equipped_weapon_data().get("unprotected_debuffs", []),
	]
	for attachment_data in _get_equipped_attachment_data():
		sources.append(attachment_data.get("unprotected_debuffs", []))
	return _merge_unprotected_debuffs(sources)


func get_combat_log_snapshot() -> Dictionary:
	var snapshot := super.get_combat_log_snapshot()
	var character_profile := _get_combat_profile()
	var weapon_data := _get_equipped_weapon_data()
	var attachment_logs: Array[Dictionary] = []
	for attachment_data in _get_equipped_attachment_data():
		attachment_logs.append({
			"name": str(attachment_data.get("name", "未知配件")),
			"stat_modifiers": (attachment_data.get("stat_modifiers", {}) as Dictionary).duplicate(true),
			"hit_location_indices": (attachment_data.get("hit_location_indices", {}) as Dictionary).duplicate(true),
			"unprotected_debuffs": (attachment_data.get("unprotected_debuffs", []) as Array).duplicate(true),
		})
	snapshot["character"] = {
		"name": character_definition.display_name if character_definition else unit_name,
		"combat_profile": character_profile.duplicate(true),
	}
	snapshot["weapon"] = {
		"name": str(weapon_data.get("name", "未装备武器")),
		"attack_power": int(weapon_data.get("attack_power", 0)),
		"distance_bands": (weapon_data.get("distance_bands", []) as Array).duplicate(true),
		"hit_location_indices": (weapon_data.get("hit_location_indices", {}) as Dictionary).duplicate(true),
		"unprotected_debuffs": (weapon_data.get("unprotected_debuffs", []) as Array).duplicate(true),
	}
	snapshot["attachments"] = attachment_logs
	snapshot["totals"] = {
		"attack_power": get_attack_power(),
		"accuracy_bonus": get_attack_accuracy(),
		"hit_location_indices": get_hit_location_indices(),
		"movement_steps": moved_steps_this_turn,
		"movement_accuracy_penalty": get_movement_attack_accuracy_penalty(),
	}
	snapshot["protection"] = {
		"helmet": _get_equipment_protection_snapshot("helmet"),
		"armor": _get_equipment_protection_snapshot("armor"),
	}
	return snapshot


func absorb_damage_at_location(location: String, raw_damage: int) -> Dictionary:
	var equipment_slot := ""
	if location == "head":
		equipment_slot = "helmet"
	elif location == "body":
		equipment_slot = "armor"
	if equipment_slot.is_empty() or _battle_inventory == null:
		return {
			"location": location,
			"had_protection": false,
			"absorbed": 0,
			"remaining_armor": 0,
			"depleted": false,
		}
	var item_uid := WarehouseService.get_equipped_uid(_battle_inventory, equipment_slot)
	var item := WarehouseService.get_item_by_uid(_battle_inventory, item_uid)
	var armor_state := WarehouseService.get_armor_state(item)
	var current_armor := int(armor_state.get("current_armor", 0))
	var per_hit_absorb := int(armor_state.get("per_hit_absorb", current_armor))
	var had_protection := current_armor > 0
	var absorbed := mini(mini(maxi(0, raw_damage), current_armor), per_hit_absorb)
	var remaining_armor := current_armor - absorbed
	if absorbed > 0:
		WarehouseService.set_item_current_armor(_battle_inventory, item_uid, remaining_armor)
		profile_changed.emit()
	return {
		"location": location,
		"had_protection": had_protection,
		"absorbed": absorbed,
		"remaining_armor": remaining_armor,
		"depleted": had_protection and remaining_armor == 0,
	}


func _get_combat_profile() -> Dictionary:
	return character_definition.combat_profile if character_definition else {}


func _get_equipped_attachment_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if _battle_inventory == null:
		return result
	var weapon_uid := WarehouseService.get_equipped_uid(_battle_inventory, "weapon", WarehouseService.OPERATOR_ID)
	if weapon_uid.is_empty():
		return result
	for attachment_uid in WarehouseService.get_weapon_attachments(_battle_inventory, weapon_uid, WarehouseService.OPERATOR_ID).values():
		var attachment := WarehouseService.get_item_by_uid(_battle_inventory, str(attachment_uid))
		var attachment_data: Variant = ItemDB.get_item(str(attachment.get("id", "")))
		if attachment_data is Dictionary:
			result.append((attachment_data as Dictionary).duplicate(true))
	return result


func _get_equipment_protection_snapshot(slot: String) -> Dictionary:
	if _battle_inventory == null:
		return {}
	var item_uid := WarehouseService.get_equipped_uid(_battle_inventory, slot, WarehouseService.OPERATOR_ID)
	var item := WarehouseService.get_item_by_uid(_battle_inventory, item_uid)
	var item_data: Variant = ItemDB.get_item(str(item.get("id", "")))
	var armor_state := WarehouseService.get_armor_state(item)
	return {
		"name": str((item_data as Dictionary).get("name", "未装备")) if item_data is Dictionary else "未装备",
		"current_armor": int(armor_state.get("current_armor", 0)),
		"max_armor": int(armor_state.get("max_armor", 0)),
		"per_hit_absorb": int(armor_state.get("per_hit_absorb", 0)),
	}

func _get_equipped_weapon_data() -> Dictionary:
	if _battle_inventory != null:
		var weapon_uid := WarehouseService.get_equipped_uid(_battle_inventory, "weapon", WarehouseService.OPERATOR_ID)
		var weapon := WarehouseService.get_item_by_uid(_battle_inventory, weapon_uid)
		var equipped_data: Variant = ItemDB.get_item(str(weapon.get("id", "")))
		if equipped_data is Dictionary:
			return (equipped_data as Dictionary).duplicate(true)
	var item_id := get_equipped_item_id(&"weapon")
	var item_data = ItemDB.get_item(item_id)
	return item_data if item_data is Dictionary else {}


func _add_hit_location_indices(target: Dictionary, value: Variant) -> void:
	if not (value is Dictionary):
		return
	var source := value as Dictionary
	for location in ["head", "body", "limb"]:
		target[location] = maxi(0, int(target.get(location, 0)) + int(source.get(location, 0)))


func _merge_unprotected_debuffs(sources: Array) -> Array[Dictionary]:
	var merged: Dictionary = {}
	for source_variant in sources:
		if not (source_variant is Array):
			continue
		for entry in source_variant:
			if not (entry is Dictionary):
				continue
			var profile := entry as Dictionary
			var effect_id := str(profile.get("id", ""))
			if effect_id.is_empty():
				continue
			if not merged.has(effect_id):
				merged[effect_id] = {"id": effect_id, "chance": 0, "locations": []}
			var combined: Dictionary = merged[effect_id]
			combined["chance"] = clampi(int(combined.get("chance", 0)) + int(profile.get("chance", 0)), 0, 100)
			var locations: Array = combined.get("locations", [])
			for location in profile.get("locations", []):
				var location_name := str(location)
				if location_name in ["head", "body", "limb"] and not locations.has(location_name):
					locations.append(location_name)
			combined["locations"] = locations
			merged[effect_id] = combined
	var result: Array[Dictionary] = []
	for profile in merged.values():
		if profile is Dictionary:
			result.append((profile as Dictionary).duplicate(true))
	return result

func _ensure_default_loadout() -> void:
	if character_definition == null:
		return
	for slot in character_definition.default_loadout:
		var item_id := str(character_definition.default_loadout[slot])
		if item_id.is_empty():
			continue
		if not owned_item_ids.has(item_id):
			owned_item_ids.append(item_id)
		if unlocked_equipment_slots.has(slot) and not equipped_item_ids.has(slot):
			equipped_item_ids[slot] = item_id

func _commit_profile_change() -> void:
	profile_changed.emit()
	if SaveManager.has_current_data():
		var save_data := SaveManager.current_data.player
		if save_data == null:
			save_data = PlayerSaveData.new()
			SaveManager.current_data.player = save_data
		write_save_data(save_data)
		SaveManager.save_current()
