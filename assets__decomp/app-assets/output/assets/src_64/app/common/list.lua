return {
	append = function(arg_1_0, arg_1_1)
		for iter_1_0, iter_1_1 in ipairs(arg_1_1) do
			table.insert(arg_1_0, iter_1_1)
		end
	end,
	popFront = function(arg_2_0)
		if arg_2_0 ~= nil and #arg_2_0 > 0 then
			return table.remove(arg_2_0, 1)
		end
	end,
	fill = function(arg_3_0, arg_3_1, arg_3_2)
		for iter_3_0 = 1, arg_3_2 do
			table.insert(arg_3_0, arg_3_1)
		end

		return arg_3_0
	end,
	reduce = function(arg_4_0, arg_4_1)
		local var_4_0

		for iter_4_0, iter_4_1 in ipairs(arg_4_0) do
			if iter_4_0 == 1 then
				var_4_0 = iter_4_1
			else
				var_4_0 = arg_4_1(var_4_0, iter_4_1)
			end
		end

		return var_4_0
	end,
	contains = function(arg_5_0, arg_5_1)
		for iter_5_0, iter_5_1 in ipairs(arg_5_0) do
			if iter_5_1 == arg_5_1 then
				return true
			end
		end
	end,
	unique = function(arg_6_0)
		local var_6_0 = {}

		for iter_6_0, iter_6_1 in ipairs(arg_6_0) do
			var_6_0[iter_6_1] = true
		end

		local var_6_1 = {}

		for iter_6_2 in pairs(var_6_0) do
			table.insert(var_6_1, iter_6_2)
		end

		return var_6_1
	end,
	randomSelect = function(arg_7_0, arg_7_1)
		local var_7_0 = {}
		local var_7_1 = 1

		for iter_7_0 = 1, arg_7_1 do
			if var_7_1 > #arg_7_0 then
				break
			end

			local var_7_2 = math.random(var_7_1, #arg_7_0)

			table.insert(var_7_0, arg_7_0[var_7_2])

			arg_7_0[var_7_1], arg_7_0[var_7_2] = arg_7_0[var_7_2], arg_7_0[var_7_1]
			var_7_1 = var_7_1 + 1
		end

		return var_7_0
	end
}
