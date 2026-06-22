class_name Weapon
extends EquipItem

const VALID_SUBTYPES := {
	"RIFLE": "步枪",
	"SMG": "冲锋枪",
	"PISTOL": "手枪",
	"SNIPER": "狙击步枪",
}

func get_subtype() -> String:
	return item_data.get("subtype", "")

func get_subtype_name() -> String:
	return VALID_SUBTYPES.get(get_subtype(), "未知")

func get_ammo_type() -> String:
	return item_data.get("ammo_type", "")
