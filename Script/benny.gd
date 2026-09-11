class_name Benny
extends Player

var rabbit_step_cooldown_turns: int = 0
var rabbit_step_bonus_ap: int = 0

func start_turn() -> void:
	super.start_turn()
	rabbit_step_bonus_ap = 0
	if rabbit_step_cooldown_turns > 0:
		rabbit_step_cooldown_turns -= 1
		return
	rabbit_step_bonus_ap = 1
	action_points += rabbit_step_bonus_ap

func spend_ap(cost: int) -> bool:
	if action_points < cost:
		return false
	var normal_ap_remaining := action_points - rabbit_step_bonus_ap
	var bonus_ap_spent := maxi(0, cost - normal_ap_remaining)
	action_points -= cost
	if bonus_ap_spent > 0:
		rabbit_step_bonus_ap = maxi(0, rabbit_step_bonus_ap - bonus_ap_spent)
		if rabbit_step_bonus_ap == 0:
			rabbit_step_cooldown_turns = 3
	return true

func get_rabbit_step_cooldown_turns() -> int:
	return rabbit_step_cooldown_turns
