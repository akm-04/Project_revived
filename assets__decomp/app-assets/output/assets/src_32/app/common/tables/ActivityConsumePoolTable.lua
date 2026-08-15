local var_0_0 = class("ActivityConsumePoolTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.rarity_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.rate_ = {}
	arg_1_0.isRarest_ = {}

	import("app.common.tables.TableParser").parse("activity_consume_pool.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.rarity_[var_2_0] = tonumber(arg_2_0.rarity)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.rate_[var_2_0] = tonumber(arg_2_0.rate)
		arg_1_0.isRarest_[var_2_0] = tonumber(arg_2_0.is_rarest)
	end)
end

function var_0_0.rarity(arg_3_0, arg_3_1)
	return arg_3_0.rarity_[arg_3_1] or 0
end

function var_0_0.gift(arg_4_0, arg_4_1)
	return arg_4_0.gift_[arg_4_1] or 0
end

function var_0_0.rate(arg_5_0, arg_5_1)
	return arg_5_0.rate_[arg_5_1] or 0
end

function var_0_0.isRarest(arg_6_0, arg_6_1)
	return arg_6_0.isRarest_[arg_6_1] or 0
end

function var_0_0.count(arg_7_0)
	return #table.keys(arg_7_0.gift_)
end

return var_0_0
