class_name Player
extends Unit

signal profile_changed

@export var character_definition: CharacterDefinition

var operator_level: int = 1
var experience: int = 0
var max_hp: int = 1
var current_hp: int = 1
var pyroxene_resistance: int = 0
var unlocked_equipment_slots: PackedStringArray = []
var owned_item_ids: PackedStringArray = []
var equipped_item_ids: Dictionary = {}
var unlocked_flags: Dictionary = {}

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
	return int(_get_equipped_weapon_data().get("range", 1))

func get_attack_cost() -> int:
	return int(_get_equipped_weapon_data().get("attack_cost", 1))

func _get_equipped_weapon_data() -> Dictionary:
	var item_id := get_equipped_item_id(&"weapon")
	var item_data = ItemDB.get_item(item_id)
	return item_data if item_data is Dictionary else {}

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
