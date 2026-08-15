local var_0_0 = class("AdventureShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.price_ = {}

	import("app.common.tables.TableParser").parse("adventure_shop.lua", function(arg_2_0)
		local var_2_0 = arg_2_0.id

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
	end)
end

function var_0_0.itemId(arg_3_0, arg_3_1)
	return arg_3_0.itemId_[arg_3_1] or 0
end

function var_0_0.price(arg_4_0, arg_4_1)
	return arg_4_0.price_[arg_4_1] or 0
end

return var_0_0
