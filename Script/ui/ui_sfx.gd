extends Node

# UI 通用音效(C 类)统一入口:自动为全项目的 Button / Popup 挂钩,
# 常驻面板用 attach_panel(),状态文案用 report_status() 走失败判定。
# 语义原则:只反馈"玩家操作",且只有真正的按钮才响 —— 格子类控件、面板上的
# 收起按钮、引擎内置 tooltip 都通过 set_silent() / silent_scripts 排除。

const CONFIG_PATH := "res://conf/audio/ui_sfx.json"
const BOUND_META := &"ui_sfx_bound"
const SILENT_META := &"ui_sfx_silent"
# 点击菜单项会顺带关掉菜单:这段时间内该 popup 的关闭不再叠 ui_close,只留 click
const CLOSE_SETTLE_MSEC := 400

var _sfx: BattleSfx
var _config: Dictionary = {}
var _cue_enabled: Dictionary = {}
var _error_markers: Array = []
var _hover_cooldown_msec := 60
var _last_hover_msec := -1000000
var _system_ui_depth := 0
var _system_ui_owner: Node = null
var _silent_scripts: Dictionary = {}
var _popup_click_msec: Dictionary = {}
var _pending_close: Dictionary = {}


func _ready() -> void:
	_config = _load_config()
	_cue_enabled = _config.get("cues", {}) as Dictionary
	_error_markers = _config.get("error_markers", []) as Array
	_hover_cooldown_msec = int(float(_config.get("hover_cooldown_seconds", 0.06)) * 1000.0)
	_silent_scripts = _load_silent_scripts()
	_sfx = BattleSfx.new(
		bool(_config.get("debug", false)),
		self,
		StringName(str(_config.get("audio_bus", "SFX")))
	)
	get_tree().node_added.connect(_on_node_added)
	_scan.call_deferred(get_tree().root)


func play(cue: StringName) -> void:
	if _sfx == null or _system_ui_depth > 0 or not is_cue_enabled(cue):
		return
	_sfx.play(cue)


# C 类音效只反馈玩家操作:系统驱动 UI(如敌方回合自动弹出单位面板)期间用这对
# 函数把整段包起来,期间所有 cue 静音。owner 传发起方节点,它被释放时自动兜底归零,
# 避免 begin/end 没配对导致 UI 音效永久静音。
func begin_system_ui(owner: Node = null) -> void:
	_system_ui_depth += 1
	if owner == null or not is_instance_valid(owner):
		return
	_system_ui_owner = owner
	if not owner.tree_exiting.is_connected(_on_system_ui_owner_exiting):
		owner.tree_exiting.connect(_on_system_ui_owner_exiting, CONNECT_ONE_SHOT)


func end_system_ui() -> void:
	_system_ui_depth = maxi(0, _system_ui_depth - 1)
	if _system_ui_depth == 0:
		_release_system_ui_owner()


func is_system_ui_active() -> bool:
	return _system_ui_depth > 0


func _release_system_ui_owner() -> void:
	if _system_ui_owner != null and is_instance_valid(_system_ui_owner):
		if _system_ui_owner.tree_exiting.is_connected(_on_system_ui_owner_exiting):
			_system_ui_owner.tree_exiting.disconnect(_on_system_ui_owner_exiting)
	_system_ui_owner = null


func _on_system_ui_owner_exiting() -> void:
	_system_ui_depth = 0
	_system_ui_owner = null


func is_cue_enabled(cue: StringName) -> bool:
	return bool(_cue_enabled.get(String(cue), true))


# 把控件标记为"不发声":继承 Button 但语义是格子的控件(背包格、装备槽、配件槽)、
# 以及面板上的收起按钮(关闭音已由面板 visibility_changed 给出,再叠 click 就吵了)。
func set_silent(node: Node, silent: bool = true) -> void:
	if node == null or not is_instance_valid(node):
		return
	node.set_meta(SILENT_META, silent)


# 静默判定放在触发时而不是绑定时:标记可能晚于 node_added(节点已入树才 _ready)。
func is_silent(node: Node) -> bool:
	if node == null or not is_instance_valid(node):
		return false
	if node.has_meta(SILENT_META):
		return bool(node.get_meta(SILENT_META))
	var script := node.get_script() as Script
	return script != null and _silent_scripts.has(script.resource_path)


# 非 Popup 的常驻面板(PanelContainer / Control):显隐变化即视为开/关。
func attach_panel(panel: Control) -> void:
	if panel == null or panel.has_meta(BOUND_META):
		return
	panel.set_meta(BOUND_META, true)
	panel.visibility_changed.connect(_on_panel_visibility_changed.bind(panel))


# 状态文案统一出口:命中失败关键字才播 ui_error,成功/提示文案保持安静。
func report_status(text: String) -> void:
	if text.is_empty():
		return
	for marker in _error_markers:
		if text.contains(str(marker)):
			play(&"ui_error")
			return


func _on_node_added(node: Node) -> void:
	# AcceptDialog(含 ConfirmationDialog)继承 Window,不是 Popup,要分开处理
	if node is AcceptDialog:
		_bind_dialog(node as AcceptDialog)
	elif node is Popup:
		_bind_popup(node as Popup)
	elif node is BaseButton:
		_bind_button(node as BaseButton)


func _scan(node: Node) -> void:
	_on_node_added(node)
	# include_internal:对话框的 确定/取消 按钮是 internal 子节点
	for child in node.get_children(true):
		_scan(child)


func _bind_popup(popup: Popup) -> void:
	if popup.has_meta(BOUND_META):
		return
	if _is_engine_tooltip(popup):
		return
	popup.set_meta(BOUND_META, true)
	popup.about_to_popup.connect(_on_popup_shown.bind(popup))
	popup.popup_hide.connect(_on_popup_hidden.bind(popup))


# Godot 4.6 的内置 tooltip 是 theme_type_variation = "TooltipPanel" 的 PopupPanel,
# 每次显示都新建一个、并 add_child 到"被 hover 的那个控件"下面(不是 Viewport),
# 不拦住就会在鼠标停留时冒出一个 ui_open。认 type variation,父节点是 Viewport 作兜底。
func _is_engine_tooltip(popup: Popup) -> bool:
	if popup.get_theme_type_variation() == &"TooltipPanel":
		return true
	return popup.get_parent() is Viewport


func _on_popup_shown(popup: Popup) -> void:
	if is_silent(popup):
		return
	play(&"ui_open")


func _on_popup_hidden(popup: Popup) -> void:
	if is_silent(popup):
		return
	# 延一帧再决定:同帧内如果登记过该 popup 的点击,说明这次关闭是点菜单项引起的
	var id := popup.get_instance_id()
	_pending_close[id] = popup
	_settle_popup_close.call_deferred(id)


func _settle_popup_close(id: int) -> void:
	var pending: Variant = _pending_close.get(id)
	_pending_close.erase(id)
	var clicked_at := int(_popup_click_msec.get(id, -1000000))
	_popup_click_msec.erase(id)
	if pending == null or not is_instance_valid(pending):
		return
	if Time.get_ticks_msec() - clicked_at <= CLOSE_SETTLE_MSEC:
		return
	play(&"ui_close")


func _bind_dialog(dialog: AcceptDialog) -> void:
	if dialog.has_meta(BOUND_META):
		return
	dialog.set_meta(BOUND_META, true)
	dialog.confirmed.connect(func() -> void: play(&"ui_confirm"))
	dialog.canceled.connect(func() -> void: play(&"ui_cancel"))
	if dialog.has_signal("visibility_changed"):
		dialog.visibility_changed.connect(_on_dialog_visibility_changed.bind(dialog))


# 对话框关闭已由 confirm / cancel 反馈,只在弹出时补一层 ui_open,避免叠音
func _on_dialog_visibility_changed(dialog: AcceptDialog) -> void:
	if dialog.visible and not is_silent(dialog):
		play(&"ui_open")


func _bind_button(button: BaseButton) -> void:
	if button.has_meta(BOUND_META) or _is_dialog_own_button(button):
		return
	button.set_meta(BOUND_META, true)
	button.pressed.connect(_on_button_pressed.bind(button))
	button.mouse_entered.connect(_on_button_hovered.bind(button))


func _on_button_pressed(button: BaseButton) -> void:
	if is_silent(button) or _is_dialog_own_button(button):
		return
	_mark_popup_click(button)
	play(&"ui_click")


func _mark_popup_click(button: BaseButton) -> void:
	var popup := _owning_popup(button)
	if popup == null:
		return
	_popup_click_msec[popup.get_instance_id()] = Time.get_ticks_msec()


func _owning_popup(node: Node) -> Popup:
	var current := node
	while current != null:
		if current is Popup:
			return current as Popup
		current = current.get_parent()
	return null


func _owning_dialog(node: Node) -> AcceptDialog:
	var current := node
	while current != null:
		if current is AcceptDialog:
			return current as AcceptDialog
		current = current.get_parent()
	return null


# 对话框自带的 确定/取消/关闭 按钮:反馈已由 confirmed / canceled 给出,不再叠 click
func _is_dialog_own_button(button: BaseButton) -> bool:
	var dialog := _owning_dialog(button)
	if dialog == null:
		return false
	# 窗口标题栏的 X 不是 Button 节点(走 close_requested),本来就不会出 click
	if button == dialog.get_ok_button():
		return true
	if dialog is ConfirmationDialog:
		return button == (dialog as ConfirmationDialog).get_cancel_button()
	return false


func _on_button_hovered(button: BaseButton) -> void:
	if button.disabled or is_silent(button):
		return
	var now := Time.get_ticks_msec()
	if now - _last_hover_msec < _hover_cooldown_msec:
		return
	_last_hover_msec = now
	play(&"ui_hover")


func _on_panel_visibility_changed(panel: Control) -> void:
	if is_silent(panel):
		return
	play(&"ui_open" if panel.visible else &"ui_close")


func _load_silent_scripts() -> Dictionary:
	var result := {}
	for path in (_config.get("silent_scripts", []) as Array):
		result[str(path)] = true
	return result


func _load_config() -> Dictionary:
	if not FileAccess.file_exists(CONFIG_PATH):
		return {}
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return (parsed as Dictionary).duplicate(true) if parsed is Dictionary else {}
