local function var_0_0(arg_1_0)
	return string.gsub(arg_1_0, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%" .. "%1")
end

local var_0_1 = tostring
local var_0_2 = string.char

local function var_0_3(arg_2_0)
	io.stderr:write(arg_2_0)
end

local function var_0_4(arg_3_0)
	io.stdout:write(arg_3_0)
end

local var_0_5 = import(".htmlparser.ElementNode")
local var_0_6 = import(".htmlparser.voidelements")
local var_0_7 = {}
local var_0_8 = {
	["<"] = var_0_2(208, 209, 208, 209),
	[">"] = var_0_2(209, 208, 209, 208)
}

function var_0_7.parse(arg_4_0, arg_4_1)
	local var_4_0 = var_0_1(arg_4_0)
	local var_4_1 = arg_4_1 or htmlparser_looplimit or 1000
	local var_4_2 = false

	local function var_4_3(arg_5_0, ...)
		local var_5_0 = {
			...
		}

		var_5_0[arg_5_0] = var_0_8[var_5_0[arg_5_0]]
		var_4_2 = true

		return table.concat(var_5_0)
	end

	local var_4_4 = var_4_0:gsub("(<)" .. "([^>]-)" .. "(<)", function(...)
		return var_4_3(3, ...)
	end):gsub("(" .. var_0_8["<"] .. ")" .. "([^%w%s])" .. "([^%2]-)" .. "(%2)" .. "(>)" .. "([^>]-)" .. "(>)", function(...)
		return var_4_3(5, ...)
	end):gsub("(['\"])" .. "([^'\">%s]-)" .. "(>)" .. "([^'\">%s]-)" .. "(['\"])", function(...)
		return var_4_3(3, ...)
	end)
	local var_4_5 = 0
	local var_4_6 = var_0_5:new(var_4_5, var_0_1(var_4_4))
	local var_4_7 = var_4_6
	local var_4_8 = true
	local var_4_9 = 1
	local var_4_10 = {}

	while true do
		if var_4_5 == var_4_1 then
			var_0_3("[HTMLParser] [ERR] Main loop reached loop limit (" .. var_4_1 .. "). Please, consider increasing it or check the code for errors")

			break
		end

		local var_4_11
		local var_4_12
		local var_4_13, var_4_14

		var_4_13, var_4_9, var_4_14 = var_4_6._text:find("<" .. "([%w-]+)" .. "[^>]*>", var_4_9)

		if not var_4_14 then
			break
		end

		var_4_5 = var_4_5 + 1

		local var_4_15 = var_0_5:new(var_4_5, var_0_1(var_4_14), var_4_7, var_4_8, var_4_13, var_4_9)

		var_4_7 = var_4_15

		local var_4_16
		local var_4_17 = var_4_15:gettext()
		local var_4_18 = 1

		while true do
			if var_4_16 == var_4_1 then
				var_0_3("[HTMLParser] [ERR] tag parsing loop reached loop limit (" .. var_4_1 .. "). Please, consider increasing it or check the code for errors")

				break
			end

			local var_4_19
			local var_4_20
			local var_4_21
			local var_4_22
			local var_4_23
			local var_4_24, var_4_25, var_4_26, var_4_27

			var_4_24, var_4_18, var_4_25, var_4_26, var_4_27 = var_4_17:find("%s+" .. "([^%s=/>]+)" .. "(=?)" .. "(['\"]?)", var_4_18)

			if not var_4_25 or var_4_25 == "/>" or var_4_25 == ">" then
				break
			end

			if var_4_26 == "=" then
				pattern = "=([^%s>]*)"

				if var_4_27 ~= "" then
					pattern = var_4_27 .. "([^" .. var_4_27 .. "]*)" .. var_4_27
				end

				local var_4_28

				var_4_28, var_4_18, var_4_23 = var_4_17:find(pattern, var_4_18)
			end

			var_4_23 = var_4_23 or ""

			if var_4_2 then
				for iter_4_0, iter_4_1 in pairs(var_0_8) do
					var_4_23 = var_4_23:gsub(iter_4_1, iter_4_0)
				end
			end

			var_4_15:addattribute(var_4_25, var_4_23)

			var_4_16 = (var_4_16 or 0) + 1
		end

		if var_0_6[var_4_15.name:lower()] then
			var_4_8 = false

			var_4_15:close()
		else
			var_4_10[var_4_15.name] = var_4_10[var_4_15.name] or {}

			table.insert(var_4_10[var_4_15.name], var_4_15)
		end

		local var_4_29 = var_4_9
		local var_4_30

		while true do
			if var_4_30 == var_4_1 then
				var_0_3("[HTMLParser] [ERR] tag closing loop reached loop limit (" .. var_4_1 .. "). Please, consider increasing it or check the code for errors")

				break
			end

			local var_4_31
			local var_4_32
			local var_4_33
			local var_4_34, var_4_35, var_4_36

			var_4_34, var_4_29, var_4_35, var_4_36 = var_4_6._text:find("[^<]*<(/?)([%w-]+)", var_4_29)

			if not var_4_35 or var_4_35 == "" then
				break
			end

			var_4_15 = table.remove(var_4_10[var_4_36] or {}) or var_4_15

			local var_4_37 = var_4_6._text:find("<", var_4_34)

			var_4_15:close(var_4_37, var_4_29 + 1)

			var_4_7 = var_4_15.parent
			var_4_8 = true
			var_4_30 = (var_4_30 or 0) + 1
		end
	end

	if var_4_2 then
		for iter_4_2, iter_4_3 in pairs(var_0_8) do
			var_4_6._text = var_4_6._text:gsub(iter_4_3, iter_4_2)
		end
	end

	return var_4_6
end

return var_0_7
