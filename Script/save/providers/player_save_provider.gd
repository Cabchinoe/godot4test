class_name PlayerSaveProvider
extends SaveProvider

var _player: Player

func _init(player: Player) -> void:
	_player = player

func write_to(data: SaveData) -> void:
	if data.player == null:
		data.player = PlayerSaveData.new()
	_player.write_save_data(data.player)

func read_from(data: SaveData) -> void:
	if data.player == null:
		data.player = PlayerSaveData.new()
		_player.write_save_data(data.player)
		return
	_player.apply_save_data(data.player)

func get_provider_name() -> String:
	return "PlayerSaveProvider"
