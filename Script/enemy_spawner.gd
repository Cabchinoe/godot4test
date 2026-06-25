class_name EnemySpawner

var level_manager: LevelManager
var enemies_container: Node2D

func _init(p_level_manager: LevelManager, p_enemies_container: Node2D) -> void:
	level_manager = p_level_manager
	enemies_container = p_enemies_container

func spawn(id: String, grid: Vector2i, level: int) -> Unit:
	var data: Dictionary = EnemyDB.get_enemy(id)
	if data.is_empty():
		return null

	var sprite_frames: SpriteFrames = load(data["sprite_frames_path"])
	if sprite_frames == null:
		push_warning("EnemySpawner: failed to load sprite_frames: %s" % data["sprite_frames_path"])
		return null

	var enemy := Unit.new()
	enemy.name = "%s_%d" % [id, enemies_container.get_child_count()]

	var sprite := AnimatedSprite2D.new()
	sprite.name = "Sprite2D"
	sprite.sprite_frames = sprite_frames
	sprite.animation = "walk"
	sprite.offset = Vector2(32, 32)
	enemy.add_child(sprite)

	enemies_container.add_child(enemy)
	enemy.init_unit(data["name"], "enemy", int(data["ap_max"]), level_manager, level)
	enemy.grid_pos = grid
	_align_to_grid(enemy)
	return enemy

func spawn_batch(rules: Array) -> Array[Unit]:
	var result: Array[Unit] = []
	var occupied: Dictionary = {}

	# 收集 player 已占格
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		for u in tree.get_nodes_in_group("units"):
			occupied[_key(u.grid_pos, u.current_level)] = true

	var pathfinder := Pathfinder.new(level_manager)
	for rule in rules:
		var id: String = rule["id"]
		var grid: Vector2i = rule["grid"]
		var level: int = rule["level"]
		var k := _key(grid, level)
		if occupied.has(k):
			push_warning("EnemySpawner: grid %s lv%d already occupied, skip" % [grid, level])
			continue
		if not pathfinder.is_walkable(grid, level):
			push_warning("EnemySpawner: grid %s lv%d not walkable, skip" % [grid, level])
			continue
		var enemy := spawn(id, grid, level)
		if enemy:
			occupied[k] = true
			result.append(enemy)
	return result

func _align_to_grid(unit: Unit) -> void:
	var ground = level_manager.get_layer(unit.current_level, "ground")
	if ground == null:
		return
	var local = ground.map_to_local(unit.grid_pos)
	var world_pos = ground.to_global(local)
	world_pos.y += level_manager.get_offset(unit.current_level)
	var sprite = unit.get_node("Sprite2D")
	var sprite_offset = sprite.offset * unit.scale
	unit.global_position = world_pos - sprite_offset

func _key(grid: Vector2i, level: int) -> String:
	return "%d_%d_%d" % [grid.x, grid.y, level]
