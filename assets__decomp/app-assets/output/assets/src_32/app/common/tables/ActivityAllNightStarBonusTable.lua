local var_0_0 = class("ActivityAllNightStarBonusTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.starNums_ = {}
	arg_1_0.awardIDs_ = {}
	arg_1_0.awardNums_ = {}

	import("app.common.tables.TableParser").parse("activity_polar_night_star_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.bonus_id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.starNums_[var_2_0] = tonumber(arg_2_0.star_num)
		arg_1_0.awardIDs_[var_2_0] = xyd.splitToNumber(arg_2_0.award_id, "|")
		arg_1_0.awardNums_[var_2_0] = xyd.splitToNumber(arg_2_0.award_num, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.starNums(arg_4_0, arg_4_1)
	return arg_4_0.starNums_[arg_4_1] or 0
end

function var_0_0.awardIDs(arg_5_0, arg_5_1)
	return arg_5_0.awardIDs_[arg_5_1] or {}
end

function var_0_0.awardNums(arg_6_0, arg_6_1)
	return arg_6_0.awardNums_[arg_6_1] or {}
end

return var_0_0
