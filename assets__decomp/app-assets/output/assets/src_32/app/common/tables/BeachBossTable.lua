local var_0_0 = class("BeachBossTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.bossHp = {}
	arg_1_0.icon = {}
	arg_1_0.json = {}
	arg_1_0.atlas = {}
	arg_1_0.modelID = {}
	arg_1_0.isSkin = {}
	arg_1_0.partnerId = {}
	arg_1_0.rewardItem_ = {}
	arg_1_0.rewardNum_ = {}
	arg_1_0.score_ = {}

	import("app.common.tables.TableParser").parse("beach_boss.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.bossHp[var_2_0] = tonumber(arg_2_0.hp)
		arg_1_0.icon[var_2_0] = arg_2_0.icon
		arg_1_0.modelID[var_2_0] = tonumber(arg_2_0.modle)
		arg_1_0.isSkin[var_2_0] = tonumber(arg_2_0.is_skin)
		arg_1_0.partnerId[var_2_0] = tonumber(arg_2_0.partner_id)
		arg_1_0.rewardItem_[var_2_0] = xyd.splitToNumber(arg_2_0.reward_item, "|")
		arg_1_0.rewardNum_[var_2_0] = xyd.splitToNumber(arg_2_0.reward_num, "|")
		arg_1_0.score_[var_2_0] = tonumber(arg_2_0.score)
	end)
end

function var_0_0.getBossHp(arg_3_0, arg_3_1)
	return arg_3_0.bossHp[arg_3_1] or 0
end

function var_0_0.getScore(arg_4_0, arg_4_1)
	return arg_4_0.score_[arg_4_1] or 0
end

function var_0_0.getBossIcon(arg_5_0, arg_5_1)
	return arg_5_0.icon[arg_5_1] or ""
end

function var_0_0.getBossModelID(arg_6_0, arg_6_1)
	return arg_6_0.modelID[arg_6_1] or 0
end

function var_0_0.getIsSkin(arg_7_0, arg_7_1)
	return arg_7_0.isSkin[arg_7_1] or 0
end

function var_0_0.getPartnerId(arg_8_0, arg_8_1)
	return arg_8_0.partnerId[arg_8_1] or 0
end

function var_0_0.getBossCount(arg_9_0)
	return #arg_9_0.bossHp or 0
end

function var_0_0.rewardItem(arg_10_0, arg_10_1)
	return arg_10_0.rewardItem_[arg_10_1] or {}
end

function var_0_0.rewardNum(arg_11_0, arg_11_1)
	return arg_11_0.rewardNum_[arg_11_1] or {}
end

return var_0_0
