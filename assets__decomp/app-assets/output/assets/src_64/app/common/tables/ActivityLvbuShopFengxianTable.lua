local var_0_0 = class("ActivityLvbuShopFengxianTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.buyLimit_ = {}
	arg_1_0.star_ = {}
	arg_1_0.awakenTimes_ = {}
	arg_1_0.price_ = {}
	arg_1_0.tips_ = {}

	import("app.common.tables.TableParser").parse("activity_lvbu_shop_fengxian.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.buyLimit_[var_2_0] = tonumber(arg_2_0.buy_limit)
		arg_1_0.star_[var_2_0] = tonumber(arg_2_0.star)
		arg_1_0.awakenTimes_[var_2_0] = tonumber(arg_2_0.awaken_times)
		arg_1_0.price_[var_2_0] = tonumber(arg_2_0.price)
		arg_1_0.tips_[var_2_0] = arg_2_0.tips
	end)
end

function var_0_0.buyLimit(arg_3_0, arg_3_1)
	return arg_3_0.buyLimit_[arg_3_1] or 0
end

function var_0_0.star(arg_4_0, arg_4_1)
	return arg_4_0.star_[arg_4_1] or 0
end

function var_0_0.awakenTimes(arg_5_0, arg_5_1)
	return arg_5_0.awakenTimes_[arg_5_1] or 0
end

function var_0_0.price(arg_6_0, arg_6_1)
	return arg_6_0.price_[arg_6_1] or 0
end

function var_0_0.tips(arg_7_0, arg_7_1)
	return arg_7_0.tips_[arg_7_1] or ""
end

function var_0_0.ids(arg_8_0)
	return table.keys(arg_8_0.buyLimit_)
end

return var_0_0
