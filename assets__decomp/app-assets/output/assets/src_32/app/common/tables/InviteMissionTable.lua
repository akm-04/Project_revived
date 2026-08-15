local var_0_0 = class("InviteMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.names_ = {}
	arg_1_0.icon_ = {}
	arg_1_0.types_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.diamond_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.type_ = {}

	import("app.common.tables.TableParser").parse("invitation_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.names_[var_2_0] = arg_2_0.name
		arg_1_0.icon_[var_2_0] = arg_2_0.icon
		arg_1_0.types_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.diamond_[var_2_0] = tonumber(arg_2_0.diamond)
		arg_1_0.condition_[var_2_0] = xyd.splitToNumber(arg_2_0.task_num, "|")
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.names_[arg_3_1]
end

function var_0_0.icon(arg_4_0, arg_4_1)
	return arg_4_0.icon_[arg_4_1] or ""
end

function var_0_0.type(arg_5_0, arg_5_1)
	return arg_5_0.types_[arg_5_1] or 0
end

function var_0_0.desc(arg_6_0, arg_6_1)
	return arg_6_0.desc_[arg_6_1]
end

function var_0_0.diamond(arg_7_0, arg_7_1)
	return arg_7_0.diamond_[arg_7_1] or 0
end

function var_0_0.condition(arg_8_0, arg_8_1)
	return arg_8_0.condition_[arg_8_1] or {}
end

return var_0_0
