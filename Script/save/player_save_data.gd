class_name PlayerSaveData
extends Resource

const CURRENT_VERSION: int = 3

@export var version: int = CURRENT_VERSION
@export var operator_id: String = "benny"
@export var operator_level: int = 1
@export var experience: int = 0
@export var owned_item_ids: PackedStringArray = []
@export var equipped_item_ids: Dictionary = {}
@export var unlocked_flags: Dictionary = {}

@export var level: int = 1
