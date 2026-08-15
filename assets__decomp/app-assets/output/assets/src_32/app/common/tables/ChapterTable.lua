local var_0_0 = class("ChapterTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.normal_ = {}
	arg_1_0.super_ = {}
	arg_1_0.team_ = {}
	arg_1_0.challenge_ = {}
	arg_1_0.nextId_ = {}
	arg_1_0.eventType_ = {}
	arg_1_0.eventCondition_ = {}
	arg_1_0.eventBossId_ = {}
	arg_1_0.eventBattleId_ = {}
	arg_1_0.eventGift_ = {}
	arg_1_0.rewardDisplay_ = {}
	arg_1_0.rewardDisplayNums_ = {}
	arg_1_0.eventEnergyNeed_ = {}
	arg_1_0.eventGuide_ = {}
	arg_1_0.eventOpenTimes_ = {}
	arg_1_0.x_ = {}
	arg_1_0.y_ = {}
	arg_1_0.hideBossMesc_ = {}
	arg_1_0.hideSmallBg_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("chapter.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.normal_[var_2_0] = xyd.splitToNumber(arg_2_0.normal, "|")
		arg_1_0.super_[var_2_0] = xyd.splitToNumber(arg_2_0.super, "|")
		arg_1_0.team_[var_2_0] = tonumber(arg_2_0.team)
		arg_1_0.challenge_[var_2_0] = xyd.splitToNumber(arg_2_0.challenge, "|")
		arg_1_0.nextId_[var_2_0] = tonumber(arg_2_0.next_id)
		arg_1_0.eventType_[var_2_0] = tonumber(arg_2_0.event_type)
		arg_1_0.eventCondition_[var_2_0] = xyd.splitToNumber(arg_2_0.event_condition, "|")
		arg_1_0.eventBossId_[var_2_0] = tonumber(arg_2_0.event_boss_id)
		arg_1_0.eventBattleId_[var_2_0] = tonumber(arg_2_0.event_battle_id)
		arg_1_0.eventGift_[var_2_0] = tonumber(arg_2_0.event_gift)
		arg_1_0.rewardDisplay_[var_2_0] = xyd.splitToNumber(arg_2_0.reward_display, "|")
		arg_1_0.rewardDisplayNums_[var_2_0] = xyd.splitToNumber(arg_2_0.reward_display_nums, "|")
		arg_1_0.eventEnergyNeed_[var_2_0] = tonumber(arg_2_0.event_energy_need)
		arg_1_0.eventGuide_[var_2_0] = tonumber(arg_2_0.event_guide)
		arg_1_0.eventOpenTimes_[var_2_0] = tonumber(arg_2_0.event_open_times)
		arg_1_0.x_[var_2_0] = tonumber(arg_2_0.x)
		arg_1_0.y_[var_2_0] = tonumber(arg_2_0.y)
		arg_1_0.hideBossMesc_[var_2_0] = arg_2_0.hide_boss_mesc
		arg_1_0.hideSmallBg_[var_2_0] = arg_2_0.hide_small_bg
		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.normal(arg_3_0, arg_3_1)
	return arg_3_0.normal_[arg_3_1] or {}
end

function var_0_0.super(arg_4_0, arg_4_1)
	return arg_4_0.super_[arg_4_1] or {}
end

function var_0_0.team(arg_5_0, arg_5_1)
	return arg_5_0.team_[arg_5_1] or 0
end

function var_0_0.challenge(arg_6_0, arg_6_1)
	return arg_6_0.challenge_[arg_6_1] or {}
end

function var_0_0.nextId(arg_7_0, arg_7_1)
	return arg_7_0.nextId_[arg_7_1] or 0
end

function var_0_0.eventType(arg_8_0, arg_8_1)
	return arg_8_0.eventType_[arg_8_1] or 0
end

function var_0_0.eventCondition(arg_9_0, arg_9_1)
	return arg_9_0.eventCondition_[arg_9_1] or {}
end

function var_0_0.eventBossId(arg_10_0, arg_10_1)
	return arg_10_0.eventBossId_[arg_10_1] or 0
end

function var_0_0.eventBattleId(arg_11_0, arg_11_1)
	return arg_11_0.eventBattleId_[arg_11_1] or 0
end

function var_0_0.eventGift(arg_12_0, arg_12_1)
	return arg_12_0.eventGift_[arg_12_1] or 0
end

function var_0_0.rewardDisplay(arg_13_0, arg_13_1)
	return arg_13_0.rewardDisplay_[arg_13_1] or {}
end

function var_0_0.rewardDisplayNums(arg_14_0, arg_14_1)
	return arg_14_0.rewardDisplayNums_[arg_14_1] or {}
end

function var_0_0.eventEnergyNeed(arg_15_0, arg_15_1)
	return arg_15_0.eventEnergyNeed_[arg_15_1] or 0
end

function var_0_0.eventGuide(arg_16_0, arg_16_1)
	return arg_16_0.eventGuide_[arg_16_1] or 0
end

function var_0_0.eventOpenTimes(arg_17_0, arg_17_1)
	return arg_17_0.eventOpenTimes_[arg_17_1] or 0
end

function var_0_0.x(arg_18_0, arg_18_1)
	return arg_18_0.x_[arg_18_1] or 0
end

function var_0_0.y(arg_19_0, arg_19_1)
	return arg_19_0.y_[arg_19_1] or 0
end

function var_0_0.hideBossMesc(arg_20_0, arg_20_1)
	return arg_20_0.hideBossMesc_[arg_20_1] or ""
end

function var_0_0.hideSmallBg(arg_21_0, arg_21_1)
	return arg_21_0.hideSmallBg_[arg_21_1] or ""
end

function var_0_0.name(arg_22_0, arg_22_1)
	return arg_22_0.name_[arg_22_1] or ""
end

return var_0_0
