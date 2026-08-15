if ngx and ngx.log then
	function print(...)
		local var_1_0 = {
			...
		}

		for iter_1_0, iter_1_1 in pairs(var_1_0) do
			var_1_0[iter_1_0] = tostring(iter_1_1)
		end

		ngx.log(ngx.ERR, table.concat(var_1_0, "\t"))
	end
end

function DEPRECATED(arg_2_0, arg_2_1, arg_2_2)
	return function(...)
		PRINT_DEPRECATED(string.format("%s() is deprecated, please use %s()", arg_2_1, arg_2_2))

		return arg_2_0(...)
	end
end

function PRINT_DEPRECATED(arg_4_0)
	if not DISABLE_DEPRECATED_WARNING then
		printf("[DEPRECATED] %s", arg_4_0)
	end
end

function printLog(arg_5_0, arg_5_1, ...)
	local var_5_0 = {
		"[",
		string.upper(tostring(arg_5_0)),
		"] ",
		string.format(tostring(arg_5_1), ...)
	}

	print(table.concat(var_5_0))
end

function printError(arg_6_0, ...)
	printLog("ERR", arg_6_0, ...)
	print(debug.traceback("", 2))
end

function printInfo(arg_7_0, ...)
	printLog("INFO", arg_7_0, ...)
end

function dump(arg_8_0, arg_8_1, arg_8_2)
	if type(arg_8_2) ~= "number" then
		arg_8_2 = 3
	end

	local var_8_0 = {}
	local var_8_1 = {}

	local function var_8_2(arg_9_0)
		if type(arg_9_0) == "string" then
			arg_9_0 = "\"" .. arg_9_0 .. "\""
		end

		return tostring(arg_9_0)
	end

	local var_8_3 = string.split(_G.__old_traceback("", 2), "\n")

	print("dump from: " .. string.trim(var_8_3[3]))

	local function var_8_4(arg_10_0, arg_10_1, arg_10_2, arg_10_3, arg_10_4)
		arg_10_1 = arg_10_1 or "<var>"

		local var_10_0 = ""

		if type(arg_10_4) == "number" then
			var_10_0 = string.rep(" ", arg_10_4 - string.len(var_8_2(arg_10_1)))
		end

		if type(arg_10_0) ~= "table" then
			var_8_1[#var_8_1 + 1] = string.format("%s%s%s = %s", arg_10_2, var_8_2(arg_10_1), var_10_0, var_8_2(arg_10_0))
		elseif var_8_0[arg_10_0] then
			var_8_1[#var_8_1 + 1] = string.format("%s%s%s = *REF*", arg_10_2, arg_10_1, var_10_0)
		else
			var_8_0[arg_10_0] = true

			if arg_10_3 > arg_8_2 then
				var_8_1[#var_8_1 + 1] = string.format("%s%s = *MAX NESTING*", arg_10_2, arg_10_1)
			else
				var_8_1[#var_8_1 + 1] = string.format("%s%s = {", arg_10_2, var_8_2(arg_10_1))

				local var_10_1 = arg_10_2 .. "    "
				local var_10_2 = {}
				local var_10_3 = 0
				local var_10_4 = {}

				for iter_10_0, iter_10_1 in pairs(arg_10_0) do
					var_10_2[#var_10_2 + 1] = iter_10_0

					local var_10_5 = var_8_2(iter_10_0)
					local var_10_6 = string.len(var_10_5)

					if var_10_3 < var_10_6 then
						var_10_3 = var_10_6
					end

					var_10_4[iter_10_0] = iter_10_1
				end

				table.sort(var_10_2, function(arg_11_0, arg_11_1)
					if type(arg_11_0) == "number" and type(arg_11_1) == "number" then
						return arg_11_0 < arg_11_1
					else
						return tostring(arg_11_0) < tostring(arg_11_1)
					end
				end)

				for iter_10_2, iter_10_3 in ipairs(var_10_2) do
					var_8_4(var_10_4[iter_10_3], iter_10_3, var_10_1, arg_10_3 + 1, var_10_3)
				end

				var_8_1[#var_8_1 + 1] = string.format("%s}", arg_10_2)
			end
		end
	end

	var_8_4(arg_8_0, arg_8_1, "- ", 1)

	for iter_8_0, iter_8_1 in ipairs(var_8_1) do
		print(iter_8_1)
	end
end
