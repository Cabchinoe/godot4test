class_name SlotInfo
extends RefCounted

var slot_id: int
var exists: bool
var timestamp: String
var days: int
var summary: Dictionary

func _init(p_slot_id: int = 0, p_exists: bool = false, p_timestamp: String = "", p_days: int = 0, p_summary: Dictionary = {}):
	slot_id = p_slot_id
	exists = p_exists
	timestamp = p_timestamp
	days = p_days
	summary = p_summary
