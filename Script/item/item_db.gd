extends Node

const VALID_TYPES := {
	"WEAPON": "武器",
	"AMMO": "弹药",
	"HELMET": "头盔",
	"ARMOR": "护甲",
	"CHESTRIG": "胸挂",
	"BACKPACK": "背包",
	"MATERIAL": "材料",
	"COLLECTIBLE": "收藏品",
	"CONSUMABLE": "消耗品",
	"WEAPON_ATTACHMENT": "武器配件",
}

const QUALITY_COLORS := {
	"S": Color(0.72, 0.28, 0.28),
	"A": Color(0.72, 0.58, 0.22),
	"B": Color(0.52, 0.28, 0.62),
	"C": Color(0.28, 0.42, 0.68),
	"D": Color(0.28, 0.58, 0.32),
}

const DEFAULT_COLOR := Color(0.5, 0.5, 0.5)

var _items: Dictionary = {}

func load_from_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("ItemDB: file not found: ", path)
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	var err := json.parse(file.get_as_text())
	file.close()
	if err != OK:
		print("ItemDB: JSON parse error: ", json.get_error_message())
		return
	var data = json.data
	if not data is Array:
		print("ItemDB: JSON root must be an array")
		return
	for entry in data:
		if _validate_entry(entry):
			_items[entry["id"]] = entry
	print("ItemDB: loaded ", _items.size(), " items")

func _validate_entry(entry: Dictionary) -> bool:
	if not entry.has("id") or not entry.has("type"):
		print("ItemDB: entry missing id or type: ", entry)
		return false
	if entry["type"] not in VALID_TYPES:
		print("ItemDB: invalid type '", entry["type"], "' for item: ", entry["id"])
		return false
	return true

func get_item(id: String):
	return _items.get(id, null)

func get_items_by_type(type: String) -> Array:
	var result := []
	for item in _items.values():
		if item["type"] == type:
			result.append(item)
	return result

func get_quality_color(quality: String) -> Color:
	return QUALITY_COLORS.get(quality, DEFAULT_COLOR)

func get_all_items() -> Array:
	return _items.values()
