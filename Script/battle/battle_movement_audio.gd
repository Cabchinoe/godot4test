class_name BattleMovementAudio
extends Node

const MIN_RING_MSEC := 450
const FADE_SECONDS := 0.08

var _sfx: BattleSfx
var _sounds: Dictionary = {}


func configure(sfx: BattleSfx) -> void:
	_sfx = sfx


static func can_hear(unit: Unit, listener: Player) -> bool:
	if unit == listener:
		return true
	var delta := unit.grid_pos - listener.grid_pos
	return absi(delta.x) + absi(delta.y) <= listener.get_hearing_range()


func step(unit: Unit, listener: Player) -> void:
	if not can_hear(unit, listener):
		stop_for(unit)
		return
	if _sfx == null:
		return
	var info: Dictionary = _sounds.get(unit, {})
	var audio := info.get("player") as AudioStreamPlayer
	var fade := info.get("fade") as Tween
	if fade != null:
		stop_for(unit)
		audio = null
	if is_instance_valid(audio) and audio.playing:
		return
	if not is_instance_valid(audio):
		var binding := _sfx.resolve_binding(&"move_step", {"attacker": unit})
		var path := BattleSfx.AUDIO_BASE + binding + BattleSfx.AUDIO_EXT
		if binding.is_empty() or not ResourceLoader.exists(path):
			return
		audio = AudioStreamPlayer.new()
		audio.stream = load(path) as AudioStream
		audio.bus = &"SFX" if AudioServer.get_bus_index("SFX") >= 0 else &"Master"
		add_child(audio)
	audio.volume_db = 0.0
	audio.play()
	_sounds[unit] = {"player": audio, "started_msec": Time.get_ticks_msec()}


func finish(unit: Unit, listener: Player) -> void:
	if not can_hear(unit, listener):
		stop_for(unit)
		return
	if not _sounds.has(unit):
		return
	var info: Dictionary = _sounds[unit]
	var audio := info.get("player") as AudioStreamPlayer
	if not is_instance_valid(audio) or not audio.playing:
		stop_for(unit)
		return
	if info.has("fade"):
		return
	var elapsed := Time.get_ticks_msec() - int(info["started_msec"])
	var hold := maxf(0.0, float(MIN_RING_MSEC - elapsed) / 1000.0)
	var fade := create_tween()
	info["fade"] = fade
	if hold > 0.0:
		fade.tween_interval(hold)
	fade.tween_property(audio, "volume_db", -60.0, FADE_SECONDS)
	fade.tween_callback(stop_for.bind(unit))


func stop_for(unit: Unit) -> void:
	var info: Dictionary = _sounds.get(unit, {})
	_sounds.erase(unit)
	_dispose_sound(info)


func stop_all() -> void:
	for info in _sounds.values():
		_dispose_sound(info)
	_sounds.clear()


func _dispose_sound(info: Dictionary) -> void:
	var fade := info.get("fade") as Tween
	if fade != null and fade.is_valid():
		fade.kill()
	var audio := info.get("player") as AudioStreamPlayer
	if is_instance_valid(audio):
		audio.stop()
		audio.queue_free()


func _exit_tree() -> void:
	stop_all()
