local var_0_0 = class("ActivitySakura2CookTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.food_ = {}
	arg_1_0.material_ = {}
	arg_1_0.caseRate_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura2_cook.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.food)

		table.insert(arg_1_0.food_, var_2_0)

		arg_1_0.material_[var_2_0] = xyd.splitToNumber(arg_2_0.material, "|")
		arg_1_0.caseRate_[var_2_0] = xyd.splitToNumber(arg_2_0.case_rate, "|")
	end)
end

function var_0_0.material(arg_3_0, arg_3_1)
	return arg_3_0.material_[arg_3_1] or {}
end

function var_0_0.getMaterialByItemId(arg_4_0, arg_4_1)
	return arg_4_0.material_[arg_4_1] or {}
end

function var_0_0.caseRate(arg_5_0, arg_5_1)
	return arg_5_0.caseRate_[arg_5_1] or {}
end

function var_0_0.canCompose(arg_6_0, arg_6_1)
	for iter_6_0, iter_6_1 in pairs(arg_6_0.food_) do
		local var_6_0 = arg_6_0:material(iter_6_1)

		for iter_6_2 = 1, #var_6_0 do
			if not arg_6_0:isInTable(arg_6_1, var_6_0[iter_6_2]) then
				break
			elseif iter_6_2 == #var_6_0 then
				return iter_6_1
			end
		end
	end

	return nil
end

function var_0_0.isInTable(arg_7_0, arg_7_1, arg_7_2)
	for iter_7_0, iter_7_1 in pairs(arg_7_1) do
		if iter_7_1 == arg_7_2 then
			return true
		end
	end

	return false
end

function var_0_0.ids(arg_8_0)
	return arg_8_0.food_
end

return var_0_0
