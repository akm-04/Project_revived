local var_0_0 = class("MarchAdvancedTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rateValue_ = {}
	arg_1_0.sweepNum_ = {}

	import("app.common.tables.TableParser").parse("march_advance.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.college_level)

		arg_1_0.rateValue_[var_2_0] = xyd.splitToNumber(arg_2_0.rate_fight, "|")
		arg_1_0.sweepNum_[var_2_0] = xyd.split(arg_2_0.clean_numb, "|")
	end)
end

function var_0_0.rateValue(arg_3_0, arg_3_1)
	return arg_3_0.rateValue_[arg_3_1] or ""
end

function var_0_0.sweepNum(arg_4_0, arg_4_1)
	return arg_4_0.sweepNum_[arg_4_1] or ""
end

return var_0_0
