local var_0_0 = class("ActivityAnni4thMapShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.giftId_ = {}
	arg_1_0.limitNum_ = {}
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("activity_anni4_campaign_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftId_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.limitNum_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.giftId(arg_3_0, arg_3_1)
	return arg_3_0.giftId_[arg_3_1] or 0
end

function var_0_0.limitNum(arg_4_0, arg_4_1)
	return arg_4_0.limitNum_[arg_4_1] or 0
end

function var_0_0.price(arg_5_0, arg_5_1)
	return arg_5_0.price_[arg_5_1] or 0
end

function var_0_0.ids(arg_6_0, ...)
	return table.keys(arg_6_0.giftId_) or {}
end

return var_0_0
