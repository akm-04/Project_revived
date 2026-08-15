local var_0_0 = class("ActivityLotteryConsumeTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.giftID_ = {}
	arg_1_0.ticketNum_ = {}
	arg_1_0.luckyNum_ = {}
	arg_1_0.ids_ = {}
	arg_1_0.photo_ = {}

	import("app.common.tables.TableParser").parse("activity_lottery_consume.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift_id)
		arg_1_0.ticketNum_[var_2_0] = tonumber(arg_2_0.ticket_num)
		arg_1_0.luckyNum_[var_2_0] = tonumber(arg_2_0.lucky_num)
		arg_1_0.photo_[var_2_0] = arg_2_0.photo

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.giftID(arg_3_0, arg_3_1)
	return arg_3_0.giftID_[arg_3_1] or 0
end

function var_0_0.ticketNum(arg_4_0, arg_4_1)
	return arg_4_0.ticketNum_[arg_4_1] or 0
end

function var_0_0.luckyNum(arg_5_0)
	return arg_5_0.luckyNum_[id] or 0
end

function var_0_0.getDays(arg_6_0)
	return #arg_6_0.ids_
end

function var_0_0.photo(arg_7_0, arg_7_1)
	return arg_7_0.photo_[arg_7_1] or ""
end

return var_0_0
