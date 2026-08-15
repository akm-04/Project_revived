local var_0_0 = class("MonthlyPrivilegeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.sweepCard_ = {}
	arg_1_0.arenaReset_ = {}
	arg_1_0.goblin_ = {}
	arg_1_0.crusade_ = {}
	arg_1_0.blackMarket_ = {}
	arg_1_0.crusadeProduction_ = {}
	arg_1_0.topReset_ = {}
	arg_1_0.spaceTrip_ = {}
	arg_1_0.teamGold_ = {}
	arg_1_0.tresureReward_ = {}
	arg_1_0.monthlyPrivilege_ = {}
	arg_1_0.iconDisplay_ = {}
	arg_1_0.numEnergy_ = {}
	arg_1_0.numMidas_ = {}
	arg_1_0.quickSweep_ = {}
	arg_1_0.numConquer_ = {}
	arg_1_0.avatarFrame_ = {}
	arg_1_0.skillMax_ = {}
	arg_1_0.numElite_ = {}

	import("app.common.tables.TableParser").parse("monthly_privilege.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.sweepCard_[var_2_0] = tonumber(arg_2_0.sweep_card)
		arg_1_0.arenaReset_[var_2_0] = tonumber(arg_2_0.arena_reset)
		arg_1_0.goblin_[var_2_0] = tonumber(arg_2_0.goblin)
		arg_1_0.skillMax_[var_2_0] = tonumber(arg_2_0.skill_max)
		arg_1_0.crusade_[var_2_0] = tonumber(arg_2_0.crusade)
		arg_1_0.blackMarket_[var_2_0] = tonumber(arg_2_0.black_market)
		arg_1_0.crusadeProduction_[var_2_0] = tonumber(arg_2_0.crusade_production)
		arg_1_0.topReset_[var_2_0] = tonumber(arg_2_0.top_reset)
		arg_1_0.spaceTrip_[var_2_0] = tonumber(arg_2_0.space_trip)
		arg_1_0.teamGold_[var_2_0] = tonumber(arg_2_0.team_gold)
		arg_1_0.tresureReward_[var_2_0] = tonumber(arg_2_0.tresure_reward)
		arg_1_0.monthlyPrivilege_[var_2_0] = arg_2_0.monthly_privilege
		arg_1_0.iconDisplay_[var_2_0] = tonumber(arg_2_0.icon_display)
		arg_1_0.numEnergy_[var_2_0] = tonumber(arg_2_0.num_energy)
		arg_1_0.numMidas_[var_2_0] = tonumber(arg_2_0.num_midas)
		arg_1_0.quickSweep_[var_2_0] = tonumber(arg_2_0.quick_sweep)
		arg_1_0.numConquer_[var_2_0] = tonumber(arg_2_0.num_conquer)
		arg_1_0.avatarFrame_[var_2_0] = arg_2_0.avatar_frame
		arg_1_0.numElite_[var_2_0] = tonumber(arg_2_0.num_elite)
	end)
end

function var_0_0.sweepCard(arg_3_0, arg_3_1)
	return arg_3_0.sweepCard_[arg_3_1] or 0
end

function var_0_0.arenaReset(arg_4_0, arg_4_1)
	return arg_4_0.arenaReset_[arg_4_1] or 0
end

function var_0_0.goblin(arg_5_0, arg_5_1)
	return arg_5_0.goblin_[arg_5_1] or 0
end

function var_0_0.skillMax(arg_6_0, arg_6_1)
	return arg_6_0.skillMax_[arg_6_1] or 0
end

function var_0_0.crusade(arg_7_0, arg_7_1)
	return arg_7_0.crusade_[arg_7_1] or 0
end

function var_0_0.blackMarket(arg_8_0, arg_8_1)
	return arg_8_0.blackMarket_[arg_8_1] or 0
end

function var_0_0.crusadeProduction(arg_9_0, arg_9_1)
	return arg_9_0.crusadeProduction_[arg_9_1] or 0
end

function var_0_0.topReset(arg_10_0, arg_10_1)
	return arg_10_0.topReset_[arg_10_1] or 0
end

function var_0_0.spaceTrip(arg_11_0, arg_11_1)
	return arg_11_0.spaceTrip_[arg_11_1] or 0
end

function var_0_0.teamGold(arg_12_0, arg_12_1)
	return arg_12_0.teamGold_[arg_12_1] or 0
end

function var_0_0.tresureReward(arg_13_0, arg_13_1)
	return arg_13_0.tresureReward_[arg_13_1] or 0
end

function var_0_0.monthlyPrivilege(arg_14_0, arg_14_1)
	return arg_14_0.monthlyPrivilege_[arg_14_1] or 0
end

function var_0_0.iconDisplay(arg_15_0, arg_15_1)
	return arg_15_0.iconDisplay_[arg_15_1] or 0
end

function var_0_0.numEnergy(arg_16_0, arg_16_1)
	return arg_16_0.numEnergy_[arg_16_1] or 0
end

function var_0_0.numMidas(arg_17_0, arg_17_1)
	return arg_17_0.numMidas_[arg_17_1] or 0
end

function var_0_0.numElite(arg_18_0, arg_18_1)
	return arg_18_0.numElite_[arg_18_1] or 0
end

function var_0_0.quickSweep(arg_19_0, arg_19_1)
	return arg_19_0.quickSweep_[arg_19_1] or 0
end

function var_0_0.numConquer(arg_20_0, arg_20_1)
	return arg_20_0.numConquer_[arg_20_1] or 0
end

function var_0_0.avatarFrame(arg_21_0, arg_21_1)
	return arg_21_0.avatarFrame_[arg_21_1] or ""
end

return var_0_0
