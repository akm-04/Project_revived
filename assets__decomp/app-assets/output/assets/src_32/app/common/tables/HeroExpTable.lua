local var_0_0 = class("HeroExpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.addExps_ = {}
	arg_1_0.totalExps_ = {}

	import("app.common.tables.TableParser").parse("partner_exp.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.lv)

		arg_1_0.addExps_[var_2_0] = tonumber(arg_2_0.exp)
		arg_1_0.totalExps_[var_2_0] = tonumber(arg_2_0.total_exp)
	end)
end

function var_0_0.addExp(arg_3_0, arg_3_1)
	return arg_3_0.addExps_[arg_3_1] or 0
end

function var_0_0.totalExp(arg_4_0, arg_4_1)
	return arg_4_0.totalExps_[arg_4_1] or 0
end

return var_0_0
