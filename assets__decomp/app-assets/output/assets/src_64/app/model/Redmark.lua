local var_0_0 = class("Redmark", import(".BaseModel"))

function var_0_0.ctor(arg_1_0)
	arg_1_0.redmarks = {}
	arg_1_0.redmarkMap = {}
end

function var_0_0.onRegister(arg_2_0)
	return
end

function var_0_0.onUpdate(arg_3_0, arg_3_1)
	if arg_3_1 and next(arg_3_1) then
		for iter_3_0, iter_3_1 in pairs(arg_3_1) do
			arg_3_0.redmarks[iter_3_1.function_id] = iter_3_1.redmark_list

			if iter_3_1.redmark_list and next(iter_3_1.redmark_list) then
				arg_3_0.redmarkMap[iter_3_1.function_id] = {}

				for iter_3_2, iter_3_3 in ipairs(iter_3_1.redmark_list) do
					arg_3_0.redmarkMap[iter_3_1.function_id][iter_3_3] = 1
				end
			else
				arg_3_0.redmarks[iter_3_1.function_id] = nil
				arg_3_0.redmarkMap[iter_3_1.function_id] = nil
			end
		end

		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.BACKEND_REDMARK
		})
	end
end

function var_0_0.isRedmark(arg_4_0, arg_4_1, arg_4_2)
	if arg_4_1 and not arg_4_2 then
		if arg_4_0.redmarkMap[arg_4_1] and next(arg_4_0.redmarkMap[arg_4_1]) then
			return true
		end
	elseif arg_4_1 and arg_4_2 and arg_4_0.redmarkMap[arg_4_1] and arg_4_0.redmarkMap[arg_4_1][arg_4_2] then
		return true
	end

	return false
end

return var_0_0
