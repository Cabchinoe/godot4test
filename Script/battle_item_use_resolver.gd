class_name BattleItemUseResolver
extends RefCounted


static func get_ap_cost(item_data: Dictionary) -> int:
	var battle_use: Dictionary = item_data.get("battle_use", {})
	return maxi(0, int(battle_use.get("ap_cost", 1)))


static func can_use(unit: Unit, item_data: Dictionary) -> bool:
	if unit == null or unit.is_defeated:
		return false
	var battle_use: Dictionary = item_data.get("battle_use", {})
	if battle_use.is_empty():
		return false
	if bool(battle_use.get("heal_full", false)) and unit.current_hp < unit.max_hp:
		return true
	if int(battle_use.get("heal", 0)) > 0 and unit.current_hp < unit.max_hp:
		return true
	if int(battle_use.get("restore_ap", 0)) > 0 and unit.action_points < unit.get_current_ap_limit():
		return true
	for effect_id in battle_use.get("remove_statuses", []):
		if unit.has_status(str(effect_id)):
			return true
	for effect_id in (battle_use.get("remove_status_stacks", {}) as Dictionary):
		if unit.has_status(str(effect_id)):
			return true
	return false


static func get_unavailable_reason(unit: Unit, item_data: Dictionary) -> String:
	if unit == null or unit.is_defeated:
		return "当前单位无法使用。"
	if not can_use(unit, item_data):
		return "当前没有可治疗的伤口或可恢复的数值。"
	return ""


static func apply(unit: Unit, item_data: Dictionary) -> Dictionary:
	var battle_use: Dictionary = item_data.get("battle_use", {})
	var result := {
		"healed": 0,
		"restored_ap": 0,
		"removed_statuses": [],
	}
	if unit == null or battle_use.is_empty():
		return result
	if bool(battle_use.get("heal_full", false)):
		result["healed"] = unit.heal(unit.max_hp)
	elif int(battle_use.get("heal", 0)) > 0:
		result["healed"] = unit.heal(int(battle_use.get("heal", 0)))
	if int(battle_use.get("restore_ap", 0)) > 0:
		var before_ap := unit.action_points
		unit.action_points = mini(unit.get_current_ap_limit(), unit.action_points + int(battle_use.get("restore_ap", 0)))
		result["restored_ap"] = unit.action_points - before_ap
	for effect_id in battle_use.get("remove_statuses", []):
		if unit.remove_status(str(effect_id)):
			(result["removed_statuses"] as Array).append({"id": str(effect_id), "stacks": -1})
	for effect_id in (battle_use.get("remove_status_stacks", {}) as Dictionary):
		var removed := unit.remove_status_stacks(str(effect_id), int((battle_use.get("remove_status_stacks", {}) as Dictionary)[effect_id]))
		if removed > 0:
			(result["removed_statuses"] as Array).append({"id": str(effect_id), "stacks": removed})
	return result
