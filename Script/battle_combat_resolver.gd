class_name BattleCombatResolver
extends RefCounted

const LOCATION_MULTIPLIERS := {
	"head": 1.6,
	"body": 1.0,
	"limb": 0.7,
}

var _rng := RandomNumberGenerator.new()


func _init() -> void:
	_rng.randomize()


func begin_turn(unit: Unit) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if unit == null or unit.is_defeated:
		return events

	unit.start_turn()
	for effect_variant in unit.get_status_effects():
		var effect := effect_variant as BattleStatusEffect
		if effect == null:
			continue
		if effect.periodic_damage > 0:
			var damage := effect.periodic_damage * effect.stack_count
			var dealt := unit.receive_damage(damage, {
				"kind": "injury_damage",
				"effect_id": effect.effect_id,
				"source": effect.source_name,
			})
			events.append({
				"kind": "injury_damage",
				"target": unit.unit_name,
				"effect": effect.display_name,
				"damage": dealt,
			})
		if unit.is_defeated:
			break
		if effect.periodic_heal > 0:
			var healed := unit.heal(effect.periodic_heal * effect.stack_count)
			events.append({
				"kind": "status_heal",
				"target": unit.unit_name,
				"effect": effect.display_name,
				"heal": healed,
			})

	if not unit.is_defeated:
		var expired := unit.advance_status_effects()
		for effect_name in expired:
			events.append({"kind": "status_expired", "target": unit.unit_name, "effect": effect_name})
	return events


func resolve_attack(attacker: Unit, defender: Unit) -> Dictionary:
	var result := {
		"attacker": attacker.unit_name if attacker else "",
		"defender": defender.unit_name if defender else "",
		"hit": false,
		"location": "",
		"damage": 0,
		"raw_damage": 0,
		"absorbed": 0,
		"remaining_armor": 0,
		"statuses": [],
		"injury_checks": [],
		"hit_formula": {},
		"damage_formula": {},
		"protection": {},
		"attacker_snapshot": {},
		"defender_snapshot": {},
	}
	if attacker == null or defender == null or attacker.is_defeated or defender.is_defeated:
		return result
	result["attacker_snapshot"] = attacker.get_combat_log_snapshot()
	result["defender_snapshot"] = defender.get_combat_log_snapshot()

	var distance := maxi(
		1,
		maxi(
			absi(attacker.grid_pos.x - defender.grid_pos.x),
			absi(attacker.grid_pos.y - defender.grid_pos.y)
		)
	)
	var distance_profile := attacker.get_attack_distance_profile(distance)
	var hit_chance := clampi(
		int(distance_profile.get("accuracy", attacker.get_attack_accuracy()))
			- defender.get_effective_evasion(),
		20,
		95
	)
	var hit_roll := _rng.randi_range(1, 100)
	var distance_base_accuracy := int(distance_profile.get("base_accuracy", distance_profile.get("accuracy", 0)))
	var accuracy_bonus := int(distance_profile.get("accuracy_bonus", 0))
	result["hit_chance"] = hit_chance
	result["distance"] = distance
	result["distance_damage_multiplier"] = float(distance_profile.get("damage_multiplier", 1.0))
	result["roll"] = hit_roll
	result["hit_formula"] = {
		"distance_base_accuracy": distance_base_accuracy,
		"attacker_accuracy_bonus": accuracy_bonus,
		"defender_evasion": defender.get_effective_evasion(),
		"final_hit_chance": hit_chance,
		"roll": hit_roll,
	}
	if hit_roll > hit_chance:
		return result

	result["hit"] = true
	var location := _roll_hit_location(attacker.get_hit_location_indices())
	var multiplier := float(LOCATION_MULTIPLIERS.get(location, 1.0))
	var attack_power := attacker.get_attack_power()
	var distance_damage := maxi(1, roundi(float(attack_power) * float(distance_profile.get("damage_multiplier", 1.0))))
	var raw_damage := maxi(
		1,
		roundi(float(distance_damage) * multiplier)
	)
	var protection := defender.absorb_damage_at_location(location, raw_damage)
	var final_damage := raw_damage - int(protection.get("absorbed", 0))
	var dealt := defender.receive_damage(final_damage, {
		"kind": "attack",
		"attacker": attacker.unit_name,
		"location": location,
		"raw_damage": raw_damage,
		"absorbed": int(protection.get("absorbed", 0)),
	})

	result["location"] = location
	result["raw_damage"] = raw_damage
	result["damage"] = dealt
	result["absorbed"] = int(protection.get("absorbed", 0))
	result["remaining_armor"] = int(protection.get("remaining_armor", 0))
	result["defeated"] = defender.is_defeated
	result["protection"] = protection.duplicate(true)
	result["damage_formula"] = {
		"attack_power_total": attack_power,
		"distance_multiplier": float(distance_profile.get("damage_multiplier", 1.0)),
		"damage_after_distance": distance_damage,
		"location": location,
		"location_multiplier": multiplier,
		"raw_damage": raw_damage,
		"absorbed": int(protection.get("absorbed", 0)),
		"final_hp_damage": dealt,
		"remaining_armor": int(protection.get("remaining_armor", 0)),
	}

	var unprotected_hit := not bool(protection.get("had_protection", false)) or (
		bool(protection.get("depleted", false)) and dealt > 0
	)
	result["damage_formula"]["unprotected_hit"] = unprotected_hit
	if not defender.is_defeated and dealt > 0 and unprotected_hit:
		var injury_result := _apply_unprotected_debuffs(attacker, defender, location)
		result["statuses"] = injury_result["applied"]
		result["injury_checks"] = injury_result["checks"]
	return result


func _roll_hit_location(indices: Dictionary) -> String:
	var head := maxi(0, int(indices.get("head", 0)))
	var body := maxi(0, int(indices.get("body", 0)))
	var limb := maxi(0, int(indices.get("limb", 0)))
	var total := head + body + limb
	if total <= 0:
		return "body"
	var roll := _rng.randi_range(1, total)
	if roll <= head:
		return "head"
	if roll <= head + body:
		return "body"
	return "limb"


func _apply_unprotected_debuffs(attacker: Unit, defender: Unit, location: String) -> Dictionary:
	var applied: Array[Dictionary] = []
	var checks: Array[Dictionary] = []
	for profile in attacker.get_unprotected_debuffs():
		var locations: Array = profile.get("locations", [])
		if not locations.has(location):
			continue
		var chance := clampi(int(profile.get("chance", 0)), 0, 100)
		var roll := _rng.randi_range(1, 100)
		var triggered := chance > 0 and roll <= chance
		var check := {
			"id": str(profile.get("id", "")),
			"chance": chance,
			"roll": roll,
			"triggered": triggered,
			"location": location,
		}
		checks.append(check)
		if not triggered:
			continue
		var effect := defender.add_status(str(profile.get("id", "")), attacker.unit_name)
		if not effect.is_empty():
			applied.append(effect)
	return {"applied": applied, "checks": checks}
