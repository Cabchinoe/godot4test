class_name BattleSfx
extends RefCounted

const BINDINGS_PATH := "res://conf/battle/sfx_bindings.json"
const AUDIO_BASE := "res://Art/audio/sfx/"
const AUDIO_EXT := ".mp3"
const POOL_MAX := 8
const DEFAULT_PROBABILITY := 1.0

var _bindings: Dictionary = {}
var _debug_enabled := false
var _host: Node = null
var _pool: Array[AudioStreamPlayer] = []
var _audio_bus: StringName = &"Master"

# 人声通道:全局唯一一条语音播放器。
# 角色台词走独立通道(不占 SFX 池),新台词开始时自动掐断上一条,
# 避免连点触发时语音叠加。static 让所有 BattleSfx 实例共用同一条通道。
static var _voice_player: AudioStreamPlayer = null

# 每个 cue 上次播过的文件名。多条变体时用来避免连续重复同一条。
# static 跨实例共享,避免 battlefield 与 battle_cut_in 各自记一份。
static var _last_played: Dictionary = {}


func _init(debug_enabled: bool = false, host: Node = null, audio_bus: StringName = &"SFX") -> void:
	_bindings = _load_bindings()
	_debug_enabled = debug_enabled
	_host = host
	_audio_bus = audio_bus if _has_bus(audio_bus) else &"Master"


func play(cue: StringName, context: Dictionary = {}) -> AudioStreamPlayer:
	var resolved: String = resolve_binding(cue, context)
	if _debug_enabled:
		print("[BattleSfx] %s -> %s" % [cue, resolved])
	return _play_file(resolved, true)


# 静默版本:文件缺失不刷 warning。用于"可选"的音效(道具专属音、语音等)。
func play_optional(cue: StringName, context: Dictionary = {}) -> AudioStreamPlayer:
	var resolved: String = resolve_binding(cue, context)
	if _debug_enabled:
		print("[BattleSfx] %s -> %s" % [cue, resolved])
	return _play_file(resolved, false)


# 播放一个已解析好的文件名。warn_missing 决定缺文件时是否 push_warning。
# 解析只做一次:多变体时两次 resolve 可能选到不同文件,必须避免。
func _play_file(resolved: String, warn_missing: bool) -> AudioStreamPlayer:
	if resolved.is_empty():
		return null
	if _host == null:
		# 没注入 host(常见于纯 debug 模式),仅打印
		return null
	var path := AUDIO_BASE + resolved + AUDIO_EXT
	if not ResourceLoader.exists(path):
		if warn_missing:
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


# 播放角色语音。占用独立的人声通道:先掐断当前正在播的上一条语音,再播新的。
#
# 绑定里可以配:
#   "files": ["voice_benny_select_01", "voice_benny_select_02"]  多条变体,随机选一条
#   "probability": 0.2                                          该 cue 的触发概率(默认 1.0)
#   "avoid_repeat": true                                        避免连续播同一条(默认 true)
#
# 文件缺失时静默跳过(返回 null),不刷 warning。
func play_voice(cue: StringName, context: Dictionary = {}) -> AudioStreamPlayer:
	var entry := _resolve_entry(cue, context)
	var files: PackedStringArray = entry.get("files", PackedStringArray())
	if files.is_empty():
		return null
	# 先滤掉还没录出来的变体:否则会抽中缺失文件,整条语音直接不响。
	# 逐条录制新变体时,已录的那条仍然每次都能播。
	var playable := PackedStringArray()
	for item in files:
		if ResourceLoader.exists(AUDIO_BASE + item + AUDIO_EXT):
			playable.append(item)
	if playable.is_empty():
		return null
	var probability := float(entry.get("probability", DEFAULT_PROBABILITY))
	if probability < 1.0 and randf() > probability:
		if _debug_enabled:
			print("[BattleSfx] voice %s skipped (probability %.2f)" % [cue, probability])
		return null
	var resolved := _pick_variant(playable, cue, bool(entry.get("avoid_repeat", true)))
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


# 解析一个 cue 当前该播哪个文件。多条变体时随机取一条。
func resolve_binding(cue: StringName, context: Dictionary = {}) -> String:
	var files := resolve_candidates(cue, context)
	if files.is_empty():
		return ""
	return _pick_variant(files, cue)


# 解析一个 cue 的全部候选文件(多变体时返回多条)。
func resolve_candidates(cue: StringName, context: Dictionary = {}) -> PackedStringArray:
	return _resolve_entry(cue, context).get("files", PackedStringArray())


# 解析一个 cue 的完整绑定条目:候选文件列表 + 触发概率 + 是否避免连续重复。
# 绑定值有两种写法:
#   "sfx_xxx"                                 单文件(音效,向后兼容)
#   {"files": ["a","b"], "probability": 0.2}  多条变体(角色台词)
func _resolve_entry(cue: StringName, context: Dictionary = {}) -> Dictionary:
	var raw: Variant = _lookup_binding(cue, context)
	var files := PackedStringArray()
	var probability := DEFAULT_PROBABILITY
	var avoid_repeat := true
	if raw is String or raw is StringName:
		var one := str(raw)
		if not one.is_empty():
			files.append(one)
	elif raw is Dictionary:
		var data := raw as Dictionary
		var raw_files: Variant = data.get("files", [])
		if raw_files is Array:
			for item in raw_files:
				var name := str(item)
				if not name.is_empty():
					files.append(name)
		probability = clampf(float(data.get("probability", DEFAULT_PROBABILITY)), 0.0, 1.0)
		avoid_repeat = bool(data.get("avoid_repeat", true))
	return {"files": files, "probability": probability, "avoid_repeat": avoid_repeat}


# 按 weapons → units.<art_key> → default 三级查找绑定值(原样返回,不解析)。
func _lookup_binding(cue: StringName, context: Dictionary = {}) -> Variant:
	var cue_name := str(cue)
	# 1) 开火按武器:同一把武器,谁拿都是同一个音。
	var weapon_id := str(context.get("weapon_id", ""))
	if not weapon_id.is_empty():
		var weapon_bindings: Variant = (_bindings.get("weapons", {}) as Dictionary).get(weapon_id, {})
		if weapon_bindings is Dictionary and (weapon_bindings as Dictionary).has(cue_name):
			return (weapon_bindings as Dictionary).get(cue_name, "")
	# 2) 受击按角色(角色 art_key 绑):victim 优先(被打的人),没 victim 才退回 attacker(兜底)。
	var unit: Unit = (context.get("victim") as Unit) if context.get("victim") is Unit else null
	if unit == null:
		unit = (context.get("attacker") as Unit) if context.get("attacker") is Unit else null
	if unit:
		var unit_key := unit.cutin_art_key
		var unit_bindings: Variant = (_bindings.get("units", {}) as Dictionary).get(unit_key, {})
		if unit_bindings is Dictionary and (unit_bindings as Dictionary).has(cue_name):
			return (unit_bindings as Dictionary).get(cue_name, "")
	# 3) default 兜底
	return (_bindings.get("default", {}) as Dictionary).get(cue_name, "")


# 多条变体里随机挑一条。avoid_repeat 时避开该 cue 上次播过的那条。
func _pick_variant(files: PackedStringArray, cue: StringName, avoid_repeat: bool = true) -> String:
	if files.is_empty():
		return ""
	if files.size() == 1:
		return files[0]
	var key := str(cue)
	var pool := files
	if avoid_repeat:
		var last := str(_last_played.get(key, ""))
		if not last.is_empty() and files.has(last):
			var filtered := PackedStringArray()
			for item in files:
				if item != last:
					filtered.append(item)
			if not filtered.is_empty():
				pool = filtered
	var picked := pool[randi_range(0, pool.size() - 1)]
	_last_played[key] = picked
	return picked


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
