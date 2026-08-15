local var_0_0 = class("FilterWordManager", import(".BaseModel"))

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	arg_2_0:createTree()
end

function var_0_0.createNode(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	return {
		c = arg_3_1 or nil,
		flag = arg_3_2 or 0,
		nodes = arg_3_3 or {}
	}
end

function var_0_0.createTree(arg_4_0)
	arg_4_0.rootNode = arg_4_0:createNode("R")

	local var_4_0 = xyd.tables.names:getNames()

	for iter_4_0 = 1, #var_4_0 do
		local var_4_1 = arg_4_0:getCharArray(var_4_0[iter_4_0])

		if #var_4_1 > 0 then
			arg_4_0:insertNode(arg_4_0.rootNode, var_4_1, 1)
		end
	end
end

function var_0_0.insertNode(arg_5_0, arg_5_1, arg_5_2, arg_5_3)
	local var_5_0 = arg_5_0:findNode(arg_5_1, arg_5_2[arg_5_3])

	if var_5_0 == nil then
		var_5_0 = arg_5_0:createNode(arg_5_2[arg_5_3])

		table.insert(arg_5_1.nodes, var_5_0)
	end

	if arg_5_3 == #arg_5_2 then
		var_5_0.flag = 1
	end

	arg_5_3 = arg_5_3 + 1

	if arg_5_3 <= #arg_5_2 then
		arg_5_0:insertNode(var_5_0, arg_5_2, arg_5_3)
	end
end

function var_0_0.findNode(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_1.nodes
	local var_6_1

	for iter_6_0, iter_6_1 in pairs(var_6_0) do
		if iter_6_1.c == arg_6_2 then
			var_6_1 = iter_6_1

			break
		end
	end

	return var_6_1
end

function var_0_0.getCharArray(arg_7_0, arg_7_1)
	arg_7_1 = arg_7_1 or ""

	local var_7_0 = {}
	local var_7_1 = string.len(arg_7_1)

	while arg_7_1 do
		local var_7_2 = string.byte(arg_7_1, 1)

		if var_7_2 == nil then
			break
		end

		if var_7_2 > 127 then
			local var_7_3 = string.sub(arg_7_1, 1, 3)

			table.insert(var_7_0, var_7_3)

			arg_7_1 = string.sub(arg_7_1, 4, var_7_1)
		else
			local var_7_4 = string.sub(arg_7_1, 1, 1)

			table.insert(var_7_0, var_7_4)

			arg_7_1 = string.sub(arg_7_1, 2, var_7_1)
		end
	end

	return var_7_0
end

function var_0_0.warningStrGsub(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_0:getCharArray(arg_8_1)
	local var_8_1 = 1
	local var_8_2 = arg_8_0.rootNode
	local var_8_3 = {}
	local var_8_4 = false

	while var_8_1 <= #var_8_0 do
		if var_8_0[var_8_1] ~= " " then
			var_8_2 = arg_8_0:findNode(var_8_2, var_8_0[var_8_1])
		end

		if var_8_2 == nil then
			var_8_1 = var_8_1 - #var_8_3
			var_8_2 = arg_8_0.rootNode
			var_8_3 = {}
		elseif var_8_2.flag == 1 then
			table.insert(var_8_3, var_8_1)

			for iter_8_0, iter_8_1 in pairs(var_8_3) do
				var_8_0[iter_8_1] = "*"
				var_8_4 = true
			end

			var_8_2 = arg_8_0.rootNode
			var_8_3 = {}
		else
			table.insert(var_8_3, var_8_1)
		end

		var_8_1 = var_8_1 + 1
	end

	local var_8_5 = ""

	for iter_8_2, iter_8_3 in ipairs(var_8_0) do
		var_8_5 = var_8_5 .. iter_8_3
	end

	return var_8_5, var_8_4
end

return var_0_0
