class_name InventoryGrid
extends GridContainer

signal gap_dropped(data: Dictionary)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and str(data.get("kind", "")) in ["inventory_item", "equipped_item", "weapon_attachment", "backpack_item", "temporary_item"]


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	gap_dropped.emit(data)
