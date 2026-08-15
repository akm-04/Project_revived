local var_0_0 = class("SummonTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.costType_ = {}
	arg_1_0.summonCost_ = {}

	import("app.common.tables.TableParser").parse("summon.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.costType_[var_2_0] = tonumber(arg_2_0.cost_type)
		arg_1_0.summonCost_[var_2_0] = xyd.splitToNumber(arg_2_0.summon_cost, "|")
	end)
end

function var_0_0.mana(arg_3_0, arg_3_1)
	return arg_3_0.summonCost_[arg_3_1][2] or 0
end

function var_0_0.manaTen(arg_4_0, arg_4_1)
	return arg_4_0.summonCost_[arg_4_1][3] or 0
end

function var_0_0.manaHundred(arg_5_0, arg_5_1)
	return arg_5_0.summonCost_[arg_5_1][4] or 0
end

function var_0_0.crystal(arg_6_0, arg_6_1)
	return arg_6_0.summonCost_[arg_6_1][1] or 0
end

function var_0_0.crystalTen(arg_7_0, arg_7_1)
	return arg_7_0.summonCost_[arg_7_1][2] or 0
end

function var_0_0.crystals(arg_8_0, arg_8_1)
	return arg_8_0.summonCost_[arg_8_1]
end

function var_0_0.stone(arg_9_0, arg_9_1)
	return arg_9_0.summonCost_[arg_9_1][1] or 0
end

return var_0_0
