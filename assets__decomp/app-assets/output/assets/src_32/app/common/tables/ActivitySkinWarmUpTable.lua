local var_0_0 = class("ActivitySkinWarmUpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids = {}
	arg_1_0.serverCharge_ = {}
	arg_1_0.serverDiscount_ = {}
	arg_1_0.charge_ = {}
	arg_1_0.discount_ = {}
	arg_1_0.giftId_ = {}

	import("app.common.tables.TableParser").parse("activity_skin_warmup.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.serverCharge_[var_2_0] = tonumber(arg_2_0.server_charge)
		arg_1_0.serverDiscount_[var_2_0] = tonumber(arg_2_0.server_discount)
		arg_1_0.charge_[var_2_0] = tonumber(arg_2_0.charge)
		arg_1_0.discount_[var_2_0] = tonumber(arg_2_0.discount)

		table.insert(arg_1_0.ids, var_2_0)
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.giftId_[arg_3_1] or 0
end

function var_0_0.serverCharge(arg_4_0, arg_4_1)
	return arg_4_0.serverCharge_[arg_4_1] or 0
end

function var_0_0.serverDiscount(arg_5_0, arg_5_1)
	return arg_5_0.serverDiscount_[arg_5_1] or 0
end

function var_0_0.charge(arg_6_0, arg_6_1)
	return arg_6_0.charge_[arg_6_1] or 0
end

function var_0_0.discount(arg_7_0, arg_7_1)
	return arg_7_0.discount_[arg_7_1] or 0
end

function var_0_0.getIds(arg_8_0)
	return arg_8_0.ids or {}
end

return var_0_0
