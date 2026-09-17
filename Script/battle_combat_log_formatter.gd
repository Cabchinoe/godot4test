class_name BattleCombatLogFormatter
extends RefCounted


static func format_attack(result: Dictionary) -> String:
	var lines: Array[String] = []
	var attacker: Dictionary = result.get("attacker_snapshot", {}) as Dictionary
	var defender: Dictionary = result.get("defender_snapshot", {}) as Dictionary
	var attacker_name := str(attacker.get("unit_name", result.get("attacker", "未知")))
	var defender_name := str(defender.get("unit_name", result.get("defender", "未知")))
	lines.append("========== 攻击结算 ==========")
	lines.append("攻击方：%s（%s）" % [attacker_name, _faction_name(str(attacker.get("faction", "")))])
	_append_attacker_sources(lines, attacker)
	_append_statuses(lines, "攻击方状态", attacker.get("statuses", []))
	var totals: Dictionary = attacker.get("totals", {}) as Dictionary
	lines.append("攻击方总数值：攻击力 %d；命中附加 %d；部位指数 %s；本回合移动 %d 格（命中惩罚 %d）" % [
		int(totals.get("attack_power", 0)),
		int(totals.get("accuracy_bonus", 0)),
		_format_indices(totals.get("hit_location_indices", {})),
		int(totals.get("movement_steps", 0)),
		int(totals.get("movement_accuracy_penalty", 0)),
	])
	lines.append("防御方：%s（%s）" % [defender_name, _faction_name(str(defender.get("faction", "")))])
	_append_statuses(lines, "防御方状态", defender.get("statuses", []))
	var defender_stats: Dictionary = defender.get("base_stats", {}) as Dictionary
	lines.append("防御方防护：%s；闪避 %d。" % [
		_format_protection(defender.get("protection", {})),
		int(defender_stats.get("evasion", 0)),
	])

	var hit_formula: Dictionary = result.get("hit_formula", {}) as Dictionary
	lines.append("命中计算：距离 %d 格；距离档基础命中 %d + 攻击方附加 %d - 移动惩罚 %d - 防御方闪避 %d = 最终命中 %d（掷骰 %d）。" % [
		int(result.get("distance", 0)),
		int(hit_formula.get("distance_base_accuracy", 0)),
		int(hit_formula.get("attacker_accuracy_bonus", 0)),
		int(hit_formula.get("movement_penalty", 0)),
		int(hit_formula.get("defender_evasion", 0)),
		int(hit_formula.get("final_hit_chance", result.get("hit_chance", 0))),
		int(hit_formula.get("roll", result.get("roll", 0))),
	])
	if not bool(result.get("hit", false)):
		lines.append("结果：未命中，本次不造成伤害。")
		return "\n".join(lines)

	var damage_formula: Dictionary = result.get("damage_formula", {}) as Dictionary
	lines.append("命中部位：%s（部位系数 ×%.2f）。" % [
		_location_name(str(damage_formula.get("location", result.get("location", "")))),
		float(damage_formula.get("location_multiplier", 1.0)),
	])
	lines.append("伤害计算：总攻击 %d × 距离系数 %.2f = %d；再 × 部位系数 %.2f = 原始伤害 %d。" % [
		int(damage_formula.get("attack_power_total", 0)),
		float(damage_formula.get("distance_multiplier", 1.0)),
		int(damage_formula.get("damage_after_distance", 0)),
		float(damage_formula.get("location_multiplier", 1.0)),
		int(damage_formula.get("raw_damage", result.get("raw_damage", 0))),
	])
	lines.append("护具结算：本次吸收 %d；剩余护具值 %d；HP 实际伤害 %d；%s。" % [
		int(damage_formula.get("absorbed", result.get("absorbed", 0))),
		int(damage_formula.get("remaining_armor", result.get("remaining_armor", 0))),
		int(damage_formula.get("final_hp_damage", result.get("damage", 0))),
		"本次为无护具/护具耗尽命中，进入伤口判定" if bool(damage_formula.get("unprotected_hit", false)) else "本次未进入伤口判定",
	])
	_append_injury_checks(lines, result.get("injury_checks", []))
	lines.append("结果：" + ("防御方被击败。" if bool(result.get("defeated", false)) else "命中完成。"))
	return "\n".join(lines)


static func _append_attacker_sources(lines: Array[String], snapshot: Dictionary) -> void:
	var character: Dictionary = snapshot.get("character", {}) as Dictionary
	if not character.is_empty():
		var profile: Dictionary = character.get("combat_profile", {}) as Dictionary
		lines.append("干员：%s；伤害修正 %d；命中修正 %d；基础部位指数 %s。" % [
			str(character.get("name", "未知干员")),
			int(profile.get("damage_flat", 0)),
			int(profile.get("accuracy_bonus", 0)),
			_format_indices(profile.get("hit_location_indices", {})),
		])
	var weapon: Dictionary = snapshot.get("weapon", {}) as Dictionary
	if not weapon.is_empty():
		lines.append("武器：%s；基础攻击 %d；武器部位指数 %s；伤口候选 %s。" % [
			str(weapon.get("name", "未装备武器")),
			int(weapon.get("attack_power", 0)),
			_format_indices(weapon.get("hit_location_indices", {})),
			_format_debuffs(weapon.get("unprotected_debuffs", [])),
		])
	var attachments: Array = snapshot.get("attachments", []) as Array
	if attachments.is_empty():
		lines.append("配件：无。")
		return
	var texts: Array[String] = []
	for attachment_variant in attachments:
		if not (attachment_variant is Dictionary):
			continue
		var attachment: Dictionary = attachment_variant as Dictionary
		texts.append("%s（数值 %s；部位指数 %s）" % [
			str(attachment.get("name", "未知配件")),
			_format_modifiers(attachment.get("stat_modifiers", {})),
			_format_indices(attachment.get("hit_location_indices", {})),
		])
	lines.append("配件：" + "；".join(texts))


static func _append_statuses(lines: Array[String], title: String, status_value: Variant) -> void:
	var statuses: Array = status_value as Array if status_value is Array else []
	if statuses.is_empty():
		lines.append("%s：无。" % title)
		return
	var texts: Array[String] = []
	for status_variant in statuses:
		if not (status_variant is Dictionary):
			continue
		var status: Dictionary = status_variant as Dictionary
		var duration := "永久" if bool(status.get("permanent", false)) else "%d 回合" % int(status.get("remaining_turns", 0))
		texts.append("%s ×%d（%s）" % [
			str(status.get("name", status.get("id", "状态"))),
			int(status.get("stack_count", 1)),
			duration,
		])
	lines.append("%s：%s。" % [title, "；".join(texts)])


static func _append_injury_checks(lines: Array[String], check_value: Variant) -> void:
	var checks: Array = check_value as Array if check_value is Array else []
	if checks.is_empty():
		return
	var texts: Array[String] = []
	for check_variant in checks:
		if not (check_variant is Dictionary):
			continue
		var check: Dictionary = check_variant as Dictionary
		texts.append("%s：概率 %d，掷骰 %d，%s" % [
			_status_name(str(check.get("id", ""))),
			int(check.get("chance", 0)),
			int(check.get("roll", 0)),
			"触发" if bool(check.get("triggered", false)) else "未触发",
		])
	lines.append("伤口判定：" + "；".join(texts) + "。")


static func _format_indices(value: Variant) -> String:
	var indices: Dictionary = value as Dictionary if value is Dictionary else {}
	return "头 %d / 身 %d / 肢 %d" % [
		int(indices.get("head", 0)),
		int(indices.get("body", 0)),
		int(indices.get("limb", 0)),
	]


static func _format_modifiers(value: Variant) -> String:
	if not (value is Dictionary) or (value as Dictionary).is_empty():
		return "无"
	var modifiers: Dictionary = value as Dictionary
	var texts: Array[String] = []
	for key in modifiers:
		texts.append("%s %+d" % [_modifier_name(str(key)), int(modifiers[key])])
	return "，".join(texts)


static func _format_debuffs(value: Variant) -> String:
	var profiles: Array = value as Array if value is Array else []
	if profiles.is_empty():
		return "无"
	var texts: Array[String] = []
	for profile_variant in profiles:
		if not (profile_variant is Dictionary):
			continue
		var profile: Dictionary = profile_variant as Dictionary
		texts.append("%s %d%%" % [_status_name(str(profile.get("id", ""))), int(profile.get("chance", 0))])
	return "，".join(texts) if not texts.is_empty() else "无"


static func _format_protection(value: Variant) -> String:
	var protection: Dictionary = value as Dictionary if value is Dictionary else {}
	if protection.has("helmet") or protection.has("armor"):
		var helmet: Dictionary = protection.get("helmet", {}) as Dictionary
		var armor: Dictionary = protection.get("armor", {}) as Dictionary
		return "头盔 %s %d/%d（单次 %d）；护甲 %s %d/%d（单次 %d）" % [
			str(helmet.get("name", "未装备")),
			int(helmet.get("current_armor", 0)),
			int(helmet.get("max_armor", 0)),
			int(helmet.get("per_hit_absorb", 0)),
			str(armor.get("name", "未装备")),
			int(armor.get("current_armor", 0)),
			int(armor.get("max_armor", 0)),
			int(armor.get("per_hit_absorb", 0)),
		]
	return "头部 %d（单次 %d）；身体 %d（单次 %d）" % [
		int(protection.get("head_current", 0)),
		int(protection.get("head_per_hit_absorb", 0)),
		int(protection.get("body_current", 0)),
		int(protection.get("body_per_hit_absorb", 0)),
	]


static func _modifier_name(key: String) -> String:
	return {"accuracy": "命中", "attack_power": "攻击"}.get(key, key)


static func _status_name(effect_id: String) -> String:
	return {"bleeding": "流血", "fractured": "骨折"}.get(effect_id, effect_id)


static func _location_name(location: String) -> String:
	return {"head": "头部", "body": "身体", "limb": "四肢"}.get(location, location)


static func _faction_name(faction: String) -> String:
	return {"player": "玩家", "enemy": "敌方"}.get(faction, faction)
