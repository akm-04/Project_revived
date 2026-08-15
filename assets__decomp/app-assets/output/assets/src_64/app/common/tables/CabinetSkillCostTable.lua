local var_0_0 = class("CabinetSkillCostTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.cost_res_type = {}
	arg_1_0.cost_res_type[1] = {}
	arg_1_0.cost_res_type[2] = {}
	arg_1_0.cost_res_type[3] = {}
	arg_1_0.cost_res_type[4] = {}
	arg_1_0.cost_res_num = {}
	arg_1_0.cost_res_num[1] = {}
	arg_1_0.cost_res_num[2] = {}
	arg_1_0.cost_res_num[3] = {}
	arg_1_0.cost_res_num[4] = {}

	import("app.common.tables.TableParser").parse("event_centre_skillcost.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.id)

		arg_1_0.cost_res_type[1][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_type1, "|")
		arg_1_0.cost_res_type[2][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_type2, "|")
		arg_1_0.cost_res_type[3][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_type3, "|")
		arg_1_0.cost_res_type[4][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_type4, "|")
		arg_1_0.cost_res_num[1][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_num1, "|")
		arg_1_0.cost_res_num[2][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_num2, "|")
		arg_1_0.cost_res_num[3][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_num3, "|")
		arg_1_0.cost_res_num[4][var_2_0] = xyd.splitToNumber(arg_2_0.cost_res_num4, "|")
	end)
end

function var_0_0.getResType(arg_3_0, arg_3_1, arg_3_2)
	return arg_3_0.cost_res_type[arg_3_1][arg_3_2] or {}
end

function var_0_0.getResNum(arg_4_0, arg_4_1, arg_4_2)
	return arg_4_0.cost_res_num[arg_4_1][arg_4_2] or {}
end

return var_0_0
