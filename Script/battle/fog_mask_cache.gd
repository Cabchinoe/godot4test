class_name FogMaskCache
extends RefCounted

signal texture_ready(entry: Dictionary, subscribers: Dictionary)

const CAPACITY := 2048
const TRANSITION_STEPS := 6
const TRANSITION_FRAME_BUDGET := 64

var generator := FogMaskGenerator.new()
var entries: Dictionary = {}
var pending: Dictionary = {}
var transitions: Dictionary = {}
var capacity: int
var transparent: Dictionary
var stats := {
	"hits": 0, "misses": 0, "generations": 0, "generation_usec": 0,
	"max_generation_usec": 0, "pending_peak": 0, "capacity_errors": 0,
	"transition_creations": 0, "transition_frame_peak": 0,
	"transition_budget_exceeded": 0,
}
var _queue: Array[String] = []
var _pending_cells: Dictionary = {}
var _failed: Dictionary = {}
var _transition_frames := 0


func _init(max_entries: int = CAPACITY) -> void:
	capacity = max_entries
	var alpha := PackedByteArray()
	alpha.resize(FogMaskGenerator.PIXELS)
	transparent = {"key": "clear", "alpha": alpha, "hash": alpha.hex_encode().sha256_text(), "texture": null}


func get_key(descriptor: Dictionary) -> String:
	return generator.recipe_id + "|" + str(descriptor["key"])


func request(descriptor: Dictionary, cell: Vector3i, revision: int, priority: float = 0.0) -> Dictionary:
	var key := get_key(descriptor)
	cancel_request(cell)
	if entries.has(key):
		stats["hits"] += 1
		return entries[key]
	if _failed.has(key):
		return {}
	if pending.has(key):
		pending[key]["subscribers"][cell] = revision
		pending[key]["priority"] = minf(float(pending[key]["priority"]), priority)
		_pending_cells[cell] = key
		return {}
	if not _reserve_key(key):
		return {}
	stats["misses"] += 1
	if bool(descriptor["uniform"]):
		return _produce(descriptor)
	pending[key] = {"descriptor": descriptor, "subscribers": {cell: revision}, "priority": priority}
	_pending_cells[cell] = key
	_queue.append(key)
	stats["pending_peak"] = maxi(int(stats["pending_peak"]), pending.size())
	return {}


func uniform_placeholder(descriptor: Dictionary) -> Dictionary:
	var samples: PackedByteArray = descriptor["samples"]
	var code := FogNeighborhood.mask_code(int(descriptor["shape_mask"]))
	var placeholder := {
		"key": "u:%s:%d" % [code, samples[0]], "shape_mask": descriptor["shape_mask"],
		"samples": samples, "uniform": true,
	}
	var key := get_key(placeholder)
	if entries.has(key):
		return entries[key]
	if not _reserve_key(key):
		return {}
	return _produce(placeholder)


func _reserve_key(key: String) -> bool:
	if entries.size() + pending.size() < capacity:
		return true
	if not _failed.has(key):
		_failed[key] = true
		stats["capacity_errors"] += 1
		push_error("FogMaskCache: capacity %d exceeded; check canonical keys and recipe." % capacity)
	return false


func cancel_request(cell: Vector3i) -> void:
	if not _pending_cells.has(cell):
		return
	var key: String = _pending_cells[cell]
	_pending_cells.erase(cell)
	if pending.has(key):
		pending[key]["subscribers"].erase(cell)


func process_generation_budget(max_jobs: int = 2, max_usec: int = 2000) -> int:
	if _queue.is_empty() or max_jobs <= 0:
		return 0
	var started := Time.get_ticks_usec()
	var processed := 0
	_queue.sort_custom(func(first: String, second: String) -> bool:
		return float(pending[first]["priority"]) < float(pending[second]["priority"])
	)
	while not _queue.is_empty() and processed < max_jobs:
		if processed > 0 and max_usec > 0 and Time.get_ticks_usec() - started >= max_usec:
			break
		var key: String = _queue.pop_front()
		var job: Dictionary = pending[key]
		pending.erase(key)
		var subscribers: Dictionary = job["subscribers"]
		for cell in subscribers:
			if _pending_cells.get(cell, "") == key:
				_pending_cells.erase(cell)
		var entry := _produce(job["descriptor"])
		processed += 1
		texture_ready.emit(entry, subscribers)
	return processed


func _produce(descriptor: Dictionary) -> Dictionary:
	var started := Time.get_ticks_usec()
	var alpha := generator.generate_alpha(descriptor)
	var key := get_key(descriptor)
	var entry := _make_entry(key, alpha)
	entries[key] = entry
	var elapsed := Time.get_ticks_usec() - started
	stats["generations"] += 1
	stats["generation_usec"] += elapsed
	stats["max_generation_usec"] = maxi(int(stats["max_generation_usec"]), elapsed)
	return entry


func _make_entry(key: String, alpha: PackedByteArray) -> Dictionary:
	return {
		"key": key, "alpha": alpha, "hash": alpha.hex_encode().sha256_text(),
		"texture": ImageTexture.create_from_image(generator.make_image(alpha)),
	}


func begin_transition(previous: Dictionary, previous_transform: int, target: Dictionary, target_transform: int) -> String:
	var relative := FogNeighborhood.compose_transforms(target_transform, FogNeighborhood.inverse_transform(previous_transform))
	var key := "%s|%s|%d" % [previous["hash"], target["hash"], relative]
	if transitions.has(key):
		transitions[key]["users"] += 1
		return key
	transitions[key] = {
		"users": 1, "source_alpha": FogNeighborhood.transform_alpha(previous["alpha"], relative),
		"target": target, "frames": {},
	}
	return key


func get_transition_frame(key: String, step: int) -> Dictionary:
	var transition: Dictionary = transitions[key]
	if step >= TRANSITION_STEPS:
		return transition["target"]
	var frames: Dictionary = transition["frames"]
	if frames.has(step):
		frames[step]["references"] += 1
		return frames[step]["entry"]
	var fraction := (1.0 - cos(PI * float(step) / float(TRANSITION_STEPS))) * 0.5
	var alpha := generator.blend_alpha(transition["source_alpha"], transition["target"]["alpha"], fraction)
	var entry := _make_entry("transition:%s:%d" % [key, step], alpha)
	frames[step] = {"references": 1, "entry": entry}
	_transition_frames += 1
	stats["transition_creations"] += 1
	stats["transition_frame_peak"] = maxi(int(stats["transition_frame_peak"]), _transition_frames)
	if _transition_frames > TRANSITION_FRAME_BUDGET:
		stats["transition_budget_exceeded"] += 1
	return entry


func release_transition_frame(key: String, step: int) -> void:
	if step < 0 or not transitions.has(key):
		return
	var frames: Dictionary = transitions[key]["frames"]
	if not frames.has(step):
		return
	frames[step]["references"] -= 1
	if int(frames[step]["references"]) <= 0:
		frames.erase(step)
		_transition_frames -= 1


func end_transition(key: String) -> void:
	if not transitions.has(key):
		return
	transitions[key]["users"] -= 1
	if int(transitions[key]["users"]) <= 0:
		_transition_frames -= (transitions[key]["frames"] as Dictionary).size()
		transitions.erase(key)


func get_stats() -> Dictionary:
	var result := stats.duplicate()
	result["entries"] = entries.size()
	result["pending"] = pending.size()
	result["shapes"] = generator.shapes.size()
	result["transition_frames"] = _transition_frames
	result["active_transition_groups"] = transitions.size()
	result["estimated_pixel_bytes"] = (
		(entries.size() + _transition_frames) * FogMaskGenerator.PIXELS * 5
		+ generator.shapes.size() * FogMaskGenerator.PIXELS
	)
	return result


func clear_all() -> void:
	entries.clear()
	pending.clear()
	_queue.clear()
	_pending_cells.clear()
	_failed.clear()
	transitions.clear()
	generator.shapes.clear()
	_transition_frames = 0
