class_name InventorySaveData
extends Resource

@export var item_quantities: Dictionary = {}
@export var warehouse_level: int = 1
@export var warehouse_items: Array[Dictionary] = []
@export var operator_loadouts: Dictionary = {}
@export var initial_content_created: bool = false
@export var starter_content_version: int = 0
