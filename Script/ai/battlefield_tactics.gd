class_name BattlefieldTactics
extends RefCounted

var bullet_range: BulletRange
var _random := RandomNumberGenerator.new()


func _init(p_bullet_range: BulletRange) -> void:
	bullet_range = p_bullet_range
	_random.randomize()


func patrol(actor: Unit) -> void:
	if actor == null or actor.is_defeated or actor.action_points <= 0:
		return
	var patrol_budget := _random.randi_range(0, actor.action_points)
	if patrol_budget <= 0:
		return
	var reachable := actor.pathfinder.bfs(actor.grid_pos, actor.current_level, patrol_budget, actor)
	var candidates: Array[Dictionary] = []
	for node in reachable:
		if node["grid"] != actor.grid_pos or node["level"] != actor.current_level:
			candidates.append(node)
	if candidates.is_empty():
		return
	var destination: Dictionary = candidates[_random.randi_range(0, candidates.size() - 1)]
	var path := actor.pathfinder.find_path(
		actor.grid_pos,
		actor.current_level,
		destination["grid"],
		destination["level"],
		actor
	)
	await move_along_path(actor, path, actor.action_points)


func find_attack_path(actor: Unit, target: Unit) -> Array[Dictionary]:
	if actor == null or target == null or bullet_range == null:
		return []
	var best: Array[Dictionary] = []
	for dy in range(-actor.get_attack_range(), actor.get_attack_range() + 1):
		for dx in range(-actor.get_attack_range(), actor.get_attack_range() + 1):
			if dx == 0 and dy == 0:
				continue
			var goal := target.grid_pos + Vector2i(dx, dy)
			if not actor.pathfinder.is_walkable(goal, target.current_level, actor):
				continue
			if not bullet_range.can_reach_cell(
				goal,
				target.current_level,
				target.grid_pos,
				target.current_level,
				actor.get_attack_range()
			):
				continue
			var path := actor.pathfinder.find_path(
				actor.grid_pos,
				actor.current_level,
				goal,
				target.current_level,
				actor
			)
			if path.is_empty():
				continue
			if best.is_empty() or path.size() < best.size():
				best = path
	return best


func retreat(actor: Unit, threat: Unit) -> void:
	if actor == null or threat == null or actor.is_defeated or actor.action_points <= 0:
		return
	var reachable := actor.pathfinder.bfs(actor.grid_pos, actor.current_level, actor.action_points, actor)
	var safe_candidates: Array[Dictionary] = []
	var all_candidates: Array[Dictionary] = []
	for node in reachable:
		if node["grid"] == actor.grid_pos and node["level"] == actor.current_level:
			continue
		var path := actor.pathfinder.find_path(
			actor.grid_pos,
			actor.current_level,
			node["grid"],
			node["level"],
			actor
		)
		if path.is_empty():
			continue
		var candidate := {
			"node": node,
			"path": path,
			"distance": _chebyshev_distance(node["grid"], threat.grid_pos),
			"steps": path.size() - 1,
		}
		all_candidates.append(candidate)
		if not _is_in_threat_gun_line(threat, node):
			safe_candidates.append(candidate)
	var candidates := safe_candidates if not safe_candidates.is_empty() else all_candidates
	if candidates.is_empty():
		return
	var selected := _select_farthest_candidate(candidates)
	var selected_path: Array[Dictionary] = selected["path"]
	await move_along_path(actor, selected_path, actor.action_points)


func move_along_path(actor: Unit, path: Array[Dictionary], max_steps: int) -> int:
	if actor == null or actor.is_defeated or path.size() <= 1 or max_steps <= 0:
		return 0
	var steps := mini(max_steps, path.size() - 1)
	if steps <= 0 or not actor.spend_ap(steps):
		return 0
	var move_path: Array[Dictionary] = path.slice(0, steps + 1)
	actor.set_move_path(move_path)
	if actor.is_moving:
		await actor.movement_finished
	return steps


func _is_in_threat_gun_line(threat: Unit, node: Dictionary) -> bool:
	if bullet_range == null:
		return false
	return bullet_range.can_reach_cell(
		threat.grid_pos,
		threat.current_level,
		node["grid"],
		node["level"],
		threat.get_attack_range()
	)


func _select_farthest_candidate(candidates: Array[Dictionary]) -> Dictionary:
	var best_distance := -1
	var best_steps := -1
	var tied: Array[Dictionary] = []
	for candidate in candidates:
		var distance := int(candidate["distance"])
		var steps := int(candidate["steps"])
		if distance > best_distance or (distance == best_distance and steps > best_steps):
			best_distance = distance
			best_steps = steps
			tied = [candidate]
		elif distance == best_distance and steps == best_steps:
			tied.append(candidate)
	return tied[_random.randi_range(0, tied.size() - 1)]


func _chebyshev_distance(first: Vector2i, second: Vector2i) -> int:
	return maxi(absi(first.x - second.x), absi(first.y - second.y))
