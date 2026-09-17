class_name BattleStatusDB
extends RefCounted

const EFFECTS = {
	"bleeding": {
		"id": "bleeding",
		"name": "流血",
		"category": "injury",
		"permanent": true,
		"max_stacks": 3,
		"periodic_damage": 5,
		"modifiers": {}
	},
	"fractured": {
		"id": "fractured",
		"name": "骨折",
		"category": "injury",
		"permanent": true,
		"max_stacks": 1,
		"modifiers": {"ap_delta": -2}
	}
}


static func get_definition(effect_id: String) -> Dictionary:
	var definition: Variant = EFFECTS.get(effect_id, {})
	return (definition as Dictionary).duplicate(true) if definition is Dictionary else {}


static func get_all_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition in EFFECTS.values():
		if definition is Dictionary:
			result.append((definition as Dictionary).duplicate(true))
	return result
