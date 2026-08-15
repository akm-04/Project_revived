local var_0_0 = class("TeacherExpTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.relation_ = {}
	arg_1_0.exp_ = {}
	arg_1_0.maxId = 0

	import("app.common.tables.TableParser").parse("teacher_exp.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.relation_[var_2_0] = tonumber(arg_2_0.relation)
		arg_1_0.exp_[var_2_0] = tonumber(arg_2_0.exp) / 100

		if not arg_1_0.maxId or var_2_0 > arg_1_0.maxId then
			arg_1_0.maxId = var_2_0
		end
	end)
end

function var_0_0.relation(arg_3_0, arg_3_1)
	return arg_3_0.relation_[arg_3_1] or 0
end

function var_0_0.exp(arg_4_0, arg_4_1)
	return arg_4_0.exp_[arg_4_1] or 0
end

return var_0_0
