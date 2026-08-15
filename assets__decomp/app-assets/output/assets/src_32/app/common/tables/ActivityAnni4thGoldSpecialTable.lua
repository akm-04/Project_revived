local var_0_0 = class("ActivityAnni4thGoldSpecialTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.level_ = {}
	arg_1_0.mapSequence_ = {}
	arg_1_0.score_ = {}

	import("app.common.tables.TableParser").parse("activity_anni_4th_gold_special.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.mapSequence_[var_2_0] = xyd.splitToNumber(arg_2_0.map_sequence, "|")
		arg_1_0.score_[var_2_0] = tonumber(arg_2_0.score)
	end)
end

function var_0_0.level(arg_3_0, arg_3_1)
	return arg_3_0.level_[arg_3_1] or 0
end

function var_0_0.mapSequence(arg_4_0, arg_4_1)
	return arg_4_0.mapSequence_[arg_4_1] or {}
end

function var_0_0.score(arg_5_0, arg_5_1)
	return arg_5_0.score_[arg_5_1] or 0
end

function var_0_0.level(arg_6_0)
	return arg_6_0.level_ or {}
end

function var_0_0.getScore(arg_7_0)
	return arg_7_0.score_ or {}
end

return var_0_0
