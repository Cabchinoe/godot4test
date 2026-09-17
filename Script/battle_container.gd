class_name BattleContainer
extends Node2D

signal opened(container: BattleContainer)

const FALLBACK_CLOSED_TEXTURE := "res://Art/tilesets/urban_night/props/containers/supply_crate_closed_a.png"
const FALLBACK_OPENED_TEXTURE := "res://Art/tilesets/urban_night/props/containers/supply_crate_open_a.png"

var resource_id: String = ""
var display_name: String = "补给箱"
var grid_pos: Vector2i = Vector2i.ZERO
var current_level: int = 1
var open_ap_cost: int = 1
var capacity: int = 8
var columns: int = 4
var loot_item_ids: Array[String] = []
var is_opened: bool = false
var is_ground_pile: bool = false
var requires_attack_range: bool = true
var can_walk: bool = false
var interaction_radius: float = 42.0
var closed_texture: Texture2D
var opened_texture: Texture2D
var _loot_seeded: bool = false
var _sprite: Sprite2D


func configure(data: Dictionary) -> void:
	resource_id = str(data.get("resource_id", resource_id))
	display_name = str(data.get("display_name", display_name))
	grid_pos = data.get("grid", grid_pos)
	current_level = int(data.get("level", current_level))
	open_ap_cost = maxi(0, int(data.get("open_ap_cost", open_ap_cost)))
	capacity = maxi(1, int(data.get("capacity", capacity)))
	columns = maxi(1, int(data.get("columns", columns)))
	is_ground_pile = bool(data.get("is_ground_pile", is_ground_pile))
	requires_attack_range = bool(data.get("requires_attack_range", requires_attack_range))
	if data.has("can_walk"):
		can_walk = bool(data.get("can_walk", can_walk))
	elif data.has("blocks_movement"):
		can_walk = not bool(data.get("blocks_movement", not can_walk))
	interaction_radius = maxf(16.0, float(data.get("interaction_radius", interaction_radius)))
	loot_item_ids.clear()
	for item_id in data.get("loot", []):
		loot_item_ids.append(str(item_id))
	var closed_path := str(data.get("closed_texture_path", ""))
	var opened_path := str(data.get("opened_texture_path", ""))
	closed_texture = _load_texture(closed_path, FALLBACK_CLOSED_TEXTURE)
	opened_texture = _load_texture(opened_path, FALLBACK_OPENED_TEXTURE)
	_refresh_visual()


func _ready() -> void:
	add_to_group("battle_containers")
	_refresh_visual()


func get_temporary_container_id() -> String:
	return "search:%s" % resource_id


func get_search_ap_cost() -> int:
	return 0 if is_opened or is_ground_pile else open_ap_cost


func can_be_searched_by(actor: Unit, bullet_range: BulletRange) -> bool:
	if actor == null or actor.is_defeated:
		return false
	if not requires_attack_range:
		return true
	if actor.grid_pos == grid_pos and actor.current_level == current_level:
		return true
	if bullet_range == null:
		return false
	var cells := bullet_range.get_reachable_cells(
		actor.grid_pos,
		actor.current_level,
		1,
		[],
		true
	)
	for cell in cells:
		if cell["grid"] == grid_pos and cell["level"] == current_level:
			return true
	return false


func begin_search(actor: Unit, bullet_range: BulletRange) -> Dictionary:
	if not can_be_searched_by(actor, bullet_range):
		return {}
	var ap_cost := get_search_ap_cost()
	if not actor.spend_ap(ap_cost):
		return {}
	var opened_now := not is_opened
	is_opened = true
	_refresh_visual()
	if opened_now:
		opened.emit(self)
	return {"opened_now": opened_now, "ap_cost": ap_cost}


func has_seeded_loot() -> bool:
	return _loot_seeded


func mark_loot_seeded() -> void:
	_loot_seeded = true


func has_remaining_loot(inventory: InventorySaveData) -> bool:
	if not _loot_seeded:
		return not loot_item_ids.is_empty()
	if inventory == null:
		return false
	return not WarehouseService.get_temporary_items(inventory, get_temporary_container_id()).is_empty()


func _refresh_visual() -> void:
	if _sprite == null:
		_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.name = "Sprite2D"
		add_child(_sprite)
	_sprite.texture = opened_texture if is_opened else closed_texture
	_sprite.centered = true


func _load_texture(path: String, fallback_path: String) -> Texture2D:
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return load(fallback_path) as Texture2D
