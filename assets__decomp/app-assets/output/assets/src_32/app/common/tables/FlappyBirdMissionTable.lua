local var_0_0 = class("FlappyBirdMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.taskReq_ = {}
	arg_1_0.taskNum_ = {}
	arg_1_0.point_ = {}
	arg_1_0.icon_ = {}

	import("app.common.tables.TableParser").parse("activity_flappy_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.taskReq_[var_2_0] = arg_2_0.task_req
		arg_1_0.taskNum_[var_2_0] = tonumber(arg_2_0.task_num)
		arg_1_0.point_[var_2_0] = tonumber(arg_2_0.point)
		arg_1_0.icon_[var_2_0] = arg_2_0.mission_icon
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1]
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1]
end

function var_0_0.taskReq(arg_5_0, arg_5_1)
	return arg_5_0.taskReq_[arg_5_1]
end

function var_0_0.taskNum(arg_6_0, arg_6_1)
	return arg_6_0.taskNum_[arg_6_1]
end

function var_0_0.point(arg_7_0, arg_7_1)
	return arg_7_0.point_[arg_7_1]
end

function var_0_0.icon(arg_8_0, arg_8_1)
	return arg_8_0.icon_[arg_8_1]
end

return var_0_0
