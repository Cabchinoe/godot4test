class_name EnemyAI

const BATTLEFIELD_PERCEPTION_SCRIPT := preload("res://Script/ai/battlefield_perception.gd")
const BATTLEFIELD_TACTICS_SCRIPT := preload("res://Script/ai/battlefield_tactics.gd")

var bullet_range: BulletRange
var combat_resolver: BattleCombatResolver
var perception
var tactics
var battle_presentation: BattlePresentation
var _random := RandomNumberGenerator.new()


func _init(p_bullet_range: BulletRange, p_combat_resolver: BattleCombatResolver) -> void:
	bullet_range = p_bullet_range
	combat_resolver = p_combat_resolver
	perception = BATTLEFIELD_PERCEPTION_SCRIPT.new()
	tactics = BATTLEFIELD_TACTICS_SCRIPT.new(bullet_range)
	_random.randomize()


func set_battle_presentation(presentation: BattlePresentation) -> void:
	battle_presentation = presentation


func run_turn(enemy: Unit) -> void:
	var plan := decide_turn(enemy)
	await execute_plan(enemy, plan)


func decide_turn(enemy: Unit) -> EnemyActionPlan:
	var plan := EnemyActionPlan.new()
	if enemy == null or enemy.is_defeated:
		return plan
	var target: Unit = perception.find_target(enemy)
	if target == null:
		var patrol: Dictionary = tactics.plan_patrol(enemy)
		if not patrol.is_empty():
			plan.add_move(patrol["path"], int(patrol["max_steps"]))
		else:
			plan.add_wait()
		return plan
	if _should_retreat(enemy):
		print("[EnemyAI] %s 触发回撤。" % enemy.unit_name)
		var retreat: Dictionary = tactics.plan_retreat(enemy, target)
		if not retreat.is_empty():
			plan.add_move(retreat["path"], int(retreat["max_steps"]))
		else:
			plan.add_wait()
		return plan
	if not _can_attack(enemy, target):
		var attack_path: Array[Dictionary] = tactics.find_attack_path(enemy, target)
		if attack_path.is_empty():
			plan.add_wait()
			return plan
		plan.add_move(attack_path, enemy.action_points)
	plan.add_attack(target)
	return plan


func execute_plan(enemy: Unit, plan: EnemyActionPlan) -> void:
	if enemy == null or plan == null or enemy.is_defeated:
		return
	for step in plan.steps:
		await execute_step(enemy, step)


func execute_step(enemy: Unit, step: Dictionary) -> void:
	if enemy == null or enemy.is_defeated:
		return
	match step.get("kind", &""):
		&"move":
			var path: Array[Dictionary] = step.get("path", [])
			await tactics.execute_move(enemy, path, int(step.get("max_steps", 0)))
		&"attack":
			var target := step.get("target") as Unit
			await _execute_attack_sequence(enemy, target)


func _execute_attack_sequence(enemy: Unit, target: Unit) -> void:
	if enemy == null or target == null or target.is_defeated:
		return
	var presentation_session_open := battle_presentation != null and enemy.action_points >= enemy.get_attack_cost() and _can_attack(enemy, target)
	if presentation_session_open:
		await battle_presentation.begin_session(enemy)
	while true:
		var continue_attacking := await _try_attack(enemy, target, presentation_session_open)
		if not continue_attacking:
			break
	if presentation_session_open:
		await battle_presentation.end_session()


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


func _try_attack(enemy: Unit, target: Unit, use_presentation: bool) -> bool:
	if enemy == null or target == null or enemy.action_points < enemy.get_attack_cost() or target.is_defeated:
		return false
	if combat_resolver == null or not _can_attack(enemy, target):
		return false
	if not enemy.spend_ap(enemy.get_attack_cost()):
		return false
	var result: Dictionary
	if battle_presentation and use_presentation:
		result = await battle_presentation.play_attack_round(enemy, target)
	else:
		result = combat_resolver.resolve_attack(enemy, target)
	print(BattleCombatLogFormatter.format_attack(result))
	print("[敌方攻击 JSON] ", result)
	return not enemy.is_defeated and not target.is_defeated
