class_name Unit
extends Node2D

signal movement_finished
signal damaged(result: Dictionary)
signal defeated(unit)
signal status_effects_changed

@export var sprite_frames: SpriteFrames
@export var animation_idle: StringName = &"idle"
@export var animation_walk: StringName = &"walk"
@export var animation_aim: StringName = &"aim"

var unit_name: String = ""
var faction: String = ""
var ap_max: int = 5
var pathfinder: Pathfinder
var level_manager: LevelManager

var max_hp: int = 100
var current_hp: int = 100
var base_attack_power: int = 20
var base_damage_flat: int = 0
var base_accuracy: int = 75
var base_evasion: int = 0
var base_attack_range: int = 1
var base_attack_cost: int = 1
var base_hit_location_indices: Dictionary = {"head": 0, "body": 100, "limb": 0}
var base_unprotected_debuffs: Array[Dictionary] = []
var head_armor: int = 0
var body_armor: int = 0
var head_per_hit_absorb: int = 0
var body_per_hit_absorb: int = 0
var loot_container_data: Dictionary = {}
var is_defeated: bool = false
var status_effects: Array = []

var grid_pos: Vector2i = Vector2i.ZERO
var current_level: int = 1
var move_path: Array[Dictionary] = []
var move_timer: float = 0.0
var move_interval: float = 0.15
var is_moving: bool = false
var action_points: int = 0


func _ready() -> void:
	_apply_sprite_frames()
	_set_default_frame()


func _apply_sprite_frames() -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite and sprite_frames:
		sprite.sprite_frames = sprite_frames


func _set_default_frame() -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_idle):
		sprite.animation = animation_idle
		sprite.frame = 0
		sprite.stop()


func configure_appearance(
	p_frames: SpriteFrames,
	p_idle: StringName = &"idle",
	p_walk: StringName = &"walk",
	p_aim: StringName = &"aim"
) -> void:
	sprite_frames = p_frames
	animation_idle = p_idle
	animation_walk = p_walk
	animation_aim = p_aim
	_apply_sprite_frames()
	_set_default_frame()


func play_idle() -> void:
	_play(animation_idle)


func play_walk() -> void:
	_play(animation_walk)


func play_aim() -> void:
	_play(animation_aim)


func stop_walk(reset_frame: bool = true) -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite and sprite.animation == animation_walk:
		sprite.stop()
		if reset_frame:
			sprite.frame = 0


func stop_all(reset_frame: bool = true) -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite:
		sprite.stop()
		if reset_frame:
			if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_idle):
				sprite.animation = animation_idle
			sprite.frame = 0


func _play(animation_name: StringName) -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite:
		sprite.play(animation_name)


func init_unit(p_name: String, p_faction: String, p_ap_max: int, p_level_manager: LevelManager, p_start_level: int = 1) -> void:
	unit_name = p_name
	faction = p_faction
	ap_max = p_ap_max
	action_points = ap_max
	max_hp = maxi(1, max_hp)
	current_hp = clampi(current_hp, 1, max_hp)
	level_manager = p_level_manager
	current_level = p_start_level
	pathfinder = Pathfinder.new(level_manager)
	_update_z_index()
	add_to_group("units")
	add_to_group(faction)


func _update_z_index() -> void:
	var obstacle := level_manager.get_layer(current_level, "obstacle")
	if obstacle:
		z_index = obstacle.z_index + 1


func configure_combat(data: Dictionary) -> void:
	max_hp = maxi(1, int(data.get("max_hp", max_hp)))
	current_hp = max_hp
	base_attack_power = maxi(1, int(data.get("attack_power", base_attack_power)))
	base_damage_flat = int(data.get("damage_flat", base_damage_flat))
	base_accuracy = clampi(int(data.get("accuracy", base_accuracy)), 5, 100)
	base_evasion = clampi(int(data.get("evasion", base_evasion)), 0, 95)
	base_attack_range = maxi(1, int(data.get("attack_range", base_attack_range)))
	base_attack_cost = maxi(0, int(data.get("attack_cost", base_attack_cost)))
	base_hit_location_indices = _normalize_hit_location_indices(data.get("hit_location_indices", base_hit_location_indices))
	base_unprotected_debuffs = _normalize_debuffs(data.get("unprotected_debuffs", []))
	head_armor = maxi(0, int(data.get("head_armor", head_armor)))
	body_armor = maxi(0, int(data.get("body_armor", data.get("armor", body_armor))))
	head_per_hit_absorb = maxi(0, int(data.get("head_per_hit_absorb", head_armor)))
	body_per_hit_absorb = maxi(0, int(data.get("body_per_hit_absorb", body_armor)))
	loot_container_data = (data.get("drop_container", {}) as Dictionary).duplicate(true)


func start_turn() -> void:
	if is_defeated:
		return
	action_points = get_current_ap_limit()


func get_current_ap_limit() -> int:
	return maxi(0, ap_max + get_status_modifier("ap_delta"))


func spend_ap(cost: int) -> bool:
	if not is_defeated and cost >= 0 and action_points >= cost:
		action_points -= cost
		return true
	return false


func get_attack_range() -> int:
	return maxi(1, base_attack_range)


func get_attack_cost() -> int:
	return maxi(0, base_attack_cost)


func get_attack_power() -> int:
	return maxi(1, base_attack_power + base_damage_flat + get_status_modifier("attack_power"))


func get_attack_accuracy() -> int:
	return base_accuracy + get_status_modifier("accuracy")


func get_attack_distance_profile(distance: int) -> Dictionary:
	return {
		"distance": maxi(1, distance),
		"damage_multiplier": 1.0,
		"accuracy": get_attack_accuracy(),
		"base_accuracy": base_accuracy,
		"accuracy_bonus": get_status_modifier("accuracy"),
	}


func get_effective_evasion() -> int:
	return clampi(base_evasion + get_status_modifier("evasion"), 0, 95)


func get_hit_location_indices() -> Dictionary:
	return base_hit_location_indices.duplicate(true)


func get_unprotected_debuffs() -> Array[Dictionary]:
	return base_unprotected_debuffs.duplicate(true)


func get_combat_log_snapshot() -> Dictionary:
	var effect_list: Array[Dictionary] = []
	for effect_variant in get_status_effects():
		var effect := effect_variant as BattleStatusEffect
		if effect:
			effect_list.append(effect.to_dictionary())
	return {
		"unit_name": unit_name,
		"faction": faction,
		"base_stats": {
			"attack_power": base_attack_power,
			"damage_flat": base_damage_flat,
			"accuracy": base_accuracy,
			"evasion": get_effective_evasion(),
			"attack_range": base_attack_range,
		},
		"totals": {
			"attack_power": get_attack_power(),
			"accuracy_bonus": get_attack_accuracy(),
			"hit_location_indices": get_hit_location_indices(),
		},
		"statuses": effect_list,
		"protection": {
			"head_current": head_armor,
			"head_per_hit_absorb": head_per_hit_absorb,
			"body_current": body_armor,
			"body_per_hit_absorb": body_per_hit_absorb,
		},
	}


func absorb_damage_at_location(location: String, raw_damage: int) -> Dictionary:
	var current_armor := 0
	var per_hit_absorb := 0
	match location:
		"head":
			current_armor = head_armor
			per_hit_absorb = head_per_hit_absorb
		"body":
			current_armor = body_armor
			per_hit_absorb = body_per_hit_absorb
	var had_protection := current_armor > 0
	var absorbed := mini(mini(maxi(0, raw_damage), current_armor), per_hit_absorb)
	var remaining := current_armor - absorbed
	match location:
		"head":
			head_armor = remaining
		"body":
			body_armor = remaining
	return {
		"location": location,
		"had_protection": had_protection,
		"absorbed": absorbed,
		"remaining_armor": remaining,
		"depleted": had_protection and remaining == 0,
	}


func receive_damage(amount: int, result: Dictionary = {}) -> int:
	if is_defeated:
		return 0
	var damage := maxi(0, amount)
	current_hp = maxi(0, current_hp - damage)
	var payload := result.duplicate(true)
	payload["damage"] = damage
	payload["current_hp"] = current_hp
	payload["max_hp"] = max_hp
	damaged.emit(payload)
	if current_hp <= 0:
		is_defeated = true
		is_moving = false
		move_path.clear()
		defeated.emit(self)
	return damage


func heal(amount: int) -> int:
	if is_defeated:
		return 0
	var old_hp := current_hp
	current_hp = clampi(current_hp + maxi(0, amount), 0, max_hp)
	return current_hp - old_hp


func add_status(effect_id: String, source_name: String = "") -> Dictionary:
	var definition := BattleStatusDB.get_definition(effect_id)
	if definition.is_empty() or is_defeated:
		return {}
	for effect_variant in status_effects:
		var effect := effect_variant as BattleStatusEffect
		if effect and effect.effect_id == effect_id:
			effect.add_application(definition, source_name)
			status_effects_changed.emit()
			return effect.to_dictionary()
	var new_effect := BattleStatusEffect.new(definition, source_name)
	status_effects.append(new_effect)
	status_effects_changed.emit()
	return new_effect.to_dictionary()


func remove_status(effect_id: String) -> bool:
	return remove_status_stacks(effect_id, 0x7fffffff) > 0


func remove_status_stacks(effect_id: String, max_stacks: int = 1) -> int:
	if max_stacks <= 0:
		return 0
	for index in range(status_effects.size() - 1, -1, -1):
		var effect := status_effects[index] as BattleStatusEffect
		if effect and effect.effect_id == effect_id:
			var removed := mini(effect.stack_count, max_stacks)
			effect.stack_count -= removed
			if effect.stack_count <= 0:
				status_effects.remove_at(index)
			status_effects_changed.emit()
			return removed
	return 0


func has_status(effect_id: String) -> bool:
	for effect_variant in status_effects:
		var effect := effect_variant as BattleStatusEffect
		if effect and effect.effect_id == effect_id:
			return true
	return false


func get_status_effects() -> Array:
	return status_effects.duplicate()


func get_status_modifier(key: String) -> int:
	var total := 0
	for effect_variant in status_effects:
		var effect := effect_variant as BattleStatusEffect
		if effect:
			total += effect.get_modifier(key)
	return total


func advance_status_effects() -> Array[String]:
	var expired: Array[String] = []
	for index in range(status_effects.size() - 1, -1, -1):
		var effect := status_effects[index] as BattleStatusEffect
		if effect and effect.tick_down():
			expired.append(effect.display_name)
			status_effects.remove_at(index)
	if not expired.is_empty():
		status_effects_changed.emit()
	return expired


func _normalize_hit_location_indices(value: Variant) -> Dictionary:
	var indices: Dictionary = value as Dictionary if value is Dictionary else {}
	return {
		"head": maxi(0, int(indices.get("head", 0))),
		"body": maxi(0, int(indices.get("body", 0))),
		"limb": maxi(0, int(indices.get("limb", 0))),
	}


func _normalize_debuffs(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not (value is Array):
		return result
	for entry in value:
		if not (entry is Dictionary):
			continue
		var source := entry as Dictionary
		var effect_id := str(source.get("id", ""))
		if effect_id.is_empty():
			continue
		var locations: Array[String] = []
		for location in source.get("locations", []):
			var location_name := str(location)
			if location_name in ["head", "body", "limb"] and not locations.has(location_name):
				locations.append(location_name)
		if locations.is_empty():
			continue
		result.append({
			"id": effect_id,
			"chance": clampi(int(source.get("chance", 0)), 0, 100),
			"locations": locations,
		})
	return result


func _process(delta: float) -> void:
	if not is_defeated and is_moving and move_path.size() > 0:
		move_timer += delta
		if move_timer >= move_interval:
			move_timer = 0.0
			_step_to_next()


func _step_to_next() -> void:
	if move_path.size() == 0:
		if is_moving:
			is_moving = false
			stop_walk()
			movement_finished.emit()
		return
	var next_node: Dictionary = move_path.pop_front()
	grid_pos = next_node["grid"]
	current_level = next_node["level"]

	var ground := level_manager.get_layer(current_level, "ground")
	var local := ground.map_to_local(grid_pos)
	var world_pos := ground.to_global(local)
	world_pos.y += level_manager.get_offset(current_level)
	var sprite = get_node("Sprite2D")
	var sprite_offset = sprite.offset * scale
	global_position = world_pos - sprite_offset
	_update_z_index()
	if move_path.size() == 0:
		is_moving = false
		stop_walk()
		movement_finished.emit()


func set_move_path(path: Array[Dictionary]) -> void:
	move_path = path
	move_timer = 0.0
	if move_path.size() > 0 and move_path[0]["grid"] == grid_pos and move_path[0]["level"] == current_level:
		move_path.pop_front()
	if move_path.size() == 0:
		is_moving = false
		stop_walk()
		movement_finished.emit()
		return
	is_moving = true
	play_walk()
