local var_0_0 = class("AbtestTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.uniqueKey_ = {}

	import("app.common.tables.TableParser").parse("abtest.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.uniqueKey_[var_2_0] = arg_2_0.unique_key
	end)
end

function var_0_0.uniqueKey(arg_3_0, arg_3_1)
	return arg_3_0.uniqueKey_[arg_3_1] or ""
end

return var_0_0
