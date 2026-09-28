class_name BattlefieldPerception
extends RefCounted


func find_target(actor: Unit) -> Unit:
	if actor == null or actor.is_defeated or actor.pathfinder == null:
		return null
	var perception := _get_perception_config(actor)
	if perception.is_empty():
		return null
	var mode := str(perception.get("mode", ""))
	var range := maxi(0, int(perception.get("range", 0)))
	if mode not in ["path_ap", "manhattan", "chebyshev"] or range <= 0:
		return null
	var allow_cross_level := bool(perception.get("allow_cross_level", false))
	var candidates: Array[Dictionary] = []
	var tree := actor.get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("units"):
		var candidate := node as Unit
		if candidate == null or candidate == actor or candidate.is_defeated or candidate.faction == actor.faction:
			continue
		var distance := _get_distance(actor, candidate, mode, range, allow_cross_level)
		if distance >= 0:
			candidates.append({"unit": candidate, "distance": distance})
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		return int(first["distance"]) < int(second["distance"])
	)
	return candidates[0]["unit"] as Unit


func _get_perception_config(actor: Unit) -> Dictionary:
	if not (actor.ai_config.get("perception", {}) is Dictionary):
		return {}
	return (actor.ai_config.get("perception", {}) as Dictionary).duplicate(true)


func _get_distance(actor: Unit, target: Unit, mode: String, range: int, allow_cross_level: bool) -> int:
	if not allow_cross_level and actor.current_level != target.current_level:
		return -1
	match mode:
		"path_ap":
			var path := actor.pathfinder.find_path(
				actor.grid_pos,
				actor.current_level,
				target.grid_pos,
				target.current_level,
				target
			)
			if path.is_empty():
				return -1
			var steps := path.size() - 1
			return steps if steps <= range else -1
		"manhattan":
			var manhattan := absi(actor.grid_pos.x - target.grid_pos.x) + absi(actor.grid_pos.y - target.grid_pos.y)
			return manhattan if manhattan <= range else -1
		"chebyshev":
			var chebyshev := maxi(absi(actor.grid_pos.x - target.grid_pos.x), absi(actor.grid_pos.y - target.grid_pos.y))
			return chebyshev if chebyshev <= range else -1
	return -1
