local var_0_0 = class("ActivityAnniversaryDiglettTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.totalTime_ = {}
	arg_1_0.stageTime_ = {}
	arg_1_0.interval_ = {}
	arg_1_0.monster_ = {}
	arg_1_0.monsterNums_ = {}
	arg_1_0.doubleTimes_ = {}
	arg_1_0.threeTimes_ = {}
	arg_1_0.moveScale_ = {}

	import("app.common.tables.TableParser").parse("activity_anniversary_diglett.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.totalTime_[var_2_0] = tonumber(arg_2_0.total_time)
		arg_1_0.stageTime_[var_2_0] = tonumber(arg_2_0.stage_time)
		arg_1_0.interval_[var_2_0] = tonumber(arg_2_0.interval)
		arg_1_0.monster_[var_2_0] = xyd.splitToNumber(arg_2_0.monster, "|")
		arg_1_0.monsterNums_[var_2_0] = xyd.splitToNumber(arg_2_0.monster_nums, "|")
		arg_1_0.doubleTimes_[var_2_0] = xyd.splitToNumber(arg_2_0.double_times, "|")
		arg_1_0.threeTimes_[var_2_0] = xyd.splitToNumber(arg_2_0.three_times, "|")
		arg_1_0.moveScale_[var_2_0] = tonumber(arg_2_0.move_scale)
	end)
end

function var_0_0.totalTime(arg_3_0, arg_3_1)
	return arg_3_0.totalTime_[arg_3_1] or 0
end

function var_0_0.stageTime(arg_4_0, arg_4_1)
	return arg_4_0.stageTime_[arg_4_1] or 0
end

function var_0_0.interval(arg_5_0, arg_5_1)
	return arg_5_0.interval_[arg_5_1] or 0
end

function var_0_0.monster(arg_6_0, arg_6_1)
	return arg_6_0.monster_[arg_6_1] or {}
end

function var_0_0.monsterNums(arg_7_0, arg_7_1)
	return arg_7_0.monsterNums_[arg_7_1] or {}
end

function var_0_0.doubleTimes(arg_8_0, arg_8_1)
	return arg_8_0.doubleTimes_[arg_8_1] or {}
end

function var_0_0.threeTimes(arg_9_0, arg_9_1)
	return arg_9_0.threeTimes_[arg_9_1] or {}
end

function var_0_0.moveScale(arg_10_0, arg_10_1)
	return arg_10_0.moveScale_[arg_10_1] or 0
end

return var_0_0
