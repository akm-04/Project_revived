local var_0_0 = class("ZhugeShopItemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.giftID_ = {}
	arg_1_0.price_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.conditionDesc_ = {}

	import("app.common.tables.TableParser").parse("zhuge_shop_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)
		arg_1_0.conditionDesc_[var_2_0] = arg_2_0.condition_desc
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.giftID(arg_4_0, arg_4_1)
	return arg_4_0.giftID_[arg_4_1] or 0
end

function var_0_0.price(arg_5_0, arg_5_1)
	return arg_5_0.price_[arg_5_1] or 0
end

function var_0_0.buyLimit(arg_6_0, arg_6_1)
	return arg_6_0.buyLimit_[arg_6_1] or -1
end

function var_0_0.condition(arg_7_0, arg_7_1)
	return arg_7_0.condition_[arg_7_1] or 0
end

function var_0_0.conditionDesc(arg_8_0, arg_8_1)
	return arg_8_0.conditionDesc_[arg_8_1] or ""
end

return var_0_0
