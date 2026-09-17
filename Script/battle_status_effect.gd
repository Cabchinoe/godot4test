class_name BattleStatusEffect
extends RefCounted

var effect_id: String = ""
var display_name: String = ""
var category: String = "debuff"
var remaining_turns: int = -1
var is_permanent: bool = false
var stack_count: int = 1
var max_stacks: int = 1
var modifiers: Dictionary = {}
var periodic_damage: int = 0
var periodic_heal: int = 0
var source_name: String = ""


func _init(definition: Dictionary = {}, applied_source_name: String = "") -> void:
	effect_id = str(definition.get("id", ""))
	display_name = str(definition.get("name", effect_id))
	category = str(definition.get("category", "debuff"))
	is_permanent = bool(definition.get("permanent", false))
	remaining_turns = -1 if is_permanent else maxi(1, int(definition.get("duration_turns", 1)))
	max_stacks = maxi(1, int(definition.get("max_stacks", 1)))
	modifiers = (definition.get("modifiers", {}) as Dictionary).duplicate(true)
	periodic_damage = maxi(0, int(definition.get("periodic_damage", 0)))
	periodic_heal = maxi(0, int(definition.get("periodic_heal", 0)))
	source_name = applied_source_name


func add_application(definition: Dictionary, applied_source_name: String = "") -> void:
	max_stacks = maxi(max_stacks, int(definition.get("max_stacks", 1)))
	if stack_count < max_stacks:
		stack_count += 1
	if not is_permanent:
		remaining_turns = maxi(remaining_turns, maxi(1, int(definition.get("duration_turns", 1))))
	if not applied_source_name.is_empty():
		source_name = applied_source_name


func get_modifier(key: String) -> int:
	return int(modifiers.get(key, 0)) * stack_count


func tick_down() -> bool:
	if is_permanent:
		return false
	remaining_turns -= 1
	return remaining_turns <= 0


func to_dictionary() -> Dictionary:
	return {
		"id": effect_id,
		"name": display_name,
		"category": category,
		"remaining_turns": remaining_turns,
		"permanent": is_permanent,
		"stack_count": stack_count,
		"source_name": source_name,
	}
