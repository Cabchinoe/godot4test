class_name Unit
extends Node2D

signal movement_finished

# --- 外观配置（由创建者赋值，不再写死动画名） ---
@export var sprite_frames: SpriteFrames
@export var animation_idle: StringName = &"idle"
@export var animation_walk: StringName = &"walk"
@export var animation_aim: StringName = &"aim"

# --- 通用状态 ---
var unit_name: String = ""
var faction: String = ""
var ap_max: int = 5
var pathfinder: Pathfinder
var level_manager: LevelManager

var grid_pos: Vector2i = Vector2i.ZERO
var current_level: int = 1
var move_path: Array[Dictionary] = []
var move_timer: float = 0.0
var move_interval: float = 0.15
var is_moving: bool = false
var action_points: int = 0

func _ready() -> void:
	_apply_sprite_frames()
	_set_default_frame()

func _apply_sprite_frames() -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite and sprite_frames:
		sprite.sprite_frames = sprite_frames

func _set_default_frame() -> void:
	# 没动画时让 sprite 至少停在 idle 第 0 帧，避免角色在 IDLE 状态看不见
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_idle):
		sprite.animation = animation_idle
		sprite.frame = 0
		sprite.stop()

# --- 公共 API：装配外观 ---
func configure_appearance(p_frames: SpriteFrames,
		p_idle: StringName = &"idle",
		p_walk: StringName = &"walk",
		p_aim: StringName = &"aim") -> void:
	sprite_frames = p_frames
	animation_idle = p_idle
	animation_walk = p_walk
	animation_aim = p_aim
	_apply_sprite_frames()
	_set_default_frame()

# --- 公共 API：动画控制 ---
func play_idle() -> void:
	_play(animation_idle)

func play_walk() -> void:
	_play(animation_walk)

func play_aim() -> void:
	_play(animation_aim)

func stop_walk(reset_frame: bool = true) -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite and sprite.animation == animation_walk:
		sprite.stop()
		if reset_frame:
			sprite.frame = 0

func stop_all(reset_frame: bool = true) -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite:
		sprite.stop()
		if reset_frame:
			# 取消选中：切到 idle 第 0 帧并停住，避免角色"消失"
			if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_idle):
				sprite.animation = animation_idle
			sprite.frame = 0

func _play(anim: StringName) -> void:
	var sprite := get_node_or_null("Sprite2D") as AnimatedSprite2D
	if sprite:
		sprite.play(anim)

# --- 初始化与状态 ---
func init_unit(p_name: String, p_faction: String, p_ap_max: int, p_level_manager: LevelManager, p_start_level: int = 1):
	unit_name = p_name
	faction = p_faction
	ap_max = p_ap_max
	action_points = ap_max
	level_manager = p_level_manager
	current_level = p_start_level
	pathfinder = Pathfinder.new(level_manager)
	_update_z_index()
	add_to_group("units")
	add_to_group(faction)

func _update_z_index():
	var obstacle = level_manager.get_layer(current_level, "obstacle")
	if obstacle:
		z_index = obstacle.z_index + 1

func start_turn():
	action_points = ap_max

func spend_ap(cost: int) -> bool:
	if action_points >= cost:
		action_points -= cost
		return true
	return false

func _process(delta: float):
	if is_moving and move_path.size() > 0:
		move_timer += delta
		if move_timer >= move_interval:
			move_timer = 0.0
			_step_to_next()

func _step_to_next():
	if move_path.size() == 0:
		if is_moving:
			is_moving = false
			stop_walk()
			movement_finished.emit()
		return
	var next_node = move_path.pop_front()
	grid_pos = next_node["grid"]
	current_level = next_node["level"]

	var ground = level_manager.get_layer(current_level, "ground")
	var local = ground.map_to_local(grid_pos)
	var world_pos = ground.to_global(local)
	world_pos.y += level_manager.get_offset(current_level)
	var sprite = get_node("Sprite2D")
	var sprite_offset = sprite.offset * scale
	global_position = world_pos - sprite_offset
	_update_z_index()
	if move_path.size() == 0:
		is_moving = false
		stop_walk()
		movement_finished.emit()

func set_move_path(path: Array[Dictionary]):
	move_path = path
	move_timer = 0.0
	if move_path.size() > 0 and move_path[0]["grid"] == grid_pos and move_path[0]["level"] == current_level:
		move_path.pop_front()
	if move_path.size() == 0:
		is_moving = false
		stop_walk()
		movement_finished.emit()
		return
	is_moving = true
	play_walk()
