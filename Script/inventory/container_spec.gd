class_name ContainerSpec
extends Resource

@export var container_id: StringName
@export var display_name: String = ""
@export var columns: int = 1
@export var capacity: int = 0
@export var accepted_item_types: PackedStringArray = []
@export var allows_swap: bool = true
@export var drag_enabled: bool = true


func accepts(item_data: Dictionary) -> bool:
	return accepted_item_types.is_empty() or accepted_item_types.has(str(item_data.get("type", "")))
