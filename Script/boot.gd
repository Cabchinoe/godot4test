extends Node

## 启动页随机播放的 BGM 候选（cue key 即 Art/audio/bgm/ 下的文件名）。
const BOOT_BGM_CUES: Array[StringName] = [&"bgm_boot_a", &"bgm_boot_b"]


func _ready() -> void:
	ItemDB.load_from_dir("res://conf/items")
	EnemyDB.load_from_file("res://conf/enemies.json")
	# 启动时随机挑一首启动曲；MainMenu 会保留它继续放
	BgmPlayer.play_random(BOOT_BGM_CUES)
	call_deferred("_open_main_menu")


func _open_main_menu() -> void:
	get_tree().change_scene_to_file("res://MainMenu.tscn")
