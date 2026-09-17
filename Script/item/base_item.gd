class_name BaseItem

var item_data: Dictionary = {}
var quantity: int = 1

func init_item(p_item_data: Dictionary, p_quantity: int = 1) -> void:
	item_data = p_item_data
	quantity = maxi(p_quantity, 1)

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

func get_battle_effect_id() -> String:
	return item_data.get("battle_effect_id", "")
