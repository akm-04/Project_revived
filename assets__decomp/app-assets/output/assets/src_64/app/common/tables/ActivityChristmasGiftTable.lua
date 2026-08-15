local var_0_0 = class("ActivityChristmasGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.awardID_ = {}
	arg_1_0.names_ = {}
	arg_1_0.consumeItems_ = {}
	arg_1_0.consumeItemsNum_ = {}
	arg_1_0.giftID_ = {}

	import("app.common.tables.TableParser").parse("activity_christmas_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.consumeItems_[var_2_0] = xyd.splitToNumber(arg_2_0.items, "|")
		arg_1_0.consumeItemsNum_[var_2_0] = xyd.splitToNumber(arg_2_0.item_nums, "|")
		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.names_[arg_3_1]
end

function var_0_0.items(arg_4_0, arg_4_1)
	return arg_4_0.consumeItems_[arg_4_1] or {}
end

function var_0_0.itemsNum(arg_5_0, arg_5_1)
	return arg_5_0.consumeItemsNum_[arg_5_1] or {}
end

function var_0_0.gift(arg_6_0, arg_6_1)
	return arg_6_0.giftID_[arg_6_1] or 0
end

function var_0_0.totalGiftCount(arg_7_0)
	return #arg_7_0.names_
end

return var_0_0
