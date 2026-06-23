extends Node

const SLOT_COUNT: int = 10
const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save.res"

var _providers: Array[SaveProvider] = []
var current_data: SaveData = null

func register_provider(provider: SaveProvider) -> void:
	_providers.append(provider)

func save(slot_id: int) -> void:
	var data = SaveData.new()
	data.slot_id = slot_id
	data.timestamp = Time.get_datetime_string_from_system()
	for provider in _providers:
		provider.write_to(data)
	var dir_path = SAVE_DIR + "slot_%d/" % slot_id
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path = dir_path + SAVE_FILE
	ResourceSaver.save(data, path)
	current_data = data

func load(slot_id: int) -> SaveData:
	var path = _get_slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return null
	var data = ResourceLoader.load(path)
	if data == null:
		return null
	if data.version < SaveData.CURRENT_VERSION:
		data = _migrate(data)
	for provider in _providers:
		provider.read_from(data)
	current_data = data
	return data

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
	return data

func _build_summary(data: SaveData) -> Dictionary:
	var summary = {}
	if data.player:
		summary["level"] = data.player.level
	return summary
