local var_0_0 = class("ActivitySummerTaskTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.taskType_ = {}
	arg_1_0.taskNum_ = {}
	arg_1_0.taskID_ = {}
	arg_1_0.nextTaskID_ = {}
	arg_1_0.giftID_ = {}

	import("app.common.tables.TableParser").parse("activity_summer_goldfish_task.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.taskType_[var_2_0] = tonumber(arg_2_0.task_type)
		arg_1_0.taskNum_[var_2_0] = tonumber(arg_2_0.task_num)
		arg_1_0.taskID_[var_2_0] = tonumber(arg_2_0.task_id)
		arg_1_0.nextTaskID_[var_2_0] = tonumber(arg_2_0.next_task_id)
		arg_1_0.giftID_[var_2_0] = tonumber(arg_2_0.gift)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.taskType(arg_4_0, arg_4_1)
	return arg_4_0.taskType_[arg_4_1] or 0
end

function var_0_0.taskNum(arg_5_0, arg_5_1)
	return arg_5_0.taskNum_[arg_5_1] or 0
end

function var_0_0.preTaskID(arg_6_0, arg_6_1)
	return arg_6_0.taskID_[arg_6_1] or 0
end

function var_0_0.nextTaskID(arg_7_0, arg_7_1)
	return arg_7_0.nextTaskID_[arg_7_1] or 0
end

function var_0_0.getTaskIDs(arg_8_0)
	return arg_8_0.ids_ or {}
end

function var_0_0.gift(arg_9_0, arg_9_1)
	return arg_9_0.giftID_[arg_9_1] or 0
end

return var_0_0
