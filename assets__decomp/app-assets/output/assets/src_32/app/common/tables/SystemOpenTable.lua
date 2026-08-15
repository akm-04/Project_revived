local var_0_0 = class("SystemOpenTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.month_ = {}
	arg_1_0.day_ = {}
	arg_1_0.week_ = {}
	arg_1_0.time_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("system_open.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.function_id)

		arg_1_0.month_[var_2_0] = xyd.splitToNumber(arg_2_0.month, "|")
		arg_1_0.day_[var_2_0] = xyd.splitToNumber(arg_2_0.month_day, "|")
		arg_1_0.week_[var_2_0] = xyd.splitToNumber(arg_2_0.week_day, "|")

		local var_2_1 = xyd.split(arg_2_0.time, "|")

		arg_1_0.time_[var_2_0] = {}

		if var_2_1 and next(var_2_1) then
			for iter_2_0 = 1, #var_2_1 do
				local var_2_2 = xyd.split(var_2_1[iter_2_0], "&")

				for iter_2_1 = 1, #var_2_2 do
					local var_2_3 = xyd.split(var_2_2[iter_2_1], ":")
					local var_2_4 = 0

					for iter_2_2 = 1, #var_2_3 do
						if iter_2_2 == 1 then
							var_2_4 = var_2_4 + var_2_3[iter_2_2] * 3600
						else
							var_2_4 = var_2_4 + var_2_3[iter_2_2] * 60
						end
					end

					table.insert(arg_1_0.time_[var_2_0], var_2_4)
				end
			end
		end

		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.month(arg_3_0, arg_3_1)
	return arg_3_0.month_[arg_3_1]
end

function var_0_0.day(arg_4_0, arg_4_1)
	return arg_4_0.day_[arg_4_1]
end

function var_0_0.week(arg_5_0, arg_5_1)
	return arg_5_0.week_[arg_5_1]
end

function var_0_0.time(arg_6_0, arg_6_1)
	return arg_6_0.time_[arg_6_1]
end

function var_0_0.name(arg_7_0, arg_7_1)
	return arg_7_0.name_[arg_7_1]
end

return var_0_0
