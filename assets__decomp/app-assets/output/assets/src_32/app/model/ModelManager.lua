local var_0_0 = {}
local var_0_1 = xyd.tables.modelDefine:names()

for iter_0_0, iter_0_1 in pairs(var_0_1) do
	var_0_0[iter_0_0] = import("." .. iter_0_1)
end

local var_0_2 = class("ModelManager")

function var_0_2.get()
	if var_0_2.INSTANCE == nil then
		var_0_2.INSTANCE = var_0_2.new()
	end

	return var_0_2.INSTANCE
end

function var_0_2.ctor(arg_2_0)
	arg_2_0.models_ = {}
	arg_2_0.totalModels_ = {}
	arg_2_0.totalModels_ = var_0_0
end

function var_0_2.loadModel(arg_3_0, arg_3_1)
	if arg_3_0.models_[arg_3_1] == nil then
		local var_3_0 = arg_3_0.totalModels_[arg_3_1].new()

		if var_3_0 ~= nil then
			arg_3_0.models_[arg_3_1] = var_3_0

			var_3_0:onRegister()
		end
	end

	return arg_3_0.models_[arg_3_1]
end

function var_0_2.reset(arg_4_0)
	arg_4_0.models_ = {}
end

return var_0_2
