class_name TurnTransition
extends CanvasLayer

const PRESENTATION_CONFIG_PATH := "res://conf/battle/presentation.json"

@onready var _root: Control = $Root
@onready var _band: ColorRect = $Root/Band
@onready var _title: Label = $Root/Band/Title
@onready var _subtitle: Label = $Root/Band/Subtitle

var _config: Dictionary = {}
var _sfx: BattleSfx
var _is_playing := false


func _ready() -> void:
	_config = _load_config()
	_sfx = BattleSfx.new(
		bool(_config.get("debug_sfx", false)),
		self,
		StringName(str(_config.get("audio_bus", "SFX")))
	)
	_root.visible = false


func play_player(turn: int, max_turns: int, evacuation_pending: bool) -> void:
	if _is_playing:
		return
	_is_playing = true
	_title.text = "玩家行动"
	_subtitle.text = "第 %d / %d 回合" % [turn, max_turns]
	if evacuation_pending:
		_subtitle.text += " · 撤离倒计时：撑过本回合"
	_band.color = Color(0.05, 0.46, 0.64, 0.94)
	await _play(Vector2(-1.0, -0.24), 0.2, 0.5, 0.3, &"turn_in")
	_is_playing = false


func play_enemy(evacuation_pending: bool) -> void:
	if _is_playing:
		return
	_is_playing = true
	_title.text = "敌方行动"
	_subtitle.text = "敌方正在推进"
	if evacuation_pending:
		_subtitle.text += " · 撤离倒计时：撑过本回合"
	_band.color = Color(0.66, 0.2, 0.14, 0.94)
	await _play(Vector2(1.0, 0.0), 0.18, 0.34, 0.28, &"turn_out")
	_is_playing = false


func is_playing() -> bool:
	return _is_playing


func _play(direction: Vector2, in_seconds: float, hold_seconds: float, out_seconds: float, cue: StringName) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var distance := Vector2(viewport_size.x, viewport_size.y) * direction
	_root.position = -distance
	_root.modulate.a = 1.0
	_root.visible = true
	_sfx.play(cue)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(_root, "position", Vector2.ZERO, in_seconds)
	await tween.finished
	await get_tree().create_timer(hold_seconds).timeout
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(_root, "position", distance, out_seconds)
	await tween.finished
	_root.visible = false
	_root.position = Vector2.ZERO


func _load_config() -> Dictionary:
	if not FileAccess.file_exists(PRESENTATION_CONFIG_PATH):
		return {}
	var file := FileAccess.open(PRESENTATION_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).duplicate(true) if parsed is Dictionary else {}
