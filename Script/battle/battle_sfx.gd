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

# 人声通道:全局唯一一条语音播放器。
# 角色台词走独立通道(不占 SFX 池),新台词开始时自动掐断上一条,
# 避免连点触发时语音叠加。static 让所有 BattleSfx 实例共用同一条通道。
static var _voice_player: AudioStreamPlayer = null


func _init(debug_enabled: bool = false, host: Node = null, audio_bus: StringName = &"SFX") -> void:
	_bindings = _load_bindings()
	_debug_enabled = debug_enabled
	_host = host
	_audio_bus = audio_bus if _has_bus(audio_bus) else &"Master"


func play(cue: StringName, context: Dictionary = {}) -> AudioStreamPlayer:
	var resolved: String = resolve_binding(cue, context)
	if _debug_enabled:
		print("[BattleSfx] %s -> %s" % [cue, resolved])
	if resolved.is_empty():
		return null
	if _host == null:
		# 没注入 host(常见于纯 debug 模式),仅打印
		return null
	var path := AUDIO_BASE + resolved + AUDIO_EXT
	if not ResourceLoader.exists(path):
		push_warning("BattleSfx: missing audio %s" % path)
		return null
	var stream: Resource = load(path)
	if stream == null:
		return null
	var player := _acquire_player()
	if player == null:
		return null
	player.stream = stream as AudioStream
	player.bus = _audio_bus
	player.volume_db = 0.0
	player.play()
	return player


func play_optional(cue: StringName, context: Dictionary = {}) -> AudioStreamPlayer:
	var resolved: String = resolve_binding(cue, context)
	if resolved.is_empty():
		return null
	var path := AUDIO_BASE + resolved + AUDIO_EXT
	if not ResourceLoader.exists(path):
		return null
	return play(cue, context)


# 播放角色语音。占用独立的人声通道:先掐断当前正在播的上一条语音,再播新的。
# 文件缺失时静默跳过(返回 null),不刷 warning。
func play_voice(cue: StringName, context: Dictionary = {}) -> AudioStreamPlayer:
	var resolved: String = resolve_binding(cue, context)
	if resolved.is_empty():
		return null
	if _debug_enabled:
		print("[BattleSfx] voice %s -> %s" % [cue, resolved])
	var path := AUDIO_BASE + resolved + AUDIO_EXT
	if not ResourceLoader.exists(path):
		return null
	var player := _ensure_voice_player()
	if player == null:
		return null
	var stream: Resource = load(path)
	if stream == null:
		return null
	player.stream = stream as AudioStream
	player.bus = _audio_bus
	player.volume_db = 0.0
	player.stop()
	player.play()
	return player


# 取人声通道的播放器。宿主节点被释放后(切场景)重建,static 引用会失效,
# 这里用 is_instance_valid 兜底。
func _ensure_voice_player() -> AudioStreamPlayer:
	if _voice_player != null and is_instance_valid(_voice_player):
		return _voice_player
	_voice_player = null
	if _host == null:
		return null
	var fresh := AudioStreamPlayer.new()
	fresh.bus = _audio_bus
	_host.add_child(fresh)
	_voice_player = fresh
	return fresh


func resolve_binding(cue: StringName, context: Dictionary = {}) -> String:
	var cue_name := str(cue)
	# 1) 开火按武器:同一把武器,谁拿都是同一个音。
	var weapon_id := str(context.get("weapon_id", ""))
	if not weapon_id.is_empty():
		var weapon_bindings: Variant = (_bindings.get("weapons", {}) as Dictionary).get(weapon_id, {})
		if weapon_bindings is Dictionary and (weapon_bindings as Dictionary).has(cue_name):
			return str((weapon_bindings as Dictionary).get(cue_name, ""))
	# 2) 受击按角色(角色 art_key 绑):victim 优先(被打的人),没 victim 才退回 attacker(兜底)。
	var unit: Unit = (context.get("victim") as Unit) if context.get("victim") is Unit else null
	if unit == null:
		unit = (context.get("attacker") as Unit) if context.get("attacker") is Unit else null
	if unit:
		var unit_key := unit.cutin_art_key
		var unit_bindings: Variant = (_bindings.get("units", {}) as Dictionary).get(unit_key, {})
		if unit_bindings is Dictionary and (unit_bindings as Dictionary).has(cue_name):
			return str((unit_bindings as Dictionary).get(cue_name, ""))
	# 3) default 兜底
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
