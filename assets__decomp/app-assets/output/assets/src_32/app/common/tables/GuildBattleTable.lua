local var_0_0 = class("GuildBattleTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.season_ = {}
	arg_1_0.round_ = {}
	arg_1_0.step_ = {}
	arg_1_0.start_month_ = {}
	arg_1_0.start_date_ = {}
	arg_1_0.end_month_ = {}
	arg_1_0.end_date_ = {}
	arg_1_0.start_time_ = {}
	arg_1_0.end_time_ = {}
	arg_1_0.time_ = {}

	import("app.common.tables.TableParser").parse("guild_battle.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.season_[var_2_0] = tonumber(arg_2_0.season)
		arg_1_0.round_[var_2_0] = tonumber(arg_2_0.round)
		arg_1_0.step_[var_2_0] = tonumber(arg_2_0.step)
		arg_1_0.start_month_[var_2_0] = math.floor(tonumber(arg_2_0.start_day) % 10000 / 100)
		arg_1_0.start_date_[var_2_0] = tonumber(arg_2_0.start_day) % 100
		arg_1_0.end_month_[var_2_0] = math.floor(tonumber(arg_2_0.end_day) % 10000 / 100)
		arg_1_0.end_date_[var_2_0] = tonumber(arg_2_0.end_day) % 100
		arg_1_0.start_time_[var_2_0] = tonumber(arg_2_0.start_time)
		arg_1_0.end_time_[var_2_0] = tonumber(arg_2_0.end_time)
		arg_1_0.time_[var_2_0] = (os.time({
			hour = 0,
			min = 0,
			sec = 0,
			year = math.floor(tonumber(arg_2_0.start_day) / 10000),
			month = arg_1_0.start_month_[var_2_0],
			day = arg_1_0.start_date_[var_2_0]
		}) or 0) + arg_1_0.start_time_[var_2_0]
	end)
end

function var_0_0.season(arg_3_0, arg_3_1)
	return arg_3_0.season_[arg_3_1]
end

function var_0_0.round(arg_4_0, arg_4_1)
	return arg_4_0.round_[arg_4_1]
end

function var_0_0.step(arg_5_0, arg_5_1)
	return arg_5_0.step_[arg_5_1]
end

function var_0_0.getStartMonth(arg_6_0, arg_6_1)
	return arg_6_0.start_month_[arg_6_1]
end

function var_0_0.getStartDate(arg_7_0, arg_7_1)
	return arg_7_0.start_date_[arg_7_1]
end

function var_0_0.getEndMonth(arg_8_0, arg_8_1)
	return arg_8_0.end_month_[arg_8_1]
end

function var_0_0.getEndDate(arg_9_0, arg_9_1)
	return arg_9_0.end_date_[arg_9_1]
end

function var_0_0.getStartTime(arg_10_0, arg_10_1)
	return arg_10_0.start_time_[arg_10_1]
end

function var_0_0.getEndTime(arg_11_0, arg_11_1)
	return arg_11_0.end_time_[arg_11_1]
end

function var_0_0.getTime(arg_12_0, arg_12_1)
	return arg_12_0.time_[arg_12_1]
end

return var_0_0
