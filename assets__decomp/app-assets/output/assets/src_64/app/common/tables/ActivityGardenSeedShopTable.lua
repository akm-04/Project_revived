local var_0_0 = class("ActivityGardenSeedShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.sellType_ = {}
	arg_1_0.sellPrice_ = {}

	import("app.common.tables.TableParser").parse("activity_garden_seed_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.sellType_[var_2_0] = tonumber(arg_2_0.sell_type)
		arg_1_0.sellPrice_[var_2_0] = tonumber(arg_2_0.sell_price)
	end)
end

function var_0_0.itemId(arg_3_0, arg_3_1)
	return arg_3_0.itemId_[arg_3_1] or 0
end

function var_0_0.sellType(arg_4_0, arg_4_1)
	return arg_4_0.sellType_[arg_4_1] or 0
end

function var_0_0.sellPrice(arg_5_0, arg_5_1)
	return arg_5_0.sellPrice_[arg_5_1] or 0
end

function var_0_0.ids(arg_6_0)
	return table.keys(arg_6_0.itemId_)
end

return var_0_0
