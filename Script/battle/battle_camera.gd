class_name BattleCamera
extends RefCounted

var _camera: Camera2D
var _home_position := Vector2.ZERO
var _tween: Tween


func _init(camera: Camera2D) -> void:
	_camera = camera
	if _camera:
		_home_position = _camera.global_position


func focus_on(unit: Unit, duration: float = 0.42) -> void:
	if _camera == null or unit == null or not is_instance_valid(unit):
		return
	_stop_active_tween()
	_tween = _camera.create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "global_position", unit.global_position, maxf(0.0, duration))
	await _tween.finished


func release(duration: float = 0.35) -> void:
	if _camera == null:
		return
	_stop_active_tween()
	_tween = _camera.create_tween()
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(_camera, "global_position", _home_position, maxf(0.0, duration))
	await _tween.finished


func _stop_active_tween() -> void:
	if _tween and _tween.is_valid() and _tween.is_running():
		_tween.kill()
