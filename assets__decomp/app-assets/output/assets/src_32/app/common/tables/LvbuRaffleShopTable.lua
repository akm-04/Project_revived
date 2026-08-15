local var_0_0 = class("LvbuRaffleShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_ = {}
	arg_1_0.num_ = {}
	arg_1_0.vip_ = {}
	arg_1_0.cost_ = {}
	arg_1_0.limit_ = {}
	arg_1_0.count = 0

	import("app.common.tables.TableParser").parse("activity_lvbu_exchange.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
		arg_1_0.limit_[var_2_0] = tonumber(arg_2_0.limit)
		arg_1_0.count = arg_1_0.count + 1
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.gift_[arg_3_1] or 0
end

function var_0_0.num(arg_4_0, arg_4_1)
	return arg_4_0.num_[arg_4_1] or 0
end

function var_0_0.vip(arg_5_0, arg_5_1)
	return arg_5_0.vip_[arg_5_1] or 0
end

function var_0_0.cost(arg_6_0, arg_6_1)
	return arg_6_0.cost_[arg_6_1] or 0
end

function var_0_0.limit(arg_7_0, arg_7_1)
	return arg_7_0.limit_[arg_7_1] or 0
end

return var_0_0
