class_name SaveData
extends Resource

const CURRENT_VERSION: int = 1

@export var version: int = CURRENT_VERSION
@export var slot_id: int = 0
@export var timestamp: String = ""
@export var days: int = 0

@export var player: PlayerSaveData
@export var inventory: InventorySaveData
@export var quest: QuestSaveData
@export var story: StorySaveData
