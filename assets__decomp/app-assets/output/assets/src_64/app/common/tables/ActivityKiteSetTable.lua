local var_0_0 = class("ActivityKiteSetTable ")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gift_ = {}
	arg_1_0.name_ = {}

	import("app.common.tables.TableParser").parse("activity_kite_set.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.name_[var_2_0] = arg_2_0.name
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.allcount(arg_5_0)
	return #arg_5_0.gift_
end

return var_0_0
