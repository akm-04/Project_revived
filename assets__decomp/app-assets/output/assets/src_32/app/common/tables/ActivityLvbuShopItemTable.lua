local var_0_0 = class("ActivityLvbuShopItemTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.giftID_ = {}
	arg_1_0.sellType_ = {}
	arg_1_0.sellPrice_ = {}
	arg_1_0.showItem_ = {}
	arg_1_0.ids_ = {}
	arg_1_0.normalIds_ = {}
	arg_1_0.unlock_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu_shop_item.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.sellType_[var_2_0] = tonumber(arg_2_0.sell_type)
		arg_1_0.sellPrice_[var_2_0] = tonumber(arg_2_0.sell_price)
		arg_1_0.showItem_[var_2_0] = tonumber(arg_2_0.show_item)
		arg_1_0.unlock_[var_2_0] = arg_2_0.unlock

		table.insert(arg_1_0.ids_, var_2_0)

		if tonumber(arg_2_0.is_special) == 0 then
			table.insert(arg_1_0.normalIds_, var_2_0)
		end
	end)
end

function var_0_0.gift(arg_3_0, arg_3_1)
	return arg_3_0.giftID_[arg_3_1] or 0
end

function var_0_0.sellType(arg_4_0, arg_4_1)
	return arg_4_0.sellType_[arg_4_1] or 0
end

function var_0_0.price(arg_5_0, arg_5_1)
	return arg_5_0.sellPrice_[arg_5_1] or 0
end

function var_0_0.showItem(arg_6_0, arg_6_1)
	return arg_6_0.showItem_[arg_6_1] or 0
end

function var_0_0.getItems(arg_7_0, arg_7_1)
	if arg_7_1 then
		return arg_7_0.ids_
	end

	return arg_7_0.normalIds_
end

function var_0_0.unlock(arg_8_0, arg_8_1)
	return arg_8_0.unlock_[arg_8_1] or ""
end

return var_0_0
