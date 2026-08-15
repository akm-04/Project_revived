local var_0_0 = class("ActivityHeroSellingTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.item_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.giftList_ = {}

	import("app.common.tables.TableParser").parse("activity_herosell.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.recharge_[var_2_0] = xyd.splitToNumber(arg_2_0.recharge, "|")
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = xyd.splitToNumber(arg_2_0.gift, "|")
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.giftList_[var_2_0] = arg_2_0.gift_list
	end)
end

function var_0_0.recharge(arg_3_0, arg_3_1)
	return arg_3_0.recharge_[arg_3_1] or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or {}
end

function var_0_0.item(arg_6_0, arg_6_1)
	return arg_6_0.item_[arg_6_1] or 0
end

function var_0_0.icon(arg_7_0, arg_7_1)
	return arg_7_0.icon_[arg_7_1] or ""
end

function var_0_0.giftList(arg_8_0, arg_8_1)
	return arg_8_0.giftList_[arg_8_1] or ""
end

function var_0_0.getItems(arg_9_0)
	return arg_9_0.item_ or {}
end

return var_0_0
