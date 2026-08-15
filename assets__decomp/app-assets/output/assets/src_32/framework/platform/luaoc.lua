local var_0_0 = {}
local var_0_1 = LuaObjcBridge.callStaticMethod

function var_0_0.callStaticMethod(arg_1_0, arg_1_1, arg_1_2)
	local var_1_0, var_1_1 = var_0_1(arg_1_0, arg_1_1, arg_1_2)

	if not var_1_0 then
		local var_1_2 = string.format("luaoc.callStaticMethod(\"%s\", \"%s\", \"%s\") - error: [%s] ", arg_1_0, arg_1_1, tostring(arg_1_2), tostring(var_1_1))

		if var_1_1 == -1 then
			printError(var_1_2 .. "INVALID PARAMETERS")
		elseif var_1_1 == -2 then
			printError(var_1_2 .. "CLASS NOT FOUND")
		elseif var_1_1 == -3 then
			printError(var_1_2 .. "METHOD NOT FOUND")
		elseif var_1_1 == -4 then
			printError(var_1_2 .. "EXCEPTION OCCURRED")
		elseif var_1_1 == -5 then
			printError(var_1_2 .. "INVALID METHOD SIGNATURE")
		else
			printError(var_1_2 .. "UNKNOWN")
		end
	end

	return var_1_0, var_1_1
end

return var_0_0
