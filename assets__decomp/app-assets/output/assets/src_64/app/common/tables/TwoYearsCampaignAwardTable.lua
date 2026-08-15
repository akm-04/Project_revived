local var_0_0 = class("TwoYearsCampaignAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.star_ = {}
	arg_1_0.reward_ = {}

	import("app.common.tables.TableParser").parse("activity_anni2_reward.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.lv)

		arg_1_0.star_[var_2_0] = tonumber(arg_2_0.star)
		arg_1_0.reward_[var_2_0] = tonumber(arg_2_0.reward)
	end)
end

function var_0_0.stars(arg_3_0)
	return arg_3_0.star_
end

function var_0_0.reward(arg_4_0, arg_4_1)
	return arg_4_0.reward_[arg_4_1]
end

return var_0_0
