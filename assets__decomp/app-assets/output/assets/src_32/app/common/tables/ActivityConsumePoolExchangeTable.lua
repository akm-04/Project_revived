local var_0_0 = class("ActivityConsumePoolExchangeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_ = {}
	arg_1_0.pt_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.rare_ = {}

	import("app.common.tables.TableParser").parse("activity_consume_pool_exchange.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.pt_[var_2_0] = tonumber(arg_2_0.pt)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.rare_[var_2_0] = tonumber(arg_2_0.rare)
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.gift_[arg_3_1] or 0
end

function var_0_0.pt(arg_4_0, arg_4_1)
	return arg_4_0.pt_[arg_4_1] or 0
end

function var_0_0.buyLimit(arg_5_0, arg_5_1)
	return arg_5_0.buyLimit_[arg_5_1] or 0
end

function var_0_0.rare(arg_6_0, arg_6_1)
	return arg_6_0.rare_[arg_6_1] or 0
end

function var_0_0.count(arg_7_0, ...)
	return #table.keys(arg_7_0.gift_)
end

return var_0_0
