class_name TransferPolicy
extends RefCounted

var double_click_rules: Dictionary = {}


func configure(rules: Dictionary) -> void:
	double_click_rules = rules.duplicate(true)


func get_double_click_targets(source_container: String, item_type: String) -> Array[Dictionary]:
	var source_rules: Dictionary = double_click_rules.get(source_container, {})
	var targets: Array = source_rules.get(item_type, source_rules.get("*", []))
	var result: Array[Dictionary] = []
	for target in targets:
		if target is Dictionary:
			result.append(target.duplicate(true))
	return result
