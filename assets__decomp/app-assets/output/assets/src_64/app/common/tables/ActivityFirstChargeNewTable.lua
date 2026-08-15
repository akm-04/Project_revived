local var_0_0 = class("ActivityFirstChargeNewTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.giftID_ = {}
	arg_1_0.des_ = {}

	import("app.common.tables.TableParser").parse("activty_firstcharge_new.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.des_[var_2_0] = tonumber(arg_2_0.des)
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.getGiftID(arg_4_0, arg_4_1)
	return arg_4_0.giftID_[arg_4_1] or 0
end

function var_0_0.getDes(arg_5_0, arg_5_1)
	return arg_5_0.des_[arg_5_1] or 0
end

return var_0_0
