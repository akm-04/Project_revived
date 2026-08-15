local var_0_0 = class("ActivitySakura3CookTable")

function var_0_0.ctor(arg_1_0)
	arg_1_0.food_ = {}
	arg_1_0.material_ = {}
	arg_1_0.satisfaction_ = {}

	import("app.common.tables.TableParser").parse("activity_sakura3_cook.lua", function(arg_2_0)
		local var_2_0 = tonumber(arg_2_0.food)

		table.insert(arg_1_0.food_, var_2_0)

		arg_1_0.material_[var_2_0] = xyd.splitToNumber(arg_2_0.material, "|")
		arg_1_0.satisfaction_[var_2_0] = tonumber(arg_2_0.satisfaction)
	end)
end

function var_0_0.material(arg_3_0, arg_3_1)
	return arg_3_0.material_[arg_3_1] or {}
end

function var_0_0.satisfaction(arg_4_0, arg_4_1)
	return arg_4_0.satisfaction_[arg_4_1] or 0
end

function var_0_0.canCompose(arg_5_0, arg_5_1)
	for iter_5_0, iter_5_1 in pairs(arg_5_0.food_) do
		local var_5_0 = arg_5_0:material(iter_5_1)

		for iter_5_2 = 1, #var_5_0 do
			if not arg_5_0:isInTable(arg_5_1, var_5_0[iter_5_2]) then
				break
			elseif iter_5_2 == #var_5_0 then
				return iter_5_1
			end
		end
	end

	return nil
end

function var_0_0.isInTable(arg_6_0, arg_6_1, arg_6_2)
	for iter_6_0, iter_6_1 in pairs(arg_6_1) do
		if iter_6_1 == arg_6_2 then
			return true
		end
	end

	return false
end

function var_0_0.ids(arg_7_0)
	return arg_7_0.food_
end

return var_0_0
