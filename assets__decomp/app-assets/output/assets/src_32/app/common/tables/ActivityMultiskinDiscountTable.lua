local var_0_0 = class("ActivityMultiskinDiscountTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.discount_ = {}

	import("app.common.tables.TableParser").parse("activity_multiskin_discount.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)
	end)
end

function var_0_0.discount(arg_3_0, arg_3_1)
	return arg_3_0.discount_[arg_3_1] or 0
end

function var_0_0.ids(arg_4_0)
	return table.keys(arg_4_0.discount_)
end

return var_0_0
