local var_0_0 = class("ActivitySnowShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.giftID_ = {}
	arg_1_0.price_ = {}
	arg_1_0.vip_ = {}

	import("app.common.tables.TableParser").parse("activity_snowman_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.vip_[var_2_0] = tonumber(arg_2_0.vip)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.price(arg_4_0, arg_4_1)
	return arg_4_0.price_[arg_4_1] or 0
end

function var_0_0.vip(arg_5_0, arg_5_1)
	return arg_5_0.vip_[arg_5_1] or 0
end

function var_0_0.giftID(arg_6_0, arg_6_1)
	return arg_6_0.giftID_[arg_6_1] or 0
end

return var_0_0
