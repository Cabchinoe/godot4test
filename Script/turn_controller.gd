class_name TurnController

enum Phase { PLAYER_PHASE, ENEMY_PHASE }

signal turn_started(turn: int)
signal turn_ended(turn: int)
signal phase_changed(phase: Phase)
signal game_over()

var current_turn: int = 1
var max_turns: int = 10
var current_phase: Phase = Phase.PLAYER_PHASE
var is_game_over: bool = false

func _init(p_max_turns: int = 10):
	max_turns = p_max_turns

func start_game():
	current_turn = 1
	current_phase = Phase.PLAYER_PHASE
	is_game_over = false
	turn_started.emit(current_turn)

func end_turn():
	if is_game_over:
		return
	if current_phase != Phase.PLAYER_PHASE:
		return
	turn_ended.emit(current_turn)
	current_phase = Phase.ENEMY_PHASE
	phase_changed.emit(current_phase)

func end_enemy_phase():
	if is_game_over:
		return
	if current_phase != Phase.ENEMY_PHASE:
		return
	if current_turn >= max_turns:
		is_game_over = true
		print("对局结束")
		game_over.emit()
		return
	current_turn += 1
	current_phase = Phase.PLAYER_PHASE
	phase_changed.emit(current_phase)
	turn_started.emit(current_turn)
