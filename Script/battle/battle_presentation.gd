class_name BattlePresentation
extends RefCounted

var _combat_resolver: BattleCombatResolver
var _cut_in: BattleCutIn
var _busy := false
var _session_open := false
var _session_attacker: Unit


func _init(combat_resolver: BattleCombatResolver, cut_in: BattleCutIn) -> void:
	_combat_resolver = combat_resolver
	_cut_in = cut_in


func play_attack(attacker: Unit, defender: Unit) -> Dictionary:
	await begin_session(attacker)
	var result := await play_attack_round(attacker, defender)
	await end_session()
	return result


func begin_session(attacker: Unit) -> void:
	if _busy or attacker == null or attacker.is_defeated:
		return
	_busy = true
	_session_open = true
	_session_attacker = attacker
	await _cut_in.begin_session(attacker)


func play_attack_round(attacker: Unit, defender: Unit) -> Dictionary:
	if not _session_open or attacker != _session_attacker or defender == null:
		return {}
	await _cut_in.set_defender(defender)
	var roll := _combat_resolver.roll_attack(attacker, defender)
	await _cut_in.play_attack_lead_in(roll)
	var applied := _combat_resolver.apply_attack(attacker, defender, roll)
	await _cut_in.show_result(applied)
	await _cut_in.finish_round()
	return applied


func end_session() -> void:
	if not _session_open:
		return
	await _cut_in.end_session()
	_session_open = false
	_session_attacker = null
	_busy = false


func is_busy() -> bool:
	return _busy
