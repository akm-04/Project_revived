local var_0_0 = class("VipTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.vipLev_ = {}
	arg_1_0.chargeReq_ = {}
	arg_1_0.sweepCard_ = {}
	arg_1_0.numEnergy_ = {}
	arg_1_0.numMidas_ = {}
	arg_1_0.numElite_ = {}
	arg_1_0.numArena_ = {}
	arg_1_0.numGlue_ = {}
	arg_1_0.sweepBuy_ = {}
	arg_1_0.skillBuy_ = {}
	arg_1_0.arenaReset_ = {}
	arg_1_0.quickSweep_ = {}
	arg_1_0.skillMax_ = {}
	arg_1_0.numWorship_ = {}
	arg_1_0.advanceWorship_ = {}
	arg_1_0.goblin_ = {}
	arg_1_0.crusade_ = {}
	arg_1_0.blackMarket_ = {}
	arg_1_0.soulBox_ = {}
	arg_1_0.crusadeProduct_ = {}
	arg_1_0.numMercenary_ = {}
	arg_1_0.numStudy_ = {}
	arg_1_0.treasureTeamOpen_ = {}
	arg_1_0.treasureNumSP_ = {}
	arg_1_0.vipPrivilege_ = {}
	arg_1_0.buyElementTimes_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.bless_value_ = {}
	arg_1_0.incubus_reset_ = {}
	arg_1_0.illusion_reset_ = {}
	arg_1_0.tresure_reward_ = {}
	arg_1_0.presetNum_ = {}
	arg_1_0.recallGift_ = {}
	arg_1_0.recallChargeGift_ = {}

	import("app.common.tables.TableParser").parse("vip.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.vipLev_[var_2_0] = tonumber(arg_2_0.id)
		arg_1_0.chargeReq_[var_2_0] = tonumber(arg_2_0.charge_req)
		arg_1_0.sweepCard_[var_2_0] = tonumber(arg_2_0.sweep_card)
		arg_1_0.numEnergy_[var_2_0] = tonumber(arg_2_0.num_energy)
		arg_1_0.numMidas_[var_2_0] = tonumber(arg_2_0.num_midas)
		arg_1_0.numElite_[var_2_0] = tonumber(arg_2_0.num_elite)
		arg_1_0.numArena_[var_2_0] = tonumber(arg_2_0.num_arena)
		arg_1_0.numGlue_[var_2_0] = tonumber(arg_2_0.num_glue)
		arg_1_0.sweepBuy_[var_2_0] = tonumber(arg_2_0.sweep_buy)
		arg_1_0.skillBuy_[var_2_0] = tonumber(arg_2_0.skill_buy)
		arg_1_0.arenaReset_[var_2_0] = tonumber(arg_2_0.arena_reset)
		arg_1_0.quickSweep_[var_2_0] = tonumber(arg_2_0.quick_sweep)
		arg_1_0.skillMax_[var_2_0] = tonumber(arg_2_0.skill_max)
		arg_1_0.numWorship_[var_2_0] = tonumber(arg_2_0.num_worship)
		arg_1_0.advanceWorship_[var_2_0] = tonumber(arg_2_0.advadnce_worship)
		arg_1_0.goblin_[var_2_0] = tonumber(arg_2_0.goblin)
		arg_1_0.crusade_[var_2_0] = tonumber(arg_2_0.crusade)
		arg_1_0.blackMarket_[var_2_0] = tonumber(arg_2_0.black_market)
		arg_1_0.soulBox_[var_2_0] = tonumber(arg_2_0.soul_box)
		arg_1_0.crusadeProduct_[var_2_0] = tonumber(arg_2_0.crusade_product)
		arg_1_0.numMercenary_[var_2_0] = tonumber(arg_2_0.num_mercenary)
		arg_1_0.numStudy_[var_2_0] = tonumber(arg_2_0.num_study)
		arg_1_0.treasureTeamOpen_[var_2_0] = tonumber(arg_2_0.treasure_team_open)
		arg_1_0.treasureNumSP_[var_2_0] = tonumber(arg_2_0.treasure_num_sp)
		arg_1_0.vipPrivilege_[var_2_0] = arg_2_0.vip_privilege
		arg_1_0.buyElementTimes_[var_2_0] = tonumber(arg_2_0.num_boss)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.reward_item)
		arg_1_0.bless_value_[var_2_0] = tonumber(arg_2_0.bless_value)
		arg_1_0.incubus_reset_[var_2_0] = tonumber(arg_2_0.incubus)
		arg_1_0.illusion_reset_[var_2_0] = tonumber(arg_2_0.paradise_buy_num)
		arg_1_0.tresure_reward_[var_2_0] = tonumber(arg_2_0.tresure_reward)
		arg_1_0.presetNum_[var_2_0] = tonumber(arg_2_0.preset_num)
		arg_1_0.recallGift_[var_2_0] = tonumber(arg_2_0.recall_gift)
		arg_1_0.recallChargeGift_[var_2_0] = tonumber(arg_2_0.recall_charge_gift)
	end)
end

function var_0_0.getBlessValue(arg_3_0, arg_3_1)
	return arg_3_0.bless_value_[arg_3_1] or 0
end

function var_0_0.vipLevel(arg_4_0, arg_4_1)
	return arg_4_0.vipLev_[arg_4_1] or 0
end

function var_0_0.chargeReq(arg_5_0, arg_5_1)
	return arg_5_0.chargeReq_[arg_5_1] or 0
end

function var_0_0.sweepCard(arg_6_0, arg_6_1)
	return arg_6_0.sweepCard_[arg_6_1] or 0
end

function var_0_0.numEnergy(arg_7_0, arg_7_1)
	return arg_7_0.numEnergy_[arg_7_1] or 0
end

function var_0_0.dianJinNum(arg_8_0, arg_8_1)
	return arg_8_0.numMidas_[arg_8_1] or 0
end

function var_0_0.resetFuben(arg_9_0, arg_9_1)
	return arg_9_0.numElite_[arg_9_1] or 0
end

function var_0_0.numArena(arg_10_0, arg_10_1)
	return arg_10_0.numArena_[arg_10_1] or 0
end

function var_0_0.numGlue(arg_11_0, arg_11_1)
	return arg_11_0.numGlue_[arg_11_1] or 0
end

function var_0_0.sweepBuy(arg_12_0, arg_12_1)
	return arg_12_0.sweepBuy_[arg_12_1] == 1
end

function var_0_0.skillBuy(arg_13_0, arg_13_1)
	return arg_13_0.skillBuy_[arg_13_1] == 1
end

function var_0_0.arenaReset(arg_14_0, arg_14_1)
	return arg_14_0.arenaReset_[arg_14_1] == 1
end

function var_0_0.quickSweep(arg_15_0, arg_15_1)
	return arg_15_0.quickSweep_[arg_15_1] == 1
end

function var_0_0.skillPoint(arg_16_0, arg_16_1)
	return arg_16_0.skillMax_[arg_16_1] or 0
end

function var_0_0.numWorship(arg_17_0, arg_17_1)
	return arg_17_0.numWorship_[arg_17_1] or 0
end

function var_0_0.advanceWorship(arg_18_0, arg_18_1)
	return arg_18_0.advanceWorship_[arg_18_1] == 1
end

function var_0_0.goblinMarket(arg_19_0, arg_19_1)
	return arg_19_0.goblin_[arg_19_1] == 1
end

function var_0_0.yuanZhengNum(arg_20_0, arg_20_1)
	return arg_20_0.crusade_[arg_20_1] or 0
end

function var_0_0.blackMarket(arg_21_0, arg_21_1)
	return arg_21_0.blackMarket_[vipLevel] == 1
end

function var_0_0.soulBox(arg_22_0, arg_22_1)
	return arg_22_0.soulBox_[arg_22_1] or 0
end

function var_0_0.yuanzhengProduct(arg_23_0, arg_23_1)
	return arg_23_0.crusadeProduct_[arg_23_1] or 0
end

function var_0_0.employee(arg_24_0, arg_24_1)
	return arg_24_0.numMercenary_[arg_24_1] or 0
end

function var_0_0.numStudy(arg_25_0, arg_25_1)
	return arg_25_0.numStudy_[arg_25_1] or 1
end

function var_0_0.treasureTeamOpen(arg_26_0, arg_26_1)
	return arg_26_0.treasureTeamOpen_[arg_26_1] or 0
end

function var_0_0.treasureNumSP(arg_27_0, arg_27_1)
	return arg_27_0.treasureNumSP_[arg_27_1] or 0
end

function var_0_0.vipPrivilege(arg_28_0, arg_28_1)
	return arg_28_0.vipPrivilege_[arg_28_1] or 0
end

function var_0_0.gift(arg_29_0, arg_29_1)
	return arg_29_0.gift_[arg_29_1] or 0
end

function var_0_0.incubusReset(arg_30_0, arg_30_1)
	return arg_30_0.incubus_reset_[arg_30_1] or 0
end

function var_0_0.illusionReset(arg_31_0, arg_31_1)
	return arg_31_0.illusion_reset_[arg_31_1] or 0
end

function var_0_0.tresureReward(arg_32_0, arg_32_1)
	return arg_32_0.tresure_reward_[arg_32_1] or 1
end

function var_0_0.presetNum(arg_33_0, arg_33_1)
	return arg_33_0.presetNum_[arg_33_1] or 0
end

function var_0_0.recallGift(arg_34_0, arg_34_1)
	return arg_34_0.recallGift_[arg_34_1] or 0
end

function var_0_0.recallChargeGift(arg_35_0, arg_35_1)
	return arg_35_0.recallChargeGift_[arg_35_1] or 0
end

return var_0_0
