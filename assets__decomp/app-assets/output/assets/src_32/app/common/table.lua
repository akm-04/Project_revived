table = table or {}

function table.sortedKeys(arg_1_0, arg_1_1)
	local var_1_0 = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0) do
		table.insert(var_1_0, iter_1_0)
	end

	table.sort(var_1_0, arg_1_1)

	return var_1_0
end

function table.contains(arg_2_0, arg_2_1)
	for iter_2_0, iter_2_1 in pairs(arg_2_0) do
		if iter_2_1 == arg_2_1 then
			return true
		end
	end

	return false
end
