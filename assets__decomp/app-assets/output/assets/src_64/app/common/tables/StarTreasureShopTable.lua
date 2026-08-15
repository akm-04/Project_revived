local var_0_0 = class("StarTreasureShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids = {}
	arg_1_0.name = {}
	arg_1_0.desc = {}
	arg_1_0.item = {}
	arg_1_0.item_num = {}
	arg_1_0.sell_price = {}

	import("app.common.tables.TableParser").parse("activity_star_exploration_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids, var_2_0)

		arg_1_0.name[var_2_0] = arg_2_0.name
		arg_1_0.desc[var_2_0] = arg_2_0.desc
		arg_1_0.item[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.item_num[var_2_0] = tonumber(arg_2_0.item_num)
		arg_1_0.sell_price[var_2_0] = tonumber(arg_2_0.sell_price)
	end)
end

function var_0_0.getName(arg_3_0, arg_3_1)
	return arg_3_0.name[arg_3_1] or ""
end

function var_0_0.getDesc(arg_4_0, arg_4_1)
	return arg_4_0.desc[arg_4_1] or ""
end

function var_0_0.getItem(arg_5_0, arg_5_1)
	return arg_5_0.item[arg_5_1] or 0
end

function var_0_0.getItemNum(arg_6_0, arg_6_1)
	return arg_6_0.item_num[arg_6_1] or 0
end

function var_0_0.getSellPrice(arg_7_0, arg_7_1)
	return arg_7_0.sell_price[arg_7_1]
end

function var_0_0.getTableIds(arg_8_0)
	return arg_8_0.ids
end

return var_0_0
