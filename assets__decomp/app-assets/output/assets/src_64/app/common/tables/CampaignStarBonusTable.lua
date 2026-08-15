local var_0_0 = class("CampaignStarBonusTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.nextIDs_ = {}
	arg_1_0.bonusTypes_ = {}
	arg_1_0.starNums_ = {}
	arg_1_0.awardCrystals_ = {}
	arg_1_0.awardManas_ = {}
	arg_1_0.awardIDs_ = {}
	arg_1_0.awardNums_ = {}

	import("app.common.tables.TableParser").parse("campaign_star_bonus.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.bonus_id)

		arg_1_0.nextIDs_[var_2_0] = tonumber(arg_2_0.next_bonus_id)
		arg_1_0.bonusTypes_[var_2_0] = tonumber(arg_2_0.bonus_type)
		arg_1_0.starNums_[var_2_0] = tonumber(arg_2_0.star_num)
		arg_1_0.awardCrystals_[var_2_0] = tonumber(arg_2_0.award_crystal)
		arg_1_0.awardManas_[var_2_0] = tonumber(arg_2_0.award_mana)
		arg_1_0.awardIDs_[var_2_0] = xyd.splitToNumber(arg_2_0.award_id, "|")
		arg_1_0.awardNums_[var_2_0] = xyd.splitToNumber(arg_2_0.award_num, "|")
	end)
end

function var_0_0.nextID(arg_3_0, arg_3_1)
	return arg_3_0.nextIDs_[arg_3_1] or 0
end

function var_0_0.bonusType(arg_4_0, arg_4_1)
	return arg_4_0.bonusTypes_[arg_4_1] or 0
end

function var_0_0.starNum(arg_5_0, arg_5_1)
	return arg_5_0.starNums_[arg_5_1] or 0
end

function var_0_0.awardCrystal(arg_6_0, arg_6_1)
	return arg_6_0.awardCrystals_[arg_6_1] or 0
end

function var_0_0.awardMana(arg_7_0, arg_7_1)
	return arg_7_0.awardManas_[arg_7_1] or 0
end

function var_0_0.awardID(arg_8_0, arg_8_1)
	return arg_8_0.awardIDs_[arg_8_1] or {}
end

function var_0_0.awardNum(arg_9_0, arg_9_1)
	return arg_9_0.awardNums_[arg_9_1] or {}
end

return var_0_0
