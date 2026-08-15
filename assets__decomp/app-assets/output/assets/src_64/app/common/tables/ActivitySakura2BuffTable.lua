local var_0_0 = class("ActivitySakura2BuffTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.buff_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura2_buff.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.partner)

		arg_1_0.buff_[var_2_0] = xyd.splitToNumber(arg_2_0.buff, "|")
	end)
end

function var_0_0.buff(arg_3_0, arg_3_1)
	return arg_3_0.buff_[arg_3_1] or {}
end

return var_0_0
