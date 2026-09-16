class_name TransferPolicy
extends RefCounted

var double_click_rules: Dictionary = {}
var container_settings: Dictionary = {}


func configure(rules: Dictionary, settings: Dictionary = {}) -> void:
	double_click_rules = rules.duplicate(true)
	container_settings = settings.duplicate(true)


func get_double_click_targets(source_container: String, item_type: String) -> Array[Dictionary]:
	var source_rules: Dictionary = double_click_rules.get(source_container, {})
	var targets: Array = source_rules.get(item_type, source_rules.get("*", []))
	var result: Array[Dictionary] = []
	for target in targets:
		if target is Dictionary:
			result.append(target.duplicate(true))
	return result


func get_container_setting(container_id: String, key: String, default_value: Variant = null) -> Variant:
	var settings: Dictionary = container_settings.get(container_id, {})
	return settings.get(key, default_value)
