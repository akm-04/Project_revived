local var_0_0 = class("PlayerTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.energyMaxValues_ = {}
	arg_1_0.awardEnergy_ = {}
	arg_1_0.expDiffValues_ = {}
	arg_1_0.expTotalValues_ = {}
	arg_1_0.heroMaxLev_ = {}

	import("app.common.tables.TableParser").parse("player.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.lev)

		arg_1_0.energyMaxValues_[var_2_0] = tonumber(arg_2_0.energy)
		arg_1_0.expDiffValues_[var_2_0] = tonumber(arg_2_0.exp)
		arg_1_0.awardEnergy_[var_2_0] = tonumber(arg_2_0.award_energy)
		arg_1_0.expTotalValues_[var_2_0] = tonumber(arg_2_0.total_exp)
		arg_1_0.heroMaxLev_[var_2_0] = tonumber(arg_2_0.hero_lev)
	end)
end

function var_0_0.maxEnergy(arg_3_0, arg_3_1)
	return arg_3_0.energyMaxValues_[arg_3_1] or 0
end

function var_0_0.diffExp(arg_4_0, arg_4_1)
	return arg_4_0.expDiffValues_[arg_4_1] or 0
end

function var_0_0.awardEnergy(arg_5_0, arg_5_1)
	return arg_5_0.awardEnergy_[arg_5_1] or 0
end

function var_0_0.totalExp(arg_6_0, arg_6_1)
	return arg_6_0.expTotalValues_[arg_6_1] or 0
end

function var_0_0.heroMaxLev(arg_7_0, arg_7_1)
	return arg_7_0.heroMaxLev_[arg_7_1] or 0
end

return var_0_0
