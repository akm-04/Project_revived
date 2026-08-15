local var_0_0 = class("ActivityLvbuRaffleGiftTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.raffleTime_ = {}
	arg_1_0.itemID_ = {}
	arg_1_0.giftID_ = {}
	arg_1_0.itemNum_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu_raffle_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.raffleTime_[var_2_0] = tonumber(arg_2_0.raffle_times)
		arg_1_0.itemID_[var_2_0] = tonumber(arg_2_0.item_id)
		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.item_numb)
	end)
end

function var_0_0.raffleTime(arg_3_0, arg_3_1)
	return arg_3_0.raffleTime_[arg_3_1] or 0
end

function var_0_0.itemID(arg_4_0, arg_4_1)
	return arg_4_0.itemID_[arg_4_1]
end

function var_0_0.giftID(arg_5_0, arg_5_1)
	return arg_5_0.giftID_[arg_5_1] or 0
end

function var_0_0.itemNum(arg_6_0, arg_6_1)
	return arg_6_0.itemNum_[arg_6_1] or 1
end

function var_0_0.getCounts(arg_7_0)
	return #arg_7_0.itemID_
end

return var_0_0
