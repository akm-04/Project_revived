local var_0_0 = class("ActivityLotteryConsumeShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.item_ = {}
	arg_1_0.itemNum_ = {}
	arg_1_0.pt_ = {}
	arg_1_0.ids_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.vipLimit_ = {}

	import("app.common.tables.TableParser").parse("activity_lottery_consume_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.itemNum_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.pt_[var_2_0] = tonumber(arg_2_0.pt)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.vipLimit_[var_2_0] = tonumber(arg_2_0.vip_limit)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.item(arg_3_0, arg_3_1)
	return arg_3_0.item_[arg_3_1] or 0
end

function var_0_0.itemNum(arg_4_0, arg_4_1)
	return arg_4_0.itemNum_[arg_4_1] or 0
end

function var_0_0.pt(arg_5_0, arg_5_1)
	return arg_5_0.pt_[arg_5_1] or 0
end

function var_0_0.getIds(arg_6_0)
	return arg_6_0.ids_
end

function var_0_0.buyLimit(arg_7_0, arg_7_1)
	return arg_7_0.buyLimit_[arg_7_1] or 0
end

function var_0_0.vipLimit(arg_8_0, arg_8_1)
	return arg_8_0.vipLimit_[arg_8_1] or 0
end

return var_0_0
