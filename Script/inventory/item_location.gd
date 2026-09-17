class_name ItemLocation
extends RefCounted

const WAREHOUSE := &"warehouse"
const BACKPACK := &"backpack"
const EQUIPMENT := &"equipment"
const WEAPON_ATTACHMENT := &"weapon_attachment"
const TEMPORARY := &"temporary"

var container_id: StringName
var owner_id: String
var position: int
var slot_id: String


func _init(
	container: StringName = &"",
	owner: String = "",
	item_position: int = -1,
	slot: String = ""
) -> void:
	container_id = container
	owner_id = owner
	position = item_position
	slot_id = slot


static func warehouse(position: int) -> ItemLocation:
	return ItemLocation.new(WAREHOUSE, "", position)


static func backpack(backpack_uid: String, position: int) -> ItemLocation:
	return ItemLocation.new(BACKPACK, backpack_uid, position)


static func equipment(operator_id: String, slot_id: String) -> ItemLocation:
	return ItemLocation.new(EQUIPMENT, operator_id, 0, slot_id)


static func weapon_attachment(weapon_uid: String, slot_id: String) -> ItemLocation:
	return ItemLocation.new(WEAPON_ATTACHMENT, weapon_uid, 0, slot_id)


static func temporary(container_id: String, position: int) -> ItemLocation:
	return ItemLocation.new(TEMPORARY, container_id, position)


func is_valid() -> bool:
	if container_id == WAREHOUSE or container_id == BACKPACK or container_id == TEMPORARY:
		return position >= 0
	if container_id == EQUIPMENT or container_id == WEAPON_ATTACHMENT:
		return not owner_id.is_empty() and not slot_id.is_empty()
	return false


func matches(other: ItemLocation) -> bool:
	return other != null \
		and container_id == other.container_id \
		and owner_id == other.owner_id \
		and position == other.position \
		and slot_id == other.slot_id
