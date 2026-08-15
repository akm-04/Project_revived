local var_0_0 = class("ActivityTutorRankTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rank_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.title_ = {}

	import("app.common.tables.TableParser").parse("activity_tutor_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.rank_[var_2_0] = xyd.splitToNumber(arg_2_0.rank, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.title_[var_2_0] = tonumber(arg_2_0.title)
	end)
end

function var_0_0.getRank(arg_3_0)
	return arg_3_0.rank_ or {}
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.title(arg_5_0, arg_5_1)
	return arg_5_0.title_[arg_5_1] or 0
end

return var_0_0
