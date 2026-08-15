local var_0_0 = class("ObjectSubjectTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.name_ = {}
	arg_1_0.department_ = {}
	arg_1_0.desc_ = {}

	import("app.common.tables.TableParser").parse("object_subject.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.department_[var_2_0] = xyd.splitToNumber(arg_2_0.department, "|")
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
	end)
end

function var_0_0.name(arg_3_0, arg_3_1)
	return arg_3_0.name_[arg_3_1] or ""
end

function var_0_0.department(arg_4_0, arg_4_1)
	return arg_4_0.department_[arg_4_1] or {}
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.objectCount(arg_6_0)
	return #arg_6_0.name_
end

return var_0_0
