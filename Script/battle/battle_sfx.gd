class_name BattleSfx
extends RefCounted

const BINDINGS_PATH := "res://conf/battle/sfx_bindings.json"
const AUDIO_BASE := "res://Art/audio/sfx/"
const AUDIO_EXT := ".mp3"
const POOL_MAX := 8

var _bindings: Dictionary = {}
var _debug_enabled := false
var _host: Node = null
var _pool: Array[AudioStreamPlayer] = []
var _audio_bus: StringName = &"Master"


func _init(debug_enabled: bool = false, host: Node = null, audio_bus: StringName = &"SFX") -> void:
	_bindings = _load_bindings()
	_debug_enabled = debug_enabled
	_host = host
	_audio_bus = audio_bus if _has_bus(audio_bus) else &"Master"


func play(cue: StringName, context: Dictionary = {}) -> void:
	var resolved: String = resolve_binding(cue, context)
	if _debug_enabled:
		print("[BattleSfx] %s -> %s" % [cue, resolved])
	if resolved.is_empty():
		return
	if _host == null:
		# 没注入 host(常见于纯 debug 模式),仅打印
		return
	var path := AUDIO_BASE + resolved + AUDIO_EXT
	if not ResourceLoader.exists(path):
		push_warning("BattleSfx: missing audio %s" % path)
		return
	var stream: Resource = load(path)
	if stream == null:
		return
	var player := _acquire_player()
	if player == null:
		return
	player.stream = stream as AudioStream
	player.bus = _audio_bus
	player.play()


func resolve_binding(cue: StringName, context: Dictionary = {}) -> String:
	var cue_name := str(cue)
	var weapon_id := str(context.get("weapon_id", ""))
	if not weapon_id.is_empty():
		var weapon_bindings: Variant = (_bindings.get("weapons", {}) as Dictionary).get(weapon_id, {})
		if weapon_bindings is Dictionary and (weapon_bindings as Dictionary).has(cue_name):
			return str((weapon_bindings as Dictionary).get(cue_name, ""))
	var attacker := context.get("attacker") as Unit
	if attacker:
		var unit_key := attacker.cutin_art_key
		var unit_bindings: Variant = (_bindings.get("units", {}) as Dictionary).get(unit_key, {})
		if unit_bindings is Dictionary and (unit_bindings as Dictionary).has(cue_name):
			return str((unit_bindings as Dictionary).get(cue_name, ""))
	return str((_bindings.get("default", {}) as Dictionary).get(cue_name, ""))


func _load_bindings() -> Dictionary:
	if not FileAccess.file_exists(BINDINGS_PATH):
		return {}
	var file := FileAccess.open(BINDINGS_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).duplicate(true) if parsed is Dictionary else {}


func _acquire_player() -> AudioStreamPlayer:
	for p in _pool:
		if is_instance_valid(p) and not p.playing:
			return p
	if _pool.size() >= POOL_MAX:
		return null
	var fresh := AudioStreamPlayer.new()
	fresh.bus = _audio_bus
	_host.add_child(fresh)
	_pool.append(fresh)
	return fresh


func _has_bus(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(String(bus_name)) >= 0