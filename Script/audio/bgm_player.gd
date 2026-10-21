extends Node
## BGM 播放系统（全局唯一入口）。
##
## 职责：
##   1. 循环播放 `res://Art/audio/bgm/` 下的 BGM（cue key 即文件名，不带扩展名）
##   2. 场景切换时的交叉淡入淡出 —— 音乐不随场景切换中断
##   3. 同一 cue 重复调用不重头播（Boot → MainMenu 不会重新起播）
##
## 用法：
##     BgmPlayer.play(&"bgm_main_menu")
##     BgmPlayer.play(&"bgm_battlefield_player")
##     BgmPlayer.stop()
##
## 音频资源缺失时静默跳过并给出 warning，不中断流程（与 `BattleSfx` 的处理一致）。

const BGM_DIR := "res://Art/audio/bgm/"
const FADE_TIME := 1.2
const BUS_NAME := "BGM"
## BGM 与音效共用 Master 总线时的相对电平；接入独立 BGM 总线后可调回 0。
const DEFAULT_VOLUME_DB := -8.0
const SILENT_DB := -60.0

var _players: Array[AudioStreamPlayer] = []
var _tweens: Array[Tween] = []
var _active := 0
var _current_cue: StringName = &""
var _volume_db := DEFAULT_VOLUME_DB


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.name = "BgmVoice%d" % i
		player.bus = _resolve_bus()
		player.volume_db = SILENT_DB
		add_child(player)
		_players.append(player)
		_tweens.append(null)


func _exit_tree() -> void:
	# 退出时停播。Godot 的 stop() 只是把播放体标记为「淡出后删除」，
	# 真正释放要等 AudioServer 的下一次 mix，这里留一点时间让它回收。
	for tween in _tweens:
		if tween != null and tween.is_valid():
			tween.kill()
	for player in _players:
		player.stop()
		player.stream = null
	OS.delay_msec(150)


## 播放指定 BGM。同一 cue 正在播放时不做任何事。
func play(cue: StringName, fade: float = FADE_TIME) -> void:
	if cue == _current_cue and _players[_active].playing:
		return

	var path := BGM_DIR + String(cue) + ".mp3"
	if not ResourceLoader.exists(path):
		push_warning("BgmPlayer: 找不到 BGM 文件 %s（跳过）" % path)
		return

	var stream := load(path) as AudioStream
	if stream == null:
		push_warning("BgmPlayer: BGM 加载失败 %s（跳过）" % path)
		return
	_enable_loop(stream)

	var incoming := _players[1 - _active]
	var outgoing := _players[_active]

	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()

	_fade_to(incoming, _volume_db, fade)
	_fade_to(outgoing, SILENT_DB, fade)

	_active = 1 - _active
	_current_cue = cue


## 从候选列表里随机挑一首播放（每次调用重新掷骰）。
## 缺文件的条目自动剔除；全部缺失时给出 warning 并静默跳过。
func play_random(cues: Array[StringName], fade: float = FADE_TIME) -> void:
	var available: Array[StringName] = []
	for cue in cues:
		if ResourceLoader.exists(BGM_DIR + String(cue) + ".mp3"):
			available.append(cue)
	if available.is_empty():
		push_warning("BgmPlayer: 候选 BGM 全部缺失（%s），跳过" % str(cues))
		return
	play(available[randi() % available.size()], fade)


## 停止 BGM（淡出）。
func stop(fade: float = FADE_TIME) -> void:
	if _current_cue == &"":
		return
	_fade_to(_players[_active], SILENT_DB, fade)
	_current_cue = &""


## 当前正在播放的 cue（未播放时为空）。
func current_cue() -> StringName:
	return _current_cue


## 设置 BGM 电平（dB）。
func set_volume_db(db: float) -> void:
	_volume_db = db
	if _current_cue != &"":
		_players[_active].volume_db = db


func _fade_to(player: AudioStreamPlayer, target_db: float, time: float) -> void:
	var index := _players.find(player)
	if index < 0:
		return
	var previous := _tweens[index]
	if previous != null and previous.is_valid():
		previous.kill()

	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_db, time)
	if target_db <= SILENT_DB:
		tween.tween_callback(player.stop)
	_tweens[index] = tween


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true


func _resolve_bus() -> String:
	return BUS_NAME if AudioServer.get_bus_index(BUS_NAME) >= 0 else "Master"
