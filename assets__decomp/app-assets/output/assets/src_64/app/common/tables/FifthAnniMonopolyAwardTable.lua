local var_0_0 = class("FifthAnniMonopolyAwardTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.weight_ = {}
	arg_1_0.param_ = {}
	arg_1_0.message_ = {}

	import("app.common.tables.TableParser").parse("fifth_anni_monopoly_award.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.type_id)

		arg_1_0.weight_[var_2_0] = xyd.splitToNumber(arg_2_0.weight, "|")
		arg_1_0.param_[var_2_0] = xyd.splitToNumber(arg_2_0.param, "|")
		arg_1_0.message_[var_2_0] = xyd.split(arg_2_0.message, "|")
	end)
end

function var_0_0.weight(arg_3_0, arg_3_1)
	return arg_3_0.weight_[arg_3_1] or 0
end

function var_0_0.param(arg_4_0, arg_4_1)
	return arg_4_0.param_[arg_4_1] or 0
end

function var_0_0.message(arg_5_0, arg_5_1)
	return arg_5_0.message_[arg_5_1] or ""
end

return var_0_0
