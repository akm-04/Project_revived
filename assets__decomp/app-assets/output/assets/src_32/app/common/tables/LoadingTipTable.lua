local var_0_0 = class("LoadingTipTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.tips_ = {}

	import("app.common.tables.TableParser").parse("loading_tips.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.tips_[var_2_0] = arg_2_0.tips
	end)
end

function var_0_0.tip(arg_3_0, arg_3_1)
	return arg_3_0.tips_[arg_3_1] or ""
end

function var_0_0.tipNum(arg_4_0)
	return #arg_4_0.tips_
end

return var_0_0
