local var_0_0 = class("StarTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.evolveStars_ = {}
	arg_1_0.evolveNums_ = {}
	arg_1_0.evolvePrices_ = {}
	arg_1_0.summonNums_ = {}
	arg_1_0.summonPrices_ = {}

	import("app.common.tables.TableParser").parse("star.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.star)

		arg_1_0.evolveStars_[var_2_0] = tonumber(arg_2_0.evolve_star)
		arg_1_0.evolveNums_[var_2_0] = tonumber(arg_2_0.evolve_num)
		arg_1_0.evolvePrices_[var_2_0] = tonumber(arg_2_0.evolve_price)
		arg_1_0.summonNums_[var_2_0] = tonumber(arg_2_0.summon_num)
		arg_1_0.summonPrices_[var_2_0] = tonumber(arg_2_0.summon_price)
	end)
end

function var_0_0.evolveStar(arg_3_0, arg_3_1)
	return arg_3_0.evolveStars_[arg_3_1] or 0
end

function var_0_0.evolveNum(arg_4_0, arg_4_1)
	return arg_4_0.evolveNums_[arg_4_1] or 0
end

function var_0_0.evolvePrice(arg_5_0, arg_5_1)
	return arg_5_0.evolvePrices_[arg_5_1] or 0
end

function var_0_0.summonNum(arg_6_0, arg_6_1)
	return arg_6_0.summonNums_[arg_6_1] or 0
end

function var_0_0.summonPrice(arg_7_0, arg_7_1)
	return arg_7_0.summonPrices_[arg_7_1] or 0
end

return var_0_0
