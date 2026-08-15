local var_0_0 = class("TeacherMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.gift_ = {}
	arg_1_0.condition_ = {}
	arg_1_0.lev_ = {}
	arg_1_0.extra_info_ = {}
	arg_1_0.is_hide_ = {}

	import("app.common.tables.TableParser").parse("teacher_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.gift_[var_2_0] = tonumber(arg_2_0.gift)
		arg_1_0.condition_[var_2_0] = tonumber(arg_2_0.condition)
		arg_1_0.lev_[var_2_0] = tonumber(arg_2_0.lev)
		arg_1_0.extra_info_[var_2_0] = tonumber(arg_2_0.extra_info)
		arg_1_0.is_hide_[var_2_0] = tonumber(arg_2_0.is_hide)
	end)
end

function var_0_0.desc(arg_3_0, arg_3_1)
	return arg_3_0.desc_[arg_3_1] or ""
end

function var_0_0.type(arg_4_0, arg_4_1)
	return arg_4_0.type_[arg_4_1] or ""
end

function var_0_0.gift(arg_5_0, arg_5_1)
	return arg_5_0.gift_[arg_5_1] or 0
end

function var_0_0.condition(arg_6_0, arg_6_1)
	return arg_6_0.condition_[arg_6_1] or 0
end

function var_0_0.openLev(arg_7_0, arg_7_1)
	return arg_7_0.lev_[arg_7_1] or 0
end

function var_0_0.extraInfo(arg_8_0, arg_8_1)
	return arg_8_0.extra_info_[arg_8_1] or 0
end

function var_0_0.isHide(arg_9_0, arg_9_1)
	return arg_9_0.is_hide_[arg_9_1] or 0
end

return var_0_0
