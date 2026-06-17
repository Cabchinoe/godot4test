class_name LevelManager

var levels: Dictionary = {}

func _init():
	pass

func add_level(level: int, ground: TileMapLayer, obstacle: TileMapLayer, hud: TileMapLayer, y_offset: int = 0):
	levels[level] = {
		"ground": ground,
		"obstacle": obstacle,
		"hud": hud,
		"y_offset": y_offset
	}

func get_layer(level: int, type: String) -> TileMapLayer:
	if not levels.has(level):
		return null
	return levels[level].get(type, null)

func get_offset(level: int) -> int:
	if not levels.has(level):
		return 0
	return levels[level]["y_offset"]

func get_all_levels() -> Array[int]:
	var result: Array[int] = []
	for level in levels.keys():
		result.append(level)
	result.sort()
	return result

func get_max_level() -> int:
	var max_level = 0
	for level in levels.keys():
		if level > max_level:
			max_level = level
	return max_level
