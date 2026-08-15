local var_0_0 = class("AnniWishingpoolTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.wish_times_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.coin = xyd.tables.misc.activityAnniversaryWishCoin

	import("app.common.tables.TableParser").parse("activity_anniversary_wish_gift.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.wish_times_[var_2_0] = tonumber(arg_2_0.wish_times)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.icon_[var_2_0] = tonumber(arg_2_0.icon)

		table.insert(arg_1_0.ids_, var_2_0)
	end)
end

function var_0_0.getAllIds(arg_3_0)
	return arg_3_0.ids_
end

function var_0_0.getWishTimes(arg_4_0, arg_4_1)
	return arg_4_0.wish_times_[arg_4_1] or ""
end

function var_0_0.getGiftId(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or ""
end

function var_0_0.getIcon(arg_6_0, arg_6_1)
	return arg_6_0.icon_[arg_6_1] or ""
end

function var_0_0.getCoinID(arg_7_0)
	return arg_7_0.coin
end

return var_0_0
