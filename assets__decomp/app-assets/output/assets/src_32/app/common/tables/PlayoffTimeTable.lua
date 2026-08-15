local var_0_0 = class("PlayoffTimeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.year_ = {}
	arg_1_0.month_ = {}
	arg_1_0.day_ = {}
	arg_1_0.hour_ = {}
	arg_1_0.minute_ = {}
	arg_1_0.project_ = {}

	import("app.common.tables.TableParser").parse("playoff_time.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.stage)

		arg_1_0.year_[var_2_0] = tonumber(arg_2_0.year)
		arg_1_0.month_[var_2_0] = tonumber(arg_2_0.month)
		arg_1_0.day_[var_2_0] = tonumber(arg_2_0.day)
		arg_1_0.hour_[var_2_0] = tonumber(arg_2_0.hour)
		arg_1_0.minute_[var_2_0] = tonumber(arg_2_0.minute)
		arg_1_0.project_[var_2_0] = arg_2_0.project
	end)
end

function var_0_0.year(arg_3_0, arg_3_1)
	return arg_3_0.year_[arg_3_1] or 0
end

function var_0_0.month(arg_4_0, arg_4_1)
	return arg_4_0.month_[arg_4_1] or 0
end

function var_0_0.day(arg_5_0, arg_5_1)
	return arg_5_0.day_[arg_5_1] or 0
end

function var_0_0.hour(arg_6_0, arg_6_1)
	return arg_6_0.hour_[arg_6_1] or 0
end

function var_0_0.minute(arg_7_0, arg_7_1)
	return arg_7_0.minute_[arg_7_1] or 0
end

function var_0_0.project(arg_8_0, arg_8_1)
	return arg_8_0.project_[arg_8_1] or 0
end

return var_0_0
