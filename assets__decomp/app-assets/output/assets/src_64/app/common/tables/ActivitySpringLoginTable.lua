local var_0_0 = class("ActivitySpringLoginTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.effect_ = {}

	import("app.common.tables.TableParser").parse("activity_springlogin.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.effect_[var_2_0] = tonumber(arg_2_0.effect)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.getGift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.setEffect(arg_5_0, arg_5_1)
	return arg_5_0.effect_[arg_5_1] or 0
end

function var_0_0.all(arg_6_0)
	return arg_6_0.name_
end

return var_0_0
