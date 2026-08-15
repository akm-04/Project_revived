local var_0_0 = class("ActivitySakuraWishesTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.rarity_ = {}
	arg_1_0.item_ = {}
	arg_1_0.num_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.vip_limit_ = {}
	arg_1_0.is_rarest_ = {}

	import("app.common.tables.TableParser").parse("activity_chest_us.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.rarity_[var_2_0] = tonumber(arg_2_0.rarity)
		arg_1_0.item_[var_2_0] = tonumber(arg_2_0.item)
		arg_1_0.num_[var_2_0] = tonumber(arg_2_0.num)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.vip_limit_[var_2_0] = tonumber(arg_2_0.vip_limit)
		arg_1_0.is_rarest_[var_2_0] = tonumber(arg_2_0.is_rarest)
	end)
	table.sort(arg_1_0.ids_, function(arg_3_0, arg_3_1)
		return arg_3_0 < arg_3_1
	end)
end

function var_0_0.ids(arg_4_0)
	return arg_4_0.ids_
end

function var_0_0.rarity(arg_5_0, arg_5_1)
	return arg_5_0.rarity_[arg_5_1]
end

function var_0_0.item(arg_6_0, arg_6_1)
	return arg_6_0.item_[arg_6_1]
end

function var_0_0.num(arg_7_0, arg_7_1)
	return arg_7_0.num_[arg_7_1]
end

function var_0_0.rate(arg_8_0, arg_8_1)
	return arg_8_0.rate_[arg_8_1]
end

function var_0_0.vipLimit(arg_9_0, arg_9_1)
	return arg_9_0.vip_limit_[arg_9_1]
end

function var_0_0.isRarest(arg_10_0, arg_10_1)
	return arg_10_0.is_rarest_[arg_10_1]
end

return var_0_0
