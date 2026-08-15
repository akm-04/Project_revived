local var_0_0 = class("AllNightBossAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.range_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_polar_night_rank.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.range(arg_3_0, arg_3_1)
	return arg_3_0.range_[arg_3_1] or 0
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.RewardCount(arg_5_0)
	return #arg_5_0.range_ or 0
end

return var_0_0
