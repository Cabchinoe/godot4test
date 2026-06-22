class_name ItemFactory

const EQUIP_TYPES := [
	"WEAPON", "AMMO", "HELMET", "ARMOR", "CHESTRIG", "BACKPACK"
]

static func create(id: String, quantity: int = 1):
	var data = ItemDB.get_item(id)
	if data == null:
		print("ItemFactory: item not found: ", id)
		return null
	var item_type: String = data.get("type", "")
	var item
	if item_type == "WEAPON":
		item = Weapon.new()
	elif item_type == "WEAPON_ATTACHMENT":
		item = WeaponAttachment.new()
	elif item_type in EQUIP_TYPES:
		item = EquipItem.new()
	elif item_type == "CONSUMABLE":
		item = UseItem.new()
	else:
		item = BaseItem.new()
	item.init_item(data, quantity)
	return item
