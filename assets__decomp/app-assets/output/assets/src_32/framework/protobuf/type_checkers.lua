local var_0_0 = type
local var_0_1 = error
local var_0_2 = string

module("type_checkers")

function TypeChecker(arg_1_0)
	local var_1_0 = arg_1_0

	return function(arg_2_0)
		local var_2_0 = var_0_0(arg_2_0)

		if var_1_0[var_0_0(arg_2_0)] == nil then
			var_0_1(var_0_2.format("%s has type %s, but expected one of: %s", arg_2_0, var_0_0(arg_2_0), var_1_0))
		end
	end
end

function Int32ValueChecker()
	local var_3_0 = -2147483648
	local var_3_1 = 2147483647

	return function(arg_4_0)
		if var_0_0(arg_4_0) ~= "number" then
			var_0_1(var_0_2.format("%s has type %s, but expected one of: number", arg_4_0, var_0_0(arg_4_0)))
		end

		if arg_4_0 < var_3_0 or arg_4_0 > var_3_1 then
			var_0_1("Value out of range: " .. arg_4_0)
		end
	end
end

function Uint32ValueChecker()
	local var_5_0 = 0
	local var_5_1 = 4294967295

	return function(arg_6_0)
		if var_0_0(arg_6_0) ~= "number" then
			var_0_1(var_0_2.format("%s has type %s, but expected one of: number", arg_6_0, var_0_0(arg_6_0)))
		end

		if arg_6_0 < var_5_0 or arg_6_0 > var_5_1 then
			var_0_1("Value out of range: " .. arg_6_0)
		end
	end
end

function Int64ValueChecker()
	local var_7_0 = -9007199254740992
	local var_7_1 = 9007199254740992

	return function(arg_8_0)
		if var_0_0(arg_8_0) ~= "number" then
			var_0_1(var_0_2.format("%s has type %s, but expected one of: number", arg_8_0, var_0_0(arg_8_0)))
		end

		if arg_8_0 < var_7_0 or arg_8_0 > var_7_1 then
			var_0_1("Value out of range: " .. arg_8_0)
		end
	end
end

function Uint64ValueChecker()
	local var_9_0 = 0
	local var_9_1 = 18014398509481984

	return function(arg_10_0)
		if var_0_0(arg_10_0) ~= "number" then
			var_0_1(var_0_2.format("%s has type %s, but expected one of: number", arg_10_0, var_0_0(arg_10_0)))
		end

		if arg_10_0 < var_9_0 or arg_10_0 > var_9_1 then
			var_0_1("Value out of range: " .. arg_10_0)
		end
	end
end

function UnicodeValueChecker()
	return function(arg_12_0)
		if var_0_0(arg_12_0) ~= "string" then
			var_0_1(var_0_2.format("%s has type %s, but expected one of: string", arg_12_0, var_0_0(arg_12_0)))
		end
	end
end
