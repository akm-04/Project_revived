local var_0_0 = class("ActivityScholarshipRewardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.range_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_scholarship_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.ids_[var_2_0] = var_2_0
		arg_1_0.range_[var_2_0] = tonumber(arg_2_0.range)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.ids(arg_3_0, arg_3_1)
	return arg_3_0.ids_ or {}
end

function var_0_0.range(arg_4_0, arg_4_1)
	return arg_4_0.range_[arg_4_1] or 0
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

return var_0_0
