extends Control

const BACKGROUNDS_DIR := "res://Art/backgrounds/"
const BG_PREFIX := "main_menu_"
const BG_EXTENSIONS := ["jpg", "jpeg", "png", "webp"]

@export var background_pool: Array[Texture2D] = []

@onready var background: TextureRect = $Background
@onready var save_load_ui = $SaveLoadUI


func _ready() -> void:
	_pick_random_background()


func _pick_random_background() -> void:
	var pool: Array[Texture2D] = []
	for tex in background_pool:
		if tex != null:
			pool.append(tex)
	if pool.is_empty():
		pool = _scan_backgrounds_dir()
	if pool.is_empty():
		push_warning("MainMenu: no backgrounds found in %s or background_pool" % BACKGROUNDS_DIR)
		return
	background.texture = pool[randi() % pool.size()]


func _scan_backgrounds_dir() -> Array[Texture2D]:
	var found: Array[Texture2D] = []
	var dir := DirAccess.open(BACKGROUNDS_DIR)
	if dir == null:
		return found
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with(BG_PREFIX):
			var ext := file_name.get_extension().to_lower()
			if ext in BG_EXTENSIONS:
				var path := BACKGROUNDS_DIR.path_join(file_name)
				var tex := load(path) as Texture2D
				if tex != null:
					found.append(tex)
		file_name = dir.get_next()
	dir.list_dir_end()
	return found


func _on_start_button_pressed() -> void:
	if not SaveManager.has_current_data():
		SaveManager.create_new_game()
	get_tree().change_scene_to_file("res://CommandCenter.tscn")


func _on_continue_button_pressed() -> void:
	save_load_ui.read_only = true
	save_load_ui.visible = true
	save_load_ui.refresh_slots()


func _on_save_load_closed() -> void:
	save_load_ui.visible = false
	if SaveManager.has_current_data():
		get_tree().change_scene_to_file("res://CommandCenter.tscn")
