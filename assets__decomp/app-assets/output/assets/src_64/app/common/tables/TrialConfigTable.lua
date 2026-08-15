local var_0_0 = class("TrialConfigTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.trials_ = {}
	arg_1_0.openDates_ = {}
	arg_1_0.energyCosts_ = {}
	arg_1_0.trialTypeDes_ = {}
	arg_1_0.showItems_ = {}
	arg_1_0.trialNames_ = {}

	import("app.common.tables.TableParser").parse("trial_config.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.trial_type_id)

		arg_1_0.trials_[var_2_0] = xyd.splitToNumber(arg_2_0.trials, "|")
		arg_1_0.openDates_[var_2_0] = xyd.splitToNumber(arg_2_0.open_date, "|")
		arg_1_0.energyCosts_[var_2_0] = tonumber(arg_2_0.energy_cost)

		local var_2_1 = arg_2_0.trial_type_des
		local var_2_2 = string.gsub(var_2_1, "|", "\n")

		arg_1_0.trialTypeDes_[var_2_0] = var_2_2
		arg_1_0.showItems_[var_2_0] = xyd.splitToNumber(arg_2_0.item_display, "|")
		arg_1_0.trialNames_[var_2_0] = arg_2_0.trail_type_name
	end)
end

function var_0_0.trials(arg_3_0, arg_3_1)
	return arg_3_0.trials_[arg_3_1] or {}
end

function var_0_0.energyCost(arg_4_0, arg_4_1)
	return arg_4_0.energyCosts_[arg_4_1] or 0
end

function var_0_0.openDates(arg_5_0, arg_5_1)
	return arg_5_0.openDates_[arg_5_1] or {}
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.trialTypeDes_[arg_6_1] or {}
end

function var_0_0.showItems(arg_7_0, arg_7_1)
	return arg_7_0.showItems_[arg_7_1] or {}
end

function var_0_0.name(arg_8_0, arg_8_1)
	return arg_8_0.trialNames_[arg_8_1] or ""
end

return var_0_0
