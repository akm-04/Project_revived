local var_0_0 = class("LibraryMissionTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.difficulty_ = {}
	arg_1_0.type_ = {}
	arg_1_0.req_ = {}
	arg_1_0.amour_ = {}
	arg_1_0.openLev_ = {}

	import("app.common.tables.TableParser").parse("library_mission.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.difficulty_[var_2_0] = tonumber(arg_2_0.difficulty)
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.req_[var_2_0] = tonumber(arg_2_0.req)
		arg_1_0.amour_[var_2_0] = tonumber(arg_2_0.amour)
		arg_1_0.openLev_[var_2_0] = tonumber(arg_2_0.open_lev)
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.desc(arg_4_0, arg_4_1)
	return arg_4_0.desc_[arg_4_1] or ""
end

function var_0_0.difficulty(arg_5_0, arg_5_1)
	return arg_5_0.difficulty_[arg_5_1] or 1
end

function var_0_0.type(arg_6_0, arg_6_1)
	return arg_6_0.type_[arg_6_1] or 0
end

function var_0_0.req(arg_7_0, arg_7_1)
	return arg_7_0.req_[arg_7_1] or 0
end

function var_0_0.amour(arg_8_0, arg_8_1)
	return arg_8_0.amour_[arg_8_1] or 0
end

function var_0_0.openLev(arg_9_0, arg_9_1)
	return arg_9_0.openLev_[arg_9_1] or 0
end

return var_0_0
