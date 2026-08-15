local var_0_0 = class("ActivityPointTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.point_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.exchangeLimit_ = {}
	arg_1_0.beginDay_ = {}

	import("app.common.tables.TableParser").parse("activity_integral.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.integral)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.exchangeLimit_[var_2_0] = tonumber(arg_2_0.exchange_limit)
		arg_1_0.beginDay_[var_2_0] = tonumber(arg_2_0.begin_day)
	end)
end

function var_0_0.point(arg_3_0, arg_3_1)
	local var_3_0 = tonumber(arg_3_1)

	return arg_3_0.point_[var_3_0] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	local var_4_0 = tonumber(arg_4_1)

	return arg_4_0.name_[var_4_0] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	local var_5_0 = tonumber(arg_5_1)

	return arg_5_0.gift_[var_5_0] or 0
end

function var_0_0.exchangeLimit(arg_6_0, arg_6_1)
	local var_6_0 = tonumber(arg_6_1)

	return arg_6_0.exchangeLimit_[var_6_0] or 0
end

function var_0_0.beginDay(arg_7_0, arg_7_1)
	local var_7_0 = tonumber(arg_7_1)

	return arg_7_0.beginDay_[var_7_0] or 0
end

return var_0_0
