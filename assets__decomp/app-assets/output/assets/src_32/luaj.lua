local var_0_0 = {}
local var_0_1 = LuaJavaBridge.callStaticMethod

local function var_0_2(arg_1_0, arg_1_1)
	if type(arg_1_0) ~= "table" then
		arg_1_0 = {}
	end

	if arg_1_1 then
		return arg_1_0, arg_1_1
	end

	arg_1_1 = {
		"("
	}

	for iter_1_0, iter_1_1 in ipairs(arg_1_0) do
		local var_1_0 = type(iter_1_1)

		if var_1_0 == "number" then
			arg_1_1[#arg_1_1 + 1] = "F"
		elseif var_1_0 == "boolean" then
			arg_1_1[#arg_1_1 + 1] = "Z"
		elseif var_1_0 == "function" then
			arg_1_1[#arg_1_1 + 1] = "I"
		else
			arg_1_1[#arg_1_1 + 1] = "Ljava/lang/String;"
		end
	end

	arg_1_1[#arg_1_1 + 1] = ")V"

	return arg_1_0, table.concat(arg_1_1)
end

function var_0_0.callStaticMethod(arg_2_0, arg_2_1, arg_2_2, arg_2_3)
	local var_2_0, var_2_1 = var_0_2(arg_2_2, arg_2_3)

	return var_0_1(arg_2_0, arg_2_1, var_2_0, var_2_1)
end

return var_0_0
