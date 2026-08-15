local var_0_0 = {
	_getFileData = function(arg_1_0)
		return (cc.HelperFunc:getFileData(arg_1_0))
	end
}

function var_0_0.loadMOFromFile(arg_2_0)
	return var_0_0.parseData(var_0_0._getFileData(arg_2_0))
end

function var_0_0.gettextFromFile(arg_3_0)
	return var_0_0.gettext(var_0_0._getFileData(arg_3_0))
end

function var_0_0.gettext(arg_4_0)
	local var_4_0 = var_0_0.parseData(arg_4_0)

	return function(arg_5_0)
		return var_4_0[arg_5_0] or arg_5_0
	end
end

function var_0_0.parseData(arg_6_0)
	local var_6_0 = string.byte
	local var_6_1 = string.sub
	local var_6_2
	local var_6_3 = var_6_1(arg_6_0, 1, 4)

	if var_6_3 == "\xDE\x12\x04\x95" then
		function var_6_2(arg_7_0)
			local var_7_0, var_7_1, var_7_2, var_7_3 = var_6_0(arg_6_0, arg_7_0 + 1, arg_7_0 + 4)

			return ((var_7_3 * 256 + var_7_2) * 256 + var_7_1) * 256 + var_7_0
		end
	elseif var_6_3 == "\x95\x04\x12\xDE" then
		function var_6_2(arg_8_0)
			local var_8_0, var_8_1, var_8_2, var_8_3 = var_6_0(arg_6_0, arg_8_0 + 1, arg_8_0 + 4)

			return ((var_8_0 * 256 + var_8_1) * 256 + var_8_2) * 256 + var_8_3
		end
	else
		return nil, "no valid mo-file"
	end

	if var_6_2(4) ~= 0 then
		return nul, "unsupported version"
	end

	local var_6_4 = var_6_2(8)
	local var_6_5 = var_6_2(12)
	local var_6_6 = var_6_2(16)
	local var_6_7 = {}

	for iter_6_0 = 1, var_6_4 do
		local var_6_8 = var_6_2(var_6_5)
		local var_6_9 = var_6_2(var_6_5 + 4)

		var_6_5 = var_6_5 + 8

		local var_6_10 = var_6_2(var_6_6)
		local var_6_11 = var_6_2(var_6_6 + 4)

		var_6_6 = var_6_6 + 8
		var_6_7[var_6_1(arg_6_0, var_6_9 + 1, var_6_9 + var_6_8)] = var_6_1(arg_6_0, var_6_11 + 1, var_6_11 + var_6_10)
	end

	return var_6_7
end

return var_0_0
