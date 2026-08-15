local var_0_0 = class("ZhugeSkillTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.ids_ = {}
	arg_1_0.name_ = {}
	arg_1_0.desc_ = {}
	arg_1_0.type_ = {}
	arg_1_0.num_ = {}

	import("app.common.tables.TableParser").parse("zhuge_skill.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		table.insert(arg_1_0.ids_, var_2_0)

		arg_1_0.name_[var_2_0] = arg_2_0.name
		arg_1_0.desc_[var_2_0] = arg_2_0.desc
		arg_1_0.type_[var_2_0] = tonumber(arg_2_0.type)
		arg_1_0.num_[var_2_0] = xyd.splitToNumber(arg_2_0.num, "|")
	end)
end

function var_0_0.ids(arg_3_0)
	return arg_3_0.ids_ or {}
end

function var_0_0.name(arg_4_0, arg_4_1)
	return arg_4_0.name_[arg_4_1] or ""
end

function var_0_0.desc(arg_5_0, arg_5_1)
	return arg_5_0.desc_[arg_5_1] or ""
end

function var_0_0.type(arg_6_0, arg_6_1)
	return arg_6_0.type_[arg_6_1] or 0
end

function var_0_0.num(arg_7_0, arg_7_1)
	return arg_7_0.num_[arg_7_1] or {}
end

return var_0_0
