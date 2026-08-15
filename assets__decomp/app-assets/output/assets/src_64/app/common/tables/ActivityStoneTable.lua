local var_0_0 = class("ActivityStoneTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.level_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.recharge_ = {}
	arg_1_0.dayMax_ = {}
	arg_1_0.dayMin_ = {}

	import("app.common.tables.TableParser").parse("activity_stone.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.level_[var_2_0] = tonumber(arg_2_0.level)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.recharge_[var_2_0] = tonumber(arg_2_0.recharge)
		arg_1_0.dayMax_[var_2_0] = tonumber(arg_2_0.day_max)
		arg_1_0.dayMin_[var_2_0] = tonumber(arg_2_0.day_min)
	end)
end

function var_0_0.level(arg_3_0, arg_3_1)
	return arg_3_0.level_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or {}
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.levels(arg_6_0)
	return arg_6_0.level_ or {}
end

function var_0_0.recharge(arg_7_0, arg_7_1)
	return arg_7_0.recharge_[arg_7_1] or 0
end

function var_0_0.dayMax(arg_8_0, arg_8_1)
	return arg_8_0.dayMax_[arg_8_1] or 0
end

function var_0_0.dayMin(arg_9_0, arg_9_1)
	return arg_9_0.dayMin_[arg_9_1] or 0
end

function var_0_0.gifts(arg_10_0)
	return arg_10_0.gift_ or {}
end

return var_0_0
