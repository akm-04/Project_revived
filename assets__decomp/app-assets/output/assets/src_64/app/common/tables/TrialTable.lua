local var_0_0 = class("TrialTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.trials_ = {}
	arg_1_0.trialLvs_ = {}
	arg_1_0.trialNames_ = {}
	arg_1_0.trialDescs_ = {}
	arg_1_0.openLvs_ = {}
	arg_1_0.energyCosts_ = {}
	arg_1_0.monsterDisplays_ = {}
	arg_1_0.monsterStars_ = {}
	arg_1_0.monsterQualitys_ = {}
	arg_1_0.monsterLevels_ = {}
	arg_1_0.itemDisplays_ = {}
	arg_1_0.icons_ = {}

	import("app.common.tables.TableParser").parse("trial.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.trail_id)

		arg_1_0.trialLvs_[var_2_0] = tonumber(arg_2_0.trial_lv)
		arg_1_0.trialNames_[var_2_0] = arg_2_0.trial_name
		arg_1_0.trialDescs_[var_2_0] = arg_2_0.trial_des
		arg_1_0.openLvs_[var_2_0] = tonumber(arg_2_0.open_lv)
		arg_1_0.energyCosts_[var_2_0] = tonumber(arg_2_0.energy_cost)
		arg_1_0.monsterDisplays_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_display, "|")
		arg_1_0.monsterStars_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_star, "|")
		arg_1_0.monsterQualitys_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_quality, "|")
		arg_1_0.monsterLevels_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_level, "|")
		arg_1_0.itemDisplays_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.icons_[var_2_0] = tonumber(arg_2_0.icon)
	end)
end

function var_0_0.trialLv(arg_3_0, arg_3_1)
	return arg_3_0.trialLvs_[arg_3_1] or {}
end

function var_0_0.trialName(arg_4_0, arg_4_1)
	return arg_4_0.trialNames_[tiralID] or ""
end

function var_0_0.trialDesc(arg_5_0, arg_5_1)
	return arg_5_0.trialDescs_[arg_5_1] or ""
end

function var_0_0.openLv(arg_6_0, arg_6_1)
	return arg_6_0.openLvs_[arg_6_1] or 0
end

function var_0_0.energyCost(arg_7_0, arg_7_1)
	return arg_7_0.energyCosts_[arg_7_1] or 0
end

function var_0_0.monsterDisplay(arg_8_0, arg_8_1)
	return arg_8_0.monsterDisplays_[arg_8_1] or {}
end

function var_0_0.monsterStar(arg_9_0, arg_9_1)
	return arg_9_0.monsterStars_[arg_9_1] or {}
end

function var_0_0.monsterQuality(arg_10_0, arg_10_1)
	return arg_10_0.monsterQualitys_[arg_10_1] or {}
end

function var_0_0.monsterLevel(arg_11_0, arg_11_1)
	return arg_11_0.monsterLevels_[arg_11_1] or {}
end

function var_0_0.itemDisplay(arg_12_0, arg_12_1)
	return arg_12_0.itemDisplays_[arg_12_1] or {}
end

function var_0_0.icon(arg_13_0, arg_13_1)
	return arg_13_0.icons_[arg_13_1] or 0
end

return var_0_0
