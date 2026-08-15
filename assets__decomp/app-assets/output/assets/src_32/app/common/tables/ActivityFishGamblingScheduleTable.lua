local var_0_0 = class("ActivityFishGamblingScheduleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.gameId_ = {}
	arg_1_0.name_ = {}
	arg_1_0.time_ = {}
	arg_1_0.subDay_ = {}

	import("app.common.tables.TableParser").parse("activity_fish_gambling_schedule.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.game_id)

		arg_1_0.gameId_[var_2_0] = tonumber(arg_2_0.game_id)
		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.time_[var_2_0] = tonumber(arg_2_0.time)
		arg_1_0.subDay_[var_2_0] = tonumber(arg_2_0.sub_day)
	end)
end

function var_0_0.gameId(arg_3_0, arg_3_1)
	return arg_3_0.gameId_[arg_3_1] or 0
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.time(arg_5_0, arg_5_1)
	return arg_5_0.time_[arg_5_1] or 0
end

function var_0_0.subDay(arg_6_0, arg_6_1)
	return arg_6_0.subDay_[arg_6_1] or 0
end

return var_0_0
