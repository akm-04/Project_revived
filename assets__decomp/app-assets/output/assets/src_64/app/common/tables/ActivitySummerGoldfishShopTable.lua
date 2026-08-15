local var_0_0 = class("ActivitySummerGoldfishShopTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.item_ = {}
	arg_1_0.num_ = {}
	arg_1_0.pt_ = {}
	arg_1_0.buyLimit_ = {}
	arg_1_0.vipLimit_ = {}
	arg_1_0.iconOff_ = {}

	import("app.common.tables.TableParser").parse("activity_summer_goldfish_shop.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.pt_[var_2_0] = tonumber(arg_2_0.pt)
		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.vipLimit_[var_2_0] = tonumber(arg_2_0.vip_limit)
		arg_1_0.iconOff_[var_2_0] = arg_2_0.icon_off
	end)
end

function var_0_0.item(arg_3_0, arg_3_1)
	return arg_3_0.item_[arg_3_1] or 0
end

function var_0_0.num(arg_4_0, arg_4_1)
	return arg_4_0.num_[arg_4_1] or 1
end

function var_0_0.pt(arg_5_0, arg_5_1)
	return arg_5_0.pt_[arg_5_1] or 0
end

function var_0_0.buyLimit(arg_6_0, arg_6_1)
	return arg_6_0.buyLimit_[arg_6_1] or 0
end

function var_0_0.vipLimit(arg_7_0, arg_7_1)
	return arg_7_0.vipLimit_[arg_7_1] or 0
end

function var_0_0.count(arg_8_0)
	return #arg_8_0.item_
end

function var_0_0.iconOff(arg_9_0, arg_9_1)
	return arg_9_0.iconOff_[arg_9_1] or ""
end

return var_0_0
