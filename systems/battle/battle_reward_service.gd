class_name BattleRewardService
extends RefCounted

func build_reward_payload(battle_state: BattleState) -> Dictionary:
	return {
		"exp_reward": battle_state.exp_reward,
		"reward_card_ids": battle_state.reward_card_ids.duplicate()
	}
