class_name BaseItem

var item_data: Dictionary = {}
var quantity: int = 1

func init_item(p_item_data: Dictionary, p_quantity: int = 1) -> void:
	item_data = p_item_data
	if item_data.get("stackable", false):
		var max_stack: int = item_data.get("max_stack", 1)
		quantity = clampi(p_quantity, 1, max_stack)
	else:
		quantity = 1

func get_id() -> String:
	return item_data.get("id", "")

func get_name() -> String:
	return item_data.get("name", "")

func get_type() -> String:
	return item_data.get("type", "")

func get_icon():
	var path: String = item_data.get("icon", "")
	if path.is_empty():
		return null
	return load(path)

func get_description() -> String:
	return item_data.get("description", "")

func get_price() -> int:
	return item_data.get("price", 0)

func get_quality() -> String:
	return item_data.get("quality", "D")

func get_quality_color() -> Color:
	return ItemDB.get_quality_color(get_quality())

func is_stackable() -> bool:
	return item_data.get("stackable", false)

func get_max_stack() -> int:
	return item_data.get("max_stack", 1)
