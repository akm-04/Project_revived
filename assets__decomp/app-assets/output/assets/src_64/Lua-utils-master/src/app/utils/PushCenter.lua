local var_0_0 = {
	_listeners = {}
}

function var_0_0.addListener(arg_1_0, arg_1_1, arg_1_2)
	assert(arg_1_2, "Tag must not be nil")

	local var_1_0 = var_0_0._listeners

	if not var_1_0[arg_1_0] then
		var_1_0[arg_1_0] = {}
	end

	local var_1_1 = var_1_0[arg_1_0]

	for iter_1_0 = 1, #var_1_1 do
		if arg_1_2 == var_1_1[iter_1_0][2] then
			return
		end
	end

	table.insert(var_1_1, {
		arg_1_1,
		arg_1_2
	})
end

function var_0_0.removeListener(arg_2_0)
	local var_2_0 = var_0_0._listeners

	for iter_2_0, iter_2_1 in pairs(var_2_0) do
		for iter_2_2 = 1, #iter_2_1 do
			if iter_2_1[iter_2_2][1] == arg_2_0 then
				table.remove(iter_2_1, iter_2_2)

				if #var_2_0[iter_2_0] == 0 then
					var_2_0[iter_2_0] = nil
				end

				return
			end
		end
	end
end

function var_0_0.removeListenerByNameAndTag(arg_3_0, arg_3_1)
	assert(arg_3_1, "Tag must not be nil")

	local var_3_0 = var_0_0._listeners
	local var_3_1 = var_3_0[arg_3_0]

	if not var_3_1 then
		return
	end

	for iter_3_0 = #var_3_1, 1, -1 do
		if var_3_1[iter_3_0][2] == arg_3_1 then
			table.remove(var_3_1, iter_3_0)

			break
		end
	end

	if #var_3_1 == 0 then
		var_3_0[arg_3_0] = nil
	end
end

function var_0_0.removeListenersByTag(arg_4_0)
	assert(arg_4_0, "Tag must not be nil")

	local var_4_0 = var_0_0._listeners

	for iter_4_0, iter_4_1 in pairs(var_4_0) do
		var_0_0.removeListenerByNameAndTag(iter_4_0, arg_4_0)
	end
end

function var_0_0.removeAllListeners()
	var_0_0._listeners = {}
end

function var_0_0.pushEvent(arg_6_0, ...)
	local var_6_0 = var_0_0._listeners[arg_6_0]

	if not var_6_0 then
		return
	end

	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(var_6_0) do
		var_6_1[iter_6_0] = iter_6_1
	end

	for iter_6_2, iter_6_3 in ipairs(var_6_1) do
		iter_6_3[1](...)
	end
end

return var_0_0
