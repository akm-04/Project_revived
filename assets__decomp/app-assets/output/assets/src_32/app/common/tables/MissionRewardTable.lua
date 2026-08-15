local var_0_0 = class("MissionRewardTable")
local var_0_1 = 5

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.medal_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.gift2_ = {}

	import("app.common.tables.TableParser").parse("mission_reward_daily.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.medal_[var_2_0] = tonumber(arg_2_0.medal)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift_exp)
		arg_1_0.gift2_[var_2_0] = tonumber(arg_2_0.gift_march_coin)
	end)
	import("app.common.tables.TableParser").parse("mission_reward_week.lua", function(arg_3_0)
		local var_3_0 = tonumber(arg_3_0.id) + var_0_1

		arg_1_0.medal_[var_3_0] = tonumber(arg_3_0.medal)
		arg_1_0.gift_[var_3_0] = tonumber(arg_3_0.gift)
		arg_1_0.gift2_[var_3_0] = tonumber(arg_3_0.gift)
	end)
end

function var_0_0.medal(arg_4_0, arg_4_1)
	return arg_4_0.medal_[arg_4_1] or 0
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.gift2(arg_6_0, arg_6_1)
	return arg_6_0.gift2_[arg_6_1] or 0
end

return var_0_0
