local var_0_0 = class("ActivityChocolateFruitTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.x_ = {}
	arg_1_0.y_ = {}
	arg_1_0.times_ = {}
	arg_1_0.point_ = {}
	arg_1_0.num_ = {}
	arg_1_0.open_ = {}
	arg_1_0.cut_ = {}
	arg_1_0.speed_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("activity_chocolate_fruit.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.x_[var_2_0] = xyd.splitToNumber(arg_2_0.x, "|")
		arg_1_0.y_[var_2_0] = xyd.splitToNumber(arg_2_0.y, "|")
		arg_1_0.times_[var_2_0] = tonumber(arg_2_0.times)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
		arg_1_0.num_[var_2_0] = xyd.splitToNumber(arg_2_0.num, "|")
		arg_1_0.open_[var_2_0] = xyd.splitToNumber(arg_2_0.open, "|")
		arg_1_0.cut_[var_2_0] = tonumber(arg_2_0.cut)
		arg_1_0.speed_[var_2_0] = xyd.splitToNumber(arg_2_0.speed, "|")
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.x(arg_4_0, arg_4_1)
	return arg_4_0.x_[arg_4_1] or {}
end

function var_0_0.y(arg_5_0, arg_5_1)
	return arg_5_0.y_[arg_5_1] or {}
end

function var_0_0.times(arg_6_0, arg_6_1)
	return arg_6_0.times_[arg_6_1] or 0
end

function var_0_0.point(arg_7_0, arg_7_1)
	return arg_7_0.point_[arg_7_1] or 0
end

function var_0_0.num(arg_8_0, arg_8_1)
	return arg_8_0.num_[arg_8_1] or {}
end

function var_0_0.open(arg_9_0, arg_9_1)
	return arg_9_0.open_[arg_9_1] or {}
end

function var_0_0.cut(arg_10_0, arg_10_1)
	return arg_10_0.cut_[arg_10_1] or 0
end

function var_0_0.speed(arg_11_0, arg_11_1)
	return arg_11_0.speed_[arg_11_1] or {}
end

function var_0_0.rate(arg_12_0, arg_12_1)
	return arg_12_0.rate_[arg_12_1] or 0
end

function var_0_0.icon(arg_13_0, arg_13_1)
	return arg_13_0.icon_[arg_13_1] or ""
end

function var_0_0.ids(arg_14_0)
	return table.keys(arg_14_0.name_)
end

function var_0_0.accumulateRate(arg_15_0)
	local var_15_0 = {}
	local var_15_1 = 0

	for iter_15_0 = 1, #arg_15_0.rate_ do
		var_15_1 = var_15_1 + arg_15_0.rate_[iter_15_0]
		var_15_0[iter_15_0] = var_15_1
	end

	return var_15_0
end

return var_0_0
