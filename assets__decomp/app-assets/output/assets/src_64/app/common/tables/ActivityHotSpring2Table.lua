local var_0_0 = class("ActivityHotSpring2Table")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.exclude_ = {}
	arg_1_0.gift_ = {}

	import("app.common.tables.TableParser").parse("activity_skin_set2.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.charge_[var_2_0] = xyd.splitToNumber(arg_2_0.charge, "|")
		arg_1_0.exclude_[var_2_0] = xyd.splitToNumber(arg_2_0.exclude, "|")
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.charge(arg_4_0, arg_4_1)
	return arg_4_0.charge_[arg_4_1][1] or 0
end

function var_0_0.exclude(arg_5_0, arg_5_1)
	return arg_5_0.exclude_[arg_5_1] or {}
end

function var_0_0.getGift(arg_6_0, arg_6_1)
	return arg_6_0.gift_[arg_6_1] or 0
end

return var_0_0
