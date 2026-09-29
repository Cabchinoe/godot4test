class_name EnemyActionPlan
extends RefCounted

var target: Unit
var steps: Array[Dictionary] = []


func add_move(path: Array[Dictionary], max_steps: int) -> void:
	if path.size() <= 1 or max_steps <= 0:
		return
	var planned_steps := mini(max_steps, path.size() - 1)
	steps.append({
		"kind": &"move",
		"path": path.slice(0, planned_steps + 1),
		"max_steps": planned_steps,
	})


func add_attack(target_unit: Unit) -> void:
	if target_unit == null:
		return
	target = target_unit
	steps.append({"kind": &"attack", "target": target_unit})


func add_wait() -> void:
	steps.append({"kind": &"wait"})


func has_move() -> bool:
	return steps.any(func(step: Dictionary) -> bool: return step.get("kind", &"") == &"move")
