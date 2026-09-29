class_name BattleSfx
extends RefCounted

const BINDINGS_PATH := "res://conf/battle/sfx_bindings.json"

var _bindings: Dictionary = {}
var _debug_enabled := false


func _init(debug_enabled: bool = false) -> void:
	_bindings = _load_bindings()
	_debug_enabled = debug_enabled


func play(cue: StringName, context: Dictionary = {}) -> void:
	if not _debug_enabled:
		return
	print("[BattleSfx] %s -> %s" % [cue, resolve_binding(cue, context)])


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
