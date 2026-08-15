local var_0_0 = class("Component")

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.name_ = arg_1_1
	arg_1_0.depends_ = checktable(arg_1_2)
end

function var_0_0.getName(arg_2_0)
	return arg_2_0.name_
end

function var_0_0.getDepends(arg_3_0)
	return arg_3_0.depends_
end

function var_0_0.getTarget(arg_4_0)
	return arg_4_0.target_
end

function var_0_0.exportMethods_(arg_5_0, arg_5_1)
	arg_5_0.exportedMethods_ = arg_5_1

	local var_5_0 = arg_5_0.target_
	local var_5_1 = arg_5_0

	for iter_5_0, iter_5_1 in ipairs(arg_5_1) do
		if not var_5_0[iter_5_1] then
			local var_5_2 = var_5_1[iter_5_1]

			var_5_0[iter_5_1] = function(arg_6_0, ...)
				return var_5_2(var_5_1, ...)
			end
		end
	end

	return arg_5_0
end

function var_0_0.bind_(arg_7_0, arg_7_1)
	arg_7_0.target_ = arg_7_1

	for iter_7_0, iter_7_1 in ipairs(arg_7_0.depends_) do
		if not arg_7_1:checkComponent(iter_7_1) then
			arg_7_1:addComponent(iter_7_1)
		end
	end

	arg_7_0:onBind_(arg_7_1)
end

function var_0_0.unbind_(arg_8_0)
	if arg_8_0.exportedMethods_ then
		local var_8_0 = arg_8_0.target_

		for iter_8_0, iter_8_1 in ipairs(arg_8_0.exportedMethods_) do
			var_8_0[iter_8_1] = nil
		end
	end

	arg_8_0:onUnbind_()
end

function var_0_0.onBind_(arg_9_0)
	return
end

function var_0_0.onUnbind_(arg_10_0)
	return
end

return var_0_0
