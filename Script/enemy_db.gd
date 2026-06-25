extends Node

var _enemies: Dictionary = {}

func load_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("EnemyDB: file not found: ", path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		print("EnemyDB: JSON parse error: ", json.get_error_message())
		return
	var data = json.data
	if not data is Array:
		print("EnemyDB: JSON root must be an array")
		return
	for entry in data:
		if _validate_entry(entry):
			_enemies[entry["id"]] = entry
	print("EnemyDB: loaded ", _enemies.size(), " enemies")

func _validate_entry(entry: Dictionary) -> bool:
	if not entry.has("id") or not entry.has("name") or not entry.has("ap_max") or not entry.has("sprite_frames_path"):
		print("EnemyDB: entry missing required fields: ", entry)
		return false
	return true

func get_enemy(id: String) -> Dictionary:
	if not _enemies.has(id):
		push_warning("EnemyDB: enemy id not found: %s" % id)
		return {}
	return _enemies[id]

func get_all_ids() -> Array:
	return _enemies.keys()
