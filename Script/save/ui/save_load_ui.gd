extends PanelContainer

signal closed()

@onready var slot_container: VBoxContainer = $VBox/ScrollContainer/SlotContainer
@onready var close_btn: Button = $VBox/CloseBtn
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

const SLOT_ITEM_SCENE: PackedScene = preload("res://Script/save/ui/save_slot_item.tscn")

var _pending_action: String = ""
var _pending_slot_id: int = 0
var read_only: bool = false

func _ready() -> void:
	close_btn.pressed.connect(_on_close_pressed)
	confirm_dialog.confirmed.connect(_on_confirm_confirmed)
	refresh_slots()

func refresh_slots() -> void:
	for child in slot_container.get_children():
		child.queue_free()
	var slots = SaveManager.list_slots()
	for info in slots:
		var item = SLOT_ITEM_SCENE.instantiate()
		slot_container.add_child(item)
		item.setup(info, read_only)
		item.save_pressed.connect(_on_slot_save)
		item.load_pressed.connect(_on_slot_load)
		item.delete_pressed.connect(_on_slot_delete)

func _on_slot_save(slot_id: int) -> void:
	if SaveManager.slot_exists(slot_id):
		_pending_action = "save"
		_pending_slot_id = slot_id
		confirm_dialog.dialog_text = "槽位 %d 已有存档，是否覆盖？" % (slot_id + 1)
		confirm_dialog.popup_centered()
	else:
		SaveManager.save(slot_id)
		refresh_slots()

func _on_slot_load(slot_id: int) -> void:
	SaveManager.load(slot_id)
	closed.emit()

func _on_slot_delete(slot_id: int) -> void:
	_pending_action = "delete"
	_pending_slot_id = slot_id
	confirm_dialog.dialog_text = "确定删除槽位 %d 的存档？" % (slot_id + 1)
	confirm_dialog.popup_centered()

func _on_confirm_confirmed() -> void:
	if _pending_action == "save":
		SaveManager.save(_pending_slot_id)
		refresh_slots()
	elif _pending_action == "delete":
		SaveManager.delete_slot(_pending_slot_id)
		refresh_slots()
	_pending_action = ""

func _on_close_pressed() -> void:
	closed.emit()
