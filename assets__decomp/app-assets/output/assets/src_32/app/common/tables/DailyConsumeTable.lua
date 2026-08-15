local var_0_0 = class("DailyConsumeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.dailyconsum_ = {}

	import("app.common.tables.TableParser").parse("daily_consume.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = arg_2_0.name
		local var_2_2 = arg_2_0.cost
		local var_2_3 = arg_2_0.num
		local var_2_4 = arg_2_0.value

		arg_1_0.dailyconsum_[var_2_0] = {
			name = var_2_1,
			cost = var_2_2,
			num = var_2_3,
			value = var_2_4
		}
	end)
end

function var_0_0.getName(arg_3_0, arg_3_1)
	return arg_3_0.dailyconsum_[arg_3_1].name or ""
end

function var_0_0.getCost(arg_4_0, arg_4_1)
	return tonumber(arg_4_0.dailyconsum_[arg_4_1].cost)
end

function var_0_0.getNum(arg_5_0, arg_5_1)
	return tonumber(arg_5_0.dailyconsum_[arg_5_1].num)
end

function var_0_0.getValue(arg_6_0, arg_6_1)
	return tonumber(arg_6_0.dailyconsum_[arg_6_1].value)
end

return var_0_0
