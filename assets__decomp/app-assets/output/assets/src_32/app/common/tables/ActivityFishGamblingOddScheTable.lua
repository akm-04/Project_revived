local var_0_0 = class("ActivityFishGamblingOddScheTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gameId_ = {}
	arg_1_0.name_ = {}
	arg_1_0.round_ = {}
	arg_1_0.day_ = {}
	arg_1_0.session_ = {}
	arg_1_0.startTime_ = {}
	arg_1_0.endTime_ = {}

	import("app.common.tables.TableParser").parse("activity_fish_gambling_odd_sche.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.game_id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.round_[var_2_0] = tonumber(arg_2_0.round)
		arg_1_0.day_[var_2_0] = tonumber(arg_2_0.day)
		arg_1_0.session_[var_2_0] = tonumber(arg_2_0.session)
		arg_1_0.startTime_[var_2_0] = tonumber(arg_2_0.start_time)
		arg_1_0.endTime_[var_2_0] = tonumber(arg_2_0.end_time)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.round(arg_4_0, arg_4_1)
	return arg_4_0.round_[arg_4_1] or 0
end

function var_0_0.day(arg_5_0, arg_5_1)
	return arg_5_0.day_[arg_5_1] or 0
end

function var_0_0.session(arg_6_0, arg_6_1)
	return arg_6_0.session_[arg_6_1] or 0
end

function var_0_0.startTime(arg_7_0, arg_7_1)
	return arg_7_0.startTime_[arg_7_1] or 0
end

function var_0_0.endTime(arg_8_0, arg_8_1)
	return arg_8_0.endTime_[arg_8_1] or 0
end

return var_0_0
