class_name UnitIntelTracker
extends RefCounted

signal intel_changed(unit: Unit)

var _revealed_ids: Dictionary = {}


func register_unit(unit: Unit) -> void:
	if unit == null:
		return
	if not unit.damaged.is_connected(_on_unit_damaged):
		unit.damaged.connect(_on_unit_damaged.bind(unit))


func mark_revealed(unit: Unit) -> void:
	if unit == null:
		return
	var unit_id := unit.get_instance_id()
	if _revealed_ids.has(unit_id):
		return
	_revealed_ids[unit_id] = true
	intel_changed.emit(unit)


func is_revealed(unit: Unit) -> bool:
	return unit != null and _revealed_ids.has(unit.get_instance_id())


func reset() -> void:
	_revealed_ids.clear()


func _on_unit_damaged(_result: Dictionary, unit: Unit) -> void:
	mark_revealed(unit)
