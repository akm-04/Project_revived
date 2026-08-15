local var_0_0 = class("WarCampShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.sellPriceAngel_ = {}
	arg_1_0.sellPriceDemon_ = {}
	arg_1_0.showItem_ = {}
	arg_1_0.pages_ = {}
	arg_1_0.limitNum_ = {}

	import("app.common.tables.TableParser").parse("camp_war_shop_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.sellPriceAngel_[var_2_0] = tonumber(arg_2_0.sell_price_angel)
		arg_1_0.sellPriceDemon_[var_2_0] = tonumber(arg_2_0.sell_price_demon)
		arg_1_0.showItem_[var_2_0] = tonumber(arg_2_0.show_item)
		arg_1_0.limitNum_[var_2_0] = tonumber(arg_2_0.limit_num)

		local var_2_1 = tonumber(arg_2_0.page)

		arg_1_0.ids_[var_2_1] = arg_1_0.ids_[var_2_1] or {}

		table.insert(arg_1_0.ids_[var_2_1], var_2_0)
	end)
end

function var_0_0.ids(arg_3_0, arg_3_1)
	return arg_3_0.ids_[arg_3_1] or {}
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1] or 0
end

function var_0_0.sellPriceAngel(arg_5_0, arg_5_1)
	return arg_5_0.sellPriceAngel_[arg_5_1] or 0
end

function var_0_0.sellPriceDemon(arg_6_0, arg_6_1)
	return arg_6_0.sellPriceDemon_[arg_6_1] or 0
end

function var_0_0.showItem(arg_7_0, arg_7_1)
	return arg_7_0.showItem_[arg_7_1] or 0
end

function var_0_0.limitNum(arg_8_0, arg_8_1)
	return arg_8_0.limitNum_[arg_8_1] or 0
end

return var_0_0
