local var_0_0 = class("ActivityServerChargeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.num_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.vip_ = {}

	import("app.common.tables.TableParser").parse("activity_servercharge.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)
	end)
end

function var_0_0.num(arg_3_0, arg_3_1)
	return arg_3_0.num_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.vip(arg_6_0, arg_6_1)
	return arg_6_0.vip_[arg_6_1] or 0
end

function var_0_0.gifts(arg_7_0)
	return arg_7_0.gift_ or {}
end

return var_0_0
