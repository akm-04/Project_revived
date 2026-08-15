local var_0_0 = class("ActivityDeExchangeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.partnerId_ = {}
	arg_1_0.limitTimes_ = {}
	arg_1_0.isSx_ = {}

	import("app.common.tables.TableParser").parse("activity_de_exchange.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.partnerId_[var_2_0] = tonumber(arg_2_0.partner_id)
		arg_1_0.limitTimes_[var_2_0] = tonumber(arg_2_0.limit_times)
		arg_1_0.isSx_[var_2_0] = tonumber(arg_2_0.is_sx)
	end)
end

function var_0_0.max(arg_3_0)
	return #arg_3_0.partnerId_
end

function var_0_0.partnerId(arg_4_0, arg_4_1)
	return arg_4_0.partnerId_[arg_4_1] or 0
end

function var_0_0.limitTimes(arg_5_0, arg_5_1)
	return arg_5_0.limitTimes_[arg_5_1] or 0
end

function var_0_0.isSx(arg_6_0, arg_6_1)
	return arg_6_0.isSx_[arg_6_1] or 0
end

return var_0_0
