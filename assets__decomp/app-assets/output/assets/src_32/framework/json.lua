local var_0_0 = {}
local var_0_1

local function var_0_2()
	var_0_1 = require("cjson")
end

if not pcall(var_0_2) then
	var_0_1 = nil
end

function var_0_0.encode(arg_2_0)
	local var_2_0, var_2_1 = pcall(var_0_1.encode, arg_2_0)

	if var_2_0 then
		return var_2_1
	end

	if DEBUG > 1 then
		printError("json.encode() - encoding failed: %s", tostring(var_2_1))
	end
end

function var_0_0.decode(arg_3_0)
	local var_3_0, var_3_1 = pcall(var_0_1.decode, arg_3_0)

	if var_3_0 then
		return var_3_1
	end

	if DEBUG > 1 then
		printError("json.decode() - decoding failed: %s", tostring(var_3_1))
	end
end

if var_0_1 then
	var_0_0.null = var_0_1.null
else
	var_0_0 = nil
end

return var_0_0
