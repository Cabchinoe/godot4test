class_name PlayerSaveProvider
extends SaveProvider

var _unit: Unit

func _init(unit: Unit) -> void:
	_unit = unit

func write_to(data: SaveData) -> void:
	if data.player == null:
		data.player = PlayerSaveData.new()
	data.player.level = _unit.level if "level" in _unit else 1
	data.player.move_range = _unit.move_range

func read_from(data: SaveData) -> void:
	if data.player == null:
		return
	_unit.move_range = data.player.move_range
	if "level" in _unit:
		_unit.level = data.player.level

func get_provider_name() -> String:
	return "PlayerSaveProvider"
