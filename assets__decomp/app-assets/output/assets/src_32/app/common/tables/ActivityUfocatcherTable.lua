local var_0_0 = class("ActivityUfocatcherTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gifts_ = {}
	arg_1_0.catch_rates_ = {}
	arg_1_0.appear_rates_ = {}

	import("app.common.tables.TableParser").parse("activity_ufocatcher.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gifts_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.catch_rates_ = tonumber(arg_2_0.catch_rate)
		arg_1_0.appear_rates_ = tonumber(arg_2_0.appear_rate)
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.gifts_[arg_3_1] or 0
end

function var_0_0.gifts(arg_4_0)
	return arg_4_0.gifts_ or {}
end

function var_0_0.catchRate(arg_5_0, arg_5_1)
	return arg_5_0.catch_rates_[arg_5_1] or 0
end

function var_0_0.appearRate(arg_6_0, arg_6_1)
	return arg_6_0.appear_rates_[arg_6_1] or 0
end

return var_0_0
