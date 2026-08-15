local var_0_0 = class("ActivityCandlePersonRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_ = {}
	arg_1_0.point_ = {}

	import("app.common.tables.TableParser").parse("activity_candle_person_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.gift_[arg_3_1] or 0
end

function var_0_0.point(arg_4_0, arg_4_1)
	return arg_4_0.point_[arg_4_1] or 0
end

function var_0_0.ids(arg_5_0, arg_5_1)
	return table.keys(arg_5_0.gift_)
end

return var_0_0
