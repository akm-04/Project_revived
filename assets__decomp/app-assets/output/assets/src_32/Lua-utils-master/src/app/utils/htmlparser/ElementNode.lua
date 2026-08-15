local var_0_0 = {}

var_0_0.mt = {
	__index = var_0_0
}

function var_0_0.new(arg_1_0, arg_1_1)
	local var_1_0 = {}
	local var_1_1

	if getmetatable(arg_1_1) == var_0_0.mt then
		var_1_1 = true
	end

	if type(arg_1_1) == "table" then
		if not var_1_1 and #arg_1_1 > 0 then
			for iter_1_0, iter_1_1 in ipairs(arg_1_1) do
				var_1_0[iter_1_1] = true
			end
		else
			for iter_1_2 in pairs(arg_1_1) do
				var_1_0[iter_1_2] = true
			end
		end
	elseif arg_1_1 ~= nil then
		var_1_0 = {
			[arg_1_1] = true
		}
	end

	return setmetatable(var_1_0, var_0_0.mt)
end

function var_0_0.add(arg_2_0, arg_2_1)
	if arg_2_1 ~= nil then
		arg_2_0[arg_2_1] = true
	end

	return arg_2_0
end

function var_0_0.remove(arg_3_0, arg_3_1)
	if arg_3_1 ~= nil then
		arg_3_0[arg_3_1] = nil
	end

	return arg_3_0
end

function var_0_0.tolist(arg_4_0)
	local var_4_0 = {}

	for iter_4_0 in pairs(arg_4_0) do
		table.insert(var_4_0, iter_4_0)
	end

	return var_4_0
end

function var_0_0.mt.__add(arg_5_0, arg_5_1)
	local var_5_0 = var_0_0:new()
	local var_5_1 = var_0_0:new(arg_5_0)
	local var_5_2 = var_0_0:new(arg_5_1)

	for iter_5_0 in pairs(var_5_1) do
		var_5_0[iter_5_0] = true
	end

	for iter_5_1 in pairs(var_5_2) do
		var_5_0[iter_5_1] = true
	end

	return var_5_0
end

function var_0_0.mt.__sub(arg_6_0, arg_6_1)
	local var_6_0 = var_0_0:new()
	local var_6_1 = var_0_0:new(arg_6_0)
	local var_6_2 = var_0_0:new(arg_6_1)

	for iter_6_0 in pairs(var_6_1) do
		var_6_0[iter_6_0] = true
	end

	for iter_6_1 in pairs(var_6_2) do
		var_6_0[iter_6_1] = nil
	end

	return var_6_0
end

function var_0_0.mt.__mul(arg_7_0, arg_7_1)
	local var_7_0 = var_0_0:new()
	local var_7_1 = var_0_0:new(arg_7_0)
	local var_7_2 = var_0_0:new(arg_7_1)

	for iter_7_0 in pairs(var_7_1) do
		var_7_0[iter_7_0] = var_7_2[iter_7_0]
	end

	return var_7_0
end

function var_0_0.mt.__tostring(arg_8_0)
	local var_8_0 = "{"
	local var_8_1 = ""

	for iter_8_0 in pairs(arg_8_0) do
		var_8_0 = var_8_0 .. var_8_1 .. tostring(iter_8_0)
		var_8_1 = ", "
	end

	return var_8_0 .. "}"
end

local var_0_1 = {}

var_0_1.mt = {
	__index = var_0_1
}

function var_0_1.new(arg_9_0, arg_9_1, arg_9_2, arg_9_3, arg_9_4, arg_9_5, arg_9_6)
	local var_9_0 = {
		level = 0,
		index = arg_9_1,
		name = arg_9_2,
		nodes = {},
		_openstart = arg_9_5,
		_openend = arg_9_6,
		_closestart = arg_9_5,
		_closeend = arg_9_6,
		attributes = {},
		classes = {},
		deepernodes = var_0_0:new(),
		deeperelements = {},
		deeperattributes = {},
		deeperids = {},
		deeperclasses = {}
	}

	if not arg_9_3 then
		var_9_0.name = "root"
		var_9_0.root = var_9_0
		var_9_0._text = arg_9_2

		local var_9_1 = string.len(arg_9_2)

		var_9_0._openstart, var_9_0._openend = 1, var_9_1
		var_9_0._closestart, var_9_0._closeend = 1, var_9_1
	elseif arg_9_4 then
		var_9_0.root = arg_9_3.root
		var_9_0.parent = arg_9_3
		var_9_0.level = arg_9_3.level + 1

		table.insert(arg_9_3.nodes, var_9_0)
	else
		var_9_0.root = arg_9_3.root
		var_9_0.parent = arg_9_3.parent
		var_9_0.level = arg_9_3.level

		table.insert(arg_9_3.parent.nodes, var_9_0)
	end

	return setmetatable(var_9_0, var_0_1.mt)
end

function var_0_1.gettext(arg_10_0)
	return string.sub(arg_10_0.root._text, arg_10_0._openstart, arg_10_0._closeend)
end

function var_0_1.settext(arg_11_0, arg_11_1)
	arg_11_0.root._text = arg_11_1
end

function var_0_1.textonly(arg_12_0)
	return (arg_12_0:gettext():gsub("<[^>]*>", ""))
end

function var_0_1.getcontent(arg_13_0)
	return string.sub(arg_13_0.root._text, arg_13_0._openend + 1, arg_13_0._closestart - 1)
end

function var_0_1.addattribute(arg_14_0, arg_14_1, arg_14_2)
	arg_14_0.attributes[arg_14_1] = arg_14_2

	if string.lower(arg_14_1) == "id" then
		arg_14_0.id = arg_14_2
	elseif string.lower(arg_14_1) == "class" then
		for iter_14_0 in string.gmatch(arg_14_2, "%S+") do
			table.insert(arg_14_0.classes, iter_14_0)
		end
	end
end

local function var_0_2(arg_15_0, arg_15_1, arg_15_2)
	arg_15_0[arg_15_1] = arg_15_0[arg_15_1] or var_0_0:new()

	arg_15_0[arg_15_1]:add(arg_15_2)
end

function var_0_1.close(arg_16_0, arg_16_1, arg_16_2)
	if arg_16_1 and arg_16_2 then
		arg_16_0._closestart, arg_16_0._closeend = arg_16_1, arg_16_2
	end

	local var_16_0 = arg_16_0

	while true do
		var_16_0 = var_16_0.parent

		if not var_16_0 then
			break
		end

		var_16_0.deepernodes:add(arg_16_0)
		var_0_2(var_16_0.deeperelements, arg_16_0.name, arg_16_0)

		for iter_16_0 in pairs(arg_16_0.attributes) do
			var_0_2(var_16_0.deeperattributes, iter_16_0, arg_16_0)
		end

		if arg_16_0.id then
			var_0_2(var_16_0.deeperids, arg_16_0.id, arg_16_0)
		end

		for iter_16_1, iter_16_2 in ipairs(arg_16_0.classes) do
			var_0_2(var_16_0.deeperclasses, iter_16_2, arg_16_0)
		end
	end
end

local function var_0_3(arg_17_0)
	return string.gsub(arg_17_0, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%" .. "%1")
end

local function var_0_4(arg_18_0, arg_18_1)
	if not arg_18_1 or type(arg_18_1) ~= "string" or arg_18_1 == "" then
		return var_0_0:new()
	end

	local var_18_0 = {
		[""] = arg_18_0.deeperelements,
		["["] = arg_18_0.deeperattributes,
		["#"] = arg_18_0.deeperids,
		["."] = arg_18_0.deeperclasses
	}

	local function var_18_1(arg_19_0, arg_19_1)
		local var_19_0
		local var_19_1
		local var_19_2

		if arg_19_0 == "[" then
			arg_19_1, var_19_0, var_19_1, var_19_2 = string.match(arg_19_1, "([^=|%*~%$!%^]+)" .. "([|%*~%$!%^]?)" .. "(=?)" .. "(.*)")
		end

		local var_19_3 = var_0_0:new(var_18_0[arg_19_0][arg_19_1])

		if var_19_1 == "=" then
			if #var_19_2 < 2 then
				var_19_2 = "'" .. var_19_2 .. "'"
			end

			local var_19_4 = string.sub(var_19_2, 2, #var_19_2 - 1)

			if var_19_0 == "!" then
				var_19_3 = var_0_0:new(arg_18_0.deepernodes)
			end

			for iter_19_0 in pairs(var_19_3) do
				local var_19_5 = iter_19_0.attributes[arg_19_1]

				if var_19_0 == "" and var_19_5 ~= var_19_4 then
					var_19_3:remove(iter_19_0)
				elseif var_19_0 == "!" and var_19_5 == var_19_4 then
					var_19_3:remove(iter_19_0)
				elseif var_19_0 == "|" and string.match(var_19_5, "^[^-]*") ~= var_19_4 then
					var_19_3:remove(iter_19_0)
				elseif var_19_0 == "*" and string.match(var_19_5, var_0_3(var_19_4)) ~= var_19_4 then
					var_19_3:remove(iter_19_0)
				elseif var_19_0 == "~" then
					var_19_3:remove(iter_19_0)

					for iter_19_1 in string.gmatch(var_19_5, "%S+") do
						if iter_19_1 == var_19_4 then
							var_19_3:add(iter_19_0)

							break
						end
					end
				elseif var_19_0 == "^" and string.match(var_19_5, "^" .. var_0_3(var_19_4)) ~= var_19_4 then
					var_19_3:remove(iter_19_0)
				elseif var_19_0 == "$" and string.match(var_19_5, var_0_3(var_19_4) .. "$") ~= var_19_4 then
					var_19_3:remove(iter_19_0)
				end
			end
		end

		return var_19_3
	end

	local var_18_2, var_18_3, var_18_4 = var_0_0:new({
		arg_18_0
	})

	for iter_18_0 in string.gmatch(arg_18_1, "%S+") do
		repeat
			if iter_18_0 == ">" then
				var_18_4 = true

				break
			end

			var_18_3 = var_0_0:new()

			for iter_18_1 in pairs(var_18_2) do
				local var_18_5 = iter_18_1.deepernodes

				if var_18_4 then
					var_18_5 = var_0_0:new(iter_18_1.nodes)
				end

				var_18_3 = var_18_3 + var_18_5
			end

			var_18_4 = false

			if iter_18_0 == "*" then
				break
			end

			local var_18_6, var_18_7 = var_0_0:new()
			local var_18_8 = 0
			local var_18_9 = 0

			while true do
				local var_18_10
				local var_18_11
				local var_18_12
				local var_18_13
				local var_18_14
				local var_18_15, var_18_16, var_18_17, var_18_18, var_18_19, var_18_20

				var_18_15, var_18_9, var_18_16, var_18_17, var_18_18, var_18_19, var_18_20 = string.find(iter_18_0, "(%(?%)?)" .. "([:%[#.]?)" .. "([%w-_\\]+)" .. "([|%*~%$!%^]?=?)" .. "(['\"]?)", var_18_9 + 1)

				if not var_18_18 then
					break
				end

				repeat
					if var_18_17 == ":" then
						var_18_7 = var_18_18

						break
					end

					if var_18_16 == ")" then
						var_18_7 = nil
					end

					if var_18_17 == "[" and var_18_20 ~= "" then
						local var_18_21
						local var_18_22, var_18_23

						var_18_22, var_18_9, var_18_23 = string.find(iter_18_0, "(%b" .. var_18_20 .. var_18_20 .. ")]", var_18_9)
						var_18_18 = var_18_18 .. var_18_19 .. var_18_23
					end

					local var_18_24 = var_18_1(var_18_17, var_18_18)

					if var_18_7 == "not" then
						var_18_6 = var_18_6 + var_18_24

						break
					end

					var_18_3 = var_18_3 * var_18_24

					break
				until true
			end

			var_18_3 = var_18_3 - var_18_6
			var_18_2 = var_0_0:new(var_18_3)

			break
		until true
	end

	local var_18_25 = var_18_3:tolist()

	table.sort(var_18_25, function(arg_20_0, arg_20_1)
		return arg_20_0.index < arg_20_1.index
	end)

	return var_18_25
end

function var_0_1.select(arg_21_0, arg_21_1)
	return var_0_4(arg_21_0, arg_21_1)
end

var_0_1.mt.__call = var_0_4

return var_0_1
