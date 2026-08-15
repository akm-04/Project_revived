local var_0_0 = class("TimeTravelTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.trail_name_ = {}
	arg_1_0.trail_icon_ = {}
	arg_1_0.trial_icon_no_ = {}
	arg_1_0.model_ = {}
	arg_1_0.trial_type_ = {}
	arg_1_0.challenge_num_ = {}
	arg_1_0.challenge_status_ = {}
	arg_1_0.cannot_challenge_ = {}
	arg_1_0.trial_model_no_ = {}
	arg_1_0.model_scale_ = {}
	arg_1_0.table_id_ = {}
	arg_1_0.trial_time_ = {}
	arg_1_0.ids_ = {}

	import("app.common.tables.TableParser").parse("time_travel.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.trail_name_[var_2_0] = arg_2_0.trail_name
		arg_1_0.trail_icon_[var_2_0] = arg_2_0.trail_icon
		arg_1_0.trial_icon_no_[var_2_0] = arg_2_0.trial_icon_no
		arg_1_0.model_[var_2_0] = tonumber(arg_2_0.model)
		arg_1_0.trial_type_[var_2_0] = tonumber(arg_2_0.trial_type)
		arg_1_0.challenge_num_[var_2_0] = tonumber(arg_2_0.challenge_num)
		arg_1_0.challenge_status_[var_2_0] = arg_2_0.challenge_status
		arg_1_0.cannot_challenge_[var_2_0] = arg_2_0.cannot_challenge
		arg_1_0.trial_model_no_[var_2_0] = arg_2_0.trial_model_no
		arg_1_0.model_scale_[var_2_0] = tonumber(arg_2_0.model_scale)
		arg_1_0.trial_time_[var_2_0] = arg_2_0.trial_time
		arg_1_0.table_id_[var_2_0] = tonumber(arg_2_0.table_id)
	end)
end

function var_0_0.trialName(arg_3_0, arg_3_1)
	return arg_3_0.trail_name_[arg_3_1] or ""
end

function var_0_0.trialIcon(arg_4_0, arg_4_1)
	return arg_4_0.trail_icon_[arg_4_1] or ""
end

function var_0_0.tableID(arg_5_0, arg_5_1)
	return arg_5_0.table_id_[arg_5_1] or 0
end

function var_0_0.trialTime(arg_6_0, arg_6_1)
	return arg_6_0.trial_time_[arg_6_1] or 0
end

function var_0_0.trialIconNo(arg_7_0, arg_7_1)
	return arg_7_0.trial_icon_no_[arg_7_1] or ""
end

function var_0_0.model(arg_8_0, arg_8_1)
	return arg_8_0.model_[arg_8_1] or 0
end

function var_0_0.trialType(arg_9_0, arg_9_1)
	return arg_9_0.trial_type_[arg_9_1] or 0
end

function var_0_0.challengeNum(arg_10_0, arg_10_1)
	return arg_10_0.challenge_num_[arg_10_1] or 0
end

function var_0_0.challengeStatus(arg_11_0, arg_11_1)
	return arg_11_0.challenge_status_[arg_11_1] or ""
end

function var_0_0.cannotChallenge(arg_12_0, arg_12_1)
	return arg_12_0.cannot_challenge_[arg_12_1] or ""
end

function var_0_0.trialModelNo(arg_13_0, arg_13_1)
	return arg_13_0.trial_model_no_[arg_13_1]
end

function var_0_0.modelScale(arg_14_0, arg_14_1)
	return arg_14_0.model_scale_[arg_14_1]
end

return var_0_0
