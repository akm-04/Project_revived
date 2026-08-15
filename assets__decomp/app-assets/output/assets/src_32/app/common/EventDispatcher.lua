local var_0_0 = class("EventDispatcher")

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.ctor(arg_2_0)
	cc(arg_2_0):addComponent("components.behavior.EventProtocol"):exportMethods()
end

return var_0_0
