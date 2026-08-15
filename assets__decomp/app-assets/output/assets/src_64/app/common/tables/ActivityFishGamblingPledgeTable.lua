local var_0_0 = class("ActivityFishGamblingPledgeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.itemId_ = {}
	arg_1_0.itemName_ = {}
	arg_1_0.coinNum_ = {}
	arg_1_0.coinNumByItem_ = {}
	arg_1_0.isMortageItem_ = {}

	import("app.common.tables.TableParser").parse("activity_fish_gambling_pledge.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)
		local var_2_1 = tonumber(arg_2_0.item_id)

		arg_1_0.itemId_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.itemName_[var_2_0] = arg_2_0.item_name
		arg_1_0.coinNum_[var_2_0] = tonumber(arg_2_0.coin_num)
		arg_1_0.coinNumByItem_[var_2_1] = tonumber(arg_2_0.coin_num)
		arg_1_0.isMortageItem_[var_2_1] = true
	end)
end

function var_0_0.itemId(arg_3_0, arg_3_1)
	return arg_3_0.itemId_[arg_3_1] or 0
end

function var_0_0.itemName(arg_4_0, arg_4_1)
	return arg_4_0.itemName_[arg_4_1] or ""
end

function var_0_0.coinNum(arg_5_0, arg_5_1)
	return arg_5_0.coinNum_[arg_5_1] or 0
end

function var_0_0.coinNumByItem(arg_6_0, arg_6_1)
	return arg_6_0.coinNumByItem_[arg_6_1] or 0
end

function var_0_0.isMortageItem(arg_7_0, arg_7_1)
	return arg_7_0.isMortageItem_[arg_7_1] or false
end

return var_0_0
