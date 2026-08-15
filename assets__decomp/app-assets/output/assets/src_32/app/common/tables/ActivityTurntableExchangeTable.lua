local var_0_0 = class("ActivityTurntableExchangeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.cost_ = {}

	import("app.common.tables.TableParser").parse("activity_turntable_exchange.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = arg_2_0.gift
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.cost_[var_2_0] = tonumber(arg_2_0.cost)
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.gift_[arg_3_1] or ""
end

function var_0_0.icon(arg_4_0, arg_4_1)
	return arg_4_0.icon_[arg_4_1] or ""
end

function var_0_0.cost(arg_5_0, arg_5_1)
	return arg_5_0.cost_[arg_5_1] or 0
end

return var_0_0
