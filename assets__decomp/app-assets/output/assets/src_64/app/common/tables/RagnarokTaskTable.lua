local var_0_0 = class("RagnarokTaskTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.id_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.missionType_ = {}
	arg_1_0.condition_ = {}

	import("app.common.tables.TableParser").parse("activity_ragnarok_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.id_[var_2_0] = var_2_0
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.missionType_[var_2_0] = tonumber(arg_2_0.mission_type)
		arg_1_0.condition_[var_2_0] = xyd.splitToNumber(arg_2_0.condition, "|")
	end)
end

function var_0_0.getIds(arg_3_0)
	return arg_3_0.id_ or {}
end

function var_0_0.getDescById(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or 0
end

function var_0_0.getTypeById(arg_5_0, arg_5_1)
	return arg_5_0.missionType_[arg_5_1] or 0
end

function var_0_0.getCondition(arg_6_0, arg_6_1)
	return arg_6_0.condition_[arg_6_1] or 0
end

return var_0_0
