local var_0_0 = class("LukangExtraRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.progress_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_lukang_extra_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.progress_[var_2_0] = tonumber(arg_2_0.progress)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.progress(arg_3_0, arg_3_1)
	return arg_3_0.progress_[arg_3_1] or 0
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

return var_0_0
