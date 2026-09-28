class_name EnemyAI

const BATTLEFIELD_PERCEPTION_SCRIPT := preload("res://Script/ai/battlefield_perception.gd")
const BATTLEFIELD_TACTICS_SCRIPT := preload("res://Script/ai/battlefield_tactics.gd")

var bullet_range: BulletRange
var combat_resolver: BattleCombatResolver
var perception
var tactics
var _random := RandomNumberGenerator.new()


func _init(p_bullet_range: BulletRange, p_combat_resolver: BattleCombatResolver) -> void:
	bullet_range = p_bullet_range
	combat_resolver = p_combat_resolver
	perception = BATTLEFIELD_PERCEPTION_SCRIPT.new()
	tactics = BATTLEFIELD_TACTICS_SCRIPT.new(bullet_range)
	_random.randomize()


func run_turn(enemy: Unit) -> void:
	if enemy == null or enemy.is_defeated:
		return
	var target: Unit = perception.find_target(enemy)
	if target == null:
		await tactics.patrol(enemy)
		return
	if _should_retreat(enemy):
		print("[EnemyAI] %s 触发回撤。" % enemy.unit_name)
		await tactics.retreat(enemy, target)
		return
	if not _can_attack(enemy, target):
		var attack_path: Array[Dictionary] = tactics.find_attack_path(enemy, target)
		if attack_path.is_empty():
			return
		await tactics.move_along_path(enemy, attack_path, enemy.action_points)
	while _try_attack(enemy, target):
		pass


func _should_retreat(enemy: Unit) -> bool:
	if enemy == null or enemy.max_hp <= 0:
		return false
	var retreat: Variant = enemy.ai_config.get("retreat", {})
	if not (retreat is Dictionary):
		return false
	var retreat_config := retreat as Dictionary
	if not bool(retreat_config.get("enabled", false)):
		return false
	var hp_ratio_threshold := clampf(float(retreat_config.get("hp_ratio_threshold", 0.0)), 0.0, 1.0)
	if float(enemy.current_hp) / float(enemy.max_hp) >= hp_ratio_threshold:
		return false
	var trigger_chance := clampf(float(retreat_config.get("trigger_chance", 0.0)), 0.0, 1.0)
	return _random.randf() < trigger_chance


func _can_attack(enemy: Unit, target: Unit) -> bool:
	if enemy == null or target == null or enemy.is_defeated or target.is_defeated or bullet_range == null:
		return false
	return bullet_range.can_reach_cell(
		enemy.grid_pos,
		enemy.current_level,
		target.grid_pos,
		target.current_level,
		enemy.get_attack_range()
	)


func _try_attack(enemy: Unit, target: Unit) -> bool:
	if enemy == null or target == null or enemy.action_points < enemy.get_attack_cost() or target.is_defeated:
		return false
	if combat_resolver == null or not _can_attack(enemy, target):
		return false
	if not enemy.spend_ap(enemy.get_attack_cost()):
		return false
	var result := combat_resolver.resolve_attack(enemy, target)
	print(BattleCombatLogFormatter.format_attack(result))
	print("[敌方攻击 JSON] ", result)
	return not enemy.is_defeated and not target.is_defeated
