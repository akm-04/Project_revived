local var_0_0 = class("ActivityFirstChargeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.giftId_ = {}

	import("app.common.tables.TableParser").parse("activity_first_charge.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
	end)
end

function var_0_0.giftId(arg_3_0, arg_3_1)
	return arg_3_0.giftId_[arg_3_1] or 0
end

return var_0_0
