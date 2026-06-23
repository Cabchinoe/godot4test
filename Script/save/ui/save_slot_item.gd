class_name SaveSlotItem
extends PanelContainer

signal save_pressed(slot_id: int)
signal load_pressed(slot_id: int)
signal delete_pressed(slot_id: int)

@onready var slot_label: Label = $VBox/SlotLabel
@onready var info_label: Label = $VBox/InfoLabel
@onready var save_btn: Button = $VBox/Buttons/SaveBtn
@onready var load_btn: Button = $VBox/Buttons/LoadBtn
@onready var delete_btn: Button = $VBox/Buttons/DeleteBtn

var slot_id: int = 0

func setup(info: SlotInfo, p_read_only: bool = false) -> void:
	slot_id = info.slot_id
	slot_label.text = "槽位 %d" % (slot_id + 1)
	if p_read_only:
		save_btn.visible = false
	if info.exists:
		info_label.text = "保存时间: %s\n天数: %d\n等级: %s" % [
			info.timestamp,
			info.days,
			str(info.summary.get("level", "?"))
		]
		save_btn.disabled = p_read_only
		load_btn.disabled = false
		delete_btn.disabled = p_read_only
	else:
		info_label.text = "空槽位"
		save_btn.disabled = p_read_only
		load_btn.disabled = true
		delete_btn.disabled = p_read_only

func _on_save_btn_pressed() -> void:
	save_pressed.emit(slot_id)

func _on_load_btn_pressed() -> void:
	load_pressed.emit(slot_id)

func _on_delete_btn_pressed() -> void:
	delete_pressed.emit(slot_id)
