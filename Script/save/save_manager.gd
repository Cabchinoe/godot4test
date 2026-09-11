extends Node

const SLOT_COUNT: int = 10
const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save.res"

var _providers: Array[SaveProvider] = []
var current_data: SaveData = null
var current_slot_id: int = -1

func register_provider(provider: SaveProvider) -> void:
	if _providers.has(provider):
		return
	_providers.append(provider)
	if current_data:
		provider.read_from(current_data)

func unregister_provider(provider: SaveProvider) -> void:
	_providers.erase(provider)

func save(slot_id: int) -> void:
	var data := current_data if current_data else SaveData.new()
	data.slot_id = slot_id
	data.timestamp = Time.get_datetime_string_from_system()
	for provider in _providers:
		provider.write_to(data)
	_write_data(slot_id, data)
	current_data = data
	current_slot_id = slot_id

func save_current() -> bool:
	if current_data == null or current_slot_id < 0:
		return false
	current_data.timestamp = Time.get_datetime_string_from_system()
	for provider in _providers:
		provider.write_to(current_data)
	return _write_data(current_slot_id, current_data) == OK

func load(slot_id: int, force_reload: bool = false) -> SaveData:
	return _load_slot(slot_id, force_reload)

func _load_slot(slot_id: int, force_reload: bool = false) -> SaveData:
	var path = _get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return null
	var cache_mode := ResourceLoader.CACHE_MODE_REPLACE if force_reload else ResourceLoader.CACHE_MODE_REUSE
	var data := ResourceLoader.load(path, "", cache_mode) as SaveData
	if data == null:
		return null
	if data.version < SaveData.CURRENT_VERSION:
		data = _migrate(data)
	for provider in _providers:
		provider.read_from(data)
	current_data = data
	current_slot_id = slot_id
	return data

func reload_current() -> SaveData:
	if current_slot_id < 0:
		return current_data
	return _load_slot(current_slot_id, true)

func create_new_game() -> SaveData:
	current_data = SaveData.new()
	current_slot_id = -1
	return current_data

func delete_slot(slot_id: int) -> void:
	var dir_path = SAVE_DIR + "slot_%d" % slot_id
	if not DirAccess.dir_exists_absolute(dir_path):
		return
	var dir = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			dir.remove(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	DirAccess.remove_absolute(dir_path)
	if current_slot_id == slot_id:
		current_data = null
		current_slot_id = -1

func slot_exists(slot_id: int) -> bool:
	return FileAccess.file_exists(_get_slot_path(slot_id))

func list_slots() -> Array:
	var slots: Array = []
	for i in SLOT_COUNT:
		if slot_exists(i):
			var data = ResourceLoader.load(_get_slot_path(i))
			if data:
				var summary = _build_summary(data)
				slots.append(SlotInfo.new(i, true, data.timestamp, data.days, summary))
			else:
				slots.append(SlotInfo.new(i, false))
		else:
			slots.append(SlotInfo.new(i, false))
	return slots

func has_current_data() -> bool:
	return current_data != null

func _get_slot_path(slot_id: int) -> String:
	return SAVE_DIR + "slot_%d/" % slot_id + SAVE_FILE

func _migrate(data: SaveData) -> SaveData:
	if data.version < 2:
		if data.player == null:
			data.player = PlayerSaveData.new()
		else:
			data.player.operator_id = "benny"
			data.player.operator_level = clampi(data.player.level, 1, 60)
			data.player.version = PlayerSaveData.CURRENT_VERSION
		data.version = 2
	if data.version < 3:
		if data.player == null:
			data.player = PlayerSaveData.new()
		else:
			var saved_level := data.player.operator_level if data.player.operator_level > 0 else data.player.level
			data.player.operator_level = clampi(saved_level, 1, 60)
			data.player.level = data.player.operator_level
			data.player.version = PlayerSaveData.CURRENT_VERSION
		data.version = 3
	return data

func _build_summary(data: SaveData) -> Dictionary:
	var summary = {}
	if data.player:
		summary["level"] = data.player.operator_level
	return summary

func _write_data(slot_id: int, data: SaveData) -> Error:
	var dir_path = SAVE_DIR + "slot_%d/" % slot_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	return ResourceSaver.save(data, dir_path + SAVE_FILE)
