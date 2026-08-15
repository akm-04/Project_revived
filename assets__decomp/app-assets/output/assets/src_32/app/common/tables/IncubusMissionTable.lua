local var_0_0 = class("IncubusMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.taskName_ = {}
	arg_1_0.taskDesc_ = {}
	arg_1_0.taskType_ = {}
	arg_1_0.taskNum_ = {}
	arg_1_0.taskTime_ = {}
	arg_1_0.monsterID_ = {}
	arg_1_0.radius_ = {}

	import("app.common.tables.TableParser").parse("incubus_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.task_id)

		if not var_2_0 then
			return
		end

		arg_1_0.taskName_[var_2_0] = arg_2_0.task_name
		arg_1_0.taskDesc_[var_2_0] = arg_2_0.task_desc
		arg_1_0.taskType_[var_2_0] = arg_2_0.task_type
		arg_1_0.taskNum_[var_2_0] = xyd.luaStringSplit(arg_2_0.task_num, "|")
		arg_1_0.taskTime_[var_2_0] = xyd.luaStringSplit(arg_2_0.task_time, "|")
		arg_1_0.monsterID_[var_2_0] = tonumber(arg_2_0.monster_id)
		arg_1_0.radius_[var_2_0] = tonumber(arg_2_0.radius)
	end)
end

function var_0_0.taskName(arg_3_0, arg_3_1)
	return arg_3_0.taskName_[arg_3_1] or 0
end

function var_0_0.taskDesc(arg_4_0, arg_4_1)
	return arg_4_0.taskDesc_[arg_4_1] or ""
end

function var_0_0.taskType(arg_5_0, arg_5_1)
	return arg_5_0.taskType_[arg_5_1] or 0
end

function var_0_0.taskNum(arg_6_0, arg_6_1)
	return arg_6_0.taskNum_[arg_6_1] or {}
end

function var_0_0.taskTime(arg_7_0, arg_7_1)
	return arg_7_0.taskTime_[arg_7_1] or {}
end

function var_0_0.monsterID(arg_8_0, arg_8_1)
	return arg_8_0.monsterID_[arg_8_1] or 0
end

function var_0_0.radius(arg_9_0, arg_9_1)
	return arg_9_0.radius_[arg_9_1] or 0
end

return var_0_0
