local var_0_0 = class("SnowGachaBuyTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.coin_ = {}
	arg_1_0.cost_ = {}

	import("app.common.tables.TableParser").parse("activity_snowman_gacha_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.coin_[var_2_0] = tonumber(arg_2_0.coin_num)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
	end)
end

function var_0_0.coin(arg_3_0, arg_3_1)
	return arg_3_0.coin_[arg_3_1] or 0
end

function var_0_0.cost(arg_4_0, arg_4_1)
	return arg_4_0.cost_[arg_4_1] or 0
end

return var_0_0
