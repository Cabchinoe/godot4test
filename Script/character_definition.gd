class_name CharacterDefinition
extends Resource

@export var character_id: StringName
@export var display_name: String = ""
@export_range(3, 5) var rarity: int = 3
@export var sprite_frames: SpriteFrames
@export var animation_idle: StringName = &"idle"
@export var animation_walk: StringName = &"walk"
@export var animation_aim: StringName = &"aim"
@export var allowed_weapon_ids: PackedStringArray = []
@export var default_loadout: Dictionary = {}
@export var level_stats: Array[Dictionary] = []

func get_level_data(level: int) -> Dictionary:
	if level_stats.is_empty():
		push_error("CharacterDefinition '%s' has no level data." % character_id)
		return {}
	var index := clampi(level, get_min_level(), get_max_level()) - get_min_level()
	return level_stats[index].duplicate(true)

func get_min_level() -> int:
	if level_stats.is_empty():
		return 1
	return int(level_stats.front().get("level", 1))

func get_max_level() -> int:
	if level_stats.is_empty():
		return 1
	return int(level_stats.back().get("level", 1))

func is_weapon_allowed(item_id: String) -> bool:
	return allowed_weapon_ids.has(item_id)
