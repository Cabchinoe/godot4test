class_name BattleFog
extends Node

const TILE_SIZE := Vector2i(64, 64)
const FADE_DURATION := 0.25

var layers: Dictionary = {}
var mask_cache := FogMaskCache.new()
var generation_jobs_per_frame := 2
var generation_budget_usec := 2000
var _level_manager: LevelManager
var _fog_exempt_cells: Array[Vector3i]
var _densities: Dictionary = {}
var _immediate_clear: Dictionary = {}
var _states: Dictionary = {}
var _animating: Dictionary = {}
var _revision := 0
var _initialized := false
var _last_canvas_transform := Transform2D.IDENTITY
var _last_viewport_size := Vector2.ZERO
var _view_rect := Rect2()
var _last_dirty_count := 0


func _init(level_manager: LevelManager, fog_exempt_cells: Array[Vector3i] = []) -> void:
	_level_manager = level_manager
	_fog_exempt_cells = fog_exempt_cells.duplicate()
	name = "BattleFog"
	mask_cache.texture_ready.connect(_on_texture_ready)
	for level in level_manager.get_all_levels():
		var ground := level_manager.get_layer(level, "ground")
		var hud := level_manager.get_layer(level, "hud")
		var fog := Node2D.new()
		fog.name = "FogOfWar"
		fog.z_as_relative = false
		fog.z_index = hud.z_index + 1
		ground.add_child(fog)
		layers[level] = fog


func refresh(visibility: BattleVisibility) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var field := FogNeighborhood.build_render_densities(_level_manager, visibility, tree, _fog_exempt_cells)
	var current: Dictionary = field["densities"]
	var dirty := FogNeighborhood.dirty_neighborhood(_densities, current)
	_densities = current
	_immediate_clear = field["immediate_clear"]
	_last_dirty_count = dirty.size()
	if is_inside_tree():
		_update_view_rect()
		_sync_visible_cells(dirty)
	_initialized = true


func _process(delta: float) -> void:
	var viewport := get_viewport()
	if (
		viewport.get_canvas_transform() != _last_canvas_transform
		or viewport.get_visible_rect().size != _last_viewport_size
	):
		_update_view_rect()
		_sync_visible_cells()
	mask_cache.process_generation_budget(generation_jobs_per_frame, generation_budget_usec)
	_advance_transitions(delta)


func _update_view_rect() -> void:
	var viewport := get_viewport()
	_last_canvas_transform = viewport.get_canvas_transform()
	_last_viewport_size = viewport.get_visible_rect().size
	var inverse := _last_canvas_transform.affine_inverse()
	var corners := [
		inverse * Vector2.ZERO, inverse * Vector2(_last_viewport_size.x, 0.0),
		inverse * _last_viewport_size, inverse * Vector2(0.0, _last_viewport_size.y),
	]
	_view_rect = Rect2(corners[0], Vector2.ZERO)
	for corner in corners:
		_view_rect = _view_rect.expand(corner)
	_view_rect = _view_rect.grow(float(TILE_SIZE.x))


func _cell_world_position(cell: Vector3i) -> Vector2:
	var ground := _level_manager.get_layer(cell.z, "ground")
	return ground.to_global(ground.map_to_local(Vector2i(cell.x, cell.y)))


func _is_in_view(cell: Vector3i) -> bool:
	return _view_rect.has_point(_cell_world_position(cell))


func _sync_visible_cells(dirty: Dictionary = {}) -> void:
	for cell in _states.keys():
		if not _is_in_view(cell):
			_remove_cell(cell)
	for cell in _densities:
		if int(_densities[cell]) <= 0 or not _is_in_view(cell):
			continue
		if not _states.has(cell) or dirty.has(cell):
			_update_cell(cell, _initialized and dirty.has(cell))
	for cell in dirty:
		if _states.has(cell) and int(_densities.get(cell, 0)) == 0:
			_update_cell(cell, _initialized and not _immediate_clear.has(cell))


func _update_cell(cell: Vector3i, animate: bool) -> void:
	if int(_densities.get(cell, 0)) == 0:
		if not _states.has(cell):
			return
		var state: Dictionary = _states[cell]
		if state["target_key"] == "clear":
			if not animate:
				_remove_cell(cell)
			return
		_revision += 1
		state["revision"] = _revision
		state["target_key"] = "clear"
		mask_cache.cancel_request(cell)
		_apply_entry(cell, mask_cache.transparent, int(state["display_transform"]), animate)
		return
	var descriptor := FogNeighborhood.canonicalize(FogNeighborhood.collect_samples(_densities, cell))
	if descriptor.is_empty():
		push_error("BattleFog: invalid density neighborhood at %s" % cell)
		return
	var key := mask_cache.get_key(descriptor)
	var transform_index := int(descriptor["transform"])
	if _states.has(cell):
		var previous: Dictionary = _states[cell]
		if previous["target_key"] == key and int(previous["target_transform"]) == transform_index:
			return
	else:
		var sprite := Sprite2D.new()
		var ground := _level_manager.get_layer(cell.z, "ground")
		sprite.position = ground.map_to_local(Vector2i(cell.x, cell.y))
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		(layers[cell.z] as Node2D).add_child(sprite)
		_states[cell] = {
			"cell": cell,
			"sprite": sprite, "entry": mask_cache.transparent, "display_transform": 0,
			"target_key": "", "target_transform": 0, "revision": 0,
			"transition": "", "frame_step": -1, "step": 0, "elapsed": 0.0,
			"pending_initial": not animate,
		}
	_revision += 1
	var state: Dictionary = _states[cell]
	state["target_key"] = key
	state["target_transform"] = transform_index
	state["revision"] = _revision
	state["pending_initial"] = not animate
	var priority := _cell_world_position(cell).distance_squared_to(_view_rect.get_center())
	var entry := mask_cache.request(descriptor, cell, _revision, priority)
	if not entry.is_empty():
		_apply_entry(cell, entry, transform_index, animate)
	elif state["entry"]["key"] == "clear":
		var placeholder := mask_cache.uniform_placeholder(descriptor)
		if not placeholder.is_empty():
			_apply_entry(cell, placeholder, transform_index, animate)


func _on_texture_ready(entry: Dictionary, subscribers: Dictionary) -> void:
	for cell in subscribers:
		if not _states.has(cell):
			continue
		var state: Dictionary = _states[cell]
		if int(state["revision"]) != int(subscribers[cell]) or state["target_key"] != entry["key"]:
			continue
		_apply_entry(cell, entry, int(state["target_transform"]), not bool(state["pending_initial"]))


func _apply_entry(cell: Vector3i, entry: Dictionary, transform_index: int, animate: bool) -> void:
	var state: Dictionary = _states[cell]
	var previous: Dictionary = state["entry"]
	var previous_transform := int(state["display_transform"])
	_stop_transition(state)
	if not animate or (previous["hash"] == entry["hash"] and previous_transform == transform_index):
		_set_display(state, entry, transform_index)
		if entry["key"] == "clear":
			_remove_cell(cell)
		return
	state["transition"] = mask_cache.begin_transition(previous, previous_transform, entry, transform_index)
	state["destination"] = entry
	state["destination_transform"] = transform_index
	state["elapsed"] = 0.0
	state["step"] = 0
	state["frame_step"] = -1
	_animating[cell] = true


func _set_display(state: Dictionary, entry: Dictionary, transform_index: int) -> void:
	var sprite := state["sprite"] as Sprite2D
	var inverse := FogNeighborhood.inverse_transform(transform_index)
	sprite.texture = entry["texture"]
	sprite.rotation = float(inverse % 4) * PI * 0.5
	sprite.flip_h = inverse >= 4
	sprite.modulate.a = 1.0
	state["entry"] = entry
	state["display_transform"] = transform_index


func _advance_transitions(delta: float) -> void:
	for cell in _animating.keys():
		var state: Dictionary = _states[cell]
		var key := str(state["transition"])
		if key.is_empty():
			continue
		state["elapsed"] = float(state["elapsed"]) + delta
		var step := mini(
			FogMaskCache.TRANSITION_STEPS,
			floori(float(state["elapsed"]) / FADE_DURATION * float(FogMaskCache.TRANSITION_STEPS))
		)
		if step <= int(state["step"]):
			continue
		state["step"] = step
		if step >= FogMaskCache.TRANSITION_STEPS:
			var target: Dictionary = state["destination"]
			var target_transform := int(state["destination_transform"])
			_stop_transition(state)
			_set_display(state, target, target_transform)
			if target["key"] == "clear":
				_remove_cell(cell)
		else:
			var frame := mask_cache.get_transition_frame(key, step)
			mask_cache.release_transition_frame(key, int(state["frame_step"]))
			state["frame_step"] = step
			_set_display(state, frame, int(state["destination_transform"]))


func _stop_transition(state: Dictionary) -> void:
	var key := str(state["transition"])
	if key.is_empty():
		return
	mask_cache.release_transition_frame(key, int(state["frame_step"]))
	mask_cache.end_transition(key)
	_animating.erase(state["cell"])
	state["transition"] = ""
	state["frame_step"] = -1


func _remove_cell(cell: Vector3i) -> void:
	if not _states.has(cell):
		return
	mask_cache.cancel_request(cell)
	var state: Dictionary = _states[cell]
	_stop_transition(state)
	var sprite := state["sprite"] as Sprite2D
	if is_instance_valid(sprite):
		sprite.queue_free()
	_states.erase(cell)


func get_stats() -> Dictionary:
	var result := mask_cache.get_stats()
	result["visible_nodes"] = _states.size()
	result["last_dirty_cells"] = _last_dirty_count
	return result


func _exit_tree() -> void:
	for cell in _states.keys():
		_remove_cell(cell)
	mask_cache.clear_all()
	for layer in layers.values():
		if is_instance_valid(layer):
			layer.queue_free()
	layers.clear()
